import 'package:flutter/material.dart';
import 'package:pluto/data/datasources/backup_preference.dart';
import 'package:pluto/data/datasources/calendar_preference.dart';
import 'package:pluto/data/datasources/category_suggest_preference.dart';
import 'package:pluto/data/datasources/day_events_view_preference.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/data/datasources/home_view_preference.dart';
import 'package:pluto/data/datasources/home_memo_local_datasource.dart';
import 'package:pluto/data/datasources/long_goal_local_datasource.dart';
import 'package:pluto/data/datasources/job_view_preference.dart';
import 'package:pluto/data/datasources/license_view_preference.dart';
import 'package:pluto/data/datasources/notification_preference.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/data/datasources/widget_preference.dart';
import 'package:pluto/data/datasources/wordmark_preference.dart';
import 'package:pluto/data/datasources/nav_preference.dart';
import 'package:pluto/domain/usecases/add_calendar_event.dart';
import 'package:pluto/domain/usecases/add_event_category.dart';
import 'package:pluto/domain/usecases/delete_event_category.dart';
import 'package:pluto/domain/usecases/add_job_application.dart';
import 'package:pluto/domain/usecases/delete_calendar_event.dart';
import 'package:pluto/domain/usecases/delete_diary.dart';
import 'package:pluto/domain/usecases/delete_ledger.dart';
import 'package:pluto/domain/usecases/delete_job_application.dart';
import 'package:pluto/domain/usecases/get_calendar_events.dart';
import 'package:pluto/domain/usecases/get_diaries.dart';
import 'package:pluto/domain/usecases/get_ledgers.dart';
import 'package:pluto/domain/usecases/get_event_categories.dart';
import 'package:pluto/domain/usecases/get_job_applications.dart';
import 'package:pluto/domain/usecases/get_licenses.dart';
import 'package:pluto/domain/usecases/add_license.dart';
import 'package:pluto/domain/usecases/update_license.dart';
import 'package:pluto/domain/usecases/delete_license.dart';
import 'package:pluto/domain/usecases/reorder_licenses.dart';
import 'package:pluto/domain/usecases/reorder_calendar_events.dart';
import 'package:pluto/domain/usecases/reorder_job_applications.dart';
import 'package:pluto/domain/usecases/reorder_event_categories.dart';
import 'package:pluto/domain/usecases/save_diary.dart';
import 'package:pluto/domain/usecases/save_ledger.dart';
import 'package:pluto/domain/usecases/update_calendar_event.dart';
import 'package:pluto/domain/usecases/update_event_category.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/usecases/update_job_application.dart';

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
    required this.getLedgerCategories,
    required this.addLedgerCategory,
    required this.updateLedgerCategory,
    required this.deleteLedgerCategory,
    required this.reorderLedgerCategories,
    required this.getLicenseCategories,
    required this.addLicenseCategory,
    required this.updateLicenseCategory,
    required this.deleteLicenseCategory,
    required this.reorderLicenseCategories,
    required this.getLicenses,
    required this.addLicense,
    required this.updateLicense,
    required this.deleteLicense,
    required this.reorderLicenses,
    required this.jobViewPreference,
    required this.licenseViewPreference,
    required this.homeViewPreference,
    required this.longGoalStore,
    required this.memoStore,
    required this.dayEmojiStore,
    required this.dayEventsViewPreference,
    required this.calendarPreference,
    required this.categorySuggestPreference,
    required this.fontPreference,
    required this.notificationPreference,
    required this.themePreference,
    required this.widgetPreference,
    required this.navPreference,
    required this.wordmarkPreference,
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
  final GetEventCategories getLedgerCategories;
  final AddEventCategory addLedgerCategory;
  final UpdateEventCategory updateLedgerCategory;
  final DeleteEventCategory deleteLedgerCategory;
  final ReorderEventCategories reorderLedgerCategories;
  final GetEventCategories getLicenseCategories;
  final AddEventCategory addLicenseCategory;
  final UpdateEventCategory updateLicenseCategory;
  final DeleteEventCategory deleteLicenseCategory;
  final ReorderEventCategories reorderLicenseCategories;
  final GetLicenses getLicenses;
  final AddLicense addLicense;
  final UpdateLicense updateLicense;
  final DeleteLicense deleteLicense;
  final ReorderLicenses reorderLicenses;
  final JobViewPreference jobViewPreference;
  final LicenseViewPreference licenseViewPreference;
  final HomeViewPreference homeViewPreference;
  final LongGoalLocalDataSource longGoalStore;
  final HomeMemoLocalDataSource memoStore;
  final DayEmojiStore dayEmojiStore;
  final DayEventsViewPreference dayEventsViewPreference;
  final CalendarPreference calendarPreference;
  final CategorySuggestPreference categorySuggestPreference;
  final FontPreference fontPreference;
  final NotificationPreference notificationPreference;
  final ThemePreference themePreference;
  final WidgetPreference widgetPreference;
  final NavPreference navPreference;
  final WordmarkPreference wordmarkPreference;
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
        getLedgerCategories != oldWidget.getLedgerCategories ||
        addLedgerCategory != oldWidget.addLedgerCategory ||
        updateLedgerCategory != oldWidget.updateLedgerCategory ||
        deleteLedgerCategory != oldWidget.deleteLedgerCategory ||
        reorderLedgerCategories != oldWidget.reorderLedgerCategories ||
        getLicenseCategories != oldWidget.getLicenseCategories ||
        addLicenseCategory != oldWidget.addLicenseCategory ||
        updateLicenseCategory != oldWidget.updateLicenseCategory ||
        deleteLicenseCategory != oldWidget.deleteLicenseCategory ||
        reorderLicenseCategories != oldWidget.reorderLicenseCategories ||
        getLicenses != oldWidget.getLicenses ||
        addLicense != oldWidget.addLicense ||
        updateLicense != oldWidget.updateLicense ||
        deleteLicense != oldWidget.deleteLicense ||
        reorderLicenses != oldWidget.reorderLicenses ||
        jobViewPreference != oldWidget.jobViewPreference ||
        licenseViewPreference != oldWidget.licenseViewPreference ||
        homeViewPreference != oldWidget.homeViewPreference ||
        longGoalStore != oldWidget.longGoalStore ||
        memoStore != oldWidget.memoStore ||
        dayEmojiStore != oldWidget.dayEmojiStore ||
        dayEventsViewPreference != oldWidget.dayEventsViewPreference ||
        calendarPreference != oldWidget.calendarPreference ||
        categorySuggestPreference != oldWidget.categorySuggestPreference ||
        fontPreference != oldWidget.fontPreference ||
        notificationPreference != oldWidget.notificationPreference ||
        themePreference != oldWidget.themePreference ||
        widgetPreference != oldWidget.widgetPreference ||
        navPreference != oldWidget.navPreference ||
        wordmarkPreference != oldWidget.wordmarkPreference ||
        backupPreference != oldWidget.backupPreference;
  }

  Future<List<EventCategory>> fetchCategories(CategoryKind kind) {
    return switch (kind) {
      CategoryKind.event => getEventCategories(),
      CategoryKind.company => getCompanyCategories(),
      CategoryKind.ledger => getLedgerCategories(),
      CategoryKind.license => getLicenseCategories(),
    };
  }

  Future<void> addCategory(CategoryKind kind, EventCategory category) {
    return switch (kind) {
      CategoryKind.event => addEventCategory(category),
      CategoryKind.company => addCompanyCategory(category),
      CategoryKind.ledger => addLedgerCategory(category),
      CategoryKind.license => addLicenseCategory(category),
    };
  }

  Future<void> saveCategory(CategoryKind kind, EventCategory category) {
    return switch (kind) {
      CategoryKind.event => updateEventCategory(category),
      CategoryKind.company => updateCompanyCategory(category),
      CategoryKind.ledger => updateLedgerCategory(category),
      CategoryKind.license => updateLicenseCategory(category),
    };
  }

  Future<void> removeCategories(CategoryKind kind, Iterable<String> ids) {
    return switch (kind) {
      CategoryKind.event => deleteEventCategory(ids),
      CategoryKind.company => deleteCompanyCategory(ids),
      CategoryKind.ledger => deleteLedgerCategory(ids),
      CategoryKind.license => deleteLicenseCategory(ids),
    };
  }

  Future<void> replaceCategories(
    CategoryKind kind,
    List<EventCategory> categories,
  ) {
    return switch (kind) {
      CategoryKind.event => reorderEventCategories(categories),
      CategoryKind.company => reorderCompanyCategories(categories),
      CategoryKind.ledger => reorderLedgerCategories(categories),
      CategoryKind.license => reorderLicenseCategories(categories),
    };
  }
}
