import 'package:flutter/material.dart';
import 'package:job_planner/presentation/theme/apply_status_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_dot.dart';

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
    final color = ApplyStatusColors.of(label);

    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.96,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              ApplyStatusDot(color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
