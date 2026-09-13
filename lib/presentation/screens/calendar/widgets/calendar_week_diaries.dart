import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto/core/calendar/month_grid.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/utils/local_file.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_day_cell.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:pluto/presentation/widgets/local_file_image.dart';

class CalendarWeekDiaries extends StatefulWidget {
  const CalendarWeekDiaries({
    super.key,
    required this.days,
    required this.diariesOf,
    this.calendarScale = 1,
    this.labelScale = 1,
    this.dateScale = 1,
    this.showLunar = false,
    this.searchHitKey,
    this.cellWidth = 0,
  });

  final List<CalendarDay> days;
  final List<DiaryEntry> Function(DateTime date) diariesOf;
  final double calendarScale;
  final double labelScale;
  final double dateScale;
  final bool showLunar;
  final String? searchHitKey;
  final double cellWidth;

  static const photoHeight = 42.0;
  static const maxPhotoSpan = 4;
  static const fadeDuration = Duration(milliseconds: 240);
  static const _phoneCellWidth = 52.0;

  static double photoHeightFor(double scale, {double cellWidth = 0}) {
    final base = photoHeight * scale;
    if (!PcLayout.isPc || cellWidth <= 0) return base;
    return (base * (cellWidth / _phoneCellWidth)).clamp(base, 160.0 * scale);
  }

  static bool showsPhoto(DiaryEntry diary) {
    return localFileExists(diary.photoPath);
  }

  static double heightFor({
    required List<CalendarDay> days,
    required List<DiaryEntry> Function(DateTime date) diariesOf,
    required double minHeight,
    double calendarScale = 1,
    double labelScale = 1,
    double dateScale = 1,
    bool showLunar = false,
    double cellWidth = 0,
  }) {
    final tiles = _tilesFor(
      days: days,
      diariesOf: diariesOf,
      calendarScale: calendarScale,
      labelScale: labelScale,
      dateScale: dateScale,
      showLunar: showLunar,
      cellWidth: cellWidth,
    );
    var content = 0.0;
    for (final day in days) {
      final top = CalendarDayCell.eventsTopFor(
        hasHoliday: day.isHoliday,
        scale: calendarScale,
        dateScale: dateScale,
        showLunar: showLunar,
      );
      if (top > content) content = top;
    }
    for (final tile in tiles) {
      final bottom = tile.top + tile.height + 6;
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
    _tiles = _tilesFor(
      days: widget.days,
      diariesOf: widget.diariesOf,
      calendarScale: widget.calendarScale,
      labelScale: widget.labelScale,
      dateScale: widget.dateScale,
      showLunar: widget.showLunar,
      cellWidth: widget.cellWidth,
    );
  }

  @override
  void didUpdateWidget(CalendarWeekDiaries oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _tilesFor(
      days: widget.days,
      diariesOf: widget.diariesOf,
      calendarScale: widget.calendarScale,
      labelScale: widget.labelScale,
      dateScale: widget.dateScale,
      showLunar: widget.showLunar,
      cellWidth: widget.cellWidth,
    );
    final sameWeek = widget.days.first.date == oldWidget.days.first.date &&
        widget.days.last.date == oldWidget.days.last.date &&
        widget.calendarScale == oldWidget.calendarScale &&
        widget.labelScale == oldWidget.labelScale &&
        widget.dateScale == oldWidget.dateScale;
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

  @override
  Widget build(BuildContext context) {
    if (_tiles.isEmpty && _exiting.isEmpty) return const SizedBox.expand();
    final photoH = CalendarWeekDiaries.photoHeightFor(
      widget.calendarScale,
      cellWidth: widget.cellWidth,
    );
    final labelH = CalendarDayCell.labelHeightFor(widget.labelScale);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          return Stack(
            children: [
              for (final tile in _tiles)
                _positioned(
                  tile: tile,
                  cellWidth: cellWidth,
                  child: _FadingDiary(
                    key: ValueKey(tile.id),
                    tile: tile,
                    cellWidth: cellWidth,
                    photoH: photoH,
                    labelH: labelH,
                    visible: true,
                    appear: _appearing.contains(tile.id),
                    searching: widget.searchHitKey != null,
                    matched: widget.searchHitKey != null &&
                        (tile.diary.groupId ?? tile.diary.id) ==
                            widget.searchHitKey,
                  ),
                ),
              for (final tile in _exiting)
                _positioned(
                  tile: tile,
                  cellWidth: cellWidth,
                  child: _FadingDiary(
                    key: ValueKey('out-${tile.id}'),
                    tile: tile,
                    cellWidth: cellWidth,
                    photoH: photoH,
                    labelH: labelH,
                    visible: false,
                    searching: widget.searchHitKey != null,
                    matched: widget.searchHitKey != null &&
                        (tile.diary.groupId ?? tile.diary.id) ==
                            widget.searchHitKey,
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
    required Widget child,
  }) {
    return AnimatedPositioned(
      duration: CalendarDayCell.lunarAnim,
      curve: Curves.easeOutCubic,
      left: cellWidth * tile.start + CalendarDayCell.sideInset,
      width: cellWidth * tile.span - CalendarDayCell.sideInset * 2,
      top: tile.top,
      height: tile.height,
      child: child,
    );
  }
}

List<_DiaryTile> _tilesFor({
  required List<CalendarDay> days,
  required List<DiaryEntry> Function(DateTime date) diariesOf,
  required double calendarScale,
  required double labelScale,
  required bool showLunar,
  double dateScale = 1,
  double cellWidth = 0,
}) {
  bool sameGroup(DiaryEntry diary, DiaryEntry other) {
    if (diary.groupId != null) return diary.groupId == other.groupId;
    return diary.id == other.id;
  }

  bool hasGroupOn(DateTime date, DiaryEntry diary) {
    return diariesOf(date).any((item) => sameGroup(diary, item));
  }

  DateTime groupStartOf(DiaryEntry diary) {
    var day = diary.day;
    if (diary.groupId == null) return day;
    for (var i = 0; i < 400; i++) {
      final prev = day.subtract(const Duration(days: 1));
      if (!hasGroupOn(prev, diary)) break;
      day = prev;
    }
    return day;
  }

  DateTime groupEndOf(DiaryEntry diary) {
    var day = diary.day;
    if (diary.groupId == null) return day;
    for (var i = 0; i < 400; i++) {
      final next = day.add(const Duration(days: 1));
      if (!hasGroupOn(next, diary)) break;
      day = next;
    }
    return day;
  }

  ({int start, int end})? photoWeekdays({
    required DateTime groupStart,
    required DateTime groupEnd,
    required DiaryEntry diary,
  }) {
    if (!CalendarWeekDiaries.showsPhoto(diary)) return null;
    final groupLength = groupEnd.difference(groupStart).inDays + 1;
    final photoSpan = math.min(groupLength, CalendarWeekDiaries.maxPhotoSpan);
    final offset = ((groupLength - photoSpan) / 2).floor();
    final photoStart = groupStart.add(Duration(days: offset));
    final photoEnd = photoStart.add(Duration(days: photoSpan - 1));
    int? start;
    int? end;
    for (var weekday = 0; weekday < days.length; weekday++) {
      final day = days[weekday].date;
      if (day.isBefore(photoStart) || day.isAfter(photoEnd)) continue;
      start ??= weekday;
      end = weekday;
    }
    if (start == null || end == null) return null;
    return (start: start, end: end);
  }

  final claimed = <String>{};
  final raw = <_RawDiary>[];
  for (var weekday = 0; weekday < days.length; weekday++) {
    for (final diary in diariesOf(days[weekday].date)) {
      final key = diary.groupId ?? diary.id;
      if (claimed.contains('$weekday|$key')) continue;
      var end = weekday;
      if (diary.groupId != null) {
        for (var next = weekday + 1; next < days.length; next++) {
          if (!hasGroupOn(days[next].date, diary)) break;
          end = next;
        }
      }
      for (var i = weekday; i <= end; i++) {
        claimed.add('$i|$key');
      }
      final previous = days[weekday].date.subtract(const Duration(days: 1));
      final groupStart = groupStartOf(diary);
      final groupEnd = groupEndOf(diary);
      raw.add(
        _RawDiary(
          start: weekday,
          end: end,
          diary: diary,
          showAccent: !hasGroupOn(previous, diary),
          inMonth: days.sublist(weekday, end + 1).any((day) => day.inMonth),
          groupStart: groupStart,
          photo: photoWeekdays(
            groupStart: groupStart,
            groupEnd: groupEnd,
            diary: diary,
          ),
        ),
      );
    }
  }

  raw.sort((a, b) {
    final byStart = a.groupStart.compareTo(b.groupStart);
    if (byStart != 0) return byStart;
    return a.start.compareTo(b.start);
  });

  final origin = [
    for (final day in days)
      CalendarDayCell.eventsTopFor(
        hasHoliday: day.isHoliday,
        scale: calendarScale,
        dateScale: dateScale,
        showLunar: showLunar,
      ),
  ];
  var shifted = true;
  while (shifted) {
    shifted = false;
    for (final item in raw) {
      if (item.diary.groupId == null) continue;
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

  double originOf(_RawDiary item) {
    var top = origin[item.start];
    for (var day = item.start; day <= item.end; day++) {
      if (origin[day] > top) top = origin[day];
    }
    return top;
  }

  final labelH = CalendarDayCell.labelHeightFor(labelScale);
  final photoH = CalendarWeekDiaries.photoHeightFor(
    calendarScale,
    cellWidth: cellWidth,
  );
  final occupied = List.generate(7, (_) => <_OccupiedRange>[]);
  final tiles = <_DiaryTile>[];

  for (final item in raw) {
    final hasPhoto = item.photo != null;
    final height =
        labelH + (hasPhoto ? CalendarDayCell.labelGap + photoH : 0);
    var top = originOf(item);
    while (true) {
      final bottom = top + height;
      final taken = [
        for (var day = item.start; day <= item.end; day++)
          occupied[day].any((range) => range.overlaps(top, bottom)),
      ].any((value) => value);
      if (!taken) {
        for (var day = item.start; day <= item.end; day++) {
          occupied[day].add(_OccupiedRange(top, bottom));
        }
        tiles.add(
          _DiaryTile(
            start: item.start,
            end: item.end,
            diary: item.diary,
            showAccent: item.showAccent,
            inMonth: item.inMonth,
            top: top,
            height: height,
            photoStart: item.photo?.start,
            photoEnd: item.photo?.end,
          ),
        );
        break;
      }
      var next = top + CalendarDayCell.labelGap;
      for (var day = item.start; day <= item.end; day++) {
        for (final range in occupied[day]) {
          if (!range.overlaps(top, bottom)) continue;
          if (range.bottom + CalendarDayCell.labelGap > next) {
            next = range.bottom + CalendarDayCell.labelGap;
          }
        }
      }
      if (next <= top) next = top + CalendarDayCell.labelGap;
      top = next;
    }
  }
  return tiles;
}

class _RawDiary {
  const _RawDiary({
    required this.start,
    required this.end,
    required this.diary,
    required this.showAccent,
    required this.inMonth,
    required this.groupStart,
    required this.photo,
  });

  final int start;
  final int end;
  final DiaryEntry diary;
  final bool showAccent;
  final bool inMonth;
  final DateTime groupStart;
  final ({int start, int end})? photo;
}

class _OccupiedRange {
  const _OccupiedRange(this.top, this.bottom);

  final double top;
  final double bottom;

  bool overlaps(double otherTop, double otherBottom) {
    return otherTop < bottom && top < otherBottom;
  }
}

class _DiaryTile {
  const _DiaryTile({
    required this.start,
    required this.end,
    required this.diary,
    required this.showAccent,
    required this.inMonth,
    required this.top,
    required this.height,
    required this.photoStart,
    required this.photoEnd,
  });

  final int start;
  final int end;
  final DiaryEntry diary;
  final bool showAccent;
  final bool inMonth;
  final double top;
  final double height;
  final int? photoStart;
  final int? photoEnd;

  String get id => '${diary.groupId ?? diary.id}:$start';

  int get span => end - start + 1;

  bool get showPhoto => photoStart != null && photoEnd != null;
}

class _FadingDiary extends StatefulWidget {
  const _FadingDiary({
    super.key,
    required this.tile,
    required this.cellWidth,
    required this.photoH,
    required this.labelH,
    required this.visible,
    this.appear = false,
    this.searching = false,
    this.matched = false,
  });

  final _DiaryTile tile;
  final double cellWidth;
  final double photoH;
  final double labelH;
  final bool visible;
  final bool appear;
  final bool searching;
  final bool matched;

  @override
  State<_FadingDiary> createState() => _FadingDiaryState();
}

class _FadingDiaryState extends State<_FadingDiary> {
  late var _opacity =
      widget.visible && !widget.appear ? 1.0 : widget.visible ? 0.0 : 1.0;

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
  void didUpdateWidget(_FadingDiary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextOpacity = widget.visible ? 1.0 : 0.0;
    if (_opacity == nextOpacity) return;
    _opacity = nextOpacity;
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final diary = tile.diary;
    final title = diary.title.trim().isEmpty
        ? AppStrings.diaryFallback
        : diary.title;
    final faded = _opacity *
        (tile.inMonth ? 1 : 0.45) *
        (widget.searching && !widget.matched ? 0.28 : 1);
    final label = CalendarEventLabel(
      title: title,
      color: diary.color,
      showAccent: tile.showAccent,
    );
    final photoStart = tile.photoStart;
    final photoEnd = tile.photoEnd;

    return AnimatedOpacity(
      duration: CalendarWeekDiaries.fadeDuration,
      curve: widget.visible ? Curves.easeOutCubic : Curves.easeInCubic,
      opacity: faded,
      child: photoStart == null || photoEnd == null
            ? label
            : Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: widget.labelH,
                    child: label,
                  ),
                  Positioned(
                    left: (photoStart - tile.start) * widget.cellWidth,
                    width: math.max(
                      0,
                      (photoEnd - photoStart + 1) * widget.cellWidth -
                          CalendarDayCell.sideInset * 2,
                    ),
                    top: widget.labelH + CalendarDayCell.labelGap,
                    height: widget.photoH,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LocalFileImage(
                        diary.photoPath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.expand();
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
