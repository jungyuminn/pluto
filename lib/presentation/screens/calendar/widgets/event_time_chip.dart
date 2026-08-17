import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';

class EventTimeChip extends StatelessWidget {
  const EventTimeChip({
    super.key,
    required this.color,
    required this.onPressed,
    this.startMinutes,
    this.endMinutes,
  });

  final Color color;
  final VoidCallback onPressed;
  final int? startMinutes;
  final int? endMinutes;

  String get _label {
    final start = startMinutes;
    final end = endMinutes;
    if (start == null || end == null) return AppStrings.allDayLabel;
    return '${CalendarEvent.formatMinutes(start)}–${CalendarEvent.formatMinutes(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      color: AppColors.of(context).card,
      pressedColor: AppColors.of(context).pressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(
                AppIcons.clock,
                width: 20,
                height: 20,
                semanticLabel: AppStrings.timeAction,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
