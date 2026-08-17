import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CoverLetterStorage {
  const CoverLetterStorage();

  Future<String> save({
    required String id,
    required String sourcePath,
    required String fileName,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'cover_letters'));
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }

    final destination = p.join(folder.path, '${id}_$fileName');
    await File(sourcePath).copy(destination);
    return destination;
  }
}
