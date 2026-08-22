import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_week_diaries.dart';
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
    this.diaryOf,
    this.showDiary = false,
    this.startMonday = false,
  });

  final DateTime month;
  final void Function(DateTime date, Rect origin)? onDayPressed;
  final void Function(DateTime start, DateTime end)? onRangeSelected;
  final ValueChanged<bool>? onRangeDragChanged;
  final List<CalendarEvent> Function(DateTime date)? eventsOf;
  final DiaryEntry? Function(DateTime date)? diaryOf;
  final bool showDiary;
  final bool startMonday;

  @override
  State<CalendarMonthGrid> createState() => _CalendarMonthGridState();
}

class _CalendarMonthGridState extends State<CalendarMonthGrid>
    with SingleTickerProviderStateMixin {
  static const _modeDuration = Duration(milliseconds: 460);

  final _keys = <DateTime, GlobalKey>{};
  final _weekKeys = <int, GlobalKey>{};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  var _dragging = false;
  late final AnimationController _mode;
  late final CurvedAnimation _ease;
  late final Animation<double> _eventsOpacity;
  late final Animation<double> _diaryOpacity;
  late final Animation<double> _eventsScale;
  late final Animation<double> _diaryScale;

  @override
  void initState() {
    super.initState();
    CalendarDayDropTarget._grids.add(this);
    _mode = AnimationController(
      vsync: this,
      duration: _modeDuration,
      reverseDuration: _modeDuration,
      value: widget.showDiary ? 1 : 0,
    );
    _ease = CurvedAnimation(
      parent: _mode,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _eventsOpacity = Tween<double>(begin: 1, end: 0).animate(_ease);
    _diaryOpacity = Tween<double>(begin: 0, end: 1).animate(_ease);
    _eventsScale = Tween<double>(begin: 1, end: 0.97).animate(_ease);
    _diaryScale = Tween<double>(begin: 0.97, end: 1).animate(_ease);
  }

  @override
  void didUpdateWidget(CalendarMonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showDiary == widget.showDiary) return;
    if (widget.showDiary) {
      _mode.forward();
    } else {
      _mode.reverse();
    }
  }

  @override
  void dispose() {
    CalendarDayDropTarget._grids.remove(this);
    _ease.dispose();
    _mode.dispose();
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
              final allowRange = widget.onRangeSelected != null;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: allowRange ? _onLongPressStart : null,
                onLongPressMoveUpdate: allowRange ? _onLongPressMove : null,
                onLongPressEnd: allowRange ? _onLongPressEnd : null,
                onLongPressCancel: allowRange ? _clearRange : null,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  primary: false,
                  physics: _dragging
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  itemCount: weekCount,
                  itemBuilder: (context, week) {
                    final weekDays = days.sublist(week * 7, week * 7 + 7);
                    final eventHeight = CalendarWeekEvents.heightFor(
                      days: weekDays,
                      eventsOf: widget.eventsOf ?? (_) => const [],
                      minHeight: minWeekHeight,
                      calendarScale: calendarScale,
                      labelScale: labelScale,
                    );
                    final diaryHeight = CalendarWeekDiaries.heightFor(
                      days: weekDays,
                      diaryOf: widget.diaryOf ?? (_) => null,
                      minHeight: minWeekHeight,
                      calendarScale: calendarScale,
                      labelScale: labelScale,
                    );
                    return AnimatedBuilder(
                      animation: _ease,
                      builder: (context, child) {
                        final t = _ease.value;
                        return SizedBox(
                          key: _weekKey(week),
                          height: eventHeight + (diaryHeight - eventHeight) * t,
                          child: child,
                        );
                      },
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
                              child: FadeTransition(
                                opacity: _eventsOpacity,
                                child: ScaleTransition(
                                  alignment: Alignment.topCenter,
                                  scale: _eventsScale,
                                  child: CalendarWeekEvents(
                                    days: weekDays,
                                    eventsOf: widget.eventsOf!,
                                    calendarScale: calendarScale,
                                    labelScale: labelScale,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.diaryOf != null)
                            Positioned.fill(
                              child: FadeTransition(
                                opacity: _diaryOpacity,
                                child: ScaleTransition(
                                  alignment: Alignment.topCenter,
                                  scale: _diaryScale,
                                  child: CalendarWeekDiaries(
                                    days: weekDays,
                                    diaryOf: widget.diaryOf!,
                                    calendarScale: calendarScale,
                                    labelScale: labelScale,
                                  ),
                                ),
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
