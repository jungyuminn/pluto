import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';

class LedgerSalaryRepeat {
  LedgerSalaryRepeat._();

  static const weeklyCount = 52;
  static const monthlyCount = 12;

  static bool isRepeating(LedgerEntry entry) {
    if (!_hasPayCycle(entry)) return false;
    final cycle = entry.salary?.cycle.selectableCycle;
    return cycle == SalaryPayCycle.weekly || cycle == SalaryPayCycle.monthly;
  }

  static bool occursOn(LedgerEntry entry, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = entry.day;
    if (!_hasPayCycle(entry)) {
      return day == start;
    }
    if (day.isBefore(start)) return false;
    final cycle = entry.salary!.cycle.selectableCycle;
    switch (cycle) {
      case SalaryPayCycle.sameDay:
        return day == start;
      case SalaryPayCycle.weekly:
      case SalaryPayCycle.biweekly:
        if (day.weekday != start.weekday) return false;
        final weeks = day.difference(start).inDays ~/ 7;
        return day.difference(start).inDays % 7 == 0 && weeks < weeklyCount;
      case SalaryPayCycle.monthly:
      case SalaryPayCycle.twiceMonthly:
        final months = (day.year - start.year) * 12 + (day.month - start.month);
        if (months < 0 || months >= monthlyCount) return false;
        return _occurrence(entry.salary!, start, months) == day;
    }
  }

  static LedgerEntry onDay(LedgerEntry entry, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (entry.day == day) return entry;
    return entry.copyWith(date: day);
  }

  static DateTime searchDay(LedgerEntry entry, [DateTime? now]) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (!isRepeating(entry) || day.isBefore(entry.day)) return entry.day;
    final start = entry.day;
    final cycle = entry.salary!.cycle.selectableCycle;
    if (cycle == SalaryPayCycle.weekly || cycle == SalaryPayCycle.biweekly) {
      var weeks = day.difference(start).inDays ~/ 7;
      if (weeks >= weeklyCount) weeks = weeklyCount - 1;
      return start.add(Duration(days: weeks * 7));
    }
    var months = (day.year - start.year) * 12 + (day.month - start.month);
    if (months >= monthlyCount) months = monthlyCount - 1;
    var candidate = _occurrence(entry.salary!, start, months);
    if (candidate.isAfter(day)) {
      months -= 1;
      if (months < 0) return start;
      candidate = _occurrence(entry.salary!, start, months);
    }
    return candidate;
  }

  static DateTime _occurrence(
    LedgerSalaryDetails salary,
    DateTime start,
    int monthsLater,
  ) {
    final first = DateTime(start.year, start.month + monthsLater);
    if (salary.monthRule == SalaryMonthRule.weekday) {
      return SalaryMonthDate.weekdayInMonth(
        year: first.year,
        month: first.month,
        weekday: salary.weekday,
        week: salary.monthWeek,
      );
    }
    final last = DateTime(first.year, first.month + 1, 0).day;
    if (salary.monthDay <= 0) {
      return DateTime(first.year, first.month, last);
    }
    final day = start.day > last ? last : start.day;
    return DateTime(first.year, first.month, day);
  }

  static bool _hasPayCycle(LedgerEntry entry) {
    return entry.isWage && entry.salary != null;
  }
}
