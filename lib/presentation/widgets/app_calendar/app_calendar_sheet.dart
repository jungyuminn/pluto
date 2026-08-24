import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/calendar/repeat_dates.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar_repeat_panel.dart';
import 'package:job_planner/presentation/widgets/app_calendar/calendar_zoom_picker.dart';

enum AppCalendarMode { single, range, repeat, multiple }

class AppCalendarResult {
  const AppCalendarResult({required this.mode, required this.dates});

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
  static const _pickerBodyHeight = 352.0;

  Color get _accent => widget.color;
  Color _sheetOf(BuildContext context) => AppColors.of(context).tint(_accent);

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
  var _zoom = CalendarZoomLevel.days;

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
    _mode = widget.initialMode;
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
      _zoom = CalendarZoomLevel.days;
    });
  }

  void _onTitlePressed() {
    if (_zoom == CalendarZoomLevel.years) return;
    setState(() => _zoom = CalendarZoom.next(_zoom));
  }

  void _showMonth(DateTime month) {
    setState(() => _zoom = CalendarZoomLevel.days);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      final target = DateTime(month.year, month.month);
      final delta =
          (target.year - _baseMonth.year) * 12 +
          (target.month - _baseMonth.month);
      _pages.jumpToPage(_initialPage + delta);
      setState(() => _visibleMonth = target);
    });
  }

  void _showYearMonths(int year) {
    setState(() {
      _visibleMonth = DateTime(year, _visibleMonth.month);
      _zoom = CalendarZoomLevel.months;
    });
  }

  Widget _zoomTitle(BuildContext context) {
    final canZoom = _zoom != CalendarZoomLevel.years;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: CalendarZoomTitle(
          text: CalendarZoom.title(_zoom, _visibleMonth),
          onPressed: canZoom ? _onTitlePressed : null,
        ),
      ),
    );
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
      AppCalendarMode.single || AppCalendarMode.multiple => List<DateTime>.from(
        _selected,
      )..sort((a, b) => a.compareTo(b)),
    };
    Navigator.of(context).pop(AppCalendarResult(mode: _mode, dates: dates));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _sheetOf(context),
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
                              startMonday: AppScope.of(
                                context,
                              ).calendarPreference.startMonday,
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
                            _zoomTitle(context),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 314,
                              child: CalendarZoomTransition(
                                level: _zoom,
                                child: switch (_zoom) {
                                  CalendarZoomLevel.days => Column(
                                    children: [
                                      _WeekdayRow(
                                        startMonday: AppScope.of(
                                          context,
                                        ).calendarPreference.startMonday,
                                      ),
                                      const SizedBox(height: 6),
                                      Expanded(
                                        child: PageView.builder(
                                          controller: _pages,
                                          onPageChanged: (page) {
                                            setState(
                                              () => _visibleMonth = _monthAt(
                                                page,
                                              ),
                                            );
                                          },
                                          itemBuilder: (context, page) {
                                            return _MonthGridView(
                                              month: _monthAt(page),
                                              accent: _accent,
                                              startMonday: AppScope.of(
                                                context,
                                              ).calendarPreference.startMonday,
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
                                  CalendarZoomLevel.months =>
                                    CalendarMonthZoomView(
                                      focused: _visibleMonth,
                                      accent: _accent,
                                      onFocusedChanged: (month) {
                                        setState(() => _visibleMonth = month);
                                      },
                                      onMonthPressed: _showMonth,
                                    ),
                                  CalendarZoomLevel.years =>
                                    CalendarYearZoomView(
                                      focused: _visibleMonth,
                                      accent: _accent,
                                      onFocusedChanged: (month) {
                                        setState(() => _visibleMonth = month);
                                      },
                                      onYearPressed: _showYearMonths,
                                    ),
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
          color: AppColors.of(context).muted,
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
    final danger = AppColors.of(context).danger;
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
                  colorFilter: ColorFilter.mode(danger, BlendMode.srcIn),
                  child: Image.asset(AppIcons.calendar, width: 22, height: 22),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Icon(Icons.close, size: 13, color: danger),
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
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.of(context).card,
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
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
                              fontFamily: AppFonts.of(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: i == index
                                  ? AppColors.of(context).secondary
                                  : AppColors.of(context).muted,
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
  const _WeekdayRow({this.startMonday = false});

  final bool startMonday;

  @override
  Widget build(BuildContext context) {
    final labels = AppStrings.weekdayLabels(startMonday: startMonday);
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).text,
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
    required this.startMonday,
    required this.isSelected,
    required this.isInRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.onDayPressed,
  });

  final DateTime month;
  final Color accent;
  final bool startMonday;
  final bool Function(DateTime date) isSelected;
  final bool Function(DateTime date) isInRange;
  final bool Function(DateTime date) isRangeStart;
  final bool Function(DateTime date) isRangeEnd;
  final ValueChanged<DateTime> onDayPressed;

  @override
  Widget build(BuildContext context) {
    final days = [...MonthGrid.daysFor(month, startMonday: startMonday)];
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

    final colors = AppColors.of(context);
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
      circleColor = colors.isDark ? colors.pressed : const Color(0xFFD7DDE6);
      foreground = colors.text;
    } else {
      circleColor = Colors.transparent;
      foreground = colors.text;
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

    return SizedBox.expand(
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
          PressBounce(
            onPressed: () => onPressed(day.date),
            color: Colors.transparent,
            pressedColor: Colors.transparent,
            pressedScale: 0.94,
            expand: true,
            alignment: Alignment.center,
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
                  fontFamily: AppFonts.of(context),
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
    );
  }
}
