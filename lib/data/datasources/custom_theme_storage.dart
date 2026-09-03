import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:path/path.dart' as p;

class CustomThemeStorage {
  const CustomThemeStorage();

  static const folderName = 'custom_themes';

  Future<String> save({
    required String id,
    required String sourcePath,
    required String fileName,
    required String slot,
  }) async {
    var ext = p.extension(fileName).toLowerCase();
    if (ext.isEmpty) ext = p.extension(sourcePath).toLowerCase();
    if (ext.isEmpty) ext = '.png';
    return SyncedFileStore.instance.import(
      folder: folderName,
      name: '${id}_$slot$ext',
      sourcePath: sourcePath,
    );
  }

  Future<void> delete(String? path) {
    return SyncedFileStore.instance.deletePath(path);
  }
}
