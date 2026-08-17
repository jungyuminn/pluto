import 'package:flutter/material.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class AppBarPill extends StatelessWidget {
  const AppBarPill({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String asset;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: PressBounce(
          onPressed: onPressed,
          color: selected ? const Color(0xFFF1F5F9) : Colors.white,
          pressedColor: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Image.asset(
              asset,
              width: 18,
              height: 18,
              semanticLabel: label,
            ),
          ),
        ),
      ),
    );
  }
}
