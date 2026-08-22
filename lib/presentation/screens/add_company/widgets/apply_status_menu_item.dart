import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class ApplyStatusMenuItem extends StatelessWidget {
  const ApplyStatusMenuItem({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.96,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}
