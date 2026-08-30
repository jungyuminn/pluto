enum RepeatKind { weekly, monthly, yearly }

enum RepeatMonthRule { date, weekday }

enum RepeatMonthWeek { first, second, third, fourth, last }

class RepeatDates {
  RepeatDates._();

  static const horizonYear = 2030;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime today([DateTime? now]) {
    final value = now ?? DateTime.now();
    return dateOnly(value);
  }

  static DateTime horizon([DateTime? now]) {
    final value = today(now);
    return clampDay(horizonYear, value.month, value.day);
  }

  static DateTime clampDay(int year, int month, int day) {
    final first = DateTime(year, month);
    final last = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, day > last ? last : day);
  }

  static int weekdayIndex(DateTime date) => date.weekday % 7;

  static DateTime weekdayInMonth({
    required int year,
    required int month,
    required int weekdayIndex,
    required RepeatMonthWeek week,
  }) {
    final weekday = weekdayIndex == 0 ? DateTime.sunday : weekdayIndex;
    if (week == RepeatMonthWeek.last) {
      final last = DateTime(year, month + 1, 0);
      var delta = last.weekday - weekday;
      if (delta < 0) delta += 7;
      return last.subtract(Duration(days: delta));
    }
    final first = DateTime(year, month, 1);
    var delta = weekday - first.weekday;
    if (delta < 0) delta += 7;
    return DateTime(year, month, 1 + delta + week.index * 7);
  }

  static RepeatMonthWeek weekOf(DateTime date) {
    final last = weekdayInMonth(
      year: date.year,
      month: date.month,
      weekdayIndex: weekdayIndex(date),
      week: RepeatMonthWeek.last,
    );
    if (date.year == last.year &&
        date.month == last.month &&
        date.day == last.day) {
      return RepeatMonthWeek.last;
    }
    return RepeatMonthWeek.values[((date.day - 1) ~/ 7).clamp(0, 3)];
  }

  static String format(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  static List<DateTime> endOptions({
    required RepeatKind kind,
    required DateTime start,
    DateTime? now,
    RepeatMonthRule monthRule = RepeatMonthRule.date,
    RepeatMonthWeek monthWeek = RepeatMonthWeek.first,
    int monthWeekday = 0,
  }) {
    final origin = today(now);
    final limit = horizon(now);
    final floor = dateOnly(start);
    final options = <DateTime>[];

    switch (kind) {
      case RepeatKind.weekly:
        var current = origin.add(const Duration(days: 7));
        while (!current.isAfter(limit)) {
          if (!current.isBefore(floor)) options.add(current);
          current = current.add(const Duration(days: 7));
        }
      case RepeatKind.monthly:
        var month = 1;
        while (true) {
          final current = monthRule == RepeatMonthRule.weekday
              ? weekdayInMonth(
                  year: floor.year,
                  month: floor.month + month,
                  weekdayIndex: monthWeekday,
                  week: monthWeek,
                )
              : clampDay(floor.year, floor.month + month, floor.day);
          if (current.isAfter(limit)) break;
          if (!current.isBefore(floor)) options.add(current);
          month++;
        }
      case RepeatKind.yearly:
        for (var year = floor.year + 1; year <= horizonYear; year++) {
          final current = clampDay(year, floor.month, floor.day);
          if (current.isAfter(limit)) break;
          if (!current.isBefore(floor)) options.add(current);
        }
    }
    return options;
  }

  static List<DateTime> occurrences({
    required RepeatKind kind,
    required DateTime start,
    DateTime? end,
    Set<int> weekdays = const {},
    RepeatMonthRule monthRule = RepeatMonthRule.date,
    RepeatMonthWeek monthWeek = RepeatMonthWeek.first,
    int monthWeekday = 0,
    DateTime? now,
  }) {
    final first = dateOnly(start);
    final limit = horizon(now);
    final last = end == null
        ? limit
        : (dateOnly(end).isAfter(limit) ? limit : dateOnly(end));
    if (first.isAfter(last)) return [];

    switch (kind) {
      case RepeatKind.weekly:
        final selected = weekdays.isEmpty ? {weekdayIndex(first)} : weekdays;
        final days = <DateTime>[];
        var current = first;
        while (!current.isAfter(last)) {
          if (selected.contains(weekdayIndex(current))) days.add(current);
          current = current.add(const Duration(days: 1));
        }
        return days;
      case RepeatKind.monthly:
        final days = <DateTime>[];
        var month = 0;
        while (true) {
          final current = monthRule == RepeatMonthRule.weekday
              ? weekdayInMonth(
                  year: first.year,
                  month: first.month + month,
                  weekdayIndex: monthWeekday,
                  week: monthWeek,
                )
              : clampDay(first.year, first.month + month, first.day);
          if (current.isAfter(last)) break;
          if (!current.isBefore(first)) days.add(current);
          month++;
        }
        return days;
      case RepeatKind.yearly:
        final days = <DateTime>[];
        var year = 0;
        while (true) {
          final current = clampDay(first.year + year, first.month, first.day);
          if (current.isAfter(last)) break;
          if (!current.isBefore(first)) days.add(current);
          year++;
        }
        return days;
    }
  }
}
