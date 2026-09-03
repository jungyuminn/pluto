import 'package:flutter/material.dart';
import 'package:pluto/core/calendar/calendar_years.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

enum CalendarZoomLevel { days, months, years }

abstract final class CalendarZoom {
  static int decadeStart(int year) => (year ~/ 10) * 10;

  static String title(
    CalendarZoomLevel level,
    DateTime month, {
    bool hideCurrentYear = false,
  }) {
    return switch (level) {
      CalendarZoomLevel.days => daysTitle(
        month,
        hideCurrentYear: hideCurrentYear,
      ),
      CalendarZoomLevel.months => '${month.year}${AppStrings.yearSuffix}',
      CalendarZoomLevel.years => yearsTitle(month.year),
    };
  }

  static String daysTitle(DateTime month, {bool hideCurrentYear = false}) {
    final monthLabel = '${month.month}${AppStrings.monthSuffix}';
    if (hideCurrentYear && month.year == DateTime.now().year) {
      return monthLabel;
    }
    return '${month.year}${AppStrings.yearSuffix} $monthLabel';
  }

  static String yearsTitle(int year) {
    final start = decadeStart(year);
    return '$start${AppStrings.yearSuffix} - ${start + 9}${AppStrings.yearSuffix}';
  }

  static CalendarZoomLevel next(CalendarZoomLevel level) {
    return switch (level) {
      CalendarZoomLevel.days => CalendarZoomLevel.months,
      CalendarZoomLevel.months => CalendarZoomLevel.years,
      CalendarZoomLevel.years => CalendarZoomLevel.years,
    };
  }
}

class CalendarZoomCell {
  const CalendarZoomCell({
    required this.label,
    required this.selected,
    required this.current,
    required this.enabled,
    this.outside = false,
    this.wide = false,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final bool current;
  final bool enabled;
  final bool outside;
  final bool wide;
  final VoidCallback? onPressed;
}

class CalendarZoomTitle extends StatelessWidget {
  const CalendarZoomTitle({
    super.key,
    required this.text,
    this.onPressed,
    this.fontSize = 22,
  });

  final String text;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.97,
      pressedColor: Colors.transparent,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppFonts.of(context),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: colors.text,
        ),
      ),
    );
  }
}

class CalendarZoomTransition extends StatefulWidget {
  const CalendarZoomTransition({
    super.key,
    required this.level,
    required this.child,
  });

  final CalendarZoomLevel level;
  final Widget child;

  @override
  State<CalendarZoomTransition> createState() => _CalendarZoomTransitionState();
}

class _CalendarZoomTransitionState extends State<CalendarZoomTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Widget _incoming;
  Widget? _outgoing;

  @override
  void initState() {
    super.initState();
    _incoming = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _outgoing != null) {
        setState(() => _outgoing = null);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CalendarZoomTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _outgoing = _incoming;
      _incoming = widget.child;
      _controller.forward(from: 0);
      return;
    }
    _incoming = widget.child;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final outT = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
          final inT = Curves.easeOutCubic.transform(
            ((t - 0.28) / 0.72).clamp(0.0, 1.0),
          );
          final incomingScale = 0.97 + 0.03 * inT;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_outgoing != null)
                IgnorePointer(
                  child: Opacity(
                    opacity: 1 - outT,
                    child: _outgoing,
                  ),
                ),
              Opacity(
                opacity: inT,
                child: Transform.scale(
                  scale: incomingScale,
                  child: _incoming,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CalendarMonthZoomView extends StatefulWidget {
  const CalendarMonthZoomView({
    super.key,
    required this.focused,
    required this.accent,
    required this.onFocusedChanged,
    required this.onMonthPressed,
    this.isMonthEnabled,
  });

  final DateTime focused;
  final Color accent;
  final ValueChanged<DateTime> onFocusedChanged;
  final ValueChanged<DateTime> onMonthPressed;
  final bool Function(DateTime month)? isMonthEnabled;

  @override
  State<CalendarMonthZoomView> createState() => _CalendarMonthZoomViewState();
}

class _CalendarMonthZoomViewState extends State<CalendarMonthZoomView> {
  static const _min = CalendarYears.min;
  late final PageController _pages;

  int get _max => CalendarYears.max();
  int get _count => _max - _min + 1;

  int _pageOf(int year) => year.clamp(_min, _max) - _min;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _pageOf(widget.focused.year));
  }

  @override
  void didUpdateWidget(covariant CalendarMonthZoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final page = _pageOf(widget.focused.year);
    if (_pages.hasClients && _pages.page?.round() != page) {
      _pages.jumpToPage(page);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return PageView.builder(
      controller: _pages,
      itemCount: _count,
      onPageChanged: (page) {
        final year = _min + page;
        widget.onFocusedChanged(DateTime(year, widget.focused.month));
      },
      itemBuilder: (context, page) {
        final year = _min + page;
        return CalendarZoomGrid(
          accent: widget.accent,
          cells: [
            for (var month = 1; month <= 12; month++)
              CalendarZoomCell(
                label: '$month${AppStrings.monthSuffix}',
                selected:
                    year == widget.focused.year &&
                    month == widget.focused.month,
                current: year == now.year && month == now.month,
                enabled: widget.isMonthEnabled?.call(DateTime(year, month)) ??
                    true,
                onPressed: (widget.isMonthEnabled?.call(DateTime(year, month)) ??
                        true)
                    ? () => widget.onMonthPressed(DateTime(year, month))
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class CalendarYearZoomView extends StatefulWidget {
  const CalendarYearZoomView({
    super.key,
    required this.focused,
    required this.accent,
    required this.onFocusedChanged,
    required this.onYearPressed,
    this.isYearEnabled,
  });

  final DateTime focused;
  final Color accent;
  final ValueChanged<DateTime> onFocusedChanged;
  final ValueChanged<int> onYearPressed;
  final bool Function(int year)? isYearEnabled;

  @override
  State<CalendarYearZoomView> createState() => _CalendarYearZoomViewState();
}

class _CalendarYearZoomViewState extends State<CalendarYearZoomView> {
  late final PageController _pages;

  int get _minYear => CalendarYears.min;
  int get _maxYear => CalendarYears.max();
  int get _firstDecade => CalendarZoom.decadeStart(_minYear);
  int get _lastDecade => CalendarZoom.decadeStart(_maxYear);
  int get _count => ((_lastDecade - _firstDecade) ~/ 10) + 1;

  int _pageOf(int year) {
    final decade = CalendarZoom.decadeStart(year.clamp(_minYear, _maxYear));
    return ((decade - _firstDecade) ~/ 10).clamp(0, _count - 1);
  }

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _pageOf(widget.focused.year));
  }

  @override
  void didUpdateWidget(covariant CalendarYearZoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final page = _pageOf(widget.focused.year);
    if (_pages.hasClients && _pages.page?.round() != page) {
      _pages.jumpToPage(page);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pages,
      itemCount: _count,
      onPageChanged: (page) {
        final decade = _firstDecade + page * 10;
        final offset =
            widget.focused.year - CalendarZoom.decadeStart(widget.focused.year);
        final year = (decade + offset).clamp(_minYear, _maxYear);
        widget.onFocusedChanged(DateTime(year, widget.focused.month));
      },
      itemBuilder: (context, page) {
        final decade = _firstDecade + page * 10;
        final nowYear = DateTime.now().year;
        return CalendarZoomGrid(
          accent: widget.accent,
          cells: [
            for (final year in List<int>.generate(
              12,
              (index) => decade + index,
            ))
              CalendarZoomCell(
                label: '$year${AppStrings.yearSuffix}',
                selected: year == widget.focused.year,
                current: year == nowYear,
                enabled: year >= _minYear &&
                    year <= _maxYear &&
                    (widget.isYearEnabled?.call(year) ?? true),
                outside: year >= decade + 10,
                wide: true,
                onPressed: year >= _minYear &&
                        year <= _maxYear &&
                        (widget.isYearEnabled?.call(year) ?? true)
                    ? () => widget.onYearPressed(year)
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class CalendarZoomGrid extends StatelessWidget {
  const CalendarZoomGrid({
    super.key,
    required this.cells,
    required this.accent,
  });

  final List<CalendarZoomCell> cells;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++)
                    Expanded(
                      child: _ZoomCell(
                        cell: cells[row * 3 + col],
                        accent: accent,
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

class _ZoomCell extends StatelessWidget {
  const _ZoomCell({required this.cell, required this.accent});

  final CalendarZoomCell cell;
  final Color accent;

  static const _size = 42.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Color fill;
    final Color foreground;
    if (!cell.enabled) {
      fill = Colors.transparent;
      foreground = colors.outside;
    } else if (cell.selected) {
      fill = accent;
      foreground = Colors.white;
    } else if (cell.current) {
      fill = colors.isDark ? colors.pressed : const Color(0xFFD7DDE6);
      foreground = colors.text;
    } else if (cell.outside) {
      fill = Colors.transparent;
      foreground = colors.muted;
    } else {
      fill = Colors.transparent;
      foreground = colors.text;
    }

    return PressBounce(
      onPressed: cell.onPressed,
      color: Colors.transparent,
      pressedColor: Colors.transparent,
      pressedScale: 0.94,
      child: SizedBox.expand(
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: cell.wide ? 68 : _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              cell.label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
