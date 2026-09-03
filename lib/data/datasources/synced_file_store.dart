import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On web this is a session cache of cloud files, not a second source of truth.
class SyncedFileStore {
  SyncedFileStore._();

  static final instance = SyncedFileStore._();

  static const webRoot = 'jpfs';
  static const folders = [
    'cover_letters',
    'license_files',
    'diaries',
    'custom_themes',
  ];

  final _bytes = <String, Uint8List>{};
  final _urls = <String, String>{};
  final _sizes = <String, int>{};
  var _parkedBytes = <String, Uint8List>{};
  var _parkedUrls = <String, String>{};
  var _parkedSizes = <String, int>{};

  static String keyOf(String folder, String name) => '$folder/$name';

  static String logicalPath(String folder, String name) =>
      '$webRoot/$folder/$name';

  static ({String folder, String name})? parse(String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final folder in folders) {
      final needle = '/$folder/';
      final index = normalized.indexOf(needle);
      if (index < 0) continue;
      final name = normalized.substring(index + needle.length);
      if (name.isEmpty || name.contains('/')) continue;
      return (folder: folder, name: name);
    }
    return null;
  }

  bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    if (_bytes.containsKey(path) || _urls.containsKey(path)) return true;
    final parsed = parse(path);
    if (parsed != null) {
      final key = keyOf(parsed.folder, parsed.name);
      if (_bytes.containsKey(key) || _urls.containsKey(key)) return true;
    }
    if (kIsWeb) return false;
    try {
      return File(path).existsSync();
    } on Object {
      return false;
    }
  }

  Uint8List? bytesFor(String path) {
    final direct = _bytes[path];
    if (direct != null) return direct;
    final parsed = parse(path);
    if (parsed == null) return null;
    return _bytes[keyOf(parsed.folder, parsed.name)];
  }

  String? urlFor(String path) {
    final direct = _urls[path];
    if (direct != null) return direct;
    final parsed = parse(path);
    if (parsed == null) return null;
    return _urls[keyOf(parsed.folder, parsed.name)];
  }

  Future<Uint8List?> read(String path) async {
    final cached = bytesFor(path);
    if (cached != null) return cached;
    if (kIsWeb) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.readAsBytes();
    } on Object {
      return null;
    }
  }

  Future<String> write(String folder, String name, Uint8List bytes) async {
    if (kIsWeb) {
      final key = keyOf(folder, name);
      _bytes[key] = bytes;
      _sizes[key] = bytes.length;
      return logicalPath(folder, name);
    }
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, folder));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final dest = File(p.join(dir.path, name));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  Future<String> import({
    required String folder,
    required String name,
    required String sourcePath,
  }) async {
    final bytes = await _resolveBytes(sourcePath);
    return write(folder, name, bytes);
  }

  Future<String> holdPicked({
    required String name,
    required Uint8List bytes,
  }) async {
    final token =
        'pending::$name::${DateTime.now().microsecondsSinceEpoch}';
    _bytes[token] = bytes;
    _sizes[token] = bytes.length;
    return token;
  }

  void rememberRemote({
    required String folder,
    required String name,
    required int size,
    Uint8List? bytes,
    String? url,
  }) {
    final key = keyOf(folder, name);
    _sizes[key] = size;
    if (bytes != null) _bytes[key] = bytes;
    if (url != null && url.isNotEmpty) _urls[key] = url;
  }

  Future<void> deletePath(String? path) async {
    if (path == null || path.isEmpty) return;
    _forget(path);
    final parsed = parse(path);
    if (parsed != null) {
      _forget(keyOf(parsed.folder, parsed.name));
    }
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object {
      // Native temp picks can vanish after import.
    }
  }

  Future<void> clearFolder(String folder) async {
    final prefix = '$folder/';
    final keys = [
      for (final key in [..._bytes.keys, ..._urls.keys, ..._sizes.keys])
        if (key.startsWith(prefix)) key,
    ];
    for (final key in keys.toSet()) {
      _forget(key);
    }
    if (kIsWeb) return;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(documents.path, folder));
      if (!dir.existsSync()) return;
      for (final entity in dir.listSync()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } on Object {
      // Web stubs dart:io Directory.
    }
  }

  Future<void> clearAll() async {
    _bytes.clear();
    _urls.clear();
    _sizes.clear();
    if (kIsWeb) return;
    for (final folder in folders) {
      await clearFolder(folder);
    }
  }

  Future<void> park() async {
    _parkedBytes = Map<String, Uint8List>.from(_bytes);
    _parkedUrls = Map<String, String>.from(_urls);
    _parkedSizes = Map<String, int>.from(_sizes);
  }

  Future<void> restoreParked() async {
    _bytes
      ..clear()
      ..addAll(_parkedBytes);
    _urls
      ..clear()
      ..addAll(_parkedUrls);
    _sizes
      ..clear()
      ..addAll(_parkedSizes);
    _parkedBytes = {};
    _parkedUrls = {};
    _parkedSizes = {};
  }

  List<({String folder, String name, int size, String path})> listAll() {
    final found = <String, ({String folder, String name, int size, String path})>{};
    for (final entry in _sizes.entries) {
      if (entry.key.startsWith('pending::')) continue;
      final parts = entry.key.split('/');
      if (parts.length != 2 || !folders.contains(parts[0])) continue;
      found[entry.key] = (
        folder: parts[0],
        name: parts[1],
        size: entry.value,
        path: logicalPath(parts[0], parts[1]),
      );
    }
    return found.values.toList()
      ..sort((a, b) => '${a.folder}/${a.name}'.compareTo('${b.folder}/${b.name}'));
  }

  Uint8List? bytesForKey(String folder, String name) =>
      _bytes[keyOf(folder, name)];

  static Future<({String path, String name})?> pick({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final file = await FilePicker.pickFile(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (file == null) return null;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      final token = await instance.holdPicked(name: file.name, bytes: bytes);
      return (path: token, name: file.name);
    }
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return (path: path, name: file.name);
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    final token = await instance.holdPicked(name: file.name, bytes: bytes);
    return (path: token, name: file.name);
  }

  Future<Uint8List> _resolveBytes(String sourcePath) async {
    final held = _bytes.remove(sourcePath);
    if (held != null) {
      _sizes.remove(sourcePath);
      _urls.remove(sourcePath);
      return held;
    }
    final parsed = parse(sourcePath);
    if (parsed != null) {
      final cached = _bytes[keyOf(parsed.folder, parsed.name)];
      if (cached != null) return Uint8List.fromList(cached);
    }
    if (!kIsWeb) {
      return File(sourcePath).readAsBytes();
    }
    throw StateError('missing-file-bytes');
  }

  void _forget(String key) {
    _bytes.remove(key);
    _urls.remove(key);
    _sizes.remove(key);
  }
}
