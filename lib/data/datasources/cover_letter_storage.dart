import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:path/path.dart' as p;

class CoverLetterStorage {
  const CoverLetterStorage({this.folderName = coverLettersFolder});

  static const coverLettersFolder = 'cover_letters';
  static const licenseFilesFolder = 'license_files';

  final String folderName;

  Future<String> save({
    required String id,
    required String sourcePath,
    required String fileName,
  }) {
    return SyncedFileStore.instance.import(
      folder: folderName,
      name: '${id}_${p.basename(fileName)}',
      sourcePath: sourcePath,
    );
  }
}
