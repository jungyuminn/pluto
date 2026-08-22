import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';

class CalendarWeekDiaries extends StatelessWidget {
  const CalendarWeekDiaries({
    super.key,
    required this.days,
    required this.diaryOf,
    this.calendarScale = 1,
    this.labelScale = 1,
  });

  final List<CalendarDay> days;
  final DiaryEntry? Function(DateTime date) diaryOf;
  final double calendarScale;
  final double labelScale;

  static const photoHeight = 42.0;

  static double photoHeightFor(double scale) => photoHeight * scale;

  static bool showsPhoto(DiaryEntry diary) {
    final path = diary.photoPath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  static double heightFor({
    required List<CalendarDay> days,
    required DiaryEntry? Function(DateTime date) diaryOf,
    required double minHeight,
    double calendarScale = 1,
    double labelScale = 1,
  }) {
    var content = 0.0;
    final photoH = photoHeightFor(calendarScale);
    final labelH = CalendarDayCell.labelHeightFor(labelScale);
    for (final day in days) {
      final top = CalendarDayCell.eventsTopFor(
        hasHoliday: day.isHoliday,
        scale: calendarScale,
      );
      final diary = diaryOf(day.date);
      if (diary == null) {
        if (top > content) content = top;
        continue;
      }
      final extra = showsPhoto(diary) ? photoH : labelH;
      final bottom = top + extra + 6;
      if (bottom > content) content = bottom;
    }
    return math.max(minHeight, content);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          final photoH = photoHeightFor(calendarScale);
          final labelH = CalendarDayCell.labelHeightFor(labelScale);
          return Stack(
            children: [
              for (var weekday = 0; weekday < days.length; weekday++)
                ..._tile(
                  day: days[weekday],
                  weekday: weekday,
                  cellWidth: cellWidth,
                  photoH: photoH,
                  labelH: labelH,
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _tile({
    required CalendarDay day,
    required int weekday,
    required double cellWidth,
    required double photoH,
    required double labelH,
  }) {
    final diary = diaryOf(day.date);
    if (diary == null) return const [];
    final photo = showsPhoto(diary);
    final top = CalendarDayCell.eventsTopFor(
      hasHoliday: day.isHoliday,
      scale: calendarScale,
    );
    final title = diary.title.trim().isEmpty
        ? AppStrings.diaryFallback
        : diary.title;
    final color = diary.color;
    return [
      Positioned(
        left: cellWidth * weekday + CalendarDayCell.sideInset,
        width: cellWidth - CalendarDayCell.sideInset * 2,
        top: top,
        height: photo ? photoH : labelH,
        child: Opacity(
          opacity: day.inMonth ? 1 : 0.45,
          child: photo
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(diary.photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return CalendarEventLabel(
                        title: title,
                        color: color,
                      );
                    },
                  ),
                )
              : CalendarEventLabel(
                  title: title,
                  color: color,
                ),
        ),
      ),
    ];
  }
}
