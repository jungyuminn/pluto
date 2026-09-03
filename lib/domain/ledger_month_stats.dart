import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/ledger_salary_repeat.dart';

class LedgerDayHighlight {
  const LedgerDayHighlight({
    required this.date,
    required this.amount,
  });

  final DateTime date;
  final int amount;
}

class LedgerMonthStats {
  const LedgerMonthStats({
    required this.consumption,
    required this.expense,
    required this.salary,
    required this.hasSalary,
    this.count = 0,
    this.topConsumptionDay,
    this.topIncomeDay,
  });

  static const empty = LedgerMonthStats(
    consumption: 0,
    expense: 0,
    salary: 0,
    hasSalary: false,
  );

  final int consumption;
  final int expense;
  final int salary;
  final bool hasSalary;
  final int count;
  final LedgerDayHighlight? topConsumptionDay;
  final LedgerDayHighlight? topIncomeDay;

  int get net => expense + salary - consumption;

  bool get isEmpty => count == 0;

  bool get hasHighlights =>
      topConsumptionDay != null || topIncomeDay != null;

  static LedgerMonthStats of({
    required DateTime month,
    required Iterable<LedgerEntry> entries,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return ofRange(start: start, end: end, entries: entries);
  }

  static LedgerMonthStats ofRange({
    required DateTime start,
    required DateTime end,
    required Iterable<LedgerEntry> entries,
  }) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    var consumption = 0;
    var expense = 0;
    var salary = 0;
    var hasSalary = false;
    var count = 0;
    final consumptionByDay = <DateTime, int>{};
    final incomeByDay = <DateTime, int>{};
    for (
      var day = startDay;
      !day.isAfter(endDay);
      day = day.add(const Duration(days: 1))
    ) {
      for (final entry in entries) {
        if (!LedgerSalaryRepeat.occursOn(entry, day)) continue;
        count++;
        switch (entry.kind) {
          case LedgerKind.consumption:
            consumption += entry.amount;
            consumptionByDay[day] =
                (consumptionByDay[day] ?? 0) + entry.amount;
          case LedgerKind.expense:
            expense += entry.amount;
            incomeByDay[day] = (incomeByDay[day] ?? 0) + entry.amount;
          case LedgerKind.hourly:
          case LedgerKind.salary:
            salary += entry.amount;
            hasSalary = true;
            incomeByDay[day] = (incomeByDay[day] ?? 0) + entry.amount;
        }
      }
    }
    return LedgerMonthStats(
      consumption: consumption,
      expense: expense,
      salary: salary,
      hasSalary: hasSalary,
      count: count,
      topConsumptionDay: _topDay(consumptionByDay),
      topIncomeDay: _topDay(incomeByDay),
    );
  }

  static LedgerDayHighlight? _topDay(Map<DateTime, int> totals) {
    DateTime? date;
    var amount = 0;
    for (final entry in totals.entries) {
      if (entry.value <= 0) continue;
      if (date == null ||
          entry.value > amount ||
          (entry.value == amount && entry.key.isBefore(date))) {
        date = entry.key;
        amount = entry.value;
      }
    }
    if (date == null) return null;
    return LedgerDayHighlight(date: date, amount: amount);
  }
}
