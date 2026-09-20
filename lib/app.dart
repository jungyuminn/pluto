import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/home_widget/home_screen_widget_service.dart';
import 'package:pluto/core/notifications/todo_reminder_service.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/theme/web_theme_color.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/data/datasources/cloud_sync_service.dart';
import 'package:pluto/data/datasources/backup_preference.dart';
import 'package:pluto/data/datasources/calendar_preference.dart';
import 'package:pluto/data/datasources/category_suggest_preference.dart';
import 'package:pluto/data/datasources/calendar_event_local_datasource.dart';
import 'package:pluto/data/datasources/diary_local_datasource.dart';
import 'package:pluto/data/datasources/ledger_local_datasource.dart';
import 'package:pluto/data/datasources/event_category_local_datasource.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/datasources/day_events_view_preference.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/home_view_preference.dart';
import 'package:pluto/data/datasources/home_memo_local_datasource.dart';
import 'package:pluto/data/datasources/job_view_preference.dart';
import 'package:pluto/data/datasources/license_view_preference.dart';
import 'package:pluto/data/datasources/license_local_datasource.dart';
import 'package:pluto/data/datasources/long_goal_local_datasource.dart';
import 'package:pluto/data/datasources/job_application_local_datasource.dart';
import 'package:pluto/data/datasources/notification_preference.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/data/datasources/tutorial_preference.dart';
import 'package:pluto/data/datasources/widget_preference.dart';
import 'package:pluto/data/datasources/wordmark_preference.dart';
import 'package:pluto/data/datasources/nav_preference.dart';
import 'package:pluto/data/repositories/calendar_event_memory_repository.dart';
import 'package:pluto/data/repositories/calendar_event_repository_impl.dart';
import 'package:pluto/data/repositories/diary_memory_repository.dart';
import 'package:pluto/data/repositories/diary_repository_impl.dart';
import 'package:pluto/data/repositories/ledger_memory_repository.dart';
import 'package:pluto/data/repositories/ledger_repository_impl.dart';
import 'package:pluto/data/repositories/event_category_memory_repository.dart';
import 'package:pluto/data/repositories/event_category_repository_impl.dart';
import 'package:pluto/data/repositories/job_application_memory_repository.dart';
import 'package:pluto/data/repositories/job_application_repository_impl.dart';
import 'package:pluto/data/repositories/license_memory_repository.dart';
import 'package:pluto/data/repositories/license_repository_impl.dart';
import 'package:pluto/domain/entities/event_category.dart';
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
import 'package:pluto/domain/usecases/update_job_application.dart';
import 'package:pluto/presentation/screens/shell/shell_screen.dart';
import 'package:pluto/presentation/screens/settings/widgets/cloud_sync_dialogs.dart';
import 'package:pluto/presentation/screens/settings/widgets/dots_loading_dialog.dart';
import 'package:pluto/presentation/screens/settings/widgets/login_page.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobPlannerApp extends StatelessWidget {
  const JobPlannerApp({
    super.key,
    this.getJobApplications,
    this.addJobApplication,
    this.updateJobApplication,
    this.deleteJobApplication,
    this.reorderJobApplications,
    this.getLicenses,
    this.addLicense,
    this.updateLicense,
    this.deleteLicense,
    this.reorderLicenses,
    this.getCalendarEvents,
    this.addCalendarEvent,
    this.updateCalendarEvent,
    this.deleteCalendarEvent,
    this.reorderCalendarEvents,
    this.getDiaries,
    this.saveDiary,
    this.deleteDiary,
    this.getLedgers,
    this.saveLedger,
    this.deleteLedger,
    this.getEventCategories,
    this.addEventCategory,
    this.updateEventCategory,
    this.deleteEventCategory,
    this.reorderEventCategories,
    this.getCompanyCategories,
    this.addCompanyCategory,
    this.updateCompanyCategory,
    this.deleteCompanyCategory,
    this.reorderCompanyCategories,
    this.getLedgerCategories,
    this.addLedgerCategory,
    this.updateLedgerCategory,
    this.deleteLedgerCategory,
    this.reorderLedgerCategories,
    this.getLicenseCategories,
    this.addLicenseCategory,
    this.updateLicenseCategory,
    this.deleteLicenseCategory,
    this.reorderLicenseCategories,
    this.jobViewPreference,
    this.licenseViewPreference,
    this.homeViewPreference,
    this.longGoalStore,
    this.memoStore,
    this.dayEmojiStore,
    this.dayEventsViewPreference,
    this.calendarPreference,
    this.categorySuggestPreference,
    this.fontPreference,
    this.notificationPreference,
    this.themePreference,
    this.widgetPreference,
    this.navPreference,
    this.wordmarkPreference,
    this.backupPreference,
  });

  final GetJobApplications? getJobApplications;
  final AddJobApplication? addJobApplication;
  final UpdateJobApplication? updateJobApplication;
  final DeleteJobApplication? deleteJobApplication;
  final ReorderJobApplications? reorderJobApplications;
  final GetLicenses? getLicenses;
  final AddLicense? addLicense;
  final UpdateLicense? updateLicense;
  final DeleteLicense? deleteLicense;
  final ReorderLicenses? reorderLicenses;
  final GetCalendarEvents? getCalendarEvents;
  final AddCalendarEvent? addCalendarEvent;
  final UpdateCalendarEvent? updateCalendarEvent;
  final DeleteCalendarEvent? deleteCalendarEvent;
  final ReorderCalendarEvents? reorderCalendarEvents;
  final GetDiaries? getDiaries;
  final SaveDiary? saveDiary;
  final DeleteDiary? deleteDiary;
  final GetLedgers? getLedgers;
  final SaveLedger? saveLedger;
  final DeleteLedger? deleteLedger;
  final GetEventCategories? getEventCategories;
  final AddEventCategory? addEventCategory;
  final UpdateEventCategory? updateEventCategory;
  final DeleteEventCategory? deleteEventCategory;
  final ReorderEventCategories? reorderEventCategories;
  final GetEventCategories? getCompanyCategories;
  final AddEventCategory? addCompanyCategory;
  final UpdateEventCategory? updateCompanyCategory;
  final DeleteEventCategory? deleteCompanyCategory;
  final ReorderEventCategories? reorderCompanyCategories;
  final GetEventCategories? getLedgerCategories;
  final AddEventCategory? addLedgerCategory;
  final UpdateEventCategory? updateLedgerCategory;
  final DeleteEventCategory? deleteLedgerCategory;
  final ReorderEventCategories? reorderLedgerCategories;
  final GetEventCategories? getLicenseCategories;
  final AddEventCategory? addLicenseCategory;
  final UpdateEventCategory? updateLicenseCategory;
  final DeleteEventCategory? deleteLicenseCategory;
  final ReorderEventCategories? reorderLicenseCategories;
  final JobViewPreference? jobViewPreference;
  final LicenseViewPreference? licenseViewPreference;
  final HomeViewPreference? homeViewPreference;
  final LongGoalLocalDataSource? longGoalStore;
  final HomeMemoLocalDataSource? memoStore;
  final DayEmojiStore? dayEmojiStore;
  final DayEventsViewPreference? dayEventsViewPreference;
  final CalendarPreference? calendarPreference;
  final CategorySuggestPreference? categorySuggestPreference;
  final FontPreference? fontPreference;
  final NotificationPreference? notificationPreference;
  final ThemePreference? themePreference;
  final WidgetPreference? widgetPreference;
  final NavPreference? navPreference;
  final WordmarkPreference? wordmarkPreference;
  final BackupPreference? backupPreference;

  @override
  Widget build(BuildContext context) {
    final getApplications = getJobApplications;
    final addApplication = addJobApplication;
    final updateApplication = updateJobApplication;
    final deleteApplication = deleteJobApplication;

    if (getApplications == null ||
        addApplication == null ||
        updateApplication == null ||
        deleteApplication == null) {
      return const _AppBootstrap();
    }

    final calendarRepository = CalendarEventMemoryRepository();
    final diaryRepository = DiaryMemoryRepository();
    final ledgerRepository = LedgerMemoryRepository();
    final categoryRepository = EventCategoryMemoryRepository();
    final companyCategoryRepository =
        EventCategoryMemoryRepository(EventCategory.companyPresets);
    final ledgerCategoryRepository =
        EventCategoryMemoryRepository(EventCategory.ledgerPresets);
    final licenseCategoryRepository =
        EventCategoryMemoryRepository(EventCategory.licensePresets);
    final licenseRepository = LicenseMemoryRepository();
    return AppScope(
      getJobApplications: getApplications,
      addJobApplication: addApplication,
      updateJobApplication: updateApplication,
      deleteJobApplication: deleteApplication,
      reorderJobApplications: reorderJobApplications ??
          ReorderJobApplications(JobApplicationMemoryRepository()),
      getLicenses: getLicenses ?? GetLicenses(licenseRepository),
      addLicense: addLicense ?? AddLicense(licenseRepository),
      updateLicense: updateLicense ?? UpdateLicense(licenseRepository),
      deleteLicense: deleteLicense ?? DeleteLicense(licenseRepository),
      reorderLicenses: reorderLicenses ?? ReorderLicenses(licenseRepository),
      getCalendarEvents:
          getCalendarEvents ?? GetCalendarEvents(calendarRepository),
      addCalendarEvent:
          addCalendarEvent ?? AddCalendarEvent(calendarRepository),
      updateCalendarEvent:
          updateCalendarEvent ?? UpdateCalendarEvent(calendarRepository),
      deleteCalendarEvent:
          deleteCalendarEvent ?? DeleteCalendarEvent(calendarRepository),
      reorderCalendarEvents:
          reorderCalendarEvents ?? ReorderCalendarEvents(calendarRepository),
      getDiaries: getDiaries ?? GetDiaries(diaryRepository),
      saveDiary: saveDiary ?? SaveDiary(diaryRepository),
      deleteDiary: deleteDiary ?? DeleteDiary(diaryRepository),
      getLedgers: getLedgers ?? GetLedgers(ledgerRepository),
      saveLedger: saveLedger ?? SaveLedger(ledgerRepository),
      deleteLedger: deleteLedger ?? DeleteLedger(ledgerRepository),
      getEventCategories:
          getEventCategories ?? GetEventCategories(categoryRepository),
      addEventCategory:
          addEventCategory ?? AddEventCategory(categoryRepository),
      updateEventCategory:
          updateEventCategory ?? UpdateEventCategory(categoryRepository),
      deleteEventCategory:
          deleteEventCategory ?? DeleteEventCategory(categoryRepository),
      reorderEventCategories:
          reorderEventCategories ?? ReorderEventCategories(categoryRepository),
      getCompanyCategories: getCompanyCategories ??
          GetEventCategories(companyCategoryRepository),
      addCompanyCategory:
          addCompanyCategory ?? AddEventCategory(companyCategoryRepository),
      updateCompanyCategory: updateCompanyCategory ??
          UpdateEventCategory(companyCategoryRepository),
      deleteCompanyCategory: deleteCompanyCategory ??
          DeleteEventCategory(companyCategoryRepository),
      reorderCompanyCategories: reorderCompanyCategories ??
          ReorderEventCategories(companyCategoryRepository),
      getLedgerCategories: getLedgerCategories ??
          GetEventCategories(ledgerCategoryRepository),
      addLedgerCategory:
          addLedgerCategory ?? AddEventCategory(ledgerCategoryRepository),
      updateLedgerCategory: updateLedgerCategory ??
          UpdateEventCategory(ledgerCategoryRepository),
      deleteLedgerCategory: deleteLedgerCategory ??
          DeleteEventCategory(ledgerCategoryRepository),
      reorderLedgerCategories: reorderLedgerCategories ??
          ReorderEventCategories(ledgerCategoryRepository),
      getLicenseCategories: getLicenseCategories ??
          GetEventCategories(licenseCategoryRepository),
      addLicenseCategory:
          addLicenseCategory ?? AddEventCategory(licenseCategoryRepository),
      updateLicenseCategory: updateLicenseCategory ??
          UpdateEventCategory(licenseCategoryRepository),
      deleteLicenseCategory: deleteLicenseCategory ??
          DeleteEventCategory(licenseCategoryRepository),
      reorderLicenseCategories: reorderLicenseCategories ??
          ReorderEventCategories(licenseCategoryRepository),
      jobViewPreference: jobViewPreference ?? JobViewPreference(),
      licenseViewPreference: licenseViewPreference ?? LicenseViewPreference(),
      homeViewPreference: homeViewPreference ?? HomeViewPreference(),
      longGoalStore: longGoalStore ?? LongGoalLocalDataSource(),
      memoStore: memoStore ?? HomeMemoLocalDataSource(),
      dayEmojiStore: dayEmojiStore ?? DayEmojiStore(),
      dayEventsViewPreference:
          dayEventsViewPreference ?? DayEventsViewPreference(),
      calendarPreference: calendarPreference ?? CalendarPreference(),
      categorySuggestPreference:
          categorySuggestPreference ?? CategorySuggestPreference(),
      fontPreference: fontPreference ?? FontPreference(),
      notificationPreference:
          notificationPreference ?? NotificationPreference(),
      themePreference: themePreference ?? ThemePreference(),
      widgetPreference: widgetPreference ?? WidgetPreference(),
      navPreference: navPreference ?? NavPreference(),
      wordmarkPreference: wordmarkPreference ?? WordmarkPreference(),
      backupPreference: backupPreference ?? BackupPreference(),
      child: const _TutorialHost(
        child: _JobPlannerMaterialApp(),
      ),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  GetJobApplications? _getJobApplications;
  AddJobApplication? _addJobApplication;
  UpdateJobApplication? _updateJobApplication;
  DeleteJobApplication? _deleteJobApplication;
  ReorderJobApplications? _reorderJobApplications;
  GetLicenses? _getLicenses;
  AddLicense? _addLicense;
  UpdateLicense? _updateLicense;
  DeleteLicense? _deleteLicense;
  ReorderLicenses? _reorderLicenses;
  GetCalendarEvents? _getCalendarEvents;
  AddCalendarEvent? _addCalendarEvent;
  UpdateCalendarEvent? _updateCalendarEvent;
  DeleteCalendarEvent? _deleteCalendarEvent;
  ReorderCalendarEvents? _reorderCalendarEvents;
  GetDiaries? _getDiaries;
  SaveDiary? _saveDiary;
  DeleteDiary? _deleteDiary;
  GetLedgers? _getLedgers;
  SaveLedger? _saveLedger;
  DeleteLedger? _deleteLedger;
  GetEventCategories? _getEventCategories;
  AddEventCategory? _addEventCategory;
  UpdateEventCategory? _updateEventCategory;
  DeleteEventCategory? _deleteEventCategory;
  ReorderEventCategories? _reorderEventCategories;
  GetEventCategories? _getCompanyCategories;
  AddEventCategory? _addCompanyCategory;
  UpdateEventCategory? _updateCompanyCategory;
  DeleteEventCategory? _deleteCompanyCategory;
  ReorderEventCategories? _reorderCompanyCategories;
  GetEventCategories? _getLedgerCategories;
  AddEventCategory? _addLedgerCategory;
  UpdateEventCategory? _updateLedgerCategory;
  DeleteEventCategory? _deleteLedgerCategory;
  ReorderEventCategories? _reorderLedgerCategories;
  GetEventCategories? _getLicenseCategories;
  AddEventCategory? _addLicenseCategory;
  UpdateEventCategory? _updateLicenseCategory;
  DeleteEventCategory? _deleteLicenseCategory;
  ReorderEventCategories? _reorderLicenseCategories;
  JobViewPreference? _jobViewPreference;
  LicenseViewPreference? _licenseViewPreference;
  HomeViewPreference? _homeViewPreference;
  LongGoalLocalDataSource? _longGoalStore;
  HomeMemoLocalDataSource? _memoStore;
  DayEmojiStore? _dayEmojiStore;
  DayEventsViewPreference? _dayEventsViewPreference;
  CalendarPreference? _calendarPreference;
  CategorySuggestPreference? _categorySuggestPreference;
  FontPreference? _fontPreference;
  NotificationPreference? _notificationPreference;
  ThemePreference? _themePreference;
  WidgetPreference? _widgetPreference;
  NavPreference? _navPreference;
  WordmarkPreference? _wordmarkPreference;
  BackupPreference? _backupPreference;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final eventDataSource = CalendarEventLocalDataSource(prefs);
    await eventDataSource.seedStartersIfNeeded();
    final diaryDataSource = DiaryLocalDataSource(prefs);
    final ledgerDataSource = LedgerLocalDataSource(prefs);
    final jobDataSource = JobApplicationLocalDataSource(prefs);
    final licenseDataSource = LicenseLocalDataSource(prefs);
    final notificationPreference = NotificationPreference(prefs: prefs);
    await TodoReminderService.instance.init(
      events: eventDataSource,
      jobs: jobDataSource,
      preference: notificationPreference,
    );
    final themePreference = ThemePreference(prefs: prefs);
    await themePreference.seedStartersIfNeeded();
    final backupPreference = BackupPreference(prefs: prefs);
    final categoryDataSource = EventCategoryLocalDataSource(prefs);
    final companyCategoryDataSource = EventCategoryLocalDataSource(
      prefs,
      key: EventCategoryLocalDataSource.companyKey,
      presets: EventCategory.companyPresets,
      syncHomeWidget: false,
    );
    final ledgerCategoryDataSource = EventCategoryLocalDataSource(
      prefs,
      key: EventCategoryLocalDataSource.ledgerKey,
      presets: EventCategory.ledgerPresets,
      syncHomeWidget: false,
    );
    final licenseCategoryDataSource = EventCategoryLocalDataSource(
      prefs,
      key: EventCategoryLocalDataSource.licenseKey,
      presets: EventCategory.licensePresets,
      syncHomeWidget: false,
    );
    final homeViewPreference = HomeViewPreference(prefs: prefs);
    final longGoalStore = LongGoalLocalDataSource(prefs: prefs);
    final memoStore = HomeMemoLocalDataSource(prefs: prefs);
    final dayEmojiStore = DayEmojiStore(prefs: prefs);
    final dayEventsViewPreference = DayEventsViewPreference(prefs: prefs);
    final calendarPreference = CalendarPreference(prefs: prefs);
    final categorySuggestPreference = CategorySuggestPreference(prefs: prefs);
    final fontPreference = FontPreference(prefs: prefs);
    final widgetPreference = WidgetPreference(prefs: prefs);
    final navPreference = NavPreference(prefs: prefs);
    final wordmarkPreference = WordmarkPreference(prefs: prefs);
    await HomeScreenWidgetService.instance.init(
      events: eventDataSource,
      jobs: jobDataSource,
      categories: categoryDataSource,
      theme: themePreference,
      homeView: homeViewPreference,
      dayEventsView: dayEventsViewPreference,
      font: fontPreference,
      calendar: calendarPreference,
      nav: navPreference,
      widget: widgetPreference,
    );

    final jobRepository = JobApplicationRepositoryImpl(jobDataSource);
    final licenseRepository = LicenseRepositoryImpl(licenseDataSource);
    final eventRepository = CalendarEventRepositoryImpl(eventDataSource);
    final diaryRepository = DiaryRepositoryImpl(diaryDataSource);
    final ledgerRepository = LedgerRepositoryImpl(ledgerDataSource);
    final categoryRepository = EventCategoryRepositoryImpl(categoryDataSource);
    final companyCategoryRepository =
        EventCategoryRepositoryImpl(companyCategoryDataSource);
    final ledgerCategoryRepository =
        EventCategoryRepositoryImpl(ledgerCategoryDataSource);
    final licenseCategoryRepository =
        EventCategoryRepositoryImpl(licenseCategoryDataSource);
    if (!mounted) return;
    setState(() {
      _getJobApplications = GetJobApplications(jobRepository);
      _addJobApplication = AddJobApplication(jobRepository);
      _updateJobApplication = UpdateJobApplication(jobRepository);
      _deleteJobApplication = DeleteJobApplication(jobRepository);
      _reorderJobApplications = ReorderJobApplications(jobRepository);
      _getLicenses = GetLicenses(licenseRepository);
      _addLicense = AddLicense(licenseRepository);
      _updateLicense = UpdateLicense(licenseRepository);
      _deleteLicense = DeleteLicense(licenseRepository);
      _reorderLicenses = ReorderLicenses(licenseRepository);
      _getCalendarEvents = GetCalendarEvents(eventRepository);
      _addCalendarEvent = AddCalendarEvent(eventRepository);
      FriendService.instance.bindCalendar(
        read: eventRepository.getAll,
        add: eventRepository.add,
        update: eventRepository.update,
        write: eventRepository.replaceAll,
        onChanged: () => AppBackupService.revision.value++,
      );
      _updateCalendarEvent = UpdateCalendarEvent(eventRepository);
      _deleteCalendarEvent = DeleteCalendarEvent(eventRepository);
      _reorderCalendarEvents = ReorderCalendarEvents(eventRepository);
      _getDiaries = GetDiaries(diaryRepository);
      _saveDiary = SaveDiary(diaryRepository);
      _deleteDiary = DeleteDiary(diaryRepository);
      _getLedgers = GetLedgers(ledgerRepository);
      _saveLedger = SaveLedger(ledgerRepository);
      _deleteLedger = DeleteLedger(ledgerRepository);
      _getEventCategories = GetEventCategories(categoryRepository);
      _addEventCategory = AddEventCategory(categoryRepository);
      _updateEventCategory = UpdateEventCategory(categoryRepository);
      _deleteEventCategory = DeleteEventCategory(categoryRepository);
      _reorderEventCategories = ReorderEventCategories(categoryRepository);
      _getCompanyCategories = GetEventCategories(companyCategoryRepository);
      _addCompanyCategory = AddEventCategory(companyCategoryRepository);
      _updateCompanyCategory = UpdateEventCategory(companyCategoryRepository);
      _deleteCompanyCategory = DeleteEventCategory(companyCategoryRepository);
      _reorderCompanyCategories =
          ReorderEventCategories(companyCategoryRepository);
      _getLedgerCategories = GetEventCategories(ledgerCategoryRepository);
      _addLedgerCategory = AddEventCategory(ledgerCategoryRepository);
      _updateLedgerCategory = UpdateEventCategory(ledgerCategoryRepository);
      _deleteLedgerCategory = DeleteEventCategory(ledgerCategoryRepository);
      _reorderLedgerCategories =
          ReorderEventCategories(ledgerCategoryRepository);
      _getLicenseCategories = GetEventCategories(licenseCategoryRepository);
      _addLicenseCategory = AddEventCategory(licenseCategoryRepository);
      _updateLicenseCategory = UpdateEventCategory(licenseCategoryRepository);
      _deleteLicenseCategory = DeleteEventCategory(licenseCategoryRepository);
      _reorderLicenseCategories =
          ReorderEventCategories(licenseCategoryRepository);
      _jobViewPreference = JobViewPreference(prefs: prefs);
      _licenseViewPreference = LicenseViewPreference(prefs: prefs);
      _homeViewPreference = homeViewPreference;
      _longGoalStore = longGoalStore;
      _memoStore = memoStore;
      _dayEmojiStore = dayEmojiStore;
      _dayEventsViewPreference = dayEventsViewPreference;
      _calendarPreference = calendarPreference;
      _categorySuggestPreference = categorySuggestPreference;
      _fontPreference = fontPreference;
      _notificationPreference = notificationPreference;
      _themePreference = themePreference;
      _widgetPreference = widgetPreference;
      _navPreference = navPreference;
      _wordmarkPreference = wordmarkPreference;
      _backupPreference = backupPreference;
      _prefs = prefs;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _afterFirstFrame(notificationPreference, backupPreference);
    });
  }

  Future<void> _afterFirstFrame(
    NotificationPreference preference,
    BackupPreference backupPreference,
  ) async {
    if (!mounted) return;
    final wantsNotifications = preference.todoReminderLead.isEnabled ||
        preference.summaryEnabled ||
        preference.leftoverEnabled;
    if (wantsNotifications) {
      await TodoReminderService.instance.requestPermission(
        requestExactAlarms: false,
      );
      if (!mounted) return;
    }
    await TodoReminderService.instance.sync();
    await HomeScreenWidgetService.instance.sync();
    unawaited(AppBackupService.runAutoIfDue(backupPreference));
  }

  @override
  Widget build(BuildContext context) {
    final getApplications = _getJobApplications;
    final addApplication = _addJobApplication;
    final updateApplication = _updateJobApplication;
    final deleteApplication = _deleteJobApplication;
    final reorderApplications = _reorderJobApplications;
    final getLicenses = _getLicenses;
    final addLicense = _addLicense;
    final updateLicense = _updateLicense;
    final deleteLicense = _deleteLicense;
    final reorderLicenses = _reorderLicenses;
    final getEvents = _getCalendarEvents;
    final addEvent = _addCalendarEvent;
    final updateEvent = _updateCalendarEvent;
    final deleteEvent = _deleteCalendarEvent;
    final reorderEvents = _reorderCalendarEvents;
    final getDiaries = _getDiaries;
    final saveDiary = _saveDiary;
    final deleteDiary = _deleteDiary;
    final getLedgers = _getLedgers;
    final saveLedger = _saveLedger;
    final deleteLedger = _deleteLedger;
    final getCategories = _getEventCategories;
    final addCategory = _addEventCategory;
    final updateCategory = _updateEventCategory;
    final deleteCategory = _deleteEventCategory;
    final reorderCategory = _reorderEventCategories;
    final getCompanyCategories = _getCompanyCategories;
    final addCompanyCategory = _addCompanyCategory;
    final updateCompanyCategory = _updateCompanyCategory;
    final deleteCompanyCategory = _deleteCompanyCategory;
    final reorderCompanyCategories = _reorderCompanyCategories;
    final getLedgerCategories = _getLedgerCategories;
    final addLedgerCategory = _addLedgerCategory;
    final updateLedgerCategory = _updateLedgerCategory;
    final deleteLedgerCategory = _deleteLedgerCategory;
    final reorderLedgerCategories = _reorderLedgerCategories;
    final getLicenseCategories = _getLicenseCategories;
    final addLicenseCategory = _addLicenseCategory;
    final updateLicenseCategory = _updateLicenseCategory;
    final deleteLicenseCategory = _deleteLicenseCategory;
    final reorderLicenseCategories = _reorderLicenseCategories;
    final jobViewPreference = _jobViewPreference;
    final licenseViewPreference = _licenseViewPreference;
    final homeViewPreference = _homeViewPreference;
    final longGoalStore = _longGoalStore;
    final memoStore = _memoStore;
    final dayEmojiStore = _dayEmojiStore;
    final dayEventsViewPreference = _dayEventsViewPreference;
    final calendarPreference = _calendarPreference;
    final categorySuggestPreference = _categorySuggestPreference;
    final fontPreference = _fontPreference;
    final notificationPreference = _notificationPreference;
    final themePreference = _themePreference;
    final widgetPreference = _widgetPreference;
    final navPreference = _navPreference;
    final wordmarkPreference = _wordmarkPreference;
    final backupPreference = _backupPreference;

    if (getApplications == null ||
        addApplication == null ||
        updateApplication == null ||
        deleteApplication == null ||
        reorderApplications == null ||
        getLicenses == null ||
        addLicense == null ||
        updateLicense == null ||
        deleteLicense == null ||
        reorderLicenses == null ||
        getEvents == null ||
        addEvent == null ||
        updateEvent == null ||
        deleteEvent == null ||
        reorderEvents == null ||
        getDiaries == null ||
        saveDiary == null ||
        deleteDiary == null ||
        getLedgers == null ||
        saveLedger == null ||
        deleteLedger == null ||
        getCategories == null ||
        addCategory == null ||
        updateCategory == null ||
        deleteCategory == null ||
        reorderCategory == null ||
        getCompanyCategories == null ||
        addCompanyCategory == null ||
        updateCompanyCategory == null ||
        deleteCompanyCategory == null ||
        reorderCompanyCategories == null ||
        getLedgerCategories == null ||
        addLedgerCategory == null ||
        updateLedgerCategory == null ||
        deleteLedgerCategory == null ||
        reorderLedgerCategories == null ||
        getLicenseCategories == null ||
        addLicenseCategory == null ||
        updateLicenseCategory == null ||
        deleteLicenseCategory == null ||
        reorderLicenseCategories == null ||
        jobViewPreference == null ||
        licenseViewPreference == null ||
        homeViewPreference == null ||
        longGoalStore == null ||
        memoStore == null ||
        dayEmojiStore == null ||
        dayEventsViewPreference == null ||
        calendarPreference == null ||
        categorySuggestPreference == null ||
        fontPreference == null ||
        notificationPreference == null ||
        themePreference == null ||
        widgetPreference == null ||
        navPreference == null ||
        wordmarkPreference == null ||
        backupPreference == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        color: Color(0xFFF8FAFC),
        home: Scaffold(
          backgroundColor: Color(0xFFF8FAFC),
          body: DotsLoadingDialog(),
        ),
      );
    }

    return AppScope(
      getJobApplications: getApplications,
      addJobApplication: addApplication,
      updateJobApplication: updateApplication,
      deleteJobApplication: deleteApplication,
      reorderJobApplications: reorderApplications,
      getLicenses: getLicenses,
      addLicense: addLicense,
      updateLicense: updateLicense,
      deleteLicense: deleteLicense,
      reorderLicenses: reorderLicenses,
      getCalendarEvents: getEvents,
      addCalendarEvent: addEvent,
      updateCalendarEvent: updateEvent,
      deleteCalendarEvent: deleteEvent,
      reorderCalendarEvents: reorderEvents,
      getDiaries: getDiaries,
      saveDiary: saveDiary,
      deleteDiary: deleteDiary,
      getLedgers: getLedgers,
      saveLedger: saveLedger,
      deleteLedger: deleteLedger,
      getEventCategories: getCategories,
      addEventCategory: addCategory,
      updateEventCategory: updateCategory,
      deleteEventCategory: deleteCategory,
      reorderEventCategories: reorderCategory,
      getCompanyCategories: getCompanyCategories,
      addCompanyCategory: addCompanyCategory,
      updateCompanyCategory: updateCompanyCategory,
      deleteCompanyCategory: deleteCompanyCategory,
      reorderCompanyCategories: reorderCompanyCategories,
      getLedgerCategories: getLedgerCategories,
      addLedgerCategory: addLedgerCategory,
      updateLedgerCategory: updateLedgerCategory,
      deleteLedgerCategory: deleteLedgerCategory,
      reorderLedgerCategories: reorderLedgerCategories,
      getLicenseCategories: getLicenseCategories,
      addLicenseCategory: addLicenseCategory,
      updateLicenseCategory: updateLicenseCategory,
      deleteLicenseCategory: deleteLicenseCategory,
      reorderLicenseCategories: reorderLicenseCategories,
      jobViewPreference: jobViewPreference,
      licenseViewPreference: licenseViewPreference,
      homeViewPreference: homeViewPreference,
      longGoalStore: longGoalStore,
      memoStore: memoStore,
      dayEmojiStore: dayEmojiStore,
      dayEventsViewPreference: dayEventsViewPreference,
      calendarPreference: calendarPreference,
      categorySuggestPreference: categorySuggestPreference,
      fontPreference: fontPreference,
      notificationPreference: notificationPreference,
      themePreference: themePreference,
      widgetPreference: widgetPreference,
      navPreference: navPreference,
      wordmarkPreference: wordmarkPreference,
      backupPreference: backupPreference,
      child: _TutorialHost(
        prefs: _prefs,
        child: const _JobPlannerMaterialApp(),
      ),
    );
  }
}

class _TutorialHost extends StatefulWidget {
  const _TutorialHost({required this.child, this.prefs});

  final Widget child;
  final SharedPreferences? prefs;

  @override
  State<_TutorialHost> createState() => _TutorialHostState();
}

class _TutorialHostState extends State<_TutorialHost> {
  late final TutorialController _controller = TutorialController(
    TutorialPreference(prefs: widget.prefs),
  );
  NavPreference? _nav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = AppScope.of(context).navPreference;
    if (identical(nav, _nav)) return;
    _nav?.removeListener(_syncNav);
    _nav = nav;
    _nav!.addListener(_syncNav);
    _controller.setHideJobTab(!nav.showJobTab);
    _controller.setHideStatsTab(!nav.showStatsTab);
  }

  void _syncNav() {
    _controller.setHideJobTab(!(_nav?.showJobTab ?? false));
    _controller.setHideStatsTab(!(_nav?.showStatsTab ?? true));
  }

  @override
  void dispose() {
    _nav?.removeListener(_syncNav);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialScope(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _JobPlannerMaterialApp extends StatefulWidget {
  const _JobPlannerMaterialApp();

  @override
  State<_JobPlannerMaterialApp> createState() => _JobPlannerMaterialAppState();
}

class _JobPlannerMaterialAppState extends State<_JobPlannerMaterialApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CloudSyncService.instance.attach(AppScope.of(context));
      if (!kIsWeb) unawaited(ensureCloudBound(context));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      AppBackupService.runAutoIfDue(AppScope.of(context).backupPreference),
    );
    unawaited(CloudSyncService.instance.onResumed());
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).themePreference;
    final font = AppScope.of(context).fontPreference;
    return ListenableBuilder(
      listenable: Listenable.merge([theme, font.appearanceListenable]),
      builder: (context, _) {
        return StreamBuilder(
          stream: AppAuthService.instance.authState,
          initialData: AppAuthService.instance.user,
          builder: (context, auth) {
            final guest = kIsWeb && auth.data == null;
            final typeface = guest ? AppTypeface.pretendard : font.typeface;
            final skin = guest ? AppSkin.classic : theme.skin;
            final accent = guest ? null : theme.customTheme?.accentColor;
            final lightTheme = AppTheme.themed(
              dark: false,
              typeface: typeface,
              skin: skin,
              customAccent: accent,
            );
            final darkTheme = AppTheme.themed(
              dark: true,
              typeface: typeface,
              skin: skin,
              customAccent: accent,
            );
            final themeMode = guest ? ThemeMode.light : theme.mode;
            final useDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    WidgetsBinding
                            .instance.platformDispatcher.platformBrightness ==
                        Brightness.dark);
            final chromeColor = (useDark ? darkTheme : lightTheme)
                .scaffoldBackgroundColor;
            return MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              color: chromeColor,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
          locale: const Locale('ko', 'KR'),
          supportedLocales: const [Locale('ko', 'KR')],
          builder: (context, child) {
            final overlay = Theme.of(context).appBarTheme.systemOverlayStyle;
            final background = Theme.of(context).scaffoldBackgroundColor;
            if (overlay != null) {
              SystemChrome.setSystemUIOverlayStyle(overlay);
            }
            if (kIsWeb) {
              SystemChrome.setApplicationSwitcherDescription(
                ApplicationSwitcherDescription(
                  label: AppStrings.appName,
                  primaryColor: background.toARGB32(),
                ),
              );
              syncWebThemeColor(background);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                syncWebThemeColor(background);
              });
            }
            return ListenableBuilder(
              listenable: font,
              builder: (context, _) {
                return FontScope(
                  typeface: typeface,
                  todoScale: guest ? 1 : font.todoScale,
                  labelScale: guest ? 1 : font.labelScale,
                  calendarScale: guest ? 1 : font.calendarScale,
                  calendarLabelScale: guest ? 1 : font.calendarLabelScale,
                  calendarDateScale: guest ? 1 : font.calendarDateScale,
                  child: overlay == null
                      ? (child ?? const SizedBox.shrink())
                      : AnnotatedRegion<SystemUiOverlayStyle>(
                          value: overlay,
                          child: child ?? const SizedBox.shrink(),
                        ),
                );
              },
            );
          },
          home: kIsWeb ? const WebAuthGate() : const ShellScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
            );
          },
        );
      },
    );
  }
}
