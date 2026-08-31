import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';

class WeekTimetableCard extends StatelessWidget {
  const WeekTimetableCard({
    super.key,
    required this.days,
    required this.today,
    required this.columns,
    this.showTime = true,
  });

  static const logicalSize = Size(440, 340);
  static const imageKey = 'week_timetable_image';
  static const emptyKey = 'week_timetable_empty';
  static const androidName = 'WeekTimetableWidgetProvider';
  static const qualifiedAndroidName =
      'com.jobplanner.job_planner.WeekTimetableWidgetProvider';
  static const iOSName = 'WeekTimetableWidget';

  static const headerHeight = 52.0;
  static const chipHeight = 24.0;
  static const chipGap = 4.0;
  static const timeHeight = 14.0;
  static const moreHeight = 16.0;
  static const _sunday = Color(0xFFEF4444);
  static const _saturday = Color(0xFF60A5FA);
  static const _today = Color(0xFF0088FF);

  final List<DateTime> days;
  final DateTime today;
  final List<List<CalendarEvent>> columns;
  final bool showTime;

  static DateTime weekStartOn(DateTime today, {bool startMonday = false}) {
    return calendarWeekStart(today, startMonday: startMonday);
  }

  static List<DateTime> weekDaysOn(DateTime today, {bool startMonday = false}) {
    final start = calendarWeekStart(today, startMonday: startMonday);
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Row(
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: _DayHeader(
                      date: days[i],
                      isToday: _isSameDay(days[i], today),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.border),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: colors.border,
                      ),
                    Expanded(
                      child: _DayColumn(
                        events: columns[i],
                        isToday: _isSameDay(days[i], today),
                        showTime: showTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Color weekdayColor(DateTime date, AppColors colors) {
    if (date.weekday == DateTime.sunday) return _sunday;
    if (date.weekday == DateTime.saturday) return _saturday;
    return colors.muted;
  }

  static Color dateColor(DateTime date, AppColors colors) {
    if (date.weekday == DateTime.sunday) return _sunday;
    if (date.weekday == DateTime.saturday) return _saturday;
    return colors.text;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.isToday,
  });

  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final weekday = AppStrings.weekdays[date.weekday % 7];
    final weekdayColor = isToday
        ? WeekTimetableCard._today
        : WeekTimetableCard.weekdayColor(date, colors);
    final numberColor = isToday
        ? Colors.white
        : WeekTimetableCard.dateColor(date, colors);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          weekday,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1,
            color: weekdayColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: isToday
              ? const BoxDecoration(
                  color: WeekTimetableCard._today,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 14,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              height: 1,
              color: numberColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.events,
    required this.isToday,
    required this.showTime,
  });

  final List<CalendarEvent> events;
  final bool isToday;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ordered = _ordered(events);
    return ColoredBox(
      color: isToday
          ? WeekTimetableCard._today.withValues(alpha: 0.06)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 6, 3, 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final visible = <CalendarEvent>[];
            var used = 0.0;
            for (final event in ordered) {
              final block = _blockHeight(event);
              final gap = visible.isEmpty ? 0.0 : WeekTimetableCard.chipGap;
              final leftover = ordered.length - visible.length - 1;
              final extra = leftover > 0
                  ? WeekTimetableCard.chipGap + WeekTimetableCard.moreHeight
                  : 0.0;
              if (used + gap + block + extra > constraints.maxHeight) break;
              visible.add(event);
              used += gap + block;
            }
            final more = ordered.length - visible.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const SizedBox(height: WeekTimetableCard.chipGap),
                  _EventEntry(
                    event: visible[i],
                    showTime: showTime,
                  ),
                ],
                if (more > 0) ...[
                  const SizedBox(height: WeekTimetableCard.chipGap),
                  Text(
                    '+$more',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: colors.muted,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  double _blockHeight(CalendarEvent event) {
    final timed = showTime && event.hasTime;
    return (timed ? WeekTimetableCard.timeHeight : 0) +
        WeekTimetableCard.chipHeight;
  }

  List<CalendarEvent> _ordered(List<CalendarEvent> events) {
    final jobs = [for (final event in events) if (event.isJob) event];
    final timed = [
      for (final event in events)
        if (!event.isJob && event.hasTime) event,
    ]..sort((a, b) => a.startMinutes!.compareTo(b.startMinutes!));
    final rest = [
      for (final event in events)
        if (!event.isJob && !event.hasTime) event,
    ];
    return [...jobs, ...timed, ...rest];
  }
}

class _EventEntry extends StatelessWidget {
  const _EventEntry({
    required this.event,
    required this.showTime,
  });

  final CalendarEvent event;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final time = showTime && event.hasTime
        ? CalendarEvent.formatMinutes(event.startMinutes!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (time != null)
          SizedBox(
            height: WeekTimetableCard.timeHeight,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
                color: event.completed ? colors.muted : event.color,
              ),
            ),
          ),
        Opacity(
          opacity: event.completed ? 0.45 : 1,
          child: CalendarEventLabel(
            title: event.title,
            color: event.color,
            completed: event.completed,
            isJob: event.isJob,
            height: WeekTimetableCard.chipHeight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            applyCalendarScale: false,
          ),
        ),
      ],
    );
  }
}
