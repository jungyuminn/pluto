import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';

class CalendarWeekdayHeader extends StatelessWidget {
  const CalendarWeekdayHeader({super.key, this.startMonday = false});

  final bool startMonday;

  @override
  Widget build(BuildContext context) {
    final labels = AppStrings.weekdayLabels(startMonday: startMonday);
    final scale = AppFonts.calendarScaleOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                  color: AppColors.of(context).muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
