import 'package:flutter/material.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class AppBarIconAction {
  const AppBarIconAction({
    required this.asset,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String asset;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
}

class AppBarIconGroup extends StatelessWidget {
  const AppBarIconGroup({super.key, required this.actions});

  final List<AppBarIconAction> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions) _IconButton(action: action),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.action});

  final AppBarIconAction action;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: action.onPressed,
      color: action.selected ? const Color(0xFFF1F5F9) : Colors.transparent,
      pressedColor: const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Image.asset(
          action.asset,
          width: 18,
          height: 18,
          semanticLabel: action.label,
        ),
      ),
    );
  }
}
