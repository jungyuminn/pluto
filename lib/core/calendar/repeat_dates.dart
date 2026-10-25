enum RepeatKind {
  daily,
  weekly,
  monthly,
  yearly,
  everyNDays,
  everyNWeeks,
  everyNMonths;

  bool get usesWeekdays =>
      this == RepeatKind.weekly || this == RepeatKind.everyNWeeks;

  bool get usesInterval =>
      this == RepeatKind.everyNDays ||
      this == RepeatKind.everyNWeeks ||
      this == RepeatKind.everyNMonths;

  bool get usesMonthRule =>
      this == RepeatKind.monthly || this == RepeatKind.everyNMonths;
}

enum RepeatMonthRule { date, weekday }

enum RepeatMonthWeek { first, second, third, fourth, last }

class RepeatDates {
  RepeatDates._();

  static const horizonYear = 2030;
  static const minInterval = 1;
  static const maxInterval = 30;

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
    int interval = minInterval,
  }) {
    final origin = today(now);
    final limit = horizon(now);
    final floor = dateOnly(start);
    final options = <DateTime>[];

    switch (kind) {
      case RepeatKind.daily:
        var current = origin.add(const Duration(days: 7));
        while (!current.isAfter(limit)) {
          if (!current.isBefore(floor)) options.add(current);
          current = current.add(const Duration(days: 7));
        }
      case RepeatKind.everyNDays:
        final step = _intervalOf(interval);
        final gap = step * ((7 + step - 1) ~/ step);
        var current = floor.add(Duration(days: gap));
        while (!current.isAfter(limit)) {
          options.add(current);
          current = current.add(Duration(days: gap));
        }
      case RepeatKind.weekly:
      case RepeatKind.everyNWeeks:
        final step = kind == RepeatKind.everyNWeeks ? 7 * _intervalOf(interval) : 7;
        var current = origin.add(Duration(days: step));
        while (!current.isAfter(limit)) {
          if (!current.isBefore(floor)) options.add(current);
          current = current.add(Duration(days: step));
        }
      case RepeatKind.monthly:
      case RepeatKind.everyNMonths:
        final step = kind == RepeatKind.everyNMonths ? _intervalOf(interval) : 1;
        var month = step;
        while (true) {
          final current = _monthDay(
            origin: floor,
            monthOffset: month,
            monthRule: monthRule,
            monthWeek: monthWeek,
            monthWeekday: monthWeekday,
          );
          if (current.isAfter(limit)) break;
          if (!current.isBefore(floor)) options.add(current);
          month += step;
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
    int interval = minInterval,
    DateTime? now,
  }) {
    final first = dateOnly(start);
    final limit = horizon(now);
    final last = end == null
        ? limit
        : (dateOnly(end).isAfter(limit) ? limit : dateOnly(end));
    if (first.isAfter(last)) return [];

    switch (kind) {
      case RepeatKind.daily:
        return _stepDays(first, last, 1);
      case RepeatKind.everyNDays:
        return _stepDays(first, last, _intervalOf(interval));
      case RepeatKind.weekly:
      case RepeatKind.everyNWeeks:
        final selected = weekdays.isEmpty ? {weekdayIndex(first)} : weekdays;
        final weekStep = kind == RepeatKind.everyNWeeks ? _intervalOf(interval) : 1;
        final days = <DateTime>[];
        var current = first;
        while (!current.isAfter(last)) {
          if (selected.contains(weekdayIndex(current)) &&
              _weekIndex(current, first) % weekStep == 0) {
            days.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
        return days;
      case RepeatKind.monthly:
      case RepeatKind.everyNMonths:
        final step = kind == RepeatKind.everyNMonths ? _intervalOf(interval) : 1;
        final days = <DateTime>[];
        var month = 0;
        while (true) {
          final current = _monthDay(
            origin: first,
            monthOffset: month,
            monthRule: monthRule,
            monthWeek: monthWeek,
            monthWeekday: monthWeekday,
          );
          if (current.isAfter(last)) break;
          if (!current.isBefore(first)) days.add(current);
          month += step;
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

  static DateTime _monthDay({
    required DateTime origin,
    required int monthOffset,
    required RepeatMonthRule monthRule,
    required RepeatMonthWeek monthWeek,
    required int monthWeekday,
  }) {
    return monthRule == RepeatMonthRule.weekday
        ? weekdayInMonth(
            year: origin.year,
            month: origin.month + monthOffset,
            weekdayIndex: monthWeekday,
            week: monthWeek,
          )
        : clampDay(origin.year, origin.month + monthOffset, origin.day);
  }

  static int _intervalOf(int interval) =>
      interval.clamp(minInterval, maxInterval);

  static int _weekIndex(DateTime date, DateTime origin) {
    final originWeek = dateOnly(origin).subtract(
      Duration(days: weekdayIndex(origin)),
    );
    final dateWeek = dateOnly(date).subtract(
      Duration(days: weekdayIndex(date)),
    );
    return dateWeek.difference(originWeek).inDays ~/ 7;
  }

  static List<DateTime> _stepDays(DateTime first, DateTime last, int step) {
    final days = <DateTime>[];
    var current = first;
    while (!current.isAfter(last)) {
      days.add(current);
      current = current.add(Duration(days: step));
    }
    return days;
  }
}
