class ApplicationRound {
  const ApplicationRound({
    this.name = '',
    this.date,
    this.endDate,
    this.note = '',
    this.completed = false,
  });

  final String name;
  final DateTime? date;
  final DateTime? endDate;
  final String note;
  final bool completed;

  bool get isEmpty => name.isEmpty && date == null && note.isEmpty;

  DateTime? get startDay => _day(date);

  DateTime? get lastDay {
    final start = startDay;
    if (start == null) return null;
    final end = _day(endDate);
    if (end == null || end.isBefore(start)) return start;
    return end;
  }

  bool get isRange {
    final start = startDay;
    final last = lastDay;
    return start != null && last != null && last.isAfter(start);
  }

  bool containsDay(DateTime day) {
    final start = startDay;
    final last = lastDay;
    if (start == null || last == null) return false;
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(start) && !target.isAfter(last);
  }

  bool overlaps(DateTime start, DateTime end) {
    final first = startDay;
    final last = lastDay;
    if (first == null || last == null) return false;
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    return !last.isBefore(from) && !first.isAfter(to);
  }

  Iterable<DateTime> get days sync* {
    final start = startDay;
    final last = lastDay;
    if (start == null || last == null) return;
    var current = start;
    while (!current.isAfter(last)) {
      yield current;
      current = current.add(const Duration(days: 1));
    }
  }

  bool isPast([DateTime? now]) {
    final last = lastDay;
    if (last == null) return false;
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    return last.isBefore(today);
  }

  /// 오늘이 기간 안이면 0, 시작이 앞이면 남은 일수, 지났으면 null.
  int? daysUntil([DateTime? now]) {
    final start = startDay;
    final last = lastDay;
    if (start == null || last == null) return null;
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    if (last.isBefore(today)) return null;
    if (!start.isAfter(today)) return 0;
    return start.difference(today).inDays;
  }

  String? get dateText {
    final start = startDay;
    if (start == null) return null;
    final last = lastDay;
    if (last == null || !last.isAfter(start)) {
      return '${start.year}년 ${start.month}월 ${start.day}일';
    }
    if (start.year == last.year && start.month == last.month) {
      return '${start.year}년 ${start.month}월 ${start.day}–${last.day}일';
    }
    if (start.year == last.year) {
      return '${start.year}년 ${start.month}월 ${start.day}일–${last.month}월 ${last.day}일';
    }
    return '${start.year}년 ${start.month}월 ${start.day}일–${last.year}년 ${last.month}월 ${last.day}일';
  }

  String get chipDateLabel {
    final start = startDay;
    if (start == null) return '';
    if (!isRange) return '${start.month}. ${start.day}.';
    final last = lastDay!;
    if (start.month == last.month) {
      return '${start.month}. ${start.day}.–${last.day}.';
    }
    return '${start.month}. ${start.day}.–${last.month}. ${last.day}.';
  }

  String? get summary {
    final dateLabel = dateText;
    if (name.isEmpty && dateLabel == null) return null;
    if (name.isNotEmpty && dateLabel != null) return '$name - $dateLabel';
    if (name.isNotEmpty) return name;
    return dateLabel;
  }

  ApplicationRound copyWith({
    String? name,
    DateTime? date,
    DateTime? endDate,
    String? note,
    bool? completed,
    bool clearDate = false,
    bool clearEndDate = false,
  }) {
    final nextDate = clearDate ? null : (date ?? this.date);
    var nextEnd = clearDate || clearEndDate ? null : (endDate ?? this.endDate);
    if (nextDate == null) {
      nextEnd = null;
    } else if (nextEnd != null) {
      final start = DateTime(nextDate.year, nextDate.month, nextDate.day);
      final last = DateTime(nextEnd.year, nextEnd.month, nextEnd.day);
      if (!last.isAfter(start)) nextEnd = null;
    }
    return ApplicationRound(
      name: name ?? this.name,
      date: nextDate,
      endDate: nextEnd,
      note: note ?? this.note,
      completed: completed ?? this.completed,
    );
  }

  static DateTime? _day(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }
}
