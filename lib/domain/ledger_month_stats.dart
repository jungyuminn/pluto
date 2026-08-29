import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/ledger_salary_repeat.dart';

class LedgerMonthStats {
  const LedgerMonthStats({
    required this.consumption,
    required this.expense,
    required this.salary,
    required this.hasSalary,
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

  int get net => expense + salary - consumption;

  static LedgerMonthStats of({
    required DateTime month,
    required Iterable<LedgerEntry> entries,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    var consumption = 0;
    var expense = 0;
    var salary = 0;
    var hasSalary = false;
    for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
      for (final entry in entries) {
        if (!LedgerSalaryRepeat.occursOn(entry, day)) continue;
        switch (entry.kind) {
          case LedgerKind.consumption:
            consumption += entry.amount;
          case LedgerKind.expense:
            expense += entry.amount;
          case LedgerKind.salary:
            salary += entry.amount;
            hasSalary = true;
        }
      }
    }
    return LedgerMonthStats(
      consumption: consumption,
      expense: expense,
      salary: salary,
      hasSalary: hasSalary,
    );
  }
}
