import 'package:flutter/material.dart';
import 'package:job_planner/data/datasources/backup_preference.dart';
import 'package:job_planner/data/datasources/calendar_preference.dart';
import 'package:job_planner/data/datasources/day_events_view_preference.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/home_view_preference.dart';
import 'package:job_planner/data/datasources/long_goal_local_datasource.dart';
import 'package:job_planner/data/datasources/job_view_preference.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:job_planner/domain/usecases/add_calendar_event.dart';
import 'package:job_planner/domain/usecases/add_event_category.dart';
import 'package:job_planner/domain/usecases/delete_event_category.dart';
import 'package:job_planner/domain/usecases/add_job_application.dart';
import 'package:job_planner/domain/usecases/delete_calendar_event.dart';
import 'package:job_planner/domain/usecases/delete_diary.dart';
import 'package:job_planner/domain/usecases/delete_ledger.dart';
import 'package:job_planner/domain/usecases/delete_job_application.dart';
import 'package:job_planner/domain/usecases/get_calendar_events.dart';
import 'package:job_planner/domain/usecases/get_diaries.dart';
import 'package:job_planner/domain/usecases/get_ledgers.dart';
import 'package:job_planner/domain/usecases/get_event_categories.dart';
import 'package:job_planner/domain/usecases/get_job_applications.dart';
import 'package:job_planner/domain/usecases/reorder_calendar_events.dart';
import 'package:job_planner/domain/usecases/reorder_job_applications.dart';
import 'package:job_planner/domain/usecases/reorder_event_categories.dart';
import 'package:job_planner/domain/usecases/save_diary.dart';
import 'package:job_planner/domain/usecases/save_ledger.dart';
import 'package:job_planner/domain/usecases/update_calendar_event.dart';
import 'package:job_planner/domain/usecases/update_event_category.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/usecases/update_job_application.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.getJobApplications,
    required this.addJobApplication,
    required this.updateJobApplication,
    required this.deleteJobApplication,
    required this.reorderJobApplications,
    required this.getCalendarEvents,
    required this.addCalendarEvent,
    required this.updateCalendarEvent,
    required this.deleteCalendarEvent,
    required this.reorderCalendarEvents,
    required this.getDiaries,
    required this.saveDiary,
    required this.deleteDiary,
    required this.getLedgers,
    required this.saveLedger,
    required this.deleteLedger,
    required this.getEventCategories,
    required this.addEventCategory,
    required this.updateEventCategory,
    required this.deleteEventCategory,
    required this.reorderEventCategories,
    required this.getCompanyCategories,
    required this.addCompanyCategory,
    required this.updateCompanyCategory,
    required this.deleteCompanyCategory,
    required this.reorderCompanyCategories,
    required this.jobViewPreference,
    required this.homeViewPreference,
    required this.longGoalStore,
    required this.dayEventsViewPreference,
    required this.calendarPreference,
    required this.fontPreference,
    required this.notificationPreference,
    required this.themePreference,
    required this.backupPreference,
    required super.child,
  });

  final GetJobApplications getJobApplications;
  final AddJobApplication addJobApplication;
  final UpdateJobApplication updateJobApplication;
  final DeleteJobApplication deleteJobApplication;
  final ReorderJobApplications reorderJobApplications;
  final GetCalendarEvents getCalendarEvents;
  final AddCalendarEvent addCalendarEvent;
  final UpdateCalendarEvent updateCalendarEvent;
  final DeleteCalendarEvent deleteCalendarEvent;
  final ReorderCalendarEvents reorderCalendarEvents;
  final GetDiaries getDiaries;
  final SaveDiary saveDiary;
  final DeleteDiary deleteDiary;
  final GetLedgers getLedgers;
  final SaveLedger saveLedger;
  final DeleteLedger deleteLedger;
  final GetEventCategories getEventCategories;
  final AddEventCategory addEventCategory;
  final UpdateEventCategory updateEventCategory;
  final DeleteEventCategory deleteEventCategory;
  final ReorderEventCategories reorderEventCategories;
  final GetEventCategories getCompanyCategories;
  final AddEventCategory addCompanyCategory;
  final UpdateEventCategory updateCompanyCategory;
  final DeleteEventCategory deleteCompanyCategory;
  final ReorderEventCategories reorderCompanyCategories;
  final JobViewPreference jobViewPreference;
  final HomeViewPreference homeViewPreference;
  final LongGoalLocalDataSource longGoalStore;
  final DayEventsViewPreference dayEventsViewPreference;
  final CalendarPreference calendarPreference;
  final FontPreference fontPreference;
  final NotificationPreference notificationPreference;
  final ThemePreference themePreference;
  final BackupPreference backupPreference;

  static AppScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AppScope가 위젯 트리에 없습니다.');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>();
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return getJobApplications != oldWidget.getJobApplications ||
        addJobApplication != oldWidget.addJobApplication ||
        updateJobApplication != oldWidget.updateJobApplication ||
        deleteJobApplication != oldWidget.deleteJobApplication ||
        reorderJobApplications != oldWidget.reorderJobApplications ||
        getCalendarEvents != oldWidget.getCalendarEvents ||
        addCalendarEvent != oldWidget.addCalendarEvent ||
        updateCalendarEvent != oldWidget.updateCalendarEvent ||
        deleteCalendarEvent != oldWidget.deleteCalendarEvent ||
        reorderCalendarEvents != oldWidget.reorderCalendarEvents ||
        getDiaries != oldWidget.getDiaries ||
        saveDiary != oldWidget.saveDiary ||
        deleteDiary != oldWidget.deleteDiary ||
        getLedgers != oldWidget.getLedgers ||
        saveLedger != oldWidget.saveLedger ||
        deleteLedger != oldWidget.deleteLedger ||
        getEventCategories != oldWidget.getEventCategories ||
        addEventCategory != oldWidget.addEventCategory ||
        updateEventCategory != oldWidget.updateEventCategory ||
        deleteEventCategory != oldWidget.deleteEventCategory ||
        reorderEventCategories != oldWidget.reorderEventCategories ||
        getCompanyCategories != oldWidget.getCompanyCategories ||
        addCompanyCategory != oldWidget.addCompanyCategory ||
        updateCompanyCategory != oldWidget.updateCompanyCategory ||
        deleteCompanyCategory != oldWidget.deleteCompanyCategory ||
        reorderCompanyCategories != oldWidget.reorderCompanyCategories ||
        jobViewPreference != oldWidget.jobViewPreference ||
        homeViewPreference != oldWidget.homeViewPreference ||
        longGoalStore != oldWidget.longGoalStore ||
        dayEventsViewPreference != oldWidget.dayEventsViewPreference ||
        calendarPreference != oldWidget.calendarPreference ||
        fontPreference != oldWidget.fontPreference ||
        notificationPreference != oldWidget.notificationPreference ||
        themePreference != oldWidget.themePreference ||
        backupPreference != oldWidget.backupPreference;
  }

  Future<List<EventCategory>> fetchCategories(CategoryKind kind) {
    return switch (kind) {
      CategoryKind.event => getEventCategories(),
      CategoryKind.company => getCompanyCategories(),
    };
  }

  Future<void> addCategory(CategoryKind kind, EventCategory category) {
    return switch (kind) {
      CategoryKind.event => addEventCategory(category),
      CategoryKind.company => addCompanyCategory(category),
    };
  }

  Future<void> saveCategory(CategoryKind kind, EventCategory category) {
    return switch (kind) {
      CategoryKind.event => updateEventCategory(category),
      CategoryKind.company => updateCompanyCategory(category),
    };
  }

  Future<void> removeCategories(CategoryKind kind, Iterable<String> ids) {
    return switch (kind) {
      CategoryKind.event => deleteEventCategory(ids),
      CategoryKind.company => deleteCompanyCategory(ids),
    };
  }

  Future<void> replaceCategories(
    CategoryKind kind,
    List<EventCategory> categories,
  ) {
    return switch (kind) {
      CategoryKind.event => reorderEventCategories(categories),
      CategoryKind.company => reorderCompanyCategories(categories),
    };
  }
}
