import 'package:flutter_test/flutter_test.dart';
import 'package:pluto/core/calendar/repeat_dates.dart';

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

  test('매일은 하루씩 반복한다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.daily,
      start: DateTime(2026, 8, 15),
      end: DateTime(2026, 8, 17),
      now: DateTime(2026, 8, 15),
    );
    expect(days, [
      DateTime(2026, 8, 15),
      DateTime(2026, 8, 16),
      DateTime(2026, 8, 17),
    ]);
  });

  test('n일마다는 시작일부터 n일 간격이다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.everyNDays,
      start: DateTime(2026, 8, 15),
      end: DateTime(2026, 8, 24),
      interval: 3,
      now: DateTime(2026, 8, 15),
    );
    expect(days, [
      DateTime(2026, 8, 15),
      DateTime(2026, 8, 18),
      DateTime(2026, 8, 21),
      DateTime(2026, 8, 24),
    ]);
  });

  test('n주마다는 시작 주부터 n주 간격의 요일만 남긴다', () {
    final monday = RepeatDates.weekdayIndex(DateTime(2026, 5, 4));
    final days = RepeatDates.occurrences(
      kind: RepeatKind.everyNWeeks,
      start: DateTime(2026, 5, 4),
      end: DateTime(2026, 6, 1),
      weekdays: {monday},
      interval: 2,
      now: DateTime(2026, 5, 4),
    );
    expect(days, [
      DateTime(2026, 5, 4),
      DateTime(2026, 5, 18),
      DateTime(2026, 6, 1),
    ]);
  });

  test('n주마다 시작일 이전 요일은 건너뛴다', () {
    final monday = RepeatDates.weekdayIndex(DateTime(2026, 5, 4));
    final wednesday = RepeatDates.weekdayIndex(DateTime(2026, 5, 6));
    final days = RepeatDates.occurrences(
      kind: RepeatKind.everyNWeeks,
      start: DateTime(2026, 5, 6),
      end: DateTime(2026, 5, 20),
      weekdays: {monday, wednesday},
      interval: 2,
      now: DateTime(2026, 5, 6),
    );
    expect(days, [
      DateTime(2026, 5, 6),
      DateTime(2026, 5, 18),
      DateTime(2026, 5, 20),
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

  test('n달마다는 시작일부터 n달 간격이다', () {
    final days = RepeatDates.occurrences(
      kind: RepeatKind.everyNMonths,
      start: DateTime(2026, 8, 15),
      end: DateTime(2027, 2, 15),
      interval: 2,
      now: DateTime(2026, 8, 15),
    );
    expect(days, [
      DateTime(2026, 8, 15),
      DateTime(2026, 10, 15),
      DateTime(2026, 12, 15),
      DateTime(2027, 2, 15),
    ]);
  });
}
