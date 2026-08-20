import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/job_application.dart';

class MonthlyCategoryStat {
  const MonthlyCategoryStat({
    required this.name,
    required this.total,
    required this.completed,
    required this.color,
  });

  final String name;
  final int total;
  final int completed;
  final int color;
}

class MonthlyNamedCount {
  const MonthlyNamedCount({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}

class MonthlyBusyDay {
  const MonthlyBusyDay({
    required this.date,
    required this.todos,
  });

  final DateTime date;
  final int todos;
}

class MonthlyStats {
  const MonthlyStats({
    required this.year,
    required this.month,
    required this.completedTodos,
    required this.totalTodos,
    required this.jobRounds,
    required this.companies,
    required this.coverLetters,
    required this.finalPassed,
    required this.passed,
    required this.rejected,
    required this.inProgress,
    required this.categories,
    required this.roundTypes,
    this.busyDay,
  });

  final int year;
  final int month;
  final int completedTodos;
  final int totalTodos;
  final int jobRounds;
  final int companies;
  final int coverLetters;
  final int finalPassed;
  final int passed;
  final int rejected;
  final int inProgress;
  final List<MonthlyCategoryStat> categories;
  final List<MonthlyNamedCount> roundTypes;
  final MonthlyBusyDay? busyDay;

  int get incompleteTodos => totalTodos - completedTodos;

  int get completionRate {
    if (totalTodos == 0) return 0;
    return ((completedTodos / totalTodos) * 100).round();
  }

  bool get isEmpty => totalTodos == 0 && jobRounds == 0;

  static DateTime previousMonth(DateTime today) {
    return DateTime(today.year, today.month - 1);
  }

  static bool _inRange(DateTime date, DateTime start, DateTime end) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static ({DateTime start, DateTime end}) previousWeek(
    DateTime today, {
    bool startMonday = false,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final offset = startMonday ? day.weekday - 1 : day.weekday % 7;
    final thisStart = day.subtract(Duration(days: offset));
    final start = thisStart.subtract(const Duration(days: 7));
    return (start: start, end: start.add(const Duration(days: 6)));
  }

  static MonthlyStats of({
    required DateTime month,
    required List<CalendarEvent> events,
    required List<JobApplication> applications,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return ofRange(
      start: start,
      end: end,
      events: events,
      applications: applications,
    );
  }

  static MonthlyStats ofRange({
    required DateTime start,
    required DateTime end,
    required List<CalendarEvent> events,
    required List<JobApplication> applications,
  }) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final year = startDay.year;
    final monthNumber = startDay.month;
    var completedTodos = 0;
    var totalTodos = 0;
    final categoryTotals = <String, int>{};
    final categoryCompleted = <String, int>{};
    final categoryColors = <String, int>{};
    final todosByDay = <DateTime, int>{};

    for (final event in events) {
      if (event.isJob) continue;
      if (!_inRange(event.date, startDay, endDay)) continue;
      totalTodos++;
      final category = event.categoryName;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + 1;
      categoryColors[category] = event.categoryColor;
      final day = event.day;
      todosByDay[day] = (todosByDay[day] ?? 0) + 1;
      if (!event.completed) continue;
      completedTodos++;
      categoryCompleted[category] = (categoryCompleted[category] ?? 0) + 1;
    }

    var jobRounds = 0;
    final companyIds = <String>{};
    final roundTypeCounts = <String, int>{};
    for (final application in applications) {
      var hadRound = false;
      for (final round in application.rounds) {
        final date = round.date;
        if (date == null || !_inRange(date, startDay, endDay)) continue;
        jobRounds++;
        hadRound = true;
        final name = round.name.trim();
        if (name.isEmpty) continue;
        roundTypeCounts[name] = (roundTypeCounts[name] ?? 0) + 1;
      }
      if (hadRound) companyIds.add(application.id);
    }

    var coverLetters = 0;
    var finalPassed = 0;
    var passed = 0;
    var rejected = 0;
    var inProgress = 0;
    for (final application in applications) {
      if (!companyIds.contains(application.id)) continue;
      final hasLetter =
          (application.coverLetterPath?.trim().isNotEmpty ?? false) ||
          (application.coverLetterFileName?.trim().isNotEmpty ?? false);
      if (hasLetter) coverLetters++;
      final status = application.applyStatus;
      if (status == ApplyStatus.finalPassed) {
        finalPassed++;
      } else if (ApplyStatus.isRejected(status)) {
        rejected++;
      } else if (status == ApplyStatus.documentPassed ||
          status == ApplyStatus.writtenPassed ||
          status == ApplyStatus.interviewPassed) {
        passed++;
      } else {
        inProgress++;
      }
    }

    final categories = [
      for (final entry in categoryTotals.entries)
        MonthlyCategoryStat(
          name: entry.key,
          total: entry.value,
          completed: categoryCompleted[entry.key] ?? 0,
          color: categoryColors[entry.key] ?? CalendarEvent.defaultCategoryColor,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));

    final roundTypes = [
      for (final entry in roundTypeCounts.entries)
        MonthlyNamedCount(name: entry.key, count: entry.value),
    ]..sort((a, b) => b.count.compareTo(a.count));

    MonthlyBusyDay? busyDay;
    for (final entry in todosByDay.entries) {
      final current = busyDay;
      if (current == null ||
          entry.value > current.todos ||
          (entry.value == current.todos && entry.key.isBefore(current.date))) {
        busyDay = MonthlyBusyDay(date: entry.key, todos: entry.value);
      }
    }

    return MonthlyStats(
      year: year,
      month: monthNumber,
      completedTodos: completedTodos,
      totalTodos: totalTodos,
      jobRounds: jobRounds,
      companies: companyIds.length,
      coverLetters: coverLetters,
      finalPassed: finalPassed,
      passed: passed,
      rejected: rejected,
      inProgress: inProgress,
      categories: categories,
      roundTypes: roundTypes,
      busyDay: busyDay,
    );
  }
}
