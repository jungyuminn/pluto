import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pluto/data/datasources/cloud_sync_files.dart';
import 'package:pluto/data/datasources/synced_file_store.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

enum OpenLocalFileResult { done, missing, failed }

Future<OpenLocalFileResult> openLocalFile(String path) async {
  final bytes = await CloudSyncFiles.ensureLocal(path);
  if (bytes != null && bytes.isNotEmpty) {
    return _openBytes(bytes, path);
  }
  final url = SyncedFileStore.instance.urlFor(path);
  if (url != null && url.isNotEmpty) {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    return ok ? OpenLocalFileResult.done : OpenLocalFileResult.failed;
  }
  return OpenLocalFileResult.missing;
}

OpenLocalFileResult _openBytes(Uint8List bytes, String path) {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: _mime(path)),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    final name = path.replaceAll('\\', '/').split('/').last;
    final opened = web.window.open(objectUrl, '_blank');
    if (opened == null) {
      final link = web.HTMLAnchorElement()
        ..href = objectUrl
        ..download = name;
      link.click();
    }
    return OpenLocalFileResult.done;
  } catch (_) {
    return OpenLocalFileResult.failed;
  }
}

String _mime(String path) {
  final name = path.toLowerCase();
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.gif')) return 'image/gif';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.pdf')) return 'application/pdf';
  if (name.endsWith('.txt')) return 'text/plain';
  if (name.endsWith('.hwp')) return 'application/x-hwp';
  if (name.endsWith('.doc')) return 'application/msword';
  if (name.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  return 'application/octet-stream';
}
