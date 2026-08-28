import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';

int jobCategoryColor(
  JobApplication application, [
  List<EventCategory> companyCategories = const [],
]) {
  final id = application.categoryId;
  if (id != null && id.isNotEmpty) {
    for (final category in companyCategories) {
      if (category.id == id) return category.color;
    }
  }
  return application.categoryColor ?? CalendarEvent.defaultCategoryColor;
}

List<CalendarEvent> jobEventsOn(
  DateTime date,
  Iterable<JobApplication> applications, {
  List<EventCategory> companyCategories = const [],
}) {
  final day = DateTime(date.year, date.month, date.day);
  final items = <CalendarEvent>[];
  for (final application in applications) {
    if (ApplyStatus.isRejected(application.applyStatus)) continue;
    for (var i = 0; i < application.rounds.length; i++) {
      final round = application.rounds[i];
      final roundDate = round.date;
      if (roundDate == null) continue;
      if (roundDate.year != day.year ||
          roundDate.month != day.month ||
          roundDate.day != day.day) {
        continue;
      }
      items.add(
        CalendarEvent(
          id: 'job:${application.id}:$i',
          title: _label(application.companyName, i + 1, round.name),
          date: day,
          memo: application.position.trim(),
          categoryId: application.categoryId,
          categoryName: application.hasCategory
              ? application.categoryName
              : (application.applyStatus.isNotEmpty
                  ? application.applyStatus
                  : application.position),
          categoryColor: jobCategoryColor(application, companyCategories),
          isJob: true,
          jobApplicationId: application.id,
        ),
      );
    }
  }
  return items;
}

List<CalendarEvent> calendarEventsOn({
  required DateTime date,
  required List<CalendarEvent> events,
  required List<JobApplication> applications,
  List<EventCategory> companyCategories = const [],
}) {
  final jobs = jobEventsOn(
    date,
    applications,
    companyCategories: companyCategories,
  );
  final todos = CalendarEvent.withRangesFirst(
    events.where((event) {
      if (event.isJob || event.someday) return false;
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }),
    all: events.where((event) => !event.isJob && !event.someday),
  );
  return [...jobs, ...todos];
}

DateTime calendarDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime calendarWeekStart(DateTime date, {bool startMonday = false}) {
  final day = calendarDay(date);
  final offset = startMonday ? day.weekday - 1 : day.weekday % 7;
  return day.subtract(Duration(days: offset));
}

DateTime calendarWeekEnd(DateTime date, {bool startMonday = false}) {
  return calendarWeekStart(date, startMonday: startMonday)
      .add(const Duration(days: 6));
}

List<CalendarEvent> calendarEventsInRange({
  required DateTime start,
  required DateTime end,
  required List<CalendarEvent> events,
  required List<JobApplication> applications,
  List<EventCategory> companyCategories = const [],
}) {
  final items = <CalendarEvent>[];
  var day = calendarDay(start);
  final last = calendarDay(end);
  while (!day.isAfter(last)) {
    items.addAll(
      calendarEventsOn(
        date: day,
        events: events,
        applications: applications,
        companyCategories: companyCategories,
      ),
    );
    day = day.add(const Duration(days: 1));
  }
  return items;
}

List<DateTime> calendarDaysInRange(DateTime start, DateTime end) {
  final days = <DateTime>[];
  var day = calendarDay(start);
  final last = calendarDay(end);
  while (!day.isAfter(last)) {
    days.add(day);
    day = day.add(const Duration(days: 1));
  }
  return days;
}

String calendarRangeLabel(DateTime start, DateTime end) {
  final first = calendarDay(start);
  final last = calendarDay(end);
  String labeled(DateTime day) {
    final weekday = AppStrings.weekdays[day.weekday % 7];
    return '${day.month}. ${day.day}. ($weekday)';
  }

  if (first == last) return labeled(first);
  return '${labeled(first)} - ${labeled(last)}';
}

List<CalendarEvent> leftoverTodosBefore(
  DateTime date,
  List<CalendarEvent> events,
) {
  final today = DateTime(date.year, date.month, date.day);
  final rangeEnd = <String, DateTime>{};
  for (final event in events) {
    final groupId = event.groupId;
    if (groupId == null) continue;
    final day = event.day;
    final current = rangeEnd[groupId];
    if (current == null || day.isAfter(current)) {
      rangeEnd[groupId] = day;
    }
  }

  final leftover = <CalendarEvent>[];
  final rangeByGroup = <String, CalendarEvent>{};
  for (final event in events) {
    if (event.isJob || event.completed || event.someday) continue;
    if (!event.day.isBefore(today)) continue;
    if (event.isRange) {
      final end = rangeEnd[event.groupId] ?? event.day;
      if (!end.isBefore(today)) continue;
      final current = rangeByGroup[event.groupId];
      if (current == null || event.day.isAfter(current.day)) {
        rangeByGroup[event.groupId!] = event;
      }
      continue;
    }
    leftover.add(event);
  }
  leftover.addAll(rangeByGroup.values);
  leftover.sort((a, b) => a.day.compareTo(b.day));
  return CalendarEvent.withRangesFirst(leftover, all: events);
}

String _label(String companyName, int number, String roundName) {
  final name = roundName.trim();
  if (name.isEmpty) return '$companyName-${number}차';
  return '$companyName-${number}차($name)';
}
