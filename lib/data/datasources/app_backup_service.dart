import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/data/datasources/backup_preference.dart';
import 'package:job_planner/data/datasources/calendar_event_local_datasource.dart';
import 'package:job_planner/data/datasources/custom_theme_storage.dart';
import 'package:job_planner/data/datasources/day_emoji_store.dart';
import 'package:job_planner/data/datasources/license_local_datasource.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBackupService {
  AppBackupService._();

  static const format = 1;
  static const appId = 'job_planner';
  static final revision = ValueNotifier(0);

  static const _jobsKey = 'job_applications';
  static const _licensesKey = LicenseLocalDataSource.key;
  static const _diariesKey = 'diary_entries';
  static const _eventsKey = 'calendar_events';
  static const _ledgersKey = 'ledger_entries';
  static const _emojisKey = DayEmojiStore.key;
  static const _coverFolder = 'cover_letters';
  static const _licenseFolder = 'license_files';
  static const _diaryFolder = 'diaries';
  static const _themesFolder = CustomThemeStorage.folderName;
  static const _autoFolder = 'auto_backups';
  static const _keepAutoCount = 3;
  static const _downloadChannel = MethodChannel('job_planner/backup_store');
  static const _icloudChannel = MethodChannel('job_planner/icloud_backup');

  static String fileName([DateTime? now]) {
    final stamp = now ?? DateTime.now();
    final month = stamp.month.toString().padLeft(2, '0');
    final day = stamp.day.toString().padLeft(2, '0');
    return '잡플래너_백업_${stamp.year}$month$day.zip';
  }

  static Future<bool> backup() async {
    final bytes = await saveLocal();
    if (!kIsWeb && Platform.isIOS) {
      await _copyToICloud(bytes);
    }
    return true;
  }

  static Future<void> runAutoIfDue(BackupPreference preference) async {
    if (!preference.isDue) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isStarterOnly(prefs)) return;
      final bytes = await saveLocal();
      if (!kIsWeb && Platform.isIOS) {
        try {
          await _copyToICloud(bytes);
        } catch (error, stack) {
          debugPrint('iCloud auto backup failed: $error\n$stack');
        }
      }
      await preference.markBackedUp();
    } catch (error, stack) {
      debugPrint('Auto backup failed: $error\n$stack');
    }
  }

  static Future<Uint8List> saveLocal() async {
    final bytes = await encode();
    final folder = await _autoBackupDirectory();
    await folder.create(recursive: true);
    final file = File(p.join(folder.path, fileName()));
    await file.writeAsBytes(bytes, flush: true);
    await _pruneAutoBackups(folder);
    await _copyToDownloads(bytes);
    return bytes;
  }

  static Future<List<File>> listLocalBackups() async {
    final folder = await _autoBackupDirectory();
    if (!folder.existsSync()) return [];
    await _pruneAutoBackups(folder);
    final files = folder
        .listSync()
        .whereType<File>()
        .where((file) => p.extension(file.path).toLowerCase() == '.zip')
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  static Future<List<BackupListItem>> listRestoreItems() async {
    final items = <String, BackupListItem>{};
    if (!kIsWeb && Platform.isIOS) {
      try {
        for (final cloud in await _listICloudBackups()) {
          items[cloud.fileName] = cloud;
        }
      } catch (error, stack) {
        debugPrint('List iCloud backups failed: $error\n$stack');
      }
    }
    for (final file in await listLocalBackups()) {
      items.putIfAbsent(p.basename(file.path), () => BackupListItem.local(file));
    }
    return items.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static String backupLabel(File file) => labelForDate(_backupDate(file));

  static String labelForDate(DateTime date) {
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.year}. ${date.month}. ${date.day}. ($weekday)';
  }

  static DateTime _backupDate(File file) {
    final name = p.basenameWithoutExtension(file.path);
    final match = RegExp(r'(\d{8})$').firstMatch(name);
    if (match != null) {
      final stamp = match.group(1)!;
      return DateTime(
        int.parse(stamp.substring(0, 4)),
        int.parse(stamp.substring(4, 6)),
        int.parse(stamp.substring(6, 8)),
      );
    }
    return file.lastModifiedSync();
  }

  static Future<void> restoreFromFile(File file) async {
    final bytes = await file.readAsBytes();
    await decode(bytes);
  }

  static Future<void> restoreFromItem(BackupListItem item) async {
    if (item.file != null) {
      await restoreFromFile(item.file!);
      return;
    }
    final bytes = await _readICloudBackup(item.fileName);
    await decode(bytes);
  }

  static Future<Directory> _autoBackupDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, _autoFolder));
  }

  static Future<void> _pruneAutoBackups(Directory folder) async {
    if (!folder.existsSync()) return;
    final files = folder.listSync().whereType<File>().toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final file in files.skip(_keepAutoCount)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static Future<void> _copyToICloud(Uint8List bytes) async {
    await _icloudChannel.invokeMethod<void>('save', {
      'fileName': fileName(),
      'bytes': bytes,
      'keep': _keepAutoCount,
      'prefix': '잡플래너_백업_',
    });
  }

  static Future<List<BackupListItem>> _listICloudBackups() async {
    final raw = await _icloudChannel.invokeMethod<List<dynamic>>('list') ?? [];
    return [
      for (final item in raw)
        if (item is Map)
          BackupListItem.cloud(
            fileName: '${item['fileName']}',
            date: DateTime.fromMillisecondsSinceEpoch(
              (item['modified'] as num?)?.toInt() ?? 0,
            ),
          ),
    ];
  }

  static Future<Uint8List> _readICloudBackup(String name) async {
    final bytes = await _icloudChannel.invokeMethod('read', {'fileName': name});
    if (bytes is Uint8List) return bytes;
    if (bytes is List<int>) return Uint8List.fromList(bytes);
    throw const FormatException('missing iCloud backup');
  }

  static Future<void> _copyToDownloads(Uint8List bytes) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _downloadChannel.invokeMethod<void>('saveDownload', {
        'fileName': fileName(),
        'bytes': bytes,
      });
      await _downloadChannel.invokeMethod<void>('pruneDownloads', {
        'keep': _keepAutoCount,
        'prefix': '잡플래너_백업_',
      });
    } catch (error, stack) {
      debugPrint('Download backup failed: $error\n$stack');
    }
  }

  static Future<bool> restoreFromPicker() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (file == null) return false;
    final bytes = await file.readAsBytes();
    await decode(bytes);
    return true;
  }

  static Future<void> applyToApp(AppScope scope) async {
    scope.themePreference.hydrate();
    scope.fontPreference.hydrate();
    scope.calendarPreference.hydrate();
    scope.notificationPreference.hydrate();
    scope.homeViewPreference.hydrate();
    scope.widgetPreference.hydrate();
    scope.navPreference.hydrate();
    scope.jobViewPreference.hydrate();
    scope.licenseViewPreference.hydrate();
    scope.wordmarkPreference.hydrate();
    scope.dayEventsViewPreference.hydrate();
    scope.backupPreference.hydrate();
    scope.longGoalStore.reload();
    scope.dayEmojiStore.reload();
    await TodoReminderService.instance.sync();
    await HomeScreenWidgetService.instance.sync();
    revision.value++;
  }

  static Future<Uint8List> encode() async {
    final prefs = await SharedPreferences.getInstance();
    final documents = await getApplicationDocumentsDirectory();
    final archive = Archive();
    final manifest = jsonEncode({
      'app': appId,
      'format': format,
      'createdAt': DateTime.now().toIso8601String(),
      'prefs': _dumpPrefs(prefs),
    });
    final manifestBytes = utf8.encode(manifest);
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    await _addFolder(archive, Directory(p.join(documents.path, _coverFolder)), _coverFolder);
    await _addFolder(
      archive,
      Directory(p.join(documents.path, _licenseFolder)),
      _licenseFolder,
    );
    await _addFolder(archive, Directory(p.join(documents.path, _diaryFolder)), _diaryFolder);
    await _addFolder(
      archive,
      Directory(p.join(documents.path, _themesFolder)),
      _themesFolder,
    );
    await _addReferencedFiles(archive, prefs, documents.path);
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  static Future<void> decode(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('missing manifest');
    }
    final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, dynamic>;
    if (manifest['app'] != appId) {
      throw const FormatException('unknown app');
    }
    final prefsMap = manifest['prefs'];
    if (prefsMap is! Map<String, dynamic>) {
      throw const FormatException('missing prefs');
    }

    final documents = await getApplicationDocumentsDirectory();
    final coverDir = Directory(p.join(documents.path, _coverFolder));
    final licenseDir = Directory(p.join(documents.path, _licenseFolder));
    final diaryDir = Directory(p.join(documents.path, _diaryFolder));
    final themesDir = Directory(p.join(documents.path, _themesFolder));
    await coverDir.create(recursive: true);
    await licenseDir.create(recursive: true);
    await diaryDir.create(recursive: true);
    await themesDir.create(recursive: true);

    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (file.name == 'manifest.json') continue;
      final name = file.name.replaceAll('\\', '/');
      Directory? folder;
      if (name.startsWith('$_coverFolder/')) {
        folder = coverDir;
      } else if (name.startsWith('$_licenseFolder/')) {
        folder = licenseDir;
      } else if (name.startsWith('$_diaryFolder/')) {
        folder = diaryDir;
      } else if (name.startsWith('$_themesFolder/')) {
        folder = themesDir;
      }
      if (folder == null) continue;
      final dest = File(p.join(folder.path, p.basename(name)));
      await dest.writeAsBytes(file.content as List<int>, flush: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await _applyPrefs(prefs, prefsMap);
    await _relocatePaths(
      prefs,
      coverDir.path,
      licenseDir.path,
      diaryDir.path,
      themesDir.path,
    );
  }

  static Map<String, dynamic> _dumpPrefs(SharedPreferences prefs) {
    final out = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value is String) {
        out[key] = {'t': 's', 'v': value};
      } else if (value is bool) {
        out[key] = {'t': 'b', 'v': value};
      } else if (value is int) {
        out[key] = {'t': 'i', 'v': value};
      } else if (value is double) {
        out[key] = {'t': 'd', 'v': value};
      } else if (value is List) {
        out[key] = {'t': 'l', 'v': List<String>.from(value)};
      }
    }
    return out;
  }

  static Future<void> _applyPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> raw,
  ) async {
    final incoming = raw.keys.toSet();
    for (final key in prefs.getKeys()) {
      if (!incoming.contains(key)) {
        await prefs.remove(key);
      }
    }
    for (final entry in raw.entries) {
      final payload = entry.value;
      if (payload is! Map) continue;
      final type = payload['t'] as String?;
      final value = payload['v'];
      switch (type) {
        case 's':
          await prefs.setString(entry.key, value as String);
        case 'b':
          await prefs.setBool(entry.key, value as bool);
        case 'i':
          await prefs.setInt(entry.key, (value as num).toInt());
        case 'd':
          await prefs.setDouble(entry.key, (value as num).toDouble());
        case 'l':
          await prefs.setStringList(entry.key, List<String>.from(value as List));
      }
    }
  }

  static bool isStarterOnly(SharedPreferences prefs) {
    if (_hasItems(prefs.getString(_jobsKey))) return false;
    if (_hasItems(prefs.getString(_licensesKey))) return false;
    if (_hasItems(prefs.getString(_diariesKey))) return false;
    if (_hasItems(prefs.getString(_ledgersKey))) return false;
    if (_hasEmojiItems(prefs.getString(_emojisKey))) return false;
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return true;
    try {
      final items = jsonDecode(raw) as List<dynamic>;
      if (items.isEmpty) return true;
      return items.every((item) {
        final id = (item as Map)['id'] as String? ?? '';
        return id.startsWith(CalendarEventLocalDataSource.starterIdPrefix);
      });
    } catch (_) {
      return false;
    }
  }

  static bool _hasEmojiItems(String? raw) {
    if (raw == null || raw.isEmpty || raw == '{}') return false;
    try {
      final items = jsonDecode(raw);
      if (items is! Map || items.isEmpty) return false;
      for (final value in items.values) {
        if (value is String && value.trim().isNotEmpty) return true;
        if (value is Map) {
          for (final item in value.values) {
            if (item is String && item.trim().isNotEmpty) return true;
          }
        }
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static bool _hasItems(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[]') return false;
    try {
      final items = jsonDecode(raw);
      return items is List && items.isNotEmpty;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _relocatePaths(
    SharedPreferences prefs,
    String coverDir,
    String licenseDir,
    String diaryDir,
    String themesDir,
  ) async {
    final jobsRaw = prefs.getString(_jobsKey);
    if (jobsRaw != null && jobsRaw.isNotEmpty) {
      final jobs = jsonDecode(jobsRaw) as List<dynamic>;
      final next = [
        for (final item in jobs)
          _rewritePath(item as Map<String, dynamic>, 'coverLetterPath', coverDir),
      ];
      await prefs.setString(_jobsKey, jsonEncode(next));
    }
    final licensesRaw = prefs.getString(_licensesKey);
    if (licensesRaw != null && licensesRaw.isNotEmpty) {
      final licenses = jsonDecode(licensesRaw) as List<dynamic>;
      final next = [
        for (final item in licenses)
          _rewritePath(item as Map<String, dynamic>, 'filePath', licenseDir),
      ];
      await prefs.setString(_licensesKey, jsonEncode(next));
    }
    final diariesRaw = prefs.getString(_diariesKey);
    if (diariesRaw != null && diariesRaw.isNotEmpty) {
      final diaries = jsonDecode(diariesRaw) as List<dynamic>;
      final next = [
        for (final item in diaries)
          _rewritePath(item as Map<String, dynamic>, 'photoPath', diaryDir),
      ];
      await prefs.setString(_diariesKey, jsonEncode(next));
    }
    final themesRaw = prefs.getString(ThemePreference.customThemesKey);
    if (themesRaw != null && themesRaw.isNotEmpty) {
      final themes = jsonDecode(themesRaw) as List<dynamic>;
      final next = [
        for (final item in themes)
          _rewriteThemePaths(item as Map<String, dynamic>, themesDir),
      ];
      await prefs.setString(ThemePreference.customThemesKey, jsonEncode(next));
    }
  }

  static Map<String, dynamic> _rewriteThemePaths(
    Map<String, dynamic> json,
    String folder,
  ) {
    var next = json;
    for (final key in const [
      'photoPath',
      'decorationPath',
      'bottomPath',
      'imagePath',
    ]) {
      next = _rewritePath(next, key, folder);
    }
    return next;
  }

  static Map<String, dynamic> _rewritePath(
    Map<String, dynamic> json,
    String key,
    String folder,
  ) {
    final path = json[key] as String?;
    if (path == null || path.isEmpty) return json;
    json[key] = p.join(folder, p.basename(path));
    return json;
  }

  static Future<void> _addFolder(
    Archive archive,
    Directory dir,
    String zipPrefix,
  ) async {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      await _addFile(archive, entity, '$zipPrefix/${p.basename(entity.path)}');
    }
  }

  static Future<void> _addReferencedFiles(
    Archive archive,
    SharedPreferences prefs,
    String documentsPath,
  ) async {
    final coverDir = p.join(documentsPath, _coverFolder);
    final licenseDir = p.join(documentsPath, _licenseFolder);
    final diaryDir = p.join(documentsPath, _diaryFolder);
    final themesDir = p.join(documentsPath, _themesFolder);
    final jobsRaw = prefs.getString(_jobsKey);
    if (jobsRaw != null && jobsRaw.isNotEmpty) {
      final jobs = jsonDecode(jobsRaw) as List<dynamic>;
      for (final item in jobs) {
        final path = (item as Map<String, dynamic>)['coverLetterPath'] as String?;
        if (path == null || path.isEmpty) continue;
        final file = File(path);
        if (!file.existsSync()) continue;
        if (p.equals(p.dirname(path), coverDir)) continue;
        await _addFile(archive, file, '$_coverFolder/${p.basename(path)}');
      }
    }
    final licensesRaw = prefs.getString(_licensesKey);
    if (licensesRaw != null && licensesRaw.isNotEmpty) {
      final licenses = jsonDecode(licensesRaw) as List<dynamic>;
      for (final item in licenses) {
        final path = (item as Map<String, dynamic>)['filePath'] as String?;
        if (path == null || path.isEmpty) continue;
        final file = File(path);
        if (!file.existsSync()) continue;
        if (p.equals(p.dirname(path), licenseDir)) continue;
        await _addFile(archive, file, '$_licenseFolder/${p.basename(path)}');
      }
    }
    final diariesRaw = prefs.getString(_diariesKey);
    if (diariesRaw != null && diariesRaw.isNotEmpty) {
      final diaries = jsonDecode(diariesRaw) as List<dynamic>;
      for (final item in diaries) {
        final path = (item as Map<String, dynamic>)['photoPath'] as String?;
        if (path == null || path.isEmpty) continue;
        final file = File(path);
        if (!file.existsSync()) continue;
        if (p.equals(p.dirname(path), diaryDir)) continue;
        await _addFile(archive, file, '$_diaryFolder/${p.basename(path)}');
      }
    }
    final themesRaw = prefs.getString(ThemePreference.customThemesKey);
    if (themesRaw != null && themesRaw.isNotEmpty) {
      final themes = jsonDecode(themesRaw) as List<dynamic>;
      for (final item in themes) {
        final map = item as Map<String, dynamic>;
        for (final key in const [
          'photoPath',
          'decorationPath',
          'bottomPath',
          'imagePath',
        ]) {
          final path = map[key] as String?;
          if (path == null || path.isEmpty) continue;
          final file = File(path);
          if (!file.existsSync()) continue;
          if (p.equals(p.dirname(path), themesDir)) continue;
          await _addFile(archive, file, '$_themesFolder/${p.basename(path)}');
        }
      }
    }
  }

  static Future<void> _addFile(
    Archive archive,
    File file,
    String zipName,
  ) async {
    if (archive.findFile(zipName) != null) return;
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(zipName, bytes.length, bytes));
  }
}

class BackupListItem {
  BackupListItem._({
    required this.fileName,
    required this.date,
    this.file,
  });

  factory BackupListItem.local(File file) {
    return BackupListItem._(
      fileName: p.basename(file.path),
      date: AppBackupService._backupDate(file),
      file: file,
    );
  }

  factory BackupListItem.cloud({
    required String fileName,
    required DateTime date,
  }) {
    return BackupListItem._(fileName: fileName, date: date);
  }

  final String fileName;
  final DateTime date;
  final File? file;

  String get label => AppBackupService.labelForDate(date);
}
