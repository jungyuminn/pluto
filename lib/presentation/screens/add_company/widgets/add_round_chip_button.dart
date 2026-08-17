import 'package:flutter/material.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class AddRoundChipButton extends StatelessWidget {
  const AddRoundChipButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      color: const Color(0xFFF1F5F9),
      pressedColor: const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(999),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Icon(
          icon,
          size: 14,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }
}
