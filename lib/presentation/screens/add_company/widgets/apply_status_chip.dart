import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/presentation/theme/apply_status_colors.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_dot.dart';

class ApplyStatusChip extends StatelessWidget {
  const ApplyStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = ApplyStatusColors.of(label);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            ApplyStatusDot(color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: colors.secondary,
          ),
        ],
      ),
    );
  }
}
