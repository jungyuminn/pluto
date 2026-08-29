import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_emoji_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_sticker_image.dart';

class CalendarWeekEvents extends StatefulWidget {
  const CalendarWeekEvents({
    super.key,
    required this.days,
    required this.eventsOf,
    this.emojisOf,
    this.calendarScale = 1,
    this.labelScale = 1,
    this.showLunar = false,
    this.searchHitKey,
    this.showAccent = true,
  });

  final List<CalendarDay> days;
  final List<CalendarEvent> Function(DateTime date) eventsOf;
  final String? Function(DateTime date)? emojisOf;
  final double calendarScale;
  final double labelScale;
  final bool showLunar;
  final String? searchHitKey;
  final bool showAccent;

  static const _moveDuration = Duration(milliseconds: 280);
  static const _fadeDuration = Duration(milliseconds: 220);

  static double heightFor({
    required List<CalendarDay> days,
    required List<CalendarEvent> Function(DateTime date) eventsOf,
    required double minHeight,
    String? Function(DateTime date)? emojisOf,
    double calendarScale = 1,
    double labelScale = 1,
    bool showLunar = false,
  }) {
    final blocks = _blocksFor(
      days,
      eventsOf,
      calendarScale,
      labelScale,
      showLunar,
    );
    var content = 0.0;
    for (final day in days) {
      final top = CalendarDayCell.eventsTopFor(
            hasHoliday: day.isHoliday,
            scale: calendarScale,
            showLunar: showLunar,
          ) +
          6;
      if (top > content) content = top;
    }
    final stride =
        CalendarDayCell.labelHeightFor(labelScale) + CalendarDayCell.labelGap;
    final labelHeight = CalendarDayCell.labelHeightFor(labelScale);
    for (final block in blocks) {
      final bottom = block.top + block.lane * stride + labelHeight + 6;
      if (bottom > content) content = bottom;
    }
    if (emojisOf != null) {
      for (var i = 0; i < days.length; i++) {
        final emoji = emojisOf(days[i].date);
        if (!DayStickers.isAsset(emoji)) continue;
        var bottom = CalendarDayCell.eventsTopFor(
          hasHoliday: days[i].isHoliday,
          scale: calendarScale,
          showLunar: showLunar,
        );
        for (final block in blocks) {
          if (block.start > i || block.end < i) continue;
          final labelBottom = block.top + block.lane * stride + labelHeight;
          if (labelBottom > bottom) bottom = labelBottom;
        }
        final emojiBottom =
            bottom +
            CalendarDayCell.labelGap +
            CalendarDayCell.emojiHeightFor(calendarScale) +
            6;
        if (emojiBottom > content) content = emojiBottom;
      }
    }
    return math.max(minHeight, content);
  }

  @override
  State<CalendarWeekEvents> createState() => _CalendarWeekEventsState();
}

class _CalendarWeekEventsState extends State<CalendarWeekEvents> {
  var _blocks = <_WeekBlock>[];
  var _exiting = <_WeekBlock>[];
  var _appearing = <String>{};
  var _appearingEmojis = <int>{};
  var _emojiPaths = <String?>[];
  var _exitGen = 0;

  List<String?> _emojiPathsOf() {
    final emojisOf = widget.emojisOf;
    if (emojisOf == null) {
      return List<String?>.filled(widget.days.length, null);
    }
    return [
      for (final day in widget.days)
        DayStickers.isAsset(emojisOf(day.date)) ? emojisOf(day.date) : null,
    ];
  }

  @override
  void initState() {
    super.initState();
    _blocks = _blocksFor(
      widget.days,
      widget.eventsOf,
      widget.calendarScale,
      widget.labelScale,
      widget.showLunar,
    );
    _emojiPaths = _emojiPathsOf();
  }

  @override
  void didUpdateWidget(CalendarWeekEvents oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _blocksFor(
      widget.days,
      widget.eventsOf,
      widget.calendarScale,
      widget.labelScale,
      widget.showLunar,
    );
    final sameWeek = widget.days.first.date == oldWidget.days.first.date &&
        widget.days.last.date == oldWidget.days.last.date &&
        widget.calendarScale == oldWidget.calendarScale &&
        widget.labelScale == oldWidget.labelScale &&
        widget.showLunar == oldWidget.showLunar;
    final nextEmojis = _emojiPathsOf();
    if (!sameWeek) {
      _exitGen++;
      setState(() {
        _blocks = next;
        _exiting = [];
        _appearing = {};
        _appearingEmojis = {};
        _emojiPaths = nextEmojis;
      });
      return;
    }

    final nextIds = {for (final block in next) block.event.id};
    final currentIds = {for (final block in _blocks) block.event.id};
    final leaving = [
      for (final block in _blocks)
        if (!nextIds.contains(block.event.id)) block,
    ];
    final appearing = {
      for (final block in next)
        if (!currentIds.contains(block.event.id)) block.event.id,
    };
    final appearingEmojis = {
      for (var i = 0; i < nextEmojis.length; i++)
        if (nextEmojis[i] != null &&
            (i >= _emojiPaths.length || nextEmojis[i] != _emojiPaths[i]))
          i,
    };

    _exitGen++;
    final gen = _exitGen;
    setState(() {
      _exiting = leaving;
      _appearing = appearing;
      _appearingEmojis = appearingEmojis;
      _emojiPaths = nextEmojis;
      _blocks = next;
    });
    if (leaving.isEmpty) return;
    Future<void>.delayed(CalendarWeekEvents._fadeDuration, () {
      if (!mounted || gen != _exitGen) return;
      setState(() => _exiting = []);
    });
  }

  bool _isSearchMatch(CalendarEvent event) {
    final key = widget.searchHitKey;
    if (key == null) return false;
    return (event.groupId ?? event.id) == key;
  }

  @override
  Widget build(BuildContext context) {
    final emojisOf = widget.emojisOf;
    final hasEmoji = emojisOf != null &&
        widget.days.any((day) {
          final emoji = emojisOf(day.date);
          return DayStickers.isAsset(emoji);
        });
    if (_blocks.isEmpty && _exiting.isEmpty && !hasEmoji) {
      return const SizedBox.expand();
    }
    final labelScale = widget.labelScale;
    final stride =
        CalendarDayCell.labelHeightFor(labelScale) + CalendarDayCell.labelGap;
    final labelHeight = CalendarDayCell.labelHeightFor(labelScale);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final block in _exiting)
                Positioned(
                  key: ValueKey('out-${block.event.id}'),
                  left: cellWidth * block.start + CalendarDayCell.sideInset,
                  width: cellWidth * block.span - CalendarDayCell.sideInset * 2,
                  top: block.top + block.lane * stride,
                  height: labelHeight,
                  child: _FadingLabel(
                    block: block,
                    visible: false,
                    searching: widget.searchHitKey != null,
                    matched: _isSearchMatch(block.event),
                    showAccent: widget.showAccent,
                  ),
                ),
              for (final block in _blocks)
                AnimatedPositioned(
                  key: ValueKey(block.event.id),
                  duration: CalendarWeekEvents._moveDuration,
                  curve: Curves.easeOutCubic,
                  left: cellWidth * block.start + CalendarDayCell.sideInset,
                  width: cellWidth * block.span - CalendarDayCell.sideInset * 2,
                  top: block.top + block.lane * stride,
                  height: labelHeight,
                  child: _FadingLabel(
                    block: block,
                    visible: true,
                    appear: _appearing.contains(block.event.id),
                    searching: widget.searchHitKey != null,
                    matched: _isSearchMatch(block.event),
                    showAccent: widget.showAccent,
                  ),
                ),
              if (emojisOf != null)
                for (var i = 0; i < widget.days.length; i++)
                  if (DayStickers.isAsset(emojisOf(widget.days[i].date)))
                    Positioned(
                      left: cellWidth * i,
                      width: cellWidth,
                      top: _emojiTop(i, stride, labelHeight),
                      height: CalendarDayCell.emojiHeightFor(widget.calendarScale),
                      child: DayStickerImage(
                        key: ValueKey(
                          '${widget.days[i].date.toIso8601String()}-${emojisOf(widget.days[i].date)}',
                        ),
                        asset: emojisOf(widget.days[i].date)!,
                        opacity: widget.days[i].inMonth ? 1 : 0.45,
                        pop: _appearingEmojis.contains(i),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  double _emojiTop(int dayIndex, double stride, double labelHeight) {
    var bottom = CalendarDayCell.eventsTopFor(
      hasHoliday: widget.days[dayIndex].isHoliday,
      scale: widget.calendarScale,
      showLunar: widget.showLunar,
    );
    for (final block in _blocks) {
      if (block.start > dayIndex || block.end < dayIndex) continue;
      final labelBottom = block.top + block.lane * stride + labelHeight;
      if (labelBottom > bottom) bottom = labelBottom;
    }
    return bottom + CalendarDayCell.labelGap;
  }
}

class _FadingLabel extends StatefulWidget {
  const _FadingLabel({
    required this.block,
    required this.visible,
    this.appear = false,
    this.searching = false,
    this.matched = false,
    this.showAccent = true,
  });

  final _WeekBlock block;
  final bool visible;
  final bool appear;
  final bool searching;
  final bool matched;
  final bool showAccent;

  @override
  State<_FadingLabel> createState() => _FadingLabelState();
}

class _FadingLabelState extends State<_FadingLabel> {
  late var _opacity = widget.visible && !widget.appear ? 1.0 : widget.visible ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.appear || !widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _opacity = widget.visible ? 1 : 0);
      });
    }
  }

  @override
  void didUpdateWidget(_FadingLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.visible ? 1.0 : 0.0;
    if (_opacity == next) return;
    _opacity = next;
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final dim = widget.searching && !widget.matched;
    return AnimatedOpacity(
      duration: CalendarWeekEvents._fadeDuration,
      curve: widget.visible ? Curves.easeOutCubic : Curves.easeInCubic,
      opacity: _opacity * (block.inMonth ? 1 : 0.45) * (dim ? 0.28 : 1),
      child: CalendarEventLabel(
        title: block.event.title,
        color: block.event.color,
        completed: block.event.completed,
        showAccent: widget.showAccent && block.showAccent,
        isJob: block.event.isJob,
      ),
    );
  }
}

class _WeekBlock {
  const _WeekBlock({
    required this.event,
    required this.start,
    required this.end,
    required this.lane,
    required this.top,
    required this.showAccent,
    required this.inMonth,
  });

  final CalendarEvent event;
  final int start;
  final int end;
  final int lane;
  final double top;
  final bool showAccent;
  final bool inMonth;

  int get span => end - start + 1;
}

class _OccupiedRange {
  const _OccupiedRange(this.top, this.bottom);

  final double top;
  final double bottom;

  bool overlaps(double otherTop, double otherBottom) {
    return otherTop < bottom && top < otherBottom;
  }
}

List<_WeekBlock> _blocksFor(
  List<CalendarDay> days,
  List<CalendarEvent> Function(DateTime date) eventsOf,
  double calendarScale,
  double labelScale,
  bool showLunar,
) {
  final occupied = List.generate(7, (_) => <_OccupiedRange>[]);
  final seenGroups = <String>{};
  final raw = <({
    CalendarEvent event,
    int start,
    int end,
    bool showAccent,
    bool inMonth,
  })>[];

  bool sameGroup(CalendarEvent event, CalendarEvent other) {
    if (event.groupId != null) return event.groupId == other.groupId;
    return event.id == other.id;
  }

  bool hasGroupOn(DateTime date, CalendarEvent event) {
    return eventsOf(date).any((item) => sameGroup(event, item));
  }

  for (var weekday = 0; weekday < 7; weekday++) {
    final day = days[weekday];
    for (final event in eventsOf(day.date)) {
      final groupId = event.groupId;
      if (groupId != null) {
        if (seenGroups.contains(groupId)) continue;
        seenGroups.add(groupId);
      }
      var end = weekday;
      if (groupId != null) {
        for (var next = weekday + 1; next < 7; next++) {
          if (!hasGroupOn(days[next].date, event)) break;
          end = next;
        }
      }
      final previous = day.date.subtract(const Duration(days: 1));
      final showAccent = groupId == null || !hasGroupOn(previous, event);
      raw.add((
        event: event,
        start: weekday,
        end: end,
        showAccent: showAccent,
        inMonth: days.sublist(weekday, end + 1).any((item) => item.inMonth),
      ));
    }
  }

  final origin = [
    for (final day in days)
      CalendarDayCell.eventsTopFor(
        hasHoliday: day.isHoliday,
        scale: calendarScale,
        showLunar: showLunar,
      ),
  ];
  var shifted = true;
  while (shifted) {
    shifted = false;
    for (final item in raw) {
      if (!item.event.isRange) continue;
      var top = origin[item.start];
      for (var day = item.start; day <= item.end; day++) {
        if (origin[day] > top) top = origin[day];
      }
      for (var day = item.start; day <= item.end; day++) {
        if (origin[day] < top) {
          origin[day] = top;
          shifted = true;
        }
      }
    }
  }

  double originOf(({int start, int end}) item) {
    var top = origin[item.start];
    for (var day = item.start; day <= item.end; day++) {
      if (origin[day] > top) top = origin[day];
    }
    return top;
  }

  final stride =
      CalendarDayCell.labelHeightFor(labelScale) + CalendarDayCell.labelGap;
  final labelHeight = CalendarDayCell.labelHeightFor(labelScale);
  final blocks = <_WeekBlock>[];
  final lastLane = List.filled(7, -1);

  void place(
    ({
      CalendarEvent event,
      int start,
      int end,
      bool showAccent,
      bool inMonth,
    }) item, {
    int? lane,
  }) {
    final top = originOf((start: item.start, end: item.end));
    var chosen = lane ?? 0;
    while (true) {
      final labelTop = top + chosen * stride;
      final labelBottom = labelTop + labelHeight;
      final taken = [
        for (var day = item.start; day <= item.end; day++)
          occupied[day].any((range) => range.overlaps(labelTop, labelBottom)),
      ].any((value) => value);
      if (!taken) {
        for (var day = item.start; day <= item.end; day++) {
          occupied[day].add(_OccupiedRange(labelTop, labelBottom));
          if (chosen > lastLane[day]) lastLane[day] = chosen;
        }
        blocks.add(
          _WeekBlock(
            event: item.event,
            start: item.start,
            end: item.end,
            lane: chosen,
            top: top,
            showAccent: item.showAccent,
            inMonth: item.inMonth,
          ),
        );
        return;
      }
      chosen++;
    }
  }

  var rangeLane = 0;
  for (final item in raw) {
    if (!item.event.isJob) continue;
    place(item);
  }
  for (final item in raw) {
    if (item.event.isJob || !item.event.isRange) continue;
    place(item, lane: rangeLane);
    rangeLane++;
  }
  for (final item in raw) {
    if (item.event.isJob || item.event.isRange) continue;
    var minLane = 0;
    for (var day = item.start; day <= item.end; day++) {
      final next = lastLane[day] + 1;
      if (next > minLane) minLane = next;
    }
    place(item, lane: minLane);
  }
  return blocks;
}
