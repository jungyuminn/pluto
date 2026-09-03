import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/domain/entities/calendar_event.dart';

class CompactDayCard extends StatelessWidget {
  const CompactDayCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.events,
    required this.emptyText,
    this.sortByTime = false,
  });

  static const maxEvents = 6;
  static const androidTodayName = 'CompactTodayWidgetProvider';
  static const androidTomorrowName = 'CompactTomorrowWidgetProvider';
  static const iOSTodayName = 'CompactTodayWidget';
  static const iOSTomorrowName = 'CompactTomorrowWidget';
  static const qualifiedTodayName =
      'com.pluto.app.$androidTodayName';
  static const qualifiedTomorrowName =
      'com.pluto.app.$androidTomorrowName';

  final String title;
  final String dateLabel;
  final List<CalendarEvent> events;
  final String emptyText;
  final bool sortByTime;

  static String monthDayLabel(DateTime date) =>
      '${date.month}${AppStrings.monthSuffix} ${date.day}${AppStrings.daySuffix}';

  static List<CalendarEvent> visibleOf(
    List<CalendarEvent> events, {
    required bool sortByTime,
  }) {
    final open = [
      for (final event in events)
        if (event.isJob || !event.completed) event,
    ];
    if (!sortByTime) return open;
    return CalendarEvent.withLockedThenStartTime(open);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final items = visibleOf(events, sortByTime: sortByTime);
    final shown = items.take(maxEvents).toList();
    final more = items.length - shown.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: colors.text,
                  ),
                ),
                TextSpan(
                  text: ' $dateLabel',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                    color: colors.text,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Text(
                    emptyText,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                      color: colors.muted,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final event in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: event.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
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
