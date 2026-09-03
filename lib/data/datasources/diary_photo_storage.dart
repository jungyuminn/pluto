import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DiaryPhotoStorage {
  const DiaryPhotoStorage();

  static const _iosPicker = MethodChannel('job_planner/image_picker');

  Future<({String path, String name})?> pick() async {
    if (!kIsWeb && Platform.isIOS) {
      final path = await _iosPicker.invokeMethod<String>('pick');
      if (path == null || path.isEmpty) return null;
      return (path: path, name: p.basename(path));
    }
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (file == null || path == null) return null;
    return (path: path, name: file.name);
  }

  Future<String> save({
    required String id,
    required String sourcePath,
    required String fileName,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'diaries'));
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }

    final safeName = p.basename(fileName);
    final destination = p.join(folder.path, '${id}_$safeName');
    final source = File(sourcePath);
    try {
      await source.copy(destination);
    } catch (_) {
      final bytes = await source.readAsBytes();
      await File(destination).writeAsBytes(bytes, flush: true);
    }
    return destination;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
