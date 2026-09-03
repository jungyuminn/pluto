import 'dart:io';

import 'package:open_filex/open_filex.dart';

enum OpenLocalFileResult { done, missing, failed }

Future<OpenLocalFileResult> openLocalFile(String path) async {
  if (!File(path).existsSync()) return OpenLocalFileResult.missing;
  final result = await OpenFilex.open(path);
  return result.type == ResultType.done
      ? OpenLocalFileResult.done
      : OpenLocalFileResult.failed;
}
