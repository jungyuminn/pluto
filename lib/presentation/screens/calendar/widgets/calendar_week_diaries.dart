import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';

class CalendarWeekDiaries extends StatefulWidget {
  const CalendarWeekDiaries({
    super.key,
    required this.days,
    required this.diaryOf,
    this.calendarScale = 1,
    this.labelScale = 1,
  });

  final List<CalendarDay> days;
  final DiaryEntry? Function(DateTime date) diaryOf;
  final double calendarScale;
  final double labelScale;

  static const photoHeight = 42.0;
  static const fadeDuration = Duration(milliseconds: 240);

  static double photoHeightFor(double scale) => photoHeight * scale;

  static bool showsPhoto(DiaryEntry diary) {
    final path = diary.photoPath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  static double heightFor({
    required List<CalendarDay> days,
    required DiaryEntry? Function(DateTime date) diaryOf,
    required double minHeight,
    double calendarScale = 1,
    double labelScale = 1,
  }) {
    var content = 0.0;
    final photoH = photoHeightFor(calendarScale);
    final labelH = CalendarDayCell.labelHeightFor(labelScale);
    for (final day in days) {
      final top = CalendarDayCell.eventsTopFor(
        hasHoliday: day.isHoliday,
        scale: calendarScale,
      );
      final diary = diaryOf(day.date);
      if (diary == null) {
        if (top > content) content = top;
        continue;
      }
      final extra = showsPhoto(diary) ? photoH : labelH;
      final bottom = top + extra + 6;
      if (bottom > content) content = bottom;
    }
    return math.max(minHeight, content);
  }

  @override
  State<CalendarWeekDiaries> createState() => _CalendarWeekDiariesState();
}

class _CalendarWeekDiariesState extends State<CalendarWeekDiaries> {
  var _tiles = <_DiaryTile>[];
  var _exiting = <_DiaryTile>[];
  var _appearing = <String>{};
  var _exitGen = 0;

  @override
  void initState() {
    super.initState();
    _tiles = _tilesFor(widget);
  }

  @override
  void didUpdateWidget(CalendarWeekDiaries oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _tilesFor(widget);
    final sameWeek = widget.days.first.date == oldWidget.days.first.date &&
        widget.days.last.date == oldWidget.days.last.date &&
        widget.calendarScale == oldWidget.calendarScale &&
        widget.labelScale == oldWidget.labelScale;
    if (!sameWeek) {
      _exitGen++;
      setState(() {
        _tiles = next;
        _exiting = [];
        _appearing = {};
      });
      return;
    }

    final nextIds = {for (final tile in next) tile.id};
    final currentIds = {for (final tile in _tiles) tile.id};
    final leaving = [
      for (final tile in _tiles)
        if (!nextIds.contains(tile.id)) tile,
    ];
    final appearing = {
      for (final tile in next)
        if (!currentIds.contains(tile.id)) tile.id,
    };

    _exitGen++;
    final gen = _exitGen;
    setState(() {
      _exiting = leaving;
      _appearing = appearing;
      _tiles = next;
    });
    if (leaving.isEmpty) return;
    Future<void>.delayed(CalendarWeekDiaries.fadeDuration, () {
      if (!mounted || gen != _exitGen) return;
      setState(() => _exiting = []);
    });
  }

  static List<_DiaryTile> _tilesFor(CalendarWeekDiaries widget) {
    return [
      for (var weekday = 0; weekday < widget.days.length; weekday++)
        if (widget.diaryOf(widget.days[weekday].date) != null)
          _DiaryTile(
            day: widget.days[weekday],
            weekday: weekday,
            diary: widget.diaryOf(widget.days[weekday].date)!,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_tiles.isEmpty && _exiting.isEmpty) return const SizedBox.expand();
    final photoH = CalendarWeekDiaries.photoHeightFor(widget.calendarScale);
    final labelH = CalendarDayCell.labelHeightFor(widget.labelScale);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          return Stack(
            children: [
              for (final tile in _exiting)
                _positioned(
                  tile: tile,
                  cellWidth: cellWidth,
                  photoH: photoH,
                  labelH: labelH,
                  child: _FadingDiary(
                    key: ValueKey('out-${tile.id}'),
                    tile: tile,
                    visible: false,
                  ),
                ),
              for (final tile in _tiles)
                _positioned(
                  tile: tile,
                  cellWidth: cellWidth,
                  photoH: photoH,
                  labelH: labelH,
                  child: _FadingDiary(
                    key: ValueKey(tile.id),
                    tile: tile,
                    visible: true,
                    appear: _appearing.contains(tile.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _positioned({
    required _DiaryTile tile,
    required double cellWidth,
    required double photoH,
    required double labelH,
    required Widget child,
  }) {
    final photo = CalendarWeekDiaries.showsPhoto(tile.diary);
    final top = CalendarDayCell.eventsTopFor(
      hasHoliday: tile.day.isHoliday,
      scale: widget.calendarScale,
    );
    return Positioned(
      left: cellWidth * tile.weekday + CalendarDayCell.sideInset,
      width: cellWidth - CalendarDayCell.sideInset * 2,
      top: top,
      height: photo ? photoH : labelH,
      child: child,
    );
  }
}

class _DiaryTile {
  const _DiaryTile({
    required this.day,
    required this.weekday,
    required this.diary,
  });

  final CalendarDay day;
  final int weekday;
  final DiaryEntry diary;

  String get id => diary.id;
}

class _FadingDiary extends StatefulWidget {
  const _FadingDiary({
    super.key,
    required this.tile,
    required this.visible,
    this.appear = false,
  });

  final _DiaryTile tile;
  final bool visible;
  final bool appear;

  @override
  State<_FadingDiary> createState() => _FadingDiaryState();
}

class _FadingDiaryState extends State<_FadingDiary> {
  late var _opacity =
      widget.visible && !widget.appear ? 1.0 : widget.visible ? 0.0 : 1.0;
  late var _scale =
      widget.visible && !widget.appear ? 1.0 : widget.visible ? 0.88 : 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.appear || !widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _opacity = widget.visible ? 1 : 0;
          _scale = widget.visible ? 1 : 0.88;
        });
      });
    }
  }

  @override
  void didUpdateWidget(_FadingDiary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextOpacity = widget.visible ? 1.0 : 0.0;
    final nextScale = widget.visible ? 1.0 : 0.88;
    if (_opacity == nextOpacity && _scale == nextScale) return;
    _opacity = nextOpacity;
    _scale = nextScale;
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final diary = tile.diary;
    final photo = CalendarWeekDiaries.showsPhoto(diary);
    final title = diary.title.trim().isEmpty
        ? AppStrings.diaryFallback
        : diary.title;
    final faded = _opacity * (tile.day.inMonth ? 1 : 0.45);

    return AnimatedScale(
      duration: CalendarWeekDiaries.fadeDuration,
      curve: widget.visible ? Curves.easeOutCubic : Curves.easeInCubic,
      scale: _scale,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: CalendarWeekDiaries.fadeDuration,
        curve: widget.visible ? Curves.easeOutCubic : Curves.easeInCubic,
        opacity: faded,
        child: photo
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(diary.photoPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CalendarEventLabel(
                      title: title,
                      color: diary.color,
                    );
                  },
                ),
              )
            : CalendarEventLabel(
                title: title,
                color: diary.color,
              ),
      ),
    );
  }
}
