import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:pluto/core/layout/pc_layout.dart';

Future<T?> showComposeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool enableDrag = true,
  double maxWidth = PcLayout.pcAddEventWidth,
}) async {
  if (!PcLayout.isPc) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x40000000),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x40000000),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: Material(
              color: Colors.transparent,
              child: builder(context),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final t = Curves.easeOutCubic.transform(animation.value);
      return Opacity(
        opacity: t,
        child: Transform.scale(
          scale: lerpDouble(0.94, 1, t)!,
          child: child,
        ),
      );
    },
  );
}
