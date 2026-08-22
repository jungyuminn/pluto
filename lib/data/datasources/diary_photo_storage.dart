import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DiaryPhotoStorage {
  const DiaryPhotoStorage();

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
    await File(sourcePath).copy(destination);
    return destination;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
