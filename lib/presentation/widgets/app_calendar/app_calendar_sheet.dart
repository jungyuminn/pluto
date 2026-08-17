import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/calendar/repeat_dates.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar_repeat_panel.dart';

enum AppCalendarMode { single, range, repeat, multiple }

class AppCalendarResult {
  const AppCalendarResult({
    required this.mode,
    required this.dates,
  });

  final AppCalendarMode mode;
  final List<DateTime> dates;

  DateTime get date => dates.first;
}

Future<AppCalendarResult?> showAppCalendarSheet(
  BuildContext context, {
  DateTime? date,
  List<DateTime>? dates,
  AppCalendarMode mode = AppCalendarMode.single,
  Color color = const Color(0xFF3B82F6),
  bool showModes = true,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<AppCalendarResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => AppCalendarSheet(
      initialDate: date,
      initialDates: dates,
      initialMode: mode,
      color: color,
      showModes: showModes,
    ),
  );
}

class AppCalendarSheet extends StatefulWidget {
  const AppCalendarSheet({
    super.key,
    this.initialDate,
    this.initialDates,
    this.initialMode = AppCalendarMode.single,
    this.color = const Color(0xFF3B82F6),
    this.showModes = true,
  });

  final DateTime? initialDate;
  final List<DateTime>? initialDates;
  final AppCalendarMode initialMode;
  final Color color;
  final bool showModes;

  @override
  State<AppCalendarSheet> createState() => _AppCalendarSheetState();
}

class _AppCalendarSheetState extends State<AppCalendarSheet> {
  static const _initialPage = 12000;
  static const _todayFill = Color(0xFFD7DDE6);
  static const _red = Color(0xFFEF4444);
  static const _pickerBodyHeight = 352.0;

  Color get _accent => widget.color;
  Color get _sheet => Color.lerp(const Color(0xFFFFFFFF), _accent, 0.28)!;

  late final DateTime _baseMonth;
  late final PageController _pages;
  late DateTime _visibleMonth;
  late AppCalendarMode _mode;
  late List<DateTime> _selected;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  var _repeatKind = RepeatKind.weekly;
  late DateTime _repeatStart;
  DateTime? _repeatEnd;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final seedDates = widget.initialDates;
    final seed = _dateOnly(
      widget.initialDate ??
          (seedDates != null && seedDates.isNotEmpty
              ? seedDates.first
              : DateTime.now()),
    );
    _baseMonth = DateTime(seed.year, seed.month);
    _visibleMonth = _baseMonth;
    _pages = PageController(initialPage: _initialPage);
    _mode = widget.showModes ? widget.initialMode : AppCalendarMode.single;
    final given = (widget.initialDates ?? const <DateTime>[])
        .map(_dateOnly)
        .toList();
    if (given.isEmpty) given.add(seed);
    given.sort((a, b) => a.compareTo(b));
    _selected = given;
    _repeatStart = seed;
    _weekdays = {RepeatDates.weekdayIndex(seed)};
    if (_mode == AppCalendarMode.range) {
      _rangeStart = given.first;
      _rangeEnd = given.length > 1 ? given.last : null;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _monthAt(int page) {
    return DateTime(_baseMonth.year, _baseMonth.month + (page - _initialPage));
  }

  DateTime get _primary {
    if (_mode == AppCalendarMode.range) {
      return _rangeStart ?? _selected.first;
    }
    return _selected.isEmpty ? _dateOnly(DateTime.now()) : _selected.first;
  }

  bool get _canConfirm {
    switch (_mode) {
      case AppCalendarMode.range:
        return _rangeStart != null && _rangeEnd != null;
      case AppCalendarMode.multiple:
        return _selected.isNotEmpty;
      case AppCalendarMode.repeat:
        return _repeatDates.isNotEmpty;
      case AppCalendarMode.single:
        return _selected.isNotEmpty;
    }
  }

  List<DateTime> get _repeatDates {
    return RepeatDates.occurrences(
      kind: _repeatKind,
      start: _repeatStart,
      end: _repeatEnd,
      weekdays: _weekdays,
    );
  }

  void _setMode(AppCalendarMode mode) {
    if (!widget.showModes) return;
    if (mode == _mode) return;
    setState(() {
      final keep = _mode == AppCalendarMode.repeat ? _repeatStart : _primary;
      _mode = mode;
      if (mode == AppCalendarMode.range) {
        _rangeStart = keep;
        _rangeEnd = null;
      } else if (mode == AppCalendarMode.repeat) {
        _rangeStart = null;
        _rangeEnd = null;
        _repeatStart = keep;
        _repeatEnd = null;
        _repeatKind = RepeatKind.weekly;
        _weekdays = {RepeatDates.weekdayIndex(keep)};
      } else {
        _rangeStart = null;
        _rangeEnd = null;
        _selected = [keep];
      }
    });
  }

  Future<void> _pickRepeatStart() async {
    final picked = await showAppCalendarSheet(
      context,
      date: _repeatStart,
      mode: AppCalendarMode.single,
      color: _accent,
      showModes: false,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _repeatStart = picked.date;
      _weekdays = {..._weekdays, RepeatDates.weekdayIndex(picked.date)};
      if (_repeatEnd != null && _repeatEnd!.isBefore(_repeatStart)) {
        _repeatEnd = null;
      }
    });
  }

  void _setRepeatKind(RepeatKind kind) {
    setState(() {
      _repeatKind = kind;
      final options = RepeatDates.endOptions(kind: kind, start: _repeatStart);
      if (_repeatEnd != null &&
          !options.any((date) => _isSameDay(date, _repeatEnd!))) {
        _repeatEnd = null;
      }
    });
  }

  void _toggleWeekday(int index) {
    setState(() {
      if (_weekdays.contains(index)) {
        if (_weekdays.length <= 1) return;
        _weekdays = {..._weekdays}..remove(index);
      } else {
        _weekdays = {..._weekdays, index};
      }
    });
  }

  void _onDayPressed(DateTime date) {
    final day = _dateOnly(date);
    setState(() {
      switch (_mode) {
        case AppCalendarMode.single:
          _selected = [day];
        case AppCalendarMode.repeat:
          break;
        case AppCalendarMode.range:
          if (_rangeStart == null || _rangeEnd != null) {
            _rangeStart = day;
            _rangeEnd = null;
          } else if (_isSameDay(day, _rangeStart!)) {
            _rangeEnd = day;
          } else if (day.isBefore(_rangeStart!)) {
            _rangeEnd = _rangeStart;
            _rangeStart = day;
          } else {
            _rangeEnd = day;
          }
        case AppCalendarMode.multiple:
          final exists = _selected.any((item) => _isSameDay(item, day));
          if (exists) {
            if (_selected.length <= 1) break;
            _selected = [
              for (final item in _selected)
                if (!_isSameDay(item, day)) item,
            ];
          } else {
            _selected = [..._selected, day]..sort((a, b) => a.compareTo(b));
          }
      }
    });
  }

  bool _isSelected(DateTime date) {
    switch (_mode) {
      case AppCalendarMode.range:
        if (_rangeStart != null && _isSameDay(date, _rangeStart!)) return true;
        if (_rangeEnd != null && _isSameDay(date, _rangeEnd!)) return true;
        return false;
      case AppCalendarMode.single:
        return _selected.any((item) => _isSameDay(item, date));
      case AppCalendarMode.repeat:
        return false;
      case AppCalendarMode.multiple:
        return _selected.any((item) => _isSameDay(item, date));
    }
  }

  bool _isInRange(DateTime date) {
    final start = _rangeStart;
    final end = _rangeEnd;
    if (_mode != AppCalendarMode.range || start == null || end == null) {
      return false;
    }
    return date.isAfter(start) && date.isBefore(end);
  }

  bool _isRangeStart(DateTime date) {
    return _mode == AppCalendarMode.range &&
        _rangeStart != null &&
        _isSameDay(date, _rangeStart!);
  }

  bool _isRangeEnd(DateTime date) {
    return _mode == AppCalendarMode.range &&
        _rangeEnd != null &&
        _isSameDay(date, _rangeEnd!);
  }

  void _confirm() {
    if (!_canConfirm) return;
    final dates = switch (_mode) {
      AppCalendarMode.range => [_rangeStart!, _rangeEnd!],
      AppCalendarMode.repeat => _repeatDates,
      AppCalendarMode.single || AppCalendarMode.multiple =>
        List<DateTime>.from(_selected)..sort((a, b) => a.compareTo(b)),
    };
    Navigator.of(context).pop(
      AppCalendarResult(mode: _mode, dates: dates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 4 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 10),
              _HeaderBar(
                accent: _accent,
                canConfirm: _canConfirm,
                onCancel: () => Navigator.of(context).pop(),
                onConfirm: _confirm,
              ),
              const SizedBox(height: 14),
              if (widget.showModes) ...[
                _ModeTabs(mode: _mode, onChanged: _setMode),
                const SizedBox(height: 18),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: _pickerBodyHeight,
                  width: double.infinity,
                  child: _mode == AppCalendarMode.repeat
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppCalendarRepeatPanel(
                              kind: _repeatKind,
                              weekdays: _weekdays,
                              start: _repeatStart,
                              end: _repeatEnd,
                              onKindChanged: _setRepeatKind,
                              onWeekdayPressed: _toggleWeekday,
                              onStartPressed: _pickRepeatStart,
                              onEndChanged: (value) {
                                setState(() => _repeatEnd = value);
                              },
                            ),
                            const Spacer(),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${_visibleMonth.year}${AppStrings.yearSuffix} ${_visibleMonth.month}${AppStrings.monthSuffix}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.pretendard,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _WeekdayRow(),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 288,
                            child: PageView.builder(
                              controller: _pages,
                              onPageChanged: (page) {
                                setState(() => _visibleMonth = _monthAt(page));
                              },
                              itemBuilder: (context, page) {
                                return _MonthGridView(
                                  month: _monthAt(page),
                                  accent: _accent,
                                  isSelected: _isSelected,
                                  isInRange: _isInRange,
                                  isRangeStart: _isRangeStart,
                                  isRangeEnd: _isRangeEnd,
                                  onDayPressed: _onDayPressed,
                                );
                              },
                            ),
                          ),
                        ],
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFC5CDD8),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.accent,
    required this.canConfirm,
    required this.onCancel,
    required this.onConfirm,
  });

  final Color accent;
  final bool canConfirm;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          onPressed: onCancel,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    _AppCalendarSheetState._red,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(AppIcons.calendar, width: 22, height: 22),
                ),
                const Positioned(
                  right: -3,
                  bottom: -3,
                  child: Icon(
                    Icons.close,
                    size: 13,
                    color: _AppCalendarSheetState._red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Opacity(
          opacity: canConfirm ? 1 : 0.35,
          child: SaveCompanyButton(
            onPressed: canConfirm ? onConfirm : () {},
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: Colors.white,
        pressedColor: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final AppCalendarMode mode;
  final ValueChanged<AppCalendarMode> onChanged;

  static const _items = [
    (AppCalendarMode.single, AppStrings.calendarModeSingle),
    (AppCalendarMode.range, AppStrings.calendarModeRange),
    (AppCalendarMode.repeat, AppStrings.calendarModeRepeat),
    (AppCalendarMode.multiple, AppStrings.calendarModeMultiple),
  ];

  static const _pillHeight = 34.0;
  static const _duration = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    final index = _items.indexWhere((item) => item.$1 == mode).clamp(0, 3);

    return SizedBox(
      height: 38,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / _items.length;
          final pillWidth = cellWidth - 6;
          final left = cellWidth * index + (cellWidth - pillWidth) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: _duration,
                curve: Curves.easeOutCubic,
                left: left,
                top: (constraints.maxHeight - _pillHeight) / 2,
                width: pillWidth,
                height: _pillHeight,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: PressBounce(
                        onPressed: () => onChanged(_items[i].$1),
                        pressedScale: 0.96,
                        pressedColor: Colors.transparent,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: _duration,
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: i == index
                                  ? const Color(0xFF5A6B80)
                                  : const Color(0xFF8B95A3),
                            ),
                            child: Text(_items[i].$2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in AppStrings.weekdays)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGridView extends StatelessWidget {
  const _MonthGridView({
    required this.month,
    required this.accent,
    required this.isSelected,
    required this.isInRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.onDayPressed,
  });

  final DateTime month;
  final Color accent;
  final bool Function(DateTime date) isSelected;
  final bool Function(DateTime date) isInRange;
  final bool Function(DateTime date) isRangeStart;
  final bool Function(DateTime date) isRangeEnd;
  final ValueChanged<DateTime> onDayPressed;

  @override
  Widget build(BuildContext context) {
    final days = [...MonthGrid.daysFor(month)];
    while (days.length < 42) {
      final last = days.last.date;
      days.add(
        CalendarDay(
          date: DateTime(last.year, last.month, last.day + 1),
          inMonth: false,
        ),
      );
    }

    return Column(
      children: [
        for (var week = 0; week < 6; week++)
          Expanded(
            child: Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: _DayCell(
                      day: days[week * 7 + weekday],
                      weekday: weekday,
                      accent: accent,
                      selected: isSelected(days[week * 7 + weekday].date),
                      inRange: isInRange(days[week * 7 + weekday].date),
                      rangeStart: isRangeStart(days[week * 7 + weekday].date),
                      rangeEnd: isRangeEnd(days[week * 7 + weekday].date),
                      onPressed: onDayPressed,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.weekday,
    required this.accent,
    required this.selected,
    required this.inRange,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onPressed,
  });

  final CalendarDay day;
  final int weekday;
  final Color accent;
  final bool selected;
  final bool inRange;
  final bool rangeStart;
  final bool rangeEnd;
  final ValueChanged<DateTime> onPressed;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    if (!day.inMonth) return const SizedBox.expand();

    final spanStart = rangeStart && rangeEnd;
    final showBar = (inRange || rangeStart || rangeEnd) && !spanStart;
    final circleSelected = selected;
    final Color circleColor;
    final Color foreground;
    if (circleSelected) {
      circleColor = accent;
      foreground = Colors.white;
    } else if (inRange) {
      circleColor = Colors.transparent;
      foreground = accent;
    } else if (day.isToday) {
      circleColor = _AppCalendarSheetState._todayFill;
      foreground = const Color(0xFF0F172A);
    } else {
      circleColor = Colors.transparent;
      foreground = const Color(0xFF0F172A);
    }

    final barFill = accent.withValues(alpha: 0.22);
    final AlignmentGeometry barAlignment;
    final double barWidthFactor;
    if (rangeStart && !rangeEnd) {
      barAlignment = Alignment.centerRight;
      barWidthFactor = 0.5;
    } else if (rangeEnd && !rangeStart) {
      barAlignment = Alignment.centerLeft;
      barWidthFactor = 0.5;
    } else {
      barAlignment = Alignment.center;
      barWidthFactor = 1;
    }

    final leftCap = inRange && weekday == 0;
    final rightCap = inRange && weekday == 6;

    return PressBounce(
      onPressed: () => onPressed(day.date),
      color: Colors.transparent,
      pressedColor: Colors.transparent,
      pressedScale: showBar ? 1 : 0.94,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showBar)
              Align(
                alignment: barAlignment,
                child: FractionallySizedBox(
                  widthFactor: barWidthFactor,
                  child: Container(
                    height: _size,
                    decoration: BoxDecoration(
                      color: barFill,
                      borderRadius: BorderRadius.horizontal(
                        left: leftCap
                            ? const Radius.circular(_size / 2)
                            : Radius.zero,
                        right: rightCap
                            ? const Radius.circular(_size / 2)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
