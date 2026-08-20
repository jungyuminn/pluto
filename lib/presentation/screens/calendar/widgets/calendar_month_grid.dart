import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_week_events.dart';

class CalendarDayDropTarget {
  CalendarDayDropTarget._();

  static final highlighted = ValueNotifier<DateTime?>(null);
  static final hidingScrim = ValueNotifier(false);
  static final _grids = <_CalendarMonthGridState>{};

  static DateTime? dateAt(Offset global) {
    for (final grid in _grids) {
      final date = grid.dateAt(global);
      if (date != null) return date;
    }
    return null;
  }

  static void highlight(DateTime? date) {
    final next = date == null
        ? null
        : DateTime(date.year, date.month, date.day);
    final current = highlighted.value;
    if (current?.year == next?.year &&
        current?.month == next?.month &&
        current?.day == next?.day) {
      return;
    }
    highlighted.value = next;
  }

  static void clear() => highlight(null);

  static void setScrimHidden(bool value) {
    if (hidingScrim.value == value) return;
    hidingScrim.value = value;
  }

  static void reset() {
    highlight(null);
    setScrimHidden(false);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class CalendarMonthGrid extends StatefulWidget {
  const CalendarMonthGrid({
    super.key,
    required this.month,
    this.onDayPressed,
    this.onRangeSelected,
    this.onRangeDragChanged,
    this.eventsOf,
    this.startMonday = false,
  });

  final DateTime month;
  final void Function(DateTime date, Rect origin)? onDayPressed;
  final void Function(DateTime start, DateTime end)? onRangeSelected;
  final ValueChanged<bool>? onRangeDragChanged;
  final List<CalendarEvent> Function(DateTime date)? eventsOf;
  final bool startMonday;

  @override
  State<CalendarMonthGrid> createState() => _CalendarMonthGridState();
}

class _CalendarMonthGridState extends State<CalendarMonthGrid> {
  final _keys = <DateTime, GlobalKey>{};
  final _weekKeys = <int, GlobalKey>{};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  var _dragging = false;

  @override
  void initState() {
    super.initState();
    CalendarDayDropTarget._grids.add(this);
  }

  @override
  void dispose() {
    CalendarDayDropTarget._grids.remove(this);
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  GlobalKey _keyFor(DateTime date) {
    return _keys.putIfAbsent(_dateOnly(date), GlobalKey.new);
  }

  GlobalKey _weekKey(int week) {
    return _weekKeys.putIfAbsent(week, GlobalKey.new);
  }

  DateTime? dateAt(Offset global) {
    final days = MonthGrid.daysFor(
      widget.month,
      startMonday: widget.startMonday,
    );
    final weekCount = days.length ~/ 7;
    for (var week = 0; week < weekCount; week++) {
      final box =
          _weekKey(week).currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final origin = box.localToGlobal(Offset.zero);
      final rect = origin & box.size;
      if (!rect.contains(global)) continue;
      final col = (global.dx - origin.dx) / box.size.width * 7;
      final weekday = col.floor().clamp(0, 6);
      return days[week * 7 + weekday].date;
    }
    for (final entry in _keys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final origin = box.localToGlobal(Offset.zero);
      if ((origin & box.size).contains(global)) return entry.key;
    }
    return null;
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    _dragging = value;
    widget.onRangeDragChanged?.call(value);
  }

  void _clearRange() {
    _setDragging(false);
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final date = dateAt(details.globalPosition);
    if (date == null) return;
    HapticFeedback.mediumImpact();
    _setDragging(true);
    setState(() {
      _rangeStart = date;
      _rangeEnd = date;
    });
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_dragging || _rangeStart == null) return;
    final date = dateAt(details.globalPosition);
    if (date == null || date == _rangeEnd) return;
    setState(() => _rangeEnd = date);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    final start = _rangeStart;
    final end = _rangeEnd;
    _clearRange();
    if (start == null || end == null || start == end) return;
    final first = start.isBefore(end) ? start : end;
    final last = start.isBefore(end) ? end : start;
    widget.onRangeSelected?.call(first, last);
  }

  bool _inRange(DateTime date) {
    final start = _rangeStart;
    final end = _rangeEnd;
    if (start == null || end == null) return false;
    final first = start.isBefore(end) ? start : end;
    final last = start.isBefore(end) ? end : start;
    final day = _dateOnly(date);
    return !day.isBefore(first) && !day.isAfter(last);
  }

  bool _isDropTarget(DateTime date, DateTime? highlighted) {
    if (highlighted == null) return false;
    return CalendarDayDropTarget.isSameDay(date, highlighted);
  }

  @override
  Widget build(BuildContext context) {
    CalendarDayDropTarget._grids.add(this);
    final days = MonthGrid.daysFor(widget.month, startMonday: widget.startMonday);
    final weekCount = days.length ~/ 7;

    return ValueListenableBuilder<DateTime?>(
      valueListenable: CalendarDayDropTarget.highlighted,
      builder: (context, highlighted, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minWeekHeight = constraints.maxHeight / weekCount;
              final calendarScale = AppFonts.calendarScaleOf(context);
              final labelScale = AppFonts.calendarLabelScaleOf(context);
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: _onLongPressStart,
                onLongPressMoveUpdate: _onLongPressMove,
                onLongPressEnd: _onLongPressEnd,
                onLongPressCancel: _clearRange,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  primary: false,
                  physics: _dragging
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  itemCount: weekCount,
                  itemBuilder: (context, week) {
                    final weekDays = days.sublist(week * 7, week * 7 + 7);
                    return AnimatedContainer(
                      key: _weekKey(week),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: CalendarWeekEvents.heightFor(
                        days: weekDays,
                        eventsOf: widget.eventsOf ?? (_) => const [],
                        minHeight: minWeekHeight,
                        calendarScale: calendarScale,
                        labelScale: labelScale,
                      ),
                      child: Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var weekday = 0; weekday < 7; weekday++)
                                Expanded(
                                  child: KeyedSubtree(
                                    key: _keyFor(weekDays[weekday].date),
                                    child: SizedBox.expand(
                                      child: CalendarDayCell(
                                        day: weekDays[weekday],
                                        inRange: _inRange(weekDays[weekday].date),
                                        highlighted: _isDropTarget(
                                          weekDays[weekday].date,
                                          highlighted,
                                        ),
                                        onPressed: widget.onDayPressed == null
                                            ? null
                                            : (origin) => widget.onDayPressed!(
                                                  weekDays[weekday].date,
                                                  origin,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (widget.eventsOf != null)
                            Positioned.fill(
                              child: CalendarWeekEvents(
                                days: weekDays,
                                eventsOf: widget.eventsOf!,
                                calendarScale: calendarScale,
                                labelScale: labelScale,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
