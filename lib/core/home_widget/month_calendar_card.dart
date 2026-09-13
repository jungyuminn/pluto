import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto/core/calendar/month_grid.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_week_events.dart';

class MonthCalendarCard extends StatelessWidget {
  const MonthCalendarCard({
    super.key,
    required this.month,
    required this.eventsOf,
    this.startMonday = false,
  });

  static const logicalSize = Size(380, 430);
  static const imageKey = 'month_calendar_image';
  static const emptyKey = 'month_calendar_empty';
  static const androidName = 'MonthCalendarWidgetProvider';
  static const iOSName = 'MonthCalendarWidget';
  static const qualifiedAndroidName =
      'com.pluto.app.$androidName';

  static const _sunday = Color(0xFFEF4444);
  static const _saturday = Color(0xFF60A5FA);

  final DateTime month;
  final List<CalendarEvent> Function(DateTime date) eventsOf;
  final bool startMonday;

  @override
  Widget build(BuildContext context) {
    final scope = FontScope.maybeOf(context);
    return FontScope(
      typeface: scope?.typeface ?? AppTypeface.pretendard,
      todoScale: scope?.todoScale ?? 1,
      labelScale: scope?.labelScale ?? 1,
            calendarScale: math.min(scope?.calendarScale ?? 1, 0.82),
      calendarLabelScale: math.min(scope?.calendarLabelScale ?? 1, 0.8),
      calendarDateScale: math.min(scope?.calendarDateScale ?? 1, 0.82),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final days = MonthGrid.daysFor(month, startMonday: startMonday);
    final weekCount = days.length ~/ 7;
    final labels = AppStrings.weekdayLabels(startMonday: startMonday);
    final scale = AppFonts.calendarScaleOf(context);
    final labelScale = AppFonts.calendarLabelScaleOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              '${month.month}${AppStrings.monthSuffix}',
              style: TextStyle(
                fontFamily: font,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: colors.text,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        color: _weekdayColor(i, colors),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (var week = 0; week < weekCount; week++)
                  Expanded(
                    child: ClipRect(
                      child: _WeekRow(
                        days: days.sublist(week * 7, week * 7 + 7),
                        eventsOf: eventsOf,
                        calendarScale: scale,
                        labelScale: labelScale,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _weekdayColor(int index, AppColors colors) {
    if (startMonday) {
      if (index == 5) return _saturday;
      if (index == 6) return _sunday;
    } else {
      if (index == 0) return _sunday;
      if (index == 6) return _saturday;
    }
    return colors.muted;
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.days,
    required this.eventsOf,
    required this.calendarScale,
    required this.labelScale,
  });

  final List<CalendarDay> days;
  final List<CalendarEvent> Function(DateTime date) eventsOf;
  final double calendarScale;
  final double labelScale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final day in days)
              Expanded(
                child: IgnorePointer(
                  child: CalendarDayCell(day: day),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CalendarWeekEvents(
              days: days,
              eventsOf: eventsOf,
              calendarScale: calendarScale,
              labelScale: labelScale,
              dateScale: AppFonts.calendarDateScaleOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
