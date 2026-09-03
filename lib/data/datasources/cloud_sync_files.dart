import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/data/datasources/cloud_sync_snapshot.dart';
import 'package:pluto/data/datasources/cover_letter_storage.dart';
import 'package:pluto/data/datasources/custom_theme_storage.dart';
import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudFileEntry {
  const CloudFileEntry({
    required this.folder,
    required this.name,
    required this.size,
    this.localPath,
  });

  final String folder;
  final String name;
  final int size;
  final String? localPath;

  String get key => '$folder/$name';

  Map<String, dynamic> toJson() => {
        'folder': folder,
        'name': name,
        'size': size,
      };

  static CloudFileEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final folder = '${raw['folder'] ?? ''}';
    final name = '${raw['name'] ?? ''}';
    if (folder.isEmpty || name.isEmpty) return null;
    if (!CloudSyncFiles.folders.contains(folder)) return null;
    if (name.contains('/') || name.contains('\\') || name == '..') return null;
    return CloudFileEntry(
      folder: folder,
      name: name,
      size: (raw['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class CloudSyncFiles {
  CloudSyncFiles._();

  static final _tasks = <UploadTask>[];
  static final _remoteSizes = <String, int>{};
  static Future<void> _chain = Future.value();

  static const folders = [
    CoverLetterStorage.coverLettersFolder,
    CoverLetterStorage.licenseFilesFolder,
    'diaries',
    CustomThemeStorage.folderName,
  ];
  static const parkedFolder = 'cloud_parked_files';

  static String fingerprint(List<CloudFileEntry> files) {
    final keys = [for (final file in files) '${file.key}:${file.size}']..sort();
    return keys.join('|');
  }

  static List<CloudFileEntry> parseManifest(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        ?CloudFileEntry.fromJson(item),
    ];
  }

  static List<CloudFileEntry> merge(List<CloudFileEntry> primary, List<CloudFileEntry> extra) {
    final found = <String, CloudFileEntry>{
      for (final file in extra) file.key: file,
    };
    for (final file in primary) {
      found[file.key] = file;
    }
    return found.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  static List<CloudFileEntry> referencedInDump(Map<String, dynamic> dump) {
    final found = <String, CloudFileEntry>{};
    void take(String? path) {
      if (path == null || path.isEmpty) return;
      final parsed = SyncedFileStore.parse(path);
      if (parsed == null) return;
      found[SyncedFileStore.keyOf(parsed.folder, parsed.name)] = CloudFileEntry(
        folder: parsed.folder,
        name: parsed.name,
        size: 0,
      );
    }

    void takeList(String key, List<String> fields) {
      final raw = dump[key];
      if (raw is! Map || raw['t'] != 's') return;
      final value = raw['v'];
      if (value is! String || value.isEmpty) return;
      final decoded = jsonDecode(value);
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is! Map) continue;
        for (final field in fields) {
          final path = item[field];
          if (path is String) take(path);
        }
      }
    }

    takeList(CloudSyncSnapshot.diariesKey, const ['photoPath']);
    takeList(CloudSyncSnapshot.jobsKey, const ['coverLetterPath']);
    takeList(CloudSyncSnapshot.licensesKey, const ['filePath']);
    takeList(CloudSyncSnapshot.themesKey, const [
      'photoPath',
      'decorationPath',
      'bottomPath',
      'imagePath',
    ]);
    return found.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  static Future<List<CloudFileEntry>> collect(SharedPreferences prefs) async {
    if (kIsWeb) {
      return [
        for (final file in SyncedFileStore.instance.listAll())
          CloudFileEntry(
            folder: file.folder,
            name: file.name,
            size: file.size,
            localPath: file.path,
          ),
      ]..sort((a, b) => a.key.compareTo(b.key));
    }
    final documents = await getApplicationDocumentsDirectory();
    final found = <String, CloudFileEntry>{};
    for (final folder in folders) {
      final dir = Directory(p.join(documents.path, folder));
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        found['$folder/$name'] = CloudFileEntry(
          folder: folder,
          name: name,
          size: entity.lengthSync(),
          localPath: entity.path,
        );
      }
    }
    return found.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  static Future<void> cancelUploads() async {
    final tasks = List<UploadTask>.of(_tasks);
    _tasks.clear();
    for (final task in tasks) {
      try {
        await task.cancel();
      } catch (_) {}
    }
  }

  static Future<void> upload(
    String uid,
    List<CloudFileEntry> files, {
    bool prune = true,
  }) {
    final previous = _chain;
    final gate = Completer<void>();
    _chain = gate.future;
    return previous.then((_) => _uploadBody(uid, files, prune: prune)).whenComplete(() {
      if (!gate.isCompleted) gate.complete();
    });
  }

  static Future<void> _uploadBody(
    String uid,
    List<CloudFileEntry> files, {
    required bool prune,
  }) async {
    for (final file in files) {
      final ref = FirebaseStorage.instance.ref(_object(uid, file));
      try {
        if (await _sameRemote(ref, file.size)) continue;
        final task = await _startPut(ref, file);
        if (task == null) continue;
        _tasks.add(task);
        try {
          await task;
          _remoteSizes[ref.fullPath] = file.size;
        } finally {
          _tasks.remove(task);
        }
      } catch (error) {
        debugPrint('Cloud file put failed ${file.key}: $error');
      }
    }
    if (prune) await pruneUnused(uid, files);
  }

  static Future<void> pruneUnused(String uid, List<CloudFileEntry> files) async {
    if (kIsWeb) return;
    const listTimeout = Duration(seconds: 8);
    final keep = {for (final file in files) file.key};
    for (final folder in folders) {
      try {
        final listed = await FirebaseStorage.instance
            .ref('users/$uid/$folder')
            .listAll()
            .timeout(listTimeout);
        for (final item in listed.items) {
          final key = '$folder/${item.name}';
          if (!keep.contains(key)) {
            try {
              await item.delete().timeout(listTimeout);
              _remoteSizes.remove(item.fullPath);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  static Future<UploadTask?> _startPut(Reference ref, CloudFileEntry file) async {
    if (kIsWeb) {
      final bytes = SyncedFileStore.instance.bytesForKey(file.folder, file.name) ??
          (file.localPath == null
              ? null
              : SyncedFileStore.instance.bytesFor(file.localPath!));
      if (bytes == null || bytes.isEmpty) return null;
      return ref.putData(bytes, SettableMetadata(contentType: _contentType(file.name)));
    }
    final path = file.localPath;
    if (path == null) return null;
    final local = File(path);
    if (!local.existsSync()) return null;
    return ref.putFile(local);
  }

  static String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  static Future<bool> _sameRemote(Reference ref, int size) async {
    if (_remoteSizes[ref.fullPath] == size) return true;
    try {
      final meta = await ref.getMetadata().timeout(const Duration(seconds: 6));
      if (meta.size == size) {
        _remoteSizes[ref.fullPath] = size;
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<Uint8List?> ensureLocal(String path) async {
    final cached = SyncedFileStore.instance.bytesFor(path);
    if (cached != null && cached.isNotEmpty) return cached;
    final parsed = SyncedFileStore.parse(path);
    if (parsed == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    await download(uid, [
      CloudFileEntry(folder: parsed.folder, name: parsed.name, size: 0),
    ]);
    return SyncedFileStore.instance.bytesForKey(parsed.folder, parsed.name) ??
        SyncedFileStore.instance.bytesFor(path);
  }

  static Future<bool> download(String uid, List<CloudFileEntry> files) async {
    if (files.isEmpty) return true;
    var ok = true;
    if (kIsWeb) {
      for (final file in files) {
        final existing =
            SyncedFileStore.instance.bytesForKey(file.folder, file.name);
        if (existing != null && existing.isNotEmpty) {
          continue;
        }
        final ref = FirebaseStorage.instance.ref(_object(uid, file));
        try {
          String? url;
          try {
            url = await ref.getDownloadURL().timeout(const Duration(seconds: 12));
          } catch (_) {}
          Uint8List? bytes = await _downloadViaFunction(file);
          if (bytes == null) {
            try {
              bytes =
                  await ref.getData(32 << 20).timeout(const Duration(seconds: 30));
            } catch (error) {
              debugPrint('Cloud file get failed ${file.key}: $error');
            }
          }
          if (bytes == null || bytes.isEmpty) {
            ok = false;
            if (url == null || url.isEmpty) continue;
          }
          SyncedFileStore.instance.rememberRemote(
            folder: file.folder,
            name: file.name,
            size: bytes?.length ?? file.size,
            bytes: bytes,
            url: url,
          );
        } catch (error) {
          ok = false;
          debugPrint('Cloud file download failed ${file.key}: $error');
        }
      }
      return ok;
    }
    final documents = await getApplicationDocumentsDirectory();
    for (final file in files) {
      final dir = Directory(p.join(documents.path, file.folder));
      await dir.create(recursive: true);
      final dest = File(p.join(dir.path, file.name));
      if (dest.existsSync() &&
          dest.lengthSync() > 0 &&
          (file.size <= 0 || dest.lengthSync() == file.size)) {
        continue;
      }
      try {
        await FirebaseStorage.instance.ref(_object(uid, file)).writeToFile(dest);
      } catch (error) {
        ok = false;
        debugPrint('Cloud file download failed ${file.key}: $error');
      }
    }
    return ok;
  }

  static Future<void> clearUnused(List<CloudFileEntry> keep) async {
    if (kIsWeb) return;
    final keepKeys = {for (final file in keep) file.key};
    final documents = await getApplicationDocumentsDirectory();
    for (final folder in folders) {
      final dir = Directory(p.join(documents.path, folder));
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        if (keepKeys.contains('$folder/${p.basename(entity.path)}')) continue;
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  static Future<void> parkLocal() async {
    if (kIsWeb) {
      await SyncedFileStore.instance.park();
      return;
    }
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, parkedFolder));
    if (root.existsSync()) {
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    }
    await root.create(recursive: true);
    for (final folder in folders) {
      final src = Directory(p.join(documents.path, folder));
      if (!src.existsSync()) continue;
      final destDir = Directory(p.join(root.path, folder));
      await destDir.create(recursive: true);
      for (final entity in src.listSync()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        try {
          await entity.copy(p.join(destDir.path, name));
        } catch (_) {}
      }
    }
  }

  static Future<void> restoreParked() async {
    if (kIsWeb) {
      await SyncedFileStore.instance.restoreParked();
      return;
    }
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, parkedFolder));
    if (!root.existsSync()) return;
    for (final folder in folders) {
      final live = Directory(p.join(documents.path, folder));
      await live.create(recursive: true);
      for (final entity in live.listSync()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
      final parked = Directory(p.join(root.path, folder));
      if (!parked.existsSync()) continue;
      for (final entity in parked.listSync()) {
        if (entity is! File) continue;
        try {
          await entity.copy(p.join(live.path, p.basename(entity.path)));
        } catch (_) {}
      }
    }
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  }

  static Future<void> clearLocal() async {
    if (kIsWeb) {
      await SyncedFileStore.instance.clearAll();
      return;
    }
    final documents = await getApplicationDocumentsDirectory();
    for (final folder in folders) {
      final dir = Directory(p.join(documents.path, folder));
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  static Future<void> deleteRemote(
    String uid, {
    List<CloudFileEntry> known = const [],
  }) async {
    const timeout = Duration(seconds: 12);
    final seen = <String>{};
    for (final file in known) {
      final path = _object(uid, file);
      if (!seen.add(path)) continue;
      try {
        await FirebaseStorage.instance.ref(path).delete().timeout(timeout);
      } catch (error) {
        debugPrint('Cloud delete failed $path: $error');
      }
    }
    try {
      await _deletePrefix(
        FirebaseStorage.instance.ref('users/$uid'),
        timeout,
      );
    } catch (error) {
      debugPrint('Cloud delete list failed users/$uid: $error');
      for (final folder in folders) {
        try {
          await _deletePrefix(
            FirebaseStorage.instance.ref('users/$uid/$folder'),
            timeout,
          );
        } catch (error) {
          debugPrint('Cloud delete list failed $folder: $error');
        }
      }
    }
  }

  static Future<void> _deletePrefix(Reference ref, Duration timeout) async {
    final listed = await ref.listAll().timeout(timeout);
    for (final item in listed.items) {
      try {
        await item.delete().timeout(timeout);
      } catch (error) {
        debugPrint('Cloud delete item failed ${item.fullPath}: $error');
      }
    }
    for (final prefix in listed.prefixes) {
      await _deletePrefix(prefix, timeout);
    }
  }

  static Future<void> relocate() => AppBackupService.relocateSyncedPaths();

  static Future<Uint8List?> _downloadViaFunction(CloudFileEntry file) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await http
          .get(
            Uri.https(
              'us-central1-jopb-65c0f.cloudfunctions.net',
              '/getSyncedFile',
              {'folder': file.folder, 'name': file.name},
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        debugPrint(
          'Cloud file proxy failed ${file.key}: ${response.statusCode}',
        );
        return null;
      }
      return response.bodyBytes;
    } catch (error) {
      debugPrint('Cloud file proxy failed ${file.key}: $error');
      return null;
    }
  }

  static String _object(String uid, CloudFileEntry file) {
    return 'users/$uid/${file.folder}/${file.name}';
  }
}
