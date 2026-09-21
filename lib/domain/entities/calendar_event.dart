import 'package:flutter/material.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.memo = '',
    this.categoryId,
    this.categoryName = defaultCategoryName,
    this.categoryColor = defaultCategoryColor,
    this.completed = false,
    this.groupId,
    this.repeatId,
    this.isJob = false,
    this.jobApplicationId,
    this.sortOrder = 0,
    this.startMinutes,
    this.endMinutes,
    this.someday = false,
    this.sharedId,
    this.sharedMine = false,
    this.sharedPeer = false,
  });

  static const defaultCategoryColor = 0xFF3B82F6;
  static const defaultCategoryName = '기본';

  final String id;
  final String title;
  final DateTime date;
  final String memo;
  final String? categoryId;
  final String categoryName;
  final int categoryColor;
  final bool completed;
  final String? groupId;
  final String? repeatId;
  final bool isJob;
  final String? jobApplicationId;
  final int sortOrder;
  final int? startMinutes;
  final int? endMinutes;
  final bool someday;
  final String? sharedId;
  final bool sharedMine;
  final bool sharedPeer;

  bool get isShared => (sharedId ?? '').trim().isNotEmpty;

  bool get isSharedWaiting => isShared && sharedMine && !completed;

  Color get color => Color(categoryColor);

  DateTime get day => DateTime(date.year, date.month, date.day);

  bool get isRange => groupId != null;

  bool get isRepeat => repeatId != null;

  bool get isLockedOrder => isJob || isRange;

  bool get isBeforeToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isBefore(today);
  }

  bool get hasTime => startMinutes != null;

  String? get timeLabel => labelTime();

  String? labelTime({bool hour24 = true}) {
    final start = startMinutes;
    if (start == null) return null;
    final startText = formatClock(start, hour24: hour24);
    final end = endMinutes;
    if (end == null) return startText;
    return '$startText–${formatClock(end, hour24: hour24)}';
  }

  static String formatMinutes(int minutes) =>
      formatClock(minutes, hour24: true);

  static String formatClock(int minutes, {bool hour24 = true}) {
    final hour = (minutes ~/ 60).clamp(0, 23);
    final minute = (minutes % 60).clamp(0, 59);
    if (hour24) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    final period = hour < 12 ? '오전' : '오후';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $hour12:${minute.toString().padLeft(2, '0')}';
  }

  static List<CalendarEvent> withRangesFirst(
    Iterable<CalendarEvent> events, {
    Iterable<CalendarEvent>? all,
  }) {
    final rangeStart = <String, DateTime>{};
    for (final event in all ?? events) {
      final groupId = event.groupId;
      if (groupId == null) continue;
      final day = event.day;
      final current = rangeStart[groupId];
      if (current == null || day.isBefore(current)) {
        rangeStart[groupId] = day;
      }
    }

    final ranges = <CalendarEvent>[];
    final regulars = <CalendarEvent>[];
    final originalIndex = <String, int>{};
    var index = 0;
    for (final event in events) {
      originalIndex[event.id] = index++;
      if (event.isRange) {
        ranges.add(event);
      } else {
        regulars.add(event);
      }
    }
    ranges.sort((a, b) {
      final aStart = rangeStart[a.groupId] ?? a.day;
      final bStart = rangeStart[b.groupId] ?? b.day;
      final byStart = aStart.compareTo(bStart);
      if (byStart != 0) return byStart;
      return a.id.compareTo(b.id);
    });
    regulars.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return (originalIndex[a.id] ?? 0).compareTo(originalIndex[b.id] ?? 0);
    });
    return [...ranges, ...regulars];
  }

  static List<CalendarEvent> withLockedThenStartTime(
    Iterable<CalendarEvent> events,
  ) {
    final jobs = <CalendarEvent>[];
    final ranges = <CalendarEvent>[];
    final todos = <CalendarEvent>[];
    for (final event in events) {
      if (event.isJob) {
        jobs.add(event);
      } else if (event.isRange) {
        ranges.add(event);
      } else {
        todos.add(event);
      }
    }
    todos.sort(_compareStartTime);
    return [...ranges, ...jobs, ...todos];
  }

  static int _compareStartTime(CalendarEvent a, CalendarEvent b) {
    final aStart = a.startMinutes;
    final bStart = b.startMinutes;
    if (aStart == null && bStart == null) {
      return a.sortOrder.compareTo(b.sortOrder);
    }
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    final byStart = aStart.compareTo(bStart);
    if (byStart != 0) return byStart;
    final byEnd = (a.endMinutes ?? aStart).compareTo(b.endMinutes ?? bStart);
    if (byEnd != 0) return byEnd;
    return a.sortOrder.compareTo(b.sortOrder);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? memo,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    bool? completed,
    String? groupId,
    String? repeatId,
    bool? isJob,
    String? jobApplicationId,
    int? sortOrder,
    int? startMinutes,
    int? endMinutes,
    bool? someday,
    String? sharedId,
    bool? sharedMine,
    bool? sharedPeer,
    bool clearTime = false,
    bool clearEnd = false,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      completed: completed ?? this.completed,
      groupId: groupId ?? this.groupId,
      repeatId: repeatId ?? this.repeatId,
      isJob: isJob ?? this.isJob,
      jobApplicationId: jobApplicationId ?? this.jobApplicationId,
      sortOrder: sortOrder ?? this.sortOrder,
      startMinutes: clearTime ? null : startMinutes ?? this.startMinutes,
      endMinutes: clearTime || clearEnd
          ? null
          : endMinutes ?? this.endMinutes,
      someday: someday ?? this.someday,
      sharedId: sharedId ?? this.sharedId,
      sharedMine: sharedMine ?? this.sharedMine,
      sharedPeer: sharedPeer ?? this.sharedPeer,
    );
  }
}
