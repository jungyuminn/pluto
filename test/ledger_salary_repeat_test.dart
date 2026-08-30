import 'package:flutter_test/flutter_test.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';
import 'package:job_planner/domain/ledger_salary_repeat.dart';

LedgerEntry _salary({
  required DateTime date,
  SalaryPayCycle cycle = SalaryPayCycle.weekly,
  SalaryMonthRule monthRule = SalaryMonthRule.date,
  SalaryMonthWeek monthWeek = SalaryMonthWeek.first,
  int weekday = DateTime.friday,
  int monthDay = 25,
}) {
  return LedgerEntry(
    id: '1',
    date: date,
    title: '알바',
    amount: 100000,
    kind: LedgerKind.hourly,
    salary: LedgerSalaryDetails(
      cycle: cycle,
      monthRule: monthRule,
      monthWeek: monthWeek,
      weekday: weekday,
      monthDay: monthDay,
    ),
  );
}

void main() {
  test('당일은 고른 날에만 나온다', () {
    final entry = _salary(
      date: DateTime(2026, 8, 30),
      cycle: SalaryPayCycle.sameDay,
    );
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 30)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 9, 6)), isFalse);
  });

  test('일주일은 고른 날부터 52주 같은 요일에 나온다', () {
    final start = DateTime(2026, 8, 30);
    final entry = _salary(date: start);
    expect(LedgerSalaryRepeat.occursOn(entry, start), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 9, 6)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 9, 7)), isFalse);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 23)), isFalse);
    expect(
      LedgerSalaryRepeat.occursOn(
        entry,
        start.add(const Duration(days: 51 * 7)),
      ),
      isTrue,
    );
    expect(
      LedgerSalaryRepeat.occursOn(
        entry,
        start.add(const Duration(days: 52 * 7)),
      ),
      isFalse,
    );
  });

  test('한 달은 고른 날부터 12개월, 말일은 그달 마지막 날로 맞춘다', () {
    final entry = _salary(
      date: DateTime(2026, 1, 31),
      cycle: SalaryPayCycle.monthly,
      monthDay: 0,
    );
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 1, 31)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 2, 28)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 3, 31)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 12, 31)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2027, 1, 31)), isFalse);
  });

  test('한 달 요일은 매월 n번째·마지막 요일에 나온다', () {
    final entry = _salary(
      date: DateTime(2026, 8, 14),
      cycle: SalaryPayCycle.monthly,
      monthRule: SalaryMonthRule.weekday,
      monthWeek: SalaryMonthWeek.second,
      weekday: DateTime.friday,
    );
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 14)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 9, 11)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 21)), isFalse);
    final lastFriday = _salary(
      date: DateTime(2026, 8, 28),
      cycle: SalaryPayCycle.monthly,
      monthRule: SalaryMonthRule.weekday,
      monthWeek: SalaryMonthWeek.last,
      weekday: DateTime.friday,
    );
    expect(
      LedgerSalaryRepeat.occursOn(lastFriday, DateTime(2026, 8, 28)),
      isTrue,
    );
    expect(
      LedgerSalaryRepeat.occursOn(lastFriday, DateTime(2026, 9, 25)),
      isTrue,
    );
  });

  test('검색은 이미 지난 반복이면 가장 가까운 받은 날로 간다', () {
    final entry = _salary(date: DateTime(2026, 8, 30));
    expect(
      LedgerSalaryRepeat.searchDay(entry, DateTime(2026, 9, 10)),
      DateTime(2026, 9, 6),
    );
  });

  test('월급은 고른 날에만 나온다', () {
    final entry = LedgerEntry(
      id: '2',
      date: DateTime(2026, 8, 30),
      title: '직장',
      amount: 2500000,
      kind: LedgerKind.salary,
    );
    expect(LedgerSalaryRepeat.isRepeating(entry), isFalse);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 30)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 9, 30)), isFalse);
  });

  test('월급 한 달은 고른 날부터 12개월 나온다', () {
    final entry = LedgerEntry(
      id: '3',
      date: DateTime(2026, 8, 25),
      title: '직장',
      amount: 2500000,
      kind: LedgerKind.salary,
      salary: const LedgerSalaryDetails(
        wageType: SalaryWageType.monthly,
        monthlyWage: 2500000,
        cycle: SalaryPayCycle.monthly,
        monthDay: 25,
      ),
    );
    expect(LedgerSalaryRepeat.isRepeating(entry), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 25)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 9, 25)), isTrue);
    expect(LedgerSalaryRepeat.occursOn(entry, DateTime(2026, 8, 26)), isFalse);
  });
}
