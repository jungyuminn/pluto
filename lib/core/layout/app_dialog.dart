import 'package:flutter/material.dart';
import 'package:pluto/core/theme/app_colors.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.barrier,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final closing = animation.status == AnimationStatus.reverse;
          final t = (closing ? Curves.easeInCubic : Curves.easeOutCubic)
              .transform(animation.value);
          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: closing ? 1 : 1.16 - 0.16 * t,
              child: child,
            ),
          );
        },
        child: child,
      );
    },
  );
}
