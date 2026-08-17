import 'package:job_planner/core/calendar/korean_holidays.dart';

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.inMonth,
    this.holidayName,
  });

  final DateTime date;
  final bool inMonth;
  final String? holidayName;

  bool get isSunday => date.weekday == DateTime.sunday;
  bool get isSaturday => date.weekday == DateTime.saturday;
  bool get isHoliday => holidayName != null;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class MonthGrid {
  MonthGrid._();

  static List<CalendarDay> daysFor(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = first.weekday % 7;
    final start = DateTime(first.year, first.month, first.day - startOffset);
    final last = DateTime(month.year, month.month + 1, 0);
    final endOffset = 6 - (last.weekday % 7);
    final count = last.day + startOffset + endOffset;

    return List<CalendarDay>.generate(count, (index) {
      final date = DateTime(start.year, start.month, start.day + index);
      return CalendarDay(
        date: date,
        inMonth: date.month == month.month,
        holidayName: KoreanHolidays.nameOn(date),
      );
    });
  }
}
