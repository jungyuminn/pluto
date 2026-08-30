import 'package:flutter_test/flutter_test.dart';
import 'package:job_planner/core/calendar/repeat_dates.dart';

void main() {
  test('매월은 같은 날짜로 반복한다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.monthly,
      start: DateTime(2026, 8, 15),
      end: DateTime(2026, 11, 15),
      now: DateTime(2026, 8, 15),
    );
    expect(days, [
      DateTime(2026, 8, 15),
      DateTime(2026, 9, 15),
      DateTime(2026, 10, 15),
      DateTime(2026, 11, 15),
    ]);
  });

  test('매월 둘째 금요일은 n째 주 요일로 반복한다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.monthly,
      start: DateTime(2026, 8, 14),
      end: DateTime(2026, 10, 31),
      monthRule: RepeatMonthRule.weekday,
      monthWeek: RepeatMonthWeek.second,
      monthWeekday: RepeatDates.weekdayIndex(DateTime(2026, 8, 14)),
      now: DateTime(2026, 8, 14),
    );
    expect(days, [
      DateTime(2026, 8, 14),
      DateTime(2026, 9, 11),
      DateTime(2026, 10, 9),
    ]);
  });

  test('매월 마지막 금요일은 그달의 마지막 그 요일이다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.monthly,
      start: DateTime(2026, 8, 28),
      end: DateTime(2026, 9, 30),
      monthRule: RepeatMonthRule.weekday,
      monthWeek: RepeatMonthWeek.last,
      monthWeekday: RepeatDates.weekdayIndex(DateTime(2026, 8, 28)),
      now: DateTime(2026, 8, 28),
    );
    expect(days, [
      DateTime(2026, 8, 28),
      DateTime(2026, 9, 25),
    ]);
  });

  test('시작일 이전의 n째 요일은 건너뛴다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.monthly,
      start: DateTime(2026, 8, 20),
      end: DateTime(2026, 9, 30),
      monthRule: RepeatMonthRule.weekday,
      monthWeek: RepeatMonthWeek.second,
      monthWeekday: RepeatDates.weekdayIndex(DateTime(2026, 8, 14)),
      now: DateTime(2026, 8, 20),
    );
    expect(days, [DateTime(2026, 9, 11)]);
  });

  test('매월 종료 날짜는 시작일의 날짜를 따른다', () {
    final options = RepeatDates.endOptions(
      kind: RepeatKind.monthly,
      start: DateTime(2026, 8, 23),
      now: DateTime(2026, 8, 31),
    );
    expect(options.take(3), [
      DateTime(2026, 9, 23),
      DateTime(2026, 10, 23),
      DateTime(2026, 11, 23),
    ]);
  });

  test('매월 요일 종료 날짜는 n째 요일을 따른다', () {
    final friday = RepeatDates.weekdayIndex(DateTime(2026, 8, 14));
    final options = RepeatDates.endOptions(
      kind: RepeatKind.monthly,
      start: DateTime(2026, 8, 14),
      now: DateTime(2026, 8, 31),
      monthRule: RepeatMonthRule.weekday,
      monthWeek: RepeatMonthWeek.second,
      monthWeekday: friday,
    );
    expect(options.take(2), [
      DateTime(2026, 9, 11),
      DateTime(2026, 10, 9),
    ]);
  });
}
