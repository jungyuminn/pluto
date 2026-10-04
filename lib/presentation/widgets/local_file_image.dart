import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto/data/datasources/cloud_sync_files.dart';
import 'package:pluto/data/datasources/synced_file_store.dart';

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

  static Future<void> precache(
    String path, {
    Size? size,
    double? pixelRatio,
  }) async {
    if (kIsWeb || path.isEmpty) return;
    try {
      final file = File(path);
      if (!file.existsSync()) return;
      final stream = FileImage(file).resolve(
        ImageConfiguration(
          size: size,
          devicePixelRatio: pixelRatio,
        ),
      );
      final done = Completer<void>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener((_, __) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.complete();
      }, onError: (_, __) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.complete();
      });
      stream.addListener(listener);
      await done.future.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  bool get _fileReady {
    if (kIsWeb || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fileReady) return _fileImage();
    CloudSyncFiles.prefetch(path);
    return ListenableBuilder(
      listenable: SyncedFileStore.instance,
      builder: (context, _) => _image(context),
    );
  }

  Widget _fallback(
    BuildContext context,
    Object error,
    StackTrace? stack,
  ) {
    return errorBuilder?.call(context, error, stack) ??
        const SizedBox.shrink();
  }

  Widget _fileImage() {
    return Image.file(
      File(path),
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      errorBuilder: _fallback,
    );
  }

  Widget _image(BuildContext context) {
    if (_fileReady) return _fileImage();
    final bytes = SyncedFileStore.instance.bytesFor(path);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        filterQuality: filterQuality,
        gaplessPlayback: true,
        errorBuilder: _fallback,
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
        gaplessPlayback: true,
        errorBuilder: _fallback,
      );
    }
    return _fallback(context, StateError('missing-local-file'), null);
  }
}
