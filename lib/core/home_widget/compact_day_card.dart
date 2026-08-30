import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';

class CompactDayCard extends StatelessWidget {
  const CompactDayCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.events,
    required this.emptyText,
  });

  static const logicalSize = Size(172, 172);
  static const maxEvents = 6;
  static const imageKeyToday = 'today_glance_image';
  static const imageKeyTomorrow = 'tomorrow_glance_image';
  static const emptyKeyToday = 'today_glance_empty';
  static const emptyKeyTomorrow = 'tomorrow_glance_empty';
  static const androidTodayName = 'CompactTodayWidgetProvider';
  static const androidTomorrowName = 'CompactTomorrowWidgetProvider';
  static const iOSTodayName = 'CompactTodayWidget';
  static const iOSTomorrowName = 'CompactTomorrowWidget';
  static const qualifiedTodayName =
      'com.jobplanner.job_planner.$androidTodayName';
  static const qualifiedTomorrowName =
      'com.jobplanner.job_planner.$androidTomorrowName';

  final String title;
  final String dateLabel;
  final List<CalendarEvent> events;
  final String emptyText;

  static String monthDayLabel(DateTime date) =>
      '${date.month}${AppStrings.monthSuffix} ${date.day}';

  static List<CalendarEvent> visibleOf(List<CalendarEvent> events) {
    return CalendarEvent.withLockedThenStartTime([
      for (final event in events)
        if (event.isJob || !event.completed) event,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final items = visibleOf(events);
    final shown = items.take(maxEvents).toList();
    final more = items.length - shown.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: colors.accent,
                  ),
                ),
                TextSpan(
                  text: ' $dateLabel',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: colors.text,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? Text(
                    emptyText,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: colors.muted,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final event in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: event.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (more > 0)
                        Text(
                          '외 $more개',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: colors.muted,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
