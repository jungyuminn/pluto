import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/data/datasources/synced_file_store.dart';

class LocalFileImage extends StatelessWidget {
  const LocalFileImage(
    this.path, {
    super.key,
    this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.medium,
    this.errorBuilder,
  });

  final String path;
  final BoxFit? fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    Widget fallback(
      BuildContext context,
      Object error,
      StackTrace? stack,
    ) {
      return errorBuilder?.call(context, error, stack) ??
          const SizedBox.shrink();
    }

    if (!kIsWeb) {
      return Image.file(
        File(path),
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        filterQuality: filterQuality,
        errorBuilder: fallback,
      );
    }
    final bytes = SyncedFileStore.instance.bytesFor(path);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        filterQuality: filterQuality,
        errorBuilder: fallback,
      );
    }
    final url = SyncedFileStore.instance.urlFor(path);
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        filterQuality: filterQuality,
        errorBuilder: fallback,
      );
    }
    return fallback(context, StateError('missing-local-file'), null);
  }
}
