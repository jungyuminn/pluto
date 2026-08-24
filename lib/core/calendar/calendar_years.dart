abstract final class CalendarYears {
  static const min = 2010;
  static const extra = 5;

  static int max([DateTime? now]) => (now ?? DateTime.now()).year + extra;

  static DateTime start() => DateTime(min, 1, 1);

  static DateTime end([DateTime? now]) {
    final year = max(now);
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }
}
