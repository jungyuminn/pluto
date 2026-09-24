import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/calendar/month_grid.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_week_diaries.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_week_events.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';

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
    this.onDayLongPressed,
    this.onRangeSelected,
    this.onRangeDragChanged,
    this.eventsOf,
    this.diariesOf,
    this.ledgersOf,
    this.emojisOf,
    this.showDiary = false,
    this.showLedger = false,
    this.showLedgerTitle = true,
    this.showLedgerAmount = false,
    this.ledgerCategoryView = false,
    this.ledgerKindColor = false,
    this.startMonday = false,
    this.showLunar = false,
    this.searchDay,
    this.searchHitKey,
  });

  final DateTime month;
  final void Function(DateTime date, Rect origin)? onDayPressed;
  final ValueChanged<DateTime>? onDayLongPressed;
  final void Function(DateTime start, DateTime end)? onRangeSelected;
  final ValueChanged<bool>? onRangeDragChanged;
  final List<CalendarEvent> Function(DateTime date)? eventsOf;
  final List<DiaryEntry> Function(DateTime date)? diariesOf;
  final List<LedgerEntry> Function(DateTime date)? ledgersOf;
  final String? Function(DateTime date)? emojisOf;
  final bool showDiary;
  final bool showLedger;
  final bool showLedgerTitle;
  final bool showLedgerAmount;
  final bool ledgerCategoryView;
  final bool ledgerKindColor;
  final bool startMonday;
  final bool showLunar;
  final DateTime? searchDay;
  final String? searchHitKey;

  @override
  State<CalendarMonthGrid> createState() => _CalendarMonthGridState();
}

class _CalendarMonthGridState extends State<CalendarMonthGrid>
    with TickerProviderStateMixin {
  static const _modeDuration = Duration(milliseconds: 460);

  final _keys = <DateTime, GlobalKey>{};
  final _weekKeys = <int, GlobalKey>{};
  final _stackKey = GlobalKey();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Rect? _searchRect;
  var _searchAnimate = false;
  var _dragging = false;
  late final AnimationController _mode;
  late final AnimationController _alt;
  late final CurvedAnimation _ease;
  late final CurvedAnimation _altEase;
  late final Animation<double> _eventsOpacity;
  late final Animation<double> _diaryOpacity;
  late final Animation<double> _eventsScale;
  late final Animation<double> _diaryScale;
  late final Animation<double> _diaryAltOpacity;
  late final Animation<double> _ledgerAltOpacity;
  late final Animation<double> _diaryAltScale;
  late final Animation<double> _ledgerAltScale;
  late bool _showLunar;

  @override
  void initState() {
    super.initState();
    _showLunar = widget.showLunar;
    CalendarDayDropTarget._grids.add(this);
    _mode = AnimationController(
      vsync: this,
      duration: _modeDuration,
      reverseDuration: _modeDuration,
      value: (widget.showDiary || widget.showLedger) ? 1 : 0,
    );
    _alt = AnimationController(
      vsync: this,
      duration: _modeDuration,
      reverseDuration: _modeDuration,
      value: widget.showLedger ? 1 : 0,
    );
    _ease = CurvedAnimation(
      parent: _mode,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _altEase = CurvedAnimation(
      parent: _alt,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _eventsOpacity = Tween<double>(begin: 1, end: 0).animate(_ease);
    _diaryOpacity = Tween<double>(begin: 0, end: 1).animate(_ease);
    _eventsScale = Tween<double>(begin: 1, end: 0.97).animate(_ease);
    _diaryScale = Tween<double>(begin: 0.97, end: 1).animate(_ease);
    _diaryAltOpacity = Tween<double>(begin: 1, end: 0).animate(_altEase);
    _ledgerAltOpacity = Tween<double>(begin: 0, end: 1).animate(_altEase);
    _diaryAltScale = Tween<double>(begin: 1, end: 0.97).animate(_altEase);
    _ledgerAltScale = Tween<double>(begin: 0.97, end: 1).animate(_altEase);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSearchHighlight(animate: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLunar();
  }

  void _syncLunar() {
    final canAnimate = TickerMode.of(context);
    if (_showLunar == widget.showLunar) return;
    if (!canAnimate) return;
    setState(() => _showLunar = widget.showLunar);
  }

  @override
  void didUpdateWidget(CalendarMonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLunar();
    final wasAlt = oldWidget.showDiary || oldWidget.showLedger;
    final isAlt = widget.showDiary || widget.showLedger;
    if (wasAlt != isAlt) {
      if (isAlt) {
        _alt.value = widget.showLedger ? 1 : 0;
        _mode.forward();
      } else {
        _mode.reverse();
      }
    } else if (isAlt && oldWidget.showLedger != widget.showLedger) {
      if (widget.showLedger) {
        _alt.forward();
      } else {
        _alt.reverse();
      }
    }
    if (oldWidget.searchDay != widget.searchDay ||
        oldWidget.month != widget.month) {
      _syncSearchHighlight(
        animate: oldWidget.searchDay != null && widget.searchDay != null,
      );
    }
  }

  @override
  void dispose() {
    CalendarDayDropTarget._grids.remove(this);
    _ease.dispose();
    _altEase.dispose();
    _mode.dispose();
    _alt.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<CalendarEvent> _ledgerEventsOn(DateTime date) {
    final ledgersOf = widget.ledgersOf;
    if (ledgersOf == null) return const [];
    if (!widget.showLedgerTitle && !widget.showLedgerAmount) return const [];
    final entries = [...ledgersOf(date)];
    if (widget.ledgerCategoryView) {
      entries.sort(LedgerEntry.compareByCategory);
    }
    return [
      for (final entry in entries)
        if (entry
            .calendarLabel(
              showTitle: widget.showLedgerTitle,
              showAmount: widget.showLedgerAmount,
            )
            .isNotEmpty)
          entry.toCalendarEvent(
            showTitle: widget.showLedgerTitle,
            showAmount: widget.showLedgerAmount,
            kindColor: widget.ledgerKindColor,
          ),
    ];
  }

  GlobalKey _keyFor(DateTime date) {
    return _keys.putIfAbsent(_dateOnly(date), GlobalKey.new);
  }

  GlobalKey _weekKey(int week) {
    return _weekKeys.putIfAbsent(week, GlobalKey.new);
  }

  Widget _maybeTodayAnchor(CalendarDay day, Widget child) {
    if (!day.inMonth || !day.isToday) return child;
    return TutorialAnchor(
      id: TutorialAnchorId.calendarDay,
      child: child,
    );
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

  bool _isInSearchMonth(DateTime day) {
    return day.year == widget.month.year && day.month == widget.month.month;
  }

  Rect? _searchRectFor(DateTime day) {
    if (!_isInSearchMonth(day)) return null;
    final cell =
        _keys[_dateOnly(day)]?.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (cell == null || stack == null || !cell.hasSize || !stack.hasSize) {
      return null;
    }
    final offset = cell.localToGlobal(Offset.zero, ancestor: stack);
    return offset & cell.size;
  }

  void _syncSearchHighlight({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final day = widget.searchDay;
      final rect = day == null ? null : _searchRectFor(day);
      if (rect == _searchRect) return;
      setState(() {
        _searchAnimate = animate && _searchRect != null && rect != null;
        _searchRect = rect;
      });
    });
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
              final cellWidth = constraints.maxWidth / 7;
              final calendarScale = AppFonts.calendarScaleOf(context);
              final labelScale = AppFonts.calendarLabelScaleOf(context);
              final dateScale = AppFonts.calendarDateScaleOf(context);
              final allowRange =
                  widget.onRangeSelected != null && !widget.showLedger;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: allowRange ? _onLongPressStart : null,
                onLongPressMoveUpdate: allowRange ? _onLongPressMove : null,
                onLongPressEnd: allowRange ? _onLongPressEnd : null,
                onLongPressCancel: allowRange ? _clearRange : null,
                child: Stack(
                  key: _stackKey,
                  children: [
                    if (_searchRect != null)
                      AnimatedPositioned(
                        duration: _searchAnimate
                            ? const Duration(milliseconds: 340)
                            : Duration.zero,
                        curve: Curves.easeInOutCubic,
                        left: _searchRect!.left,
                        top: _searchRect!.top,
                        width: _searchRect!.width,
                        height: _searchRect!.height,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.of(context).rangeFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ListView.builder(
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
                      emojisOf: widget.emojisOf,
                      minHeight: minWeekHeight,
                      calendarScale: calendarScale,
                      labelScale: labelScale,
                      dateScale: dateScale,
                      showLunar: _showLunar,
                    );
                    final diaryHeight = CalendarWeekDiaries.heightFor(
                      days: weekDays,
                      diariesOf: widget.diariesOf ?? (_) => const [],
                      minHeight: minWeekHeight,
                      calendarScale: calendarScale,
                      labelScale: labelScale,
                      dateScale: dateScale,
                      showLunar: _showLunar,
                      cellWidth: cellWidth,
                    );
                    final ledgerHeight = CalendarWeekEvents.heightFor(
                      days: weekDays,
                      eventsOf: _ledgerEventsOn,
                      emojisOf: widget.emojisOf,
                      minHeight: minWeekHeight,
                      calendarScale: calendarScale,
                      labelScale: labelScale,
                      dateScale: dateScale,
                      showLunar: _showLunar,
                    );
                    return AnimatedBuilder(
                      animation: Listenable.merge([_ease, _altEase]),
                      builder: (context, child) {
                        final t = _ease.value;
                        final altHeight = diaryHeight +
                            (ledgerHeight - diaryHeight) * _altEase.value;
                        return AnimatedContainer(
                          key: _weekKey(week),
                          duration: _mode.isAnimating || _alt.isAnimating
                              ? Duration.zero
                              : CalendarDayCell.lunarAnim,
                          curve: Curves.easeOutCubic,
                          height:
                              eventHeight + (altHeight - eventHeight) * t,
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
                                      child: _maybeTodayAnchor(
                                        weekDays[weekday],
                                        CalendarDayCell(
                                          day: weekDays[weekday],
                                          inRange: _inRange(weekDays[weekday].date),
                                          highlighted: _isDropTarget(
                                            weekDays[weekday].date,
                                            highlighted,
                                          ),
                                          showLunar: _showLunar,
                                          onPressed: widget.onDayPressed == null
                                              ? null
                                              : (origin) => widget.onDayPressed!(
                                                    weekDays[weekday].date,
                                                    origin,
                                                  ),
                                          onLongPressed:
                                              widget.onDayLongPressed == null
                                                  ? null
                                                  : () => widget.onDayLongPressed!(
                                                        weekDays[weekday].date,
                                                      ),
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
                                    emojisOf: widget.emojisOf,
                                    calendarScale: calendarScale,
                                    labelScale: labelScale,
                                    dateScale: dateScale,
                                    showLunar: _showLunar,
                                    searchHitKey: widget.searchHitKey,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.diariesOf != null ||
                              widget.ledgersOf != null)
                            Positioned.fill(
                              child: FadeTransition(
                                opacity: _diaryOpacity,
                                child: ScaleTransition(
                                  alignment: Alignment.topCenter,
                                  scale: _diaryScale,
                                  child: Stack(
                                    children: [
                                      if (widget.diariesOf != null)
                                        Positioned.fill(
                                          child: FadeTransition(
                                            opacity: _diaryAltOpacity,
                                            child: ScaleTransition(
                                              alignment: Alignment.topCenter,
                                              scale: _diaryAltScale,
                                              child: IgnorePointer(
                                                ignoring: _alt.value >= 0.5,
                                                child: CalendarWeekDiaries(
                                                  days: weekDays,
                                                  diariesOf: widget.diariesOf!,
                                                  calendarScale: calendarScale,
                                                  labelScale: labelScale,
                                                  dateScale: dateScale,
                                                  showLunar: _showLunar,
                                                  searchHitKey:
                                                      widget.searchHitKey,
                                                  cellWidth: cellWidth,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (widget.ledgersOf != null)
                                        Positioned.fill(
                                          child: FadeTransition(
                                            opacity: _ledgerAltOpacity,
                                            child: ScaleTransition(
                                              alignment: Alignment.topCenter,
                                              scale: _ledgerAltScale,
                                              child: IgnorePointer(
                                                ignoring: _alt.value < 0.5,
                                                child: CalendarWeekEvents(
                                                  days: weekDays,
                                                  eventsOf: _ledgerEventsOn,
                                                  emojisOf: widget.emojisOf,
                                                  calendarScale: calendarScale,
                                                  labelScale: labelScale,
                                                  dateScale: dateScale,
                                                  showLunar: _showLunar,
                                                  searchHitKey:
                                                      widget.searchHitKey,
                                                  showAccent: false,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
