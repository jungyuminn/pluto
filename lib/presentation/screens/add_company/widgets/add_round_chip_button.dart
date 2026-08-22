import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class AddRoundChipButton extends StatelessWidget {
  const AddRoundChipButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final bool enabled;

  static const size = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: enabled ? 1 : 0.32,
      child: SizedBox(
        width: size,
        height: size,
        child: PressBounce(
          expand: true,
          color: colors.card,
          pressedColor: colors.pressed,
          borderRadius: BorderRadius.circular(999),
          onPressed: enabled ? onPressed : null,
          child: Icon(
            icon,
            size: 18,
            color: colors.secondary,
          ),
        ),
      ),
    );
  }
}
