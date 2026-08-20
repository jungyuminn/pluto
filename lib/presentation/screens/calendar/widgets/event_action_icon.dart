import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class EventActionIcon extends StatelessWidget {
  const EventActionIcon({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    this.label,
    this.selected = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final String? label;
  final bool selected;

  static const _size = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: PressBounce(
        onPressed: onPressed,
        color: selected ? colors.card : Colors.transparent,
        pressedColor: selected ? colors.pressed : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: SizedBox(
              width: _size,
              height: _size,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
