import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';

class TodayWidgetSnapshot {
  const TodayWidgetSnapshot({
    required this.items,
    required this.moreCount,
  });

  final List<TodayWidgetItem> items;
  final int moreCount;

  Size get size => TodayWidgetCard.layoutSize(
        items: items,
        moreCount: moreCount,
      );
}

class TodayWidgetItem {
  const TodayWidgetItem.event(this.event)
      : headerName = null,
        headerColor = null,
        showTopGap = false,
        showDot = true;

  const TodayWidgetItem.header({
    required String name,
    required Color color,
    this.showTopGap = false,
    this.showDot = true,
  })  : event = null,
        headerName = name,
        headerColor = color;

  final CalendarEvent? event;
  final String? headerName;
  final Color? headerColor;
  final bool showTopGap;
  final bool showDot;

  double get extent {
    if (event != null) return TodayWidgetCard.eventExtent;
    return TodayWidgetCard.headerExtent +
        (showTopGap ? TodayWidgetCard.headerGap : 0);
  }
}

class TodayWidgetCard extends StatelessWidget {
  const TodayWidgetCard({
    super.key,
    required this.dateLabel,
    required this.snapshot,
    required this.showTime,
    this.officeIcon,
  });

  static const cardRadius = 24.0;
  static const shadowPad = EdgeInsets.fromLTRB(4, 2, 4, 8);
  static const _pad = EdgeInsets.fromLTRB(16, 14, 16, 12);
  static const eventExtent = 62.0;
  static const headerExtent = 24.0;
  static const headerGap = 6.0;
  static const moreExtent = 18.0;
  static const titleBlock = 20.0;
  static const dateBlock = 18.4;
  static const listGap = 12.0;
  static const maxEvents = 40;
  static const cardWidth = 412.0;
  static const headerSize = Size(cardWidth, titleBlock + 4 + dateBlock);

  final String dateLabel;
  final TodayWidgetSnapshot snapshot;
  final bool showTime;
  final ui.Image? officeIcon;

  static Size layoutSize({
    required List<TodayWidgetItem> items,
    required int moreCount,
    double width = cardWidth,
  }) {
    var height =
        shadowPad.vertical + _pad.vertical + titleBlock + dateBlock + listGap;
    for (final item in items) {
      height += item.extent;
    }
    if (moreCount > 0) height += moreExtent;
    return Size(width, height + 6);
  }

  static TodayWidgetSnapshot snapshotFor({
    required List<CalendarEvent> events,
    required List<EventCategory> categories,
    required bool compact,
    required bool sortByTime,
    int maxEvents = TodayWidgetCard.maxEvents,
  }) {
    final items = _itemsFor(
      events: events,
      categories: categories,
      compact: compact,
      sortByTime: sortByTime,
    );
    final visible = <TodayWidgetItem>[];
    var eventCount = 0;
    var skipped = 0;
    for (final item in items) {
      if (item.event == null) {
        if (eventCount >= maxEvents) continue;
        visible.add(item);
        continue;
      }
      if (eventCount >= maxEvents) {
        skipped++;
        continue;
      }
      visible.add(item);
      eventCount++;
    }
    while (visible.isNotEmpty && visible.last.event == null) {
      visible.removeLast();
    }
    return TodayWidgetSnapshot(items: visible, moreCount: skipped);
  }

  static List<TodayWidgetItem> _itemsFor({
    required List<CalendarEvent> events,
    required List<EventCategory> categories,
    required bool compact,
    required bool sortByTime,
  }) {
    if (!compact) {
      final ordered = sortByTime
          ? CalendarEvent.withLockedThenStartTime(events)
          : events;
      return [for (final event in ordered) TodayWidgetItem.event(event)];
    }

    final jobs = [for (final event in events) if (event.isJob) event];
    final todos = [for (final event in events) if (!event.isJob) event];
    final groups = <String, List<CalendarEvent>>{};
    for (final event in todos) {
      final key = event.categoryId ?? event.categoryName;
      groups.putIfAbsent(key, () => []).add(event);
    }

    final items = <TodayWidgetItem>[];
    final used = <String>{};
    var firstHeader = true;

    void addSection({
      required String name,
      required Color color,
      required List<CalendarEvent> section,
    }) {
      final ordered = sortByTime
          ? CalendarEvent.withLockedThenStartTime(section)
          : section;
      items.add(
        TodayWidgetItem.header(
          name: name,
          color: color,
          showTopGap: !firstHeader,
        ),
      );
      firstHeader = false;
      for (final event in ordered) {
        items.add(TodayWidgetItem.event(event));
      }
    }

    if (jobs.isNotEmpty) {
      addSection(
        name: AppStrings.companySection,
        color: jobs.first.color,
        section: jobs,
      );
    }

    for (final category in categories) {
      final grouped = groups[category.id];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(category.id);
      addSection(
        name: category.name,
        color: category.tint,
        section: grouped,
      );
    }
    for (final event in todos) {
      final key = event.categoryId ?? event.categoryName;
      if (used.contains(key)) continue;
      final grouped = groups[key];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(key);
      addSection(
        name: event.categoryName,
        color: event.color,
        section: grouped,
      );
    }
    return items;
  }

  String? _timeText(CalendarEvent event) {
    return timeTextFor(event, showTime);
  }

  static String? timeTextFor(CalendarEvent event, bool showTime) {
    if (!showTime) return null;
    return event.timeLabel ?? (event.isJob ? null : AppStrings.allDayLabel);
  }

  static Widget header({
    required String title,
    required String dateLabel,
  }) {
    return Builder(
      builder: (context) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: font,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: font,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: colors.muted,
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget row({
    required TodayWidgetItem item,
    required bool showTime,
    ui.Image? officeIcon,
  }) {
    if (item.event == null) {
      return _CategoryHeader(
        name: item.headerName!,
        color: item.headerColor!,
        showTopGap: item.showTopGap,
        showDot: item.showDot,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _WidgetEventLabel(
        event: item.event!,
        timeText: timeTextFor(item.event!, showTime),
        officeIcon: officeIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: shadowPad,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: _pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.todayTitle,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: listGap),
              for (final item in snapshot.items)
                if (item.event == null)
                  _CategoryHeader(
                    name: item.headerName!,
                    color: item.headerColor!,
                    showTopGap: item.showTopGap,
                    showDot: item.showDot,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WidgetEventLabel(
                      event: item.event!,
                      timeText: _timeText(item.event!),
                      officeIcon: officeIcon,
                    ),
                  ),
              if (snapshot.moreCount > 0)
                Text(
                  '외 ${snapshot.moreCount}개',
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: colors.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.name,
    required this.color,
    required this.showTopGap,
    this.showDot = true,
  });

  final String name;
  final Color color;
  final bool showTopGap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: showTopGap ? TodayWidgetCard.headerGap : 0,
        bottom: 8,
      ),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (showDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1,
                color: AppColors.of(context).text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetEventLabel extends StatelessWidget {
  const _WidgetEventLabel({
    required this.event,
    required this.timeText,
    this.officeIcon,
  });

  static const _height = 52.0;

  final CalendarEvent event;
  final String? timeText;
  final ui.Image? officeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = colors.tint(event.color, 0.14);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: Row(
            children: [
              Container(
                width: (event.completed || event.isJob) ? 0 : 4,
                height: _height,
                color: event.color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.categoryName,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.of(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                                color: colors.hint,
                              ),
                            ),
                          ),
                          if (timeText != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              timeText!,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppFonts.of(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: event.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (event.isJob && officeIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      event.color,
                      BlendMode.srcIn,
                    ),
                    child: RawImage(
                      image: officeIcon,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              if (event.isRange)
                Padding(
                  padding: EdgeInsets.only(right: event.isRepeat ? 0 : 6),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 22,
                      color: event.color,
                    ),
                  ),
                ),
              if (event.isRepeat)
                Padding(
                  padding: EdgeInsets.only(right: event.isJob ? 6 : 0),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.repeat_rounded,
                      size: 22,
                      color: event.color,
                    ),
                  ),
                ),
              if (!event.isJob)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CustomPaint(
                          painter: _CompleteMarkPainter(
                            completed: event.completed,
                            color: event.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteMarkPainter extends CustomPainter {
  const _CompleteMarkPainter({
    required this.completed,
    required this.color,
  });

  final bool completed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final progress = completed ? 1.0 : 0.0;
    final circleProgress = (1 - progress * 1.15).clamp(0.0, 1.0);

    if (circleProgress > 0) {
      final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width * 0.36,
      );
      final circle = Path()..addArc(rect, -math.pi / 2, 2 * math.pi);
      final metric = circle.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * circleProgress),
        paint,
      );
    }

    if (progress > 0) {
      final check = Path()
        ..moveTo(size.width * 0.18, size.height * 0.52)
        ..lineTo(size.width * 0.40, size.height * 0.74)
        ..lineTo(size.width * 0.84, size.height * 0.26);
      final metric = check.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompleteMarkPainter oldDelegate) {
    return oldDelegate.completed != completed || oldDelegate.color != color;
  }
}
