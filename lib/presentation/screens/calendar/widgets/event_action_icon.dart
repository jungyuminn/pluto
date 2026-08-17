import 'package:flutter/material.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class EventActionIcon extends StatelessWidget {
  const EventActionIcon({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    this.label,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final String? label;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressBounce(
        onPressed: onPressed,
        pressedColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
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
