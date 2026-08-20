import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class HomeMonthlyStatsCard extends StatelessWidget {
  const HomeMonthlyStatsCard({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        pressedScale: 0.98,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: colors.accentBright,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: colors.accentBright,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
