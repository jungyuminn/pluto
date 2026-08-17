import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
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
    final colors = AppColors.of(context);
    return PressBounce(
      color: colors.pressed,
      pressedColor: colors.border,
      borderRadius: BorderRadius.circular(999),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Icon(
          icon,
          size: 14,
          color: colors.text,
        ),
      ),
    );
  }
}
