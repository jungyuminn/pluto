import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pluto/core/theme/app_colors.dart';

class OverlayAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OverlayAppBar({
    super.key,
    required this.title,
    required this.actions,
    this.leading,
    this.centerTitle = false,
  });

  final Widget title;
  final Widget actions;
  final Widget? leading;
  final bool centerTitle;

  static const extraTop = 6.0;

  static double overlapOf(BuildContext context) {
    final top = MediaQueryData.fromView(View.of(context)).padding.top;
    return top + kToolbarHeight + extraTop;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + extraTop);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.background,
                  colors.background.withValues(alpha: 0.72),
                  colors.background.withValues(alpha: 0),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 12, top: extraTop),
            child: centerTitle
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      title,
                      if (leading != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.translate(
                            offset: const Offset(0, -3),
                            child: leading,
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Transform.translate(
                          offset: const Offset(0, -3),
                          child: actions,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: title,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.translate(
                        offset: const Offset(0, -3),
                        child: actions,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class FrostedAppBarFill extends StatelessWidget {
  const FrostedAppBarFill({super.key});

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.of(context).groupedBackground;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, 0.58, 1],
              ).createShader(bounds);
            },
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tint.withValues(alpha: 0.72),
                  tint.withValues(alpha: 0.5),
                  tint.withValues(alpha: 0),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
