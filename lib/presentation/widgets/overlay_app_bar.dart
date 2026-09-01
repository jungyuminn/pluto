import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class OverlayAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OverlayAppBar({
    super.key,
    required this.title,
    required this.actions,
  });

  final Widget title;
  final Widget actions;

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
            child: Row(
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
