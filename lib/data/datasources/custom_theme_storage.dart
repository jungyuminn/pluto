import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CustomThemeStorage {
  const CustomThemeStorage();

  static const folderName = 'custom_themes';

  Future<Directory> directory() async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, folderName));
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<String> save({
    required String id,
    required String sourcePath,
    required String fileName,
    required String slot,
  }) async {
    final folder = await directory();
    var ext = p.extension(fileName).toLowerCase();
    if (ext.isEmpty) ext = p.extension(sourcePath).toLowerCase();
    if (ext.isEmpty) ext = '.png';
    final destination = p.join(folder.path, '${id}_$slot$ext');
    final source = File(sourcePath);
    if (p.equals(source.path, destination)) return destination;
    if (File(destination).existsSync() &&
        !p.equals(p.canonicalize(source.path), p.canonicalize(destination))) {
      await File(destination).delete();
    }
    await source.copy(destination);
    return destination;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
