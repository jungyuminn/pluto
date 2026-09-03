import 'package:pluto/domain/entities/apply_status.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/ledger_month_stats.dart';
import 'package:pluto/domain/ledger_salary_repeat.dart';

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

enum MonthlyBusyDayKind { todo, job, diary, ledger }

class MonthlyBusyDayItem {
  const MonthlyBusyDayItem({
    required this.title,
    required this.color,
    this.kind = MonthlyBusyDayKind.todo,
    this.timeLabel,
    this.trailing,
    this.completed = false,
  });

  final String title;
  final int color;
  final MonthlyBusyDayKind kind;
  final String? timeLabel;
  final String? trailing;
  final bool completed;
}

class MonthlyBusyDay {
  const MonthlyBusyDay({
    required this.date,
    this.items = const [],
  });

  final DateTime date;
  final List<MonthlyBusyDayItem> items;
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
    this.diaries = 0,
    this.diaryDays = 0,
    this.diaryPhotos = 0,
    this.diaryCategories = const [],
    this.ledger = LedgerMonthStats.empty,
    this.ledgerCategories = const [],
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
  final int diaries;
  final int diaryDays;
  final int diaryPhotos;
  final List<MonthlyCategoryStat> diaryCategories;
  final LedgerMonthStats ledger;
  final List<MonthlyCategoryStat> ledgerCategories;

  int get incompleteTodos => totalTodos - completedTodos;

  int get completionRate {
    if (totalTodos == 0) return 0;
    return ((completedTodos / totalTodos) * 100).round();
  }

  bool get isEmpty =>
      totalTodos == 0 &&
      jobRounds == 0 &&
      diaries == 0 &&
      ledger.isEmpty;

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
    List<DiaryEntry> diaries = const [],
    List<LedgerEntry> ledgers = const [],
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return ofRange(
      start: start,
      end: end,
      events: events,
      applications: applications,
      diaries: diaries,
      ledgers: ledgers,
    );
  }

  static MonthlyStats ofRange({
    required DateTime start,
    required DateTime end,
    required List<CalendarEvent> events,
    required List<JobApplication> applications,
    List<DiaryEntry> diaries = const [],
    List<LedgerEntry> ledgers = const [],
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
    final busyScore = <DateTime, int>{};

    for (final event in events) {
      if (event.isJob || event.someday) continue;
      if (!_inRange(event.date, startDay, endDay)) continue;
      totalTodos++;
      final category = event.categoryName;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + 1;
      categoryColors[category] = event.categoryColor;
      final day = event.day;
      busyScore[day] = (busyScore[day] ?? 0) + 1;
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
        final roundDay = DateTime(date.year, date.month, date.day);
        busyScore[roundDay] = (busyScore[roundDay] ?? 0) + 1;
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

    DateTime? busyDate;
    var best = 0;
    for (final entry in busyScore.entries) {
      if (busyDate == null ||
          entry.value > best ||
          (entry.value == best && entry.key.isBefore(busyDate))) {
        busyDate = entry.key;
        best = entry.value;
      }
    }
    MonthlyBusyDay? busyDay;
    if (busyDate != null) {
      final items = _itemsOn(
        busyDate,
        events: events,
        applications: applications,
        diaries: diaries,
        ledgers: ledgers,
      );
      if (items.isNotEmpty) {
        busyDay = MonthlyBusyDay(date: busyDate, items: items);
      }
    }

    final diaryKeys = <String>{};
    final diaryDaySet = <DateTime>{};
    final photoKeys = <String>{};
    final diaryCategoryTotals = <String, int>{};
    final diaryCategoryColors = <String, int>{};
    for (final diary in diaries) {
      if (!_inRange(diary.date, startDay, endDay)) continue;
      final key = diary.groupId ?? diary.id;
      diaryDaySet.add(diary.day);
      final isNew = diaryKeys.add(key);
      if (diary.hasPhoto) photoKeys.add(key);
      if (!isNew) continue;
      final category = diary.categoryName;
      diaryCategoryTotals[category] = (diaryCategoryTotals[category] ?? 0) + 1;
      diaryCategoryColors[category] = diary.categoryColor;
    }

    final diaryCategories = [
      for (final entry in diaryCategoryTotals.entries)
        MonthlyCategoryStat(
          name: entry.key,
          total: entry.value,
          completed: entry.value,
          color: diaryCategoryColors[entry.key] ??
              CalendarEvent.defaultCategoryColor,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));

    final ledger = LedgerMonthStats.ofRange(
      start: startDay,
      end: endDay,
      entries: ledgers,
    );
    final ledgerCategoryTotals = <String, int>{};
    final ledgerCategoryColors = <String, int>{};
    var hasNamedLedgerCategory = false;
    if (!ledger.isEmpty) {
      for (
        var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))
      ) {
        for (final entry in ledgers) {
          if (!LedgerSalaryRepeat.occursOn(entry, day)) continue;
          if (entry.categoryName.trim().isNotEmpty) {
            hasNamedLedgerCategory = true;
          }
          final name = entry.displayCategoryName;
          ledgerCategoryTotals[name] = (ledgerCategoryTotals[name] ?? 0) + 1;
          ledgerCategoryColors[name] = entry.displayCategoryColor;
        }
      }
    }

    final ledgerCategories = [
      if (hasNamedLedgerCategory)
        for (final entry in ledgerCategoryTotals.entries)
          MonthlyCategoryStat(
            name: entry.key,
            total: entry.value,
            completed: entry.value,
            color: ledgerCategoryColors[entry.key] ??
              CalendarEvent.defaultCategoryColor,
          ),
    ]..sort((a, b) => b.total.compareTo(a.total));

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
      diaries: diaryKeys.length,
      diaryDays: diaryDaySet.length,
      diaryPhotos: photoKeys.length,
      diaryCategories: diaryCategories,
      ledger: ledger,
      ledgerCategories: ledgerCategories,
    );
  }

  static List<MonthlyBusyDayItem> _itemsOn(
    DateTime date, {
    required List<CalendarEvent> events,
    required List<JobApplication> applications,
    required List<DiaryEntry> diaries,
    required List<LedgerEntry> ledgers,
  }) {
    final items = <MonthlyBusyDayItem>[];
    for (final application in applications) {
      for (var i = 0; i < application.rounds.length; i++) {
        final round = application.rounds[i];
        final roundDate = round.date;
        if (roundDate == null || !_inRange(roundDate, date, date)) continue;
        items.add(
          MonthlyBusyDayItem(
            title: _jobRoundLabel(application.companyName, round.name),
            color:
                application.categoryColor ?? CalendarEvent.defaultCategoryColor,
            kind: MonthlyBusyDayKind.job,
          ),
        );
      }
    }

    final dayTodos = [
      for (final event in events)
        if (!event.isJob &&
            !event.someday &&
            _inRange(event.date, date, date))
          event,
    ];
    final ordered = CalendarEvent.withRangesFirst(
      dayTodos,
      all: events.where((event) => !event.isJob && !event.someday),
    );
    for (final event in ordered) {
      items.add(
        MonthlyBusyDayItem(
          title: event.title,
          color: event.categoryColor,
          timeLabel: event.timeLabel,
          completed: event.completed,
        ),
      );
    }

    final seenDiary = <String>{};
    for (final diary in diaries) {
      if (!_inRange(diary.date, date, date)) continue;
      if (!seenDiary.add(diary.groupId ?? diary.id)) continue;
      final title = diary.title.trim();
      items.add(
        MonthlyBusyDayItem(
          title: title.isNotEmpty ? title : diary.body.trim().split('\n').first,
          color: diary.categoryColor,
          kind: MonthlyBusyDayKind.diary,
        ),
      );
    }

    final dayLedgers = [
      for (final entry in ledgers)
        if (LedgerSalaryRepeat.occursOn(entry, date)) entry,
    ]..sort(LedgerEntry.compareDisplay);
    for (final entry in dayLedgers) {
      final title = entry.title.trim();
      items.add(
        MonthlyBusyDayItem(
          title: title.isNotEmpty ? title : entry.displayCategoryName,
          color: entry.displayCategoryColor,
          trailing: '${entry.signedLabel}원',
          kind: MonthlyBusyDayKind.ledger,
        ),
      );
    }
    return items;
  }

  static String _jobRoundLabel(String companyName, String roundName) {
    final name = roundName.trim();
    if (name.isEmpty) return companyName;
    return '$companyName($name)';
  }
}
