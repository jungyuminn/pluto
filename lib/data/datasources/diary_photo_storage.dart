import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:path/path.dart' as p;

class DiaryPhotoStorage {
  const DiaryPhotoStorage();

  static const _iosPicker = MethodChannel('job_planner/image_picker');

  Future<({String path, String name})?> pick() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final path = await _iosPicker.invokeMethod<String>('pick');
      if (path == null || path.isEmpty) return null;
      return (path: path, name: p.basename(path));
    }
    return SyncedFileStore.pick(type: FileType.image);
  }

  Future<String> save({
    required String id,
    required String sourcePath,
    required String fileName,
  }) {
    return SyncedFileStore.instance.import(
      folder: 'diaries',
      name: '${id}_${_safeFileName(fileName)}',
      sourcePath: sourcePath,
    );
  }

  Future<void> delete(String? path) {
    return SyncedFileStore.instance.deletePath(path);
  }

  static String _safeFileName(String fileName) {
    final base = p.basename(fileName);
    final dot = base.lastIndexOf('.');
    final stem = dot > 0 ? base.substring(0, dot) : base;
    final ext = dot > 0 ? base.substring(dot).toLowerCase() : '.jpg';
    final safe = stem.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final name = safe.replaceAll(RegExp(r'^_+|_+$'), '');
    const allowed = {'.png', '.jpg', '.jpeg', '.gif', '.webp'};
    final suffix = allowed.contains(ext) ? ext : '.jpg';
    return '${name.isEmpty ? 'photo' : name}$suffix';
  }
}
