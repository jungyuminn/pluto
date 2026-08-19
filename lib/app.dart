import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/core/theme/app_theme.dart';
import 'package:job_planner/data/datasources/calendar_preference.dart';
import 'package:job_planner/data/datasources/calendar_event_local_datasource.dart';
import 'package:job_planner/data/datasources/event_category_local_datasource.dart';
import 'package:job_planner/data/datasources/day_events_view_preference.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/home_view_preference.dart';
import 'package:job_planner/data/datasources/job_view_preference.dart';
import 'package:job_planner/data/datasources/job_application_local_datasource.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:job_planner/data/repositories/calendar_event_memory_repository.dart';
import 'package:job_planner/data/repositories/calendar_event_repository_impl.dart';
import 'package:job_planner/data/repositories/event_category_memory_repository.dart';
import 'package:job_planner/data/repositories/event_category_repository_impl.dart';
import 'package:job_planner/data/repositories/job_application_memory_repository.dart';
import 'package:job_planner/data/repositories/job_application_repository_impl.dart';
import 'package:job_planner/domain/usecases/add_calendar_event.dart';
import 'package:job_planner/domain/usecases/add_event_category.dart';
import 'package:job_planner/domain/usecases/delete_event_category.dart';
import 'package:job_planner/domain/usecases/add_job_application.dart';
import 'package:job_planner/domain/usecases/delete_calendar_event.dart';
import 'package:job_planner/domain/usecases/delete_job_application.dart';
import 'package:job_planner/domain/usecases/get_calendar_events.dart';
import 'package:job_planner/domain/usecases/get_event_categories.dart';
import 'package:job_planner/domain/usecases/get_job_applications.dart';
import 'package:job_planner/domain/usecases/reorder_calendar_events.dart';
import 'package:job_planner/domain/usecases/reorder_job_applications.dart';
import 'package:job_planner/domain/usecases/reorder_event_categories.dart';
import 'package:job_planner/domain/usecases/update_calendar_event.dart';
import 'package:job_planner/domain/usecases/update_event_category.dart';
import 'package:job_planner/domain/usecases/update_job_application.dart';
import 'package:job_planner/presentation/screens/shell/shell_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobPlannerApp extends StatelessWidget {
  const JobPlannerApp({
    super.key,
    this.getJobApplications,
    this.addJobApplication,
    this.updateJobApplication,
    this.deleteJobApplication,
    this.reorderJobApplications,
    this.getCalendarEvents,
    this.addCalendarEvent,
    this.updateCalendarEvent,
    this.deleteCalendarEvent,
    this.reorderCalendarEvents,
    this.getEventCategories,
    this.addEventCategory,
    this.updateEventCategory,
    this.deleteEventCategory,
    this.reorderEventCategories,
    this.jobViewPreference,
    this.homeViewPreference,
    this.dayEventsViewPreference,
    this.calendarPreference,
    this.fontPreference,
    this.notificationPreference,
    this.themePreference,
  });

  final GetJobApplications? getJobApplications;
  final AddJobApplication? addJobApplication;
  final UpdateJobApplication? updateJobApplication;
  final DeleteJobApplication? deleteJobApplication;
  final ReorderJobApplications? reorderJobApplications;
  final GetCalendarEvents? getCalendarEvents;
  final AddCalendarEvent? addCalendarEvent;
  final UpdateCalendarEvent? updateCalendarEvent;
  final DeleteCalendarEvent? deleteCalendarEvent;
  final ReorderCalendarEvents? reorderCalendarEvents;
  final GetEventCategories? getEventCategories;
  final AddEventCategory? addEventCategory;
  final UpdateEventCategory? updateEventCategory;
  final DeleteEventCategory? deleteEventCategory;
  final ReorderEventCategories? reorderEventCategories;
  final JobViewPreference? jobViewPreference;
  final HomeViewPreference? homeViewPreference;
  final DayEventsViewPreference? dayEventsViewPreference;
  final CalendarPreference? calendarPreference;
  final FontPreference? fontPreference;
  final NotificationPreference? notificationPreference;
  final ThemePreference? themePreference;

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
    final categoryRepository = EventCategoryMemoryRepository();
    return AppScope(
      getJobApplications: getApplications,
      addJobApplication: addApplication,
      updateJobApplication: updateApplication,
      deleteJobApplication: deleteApplication,
      reorderJobApplications: reorderJobApplications ??
          ReorderJobApplications(JobApplicationMemoryRepository()),
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
      jobViewPreference: jobViewPreference ?? JobViewPreference(),
      homeViewPreference: homeViewPreference ?? HomeViewPreference(),
      dayEventsViewPreference:
          dayEventsViewPreference ?? DayEventsViewPreference(),
      calendarPreference: calendarPreference ?? CalendarPreference(),
      fontPreference: fontPreference ?? FontPreference(),
      notificationPreference:
          notificationPreference ?? NotificationPreference(),
      themePreference: themePreference ?? ThemePreference(),
      child: const _JobPlannerMaterialApp(),
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
  GetCalendarEvents? _getCalendarEvents;
  AddCalendarEvent? _addCalendarEvent;
  UpdateCalendarEvent? _updateCalendarEvent;
  DeleteCalendarEvent? _deleteCalendarEvent;
  ReorderCalendarEvents? _reorderCalendarEvents;
  GetEventCategories? _getEventCategories;
  AddEventCategory? _addEventCategory;
  UpdateEventCategory? _updateEventCategory;
  DeleteEventCategory? _deleteEventCategory;
  ReorderEventCategories? _reorderEventCategories;
  JobViewPreference? _jobViewPreference;
  HomeViewPreference? _homeViewPreference;
  DayEventsViewPreference? _dayEventsViewPreference;
  CalendarPreference? _calendarPreference;
  FontPreference? _fontPreference;
  NotificationPreference? _notificationPreference;
  ThemePreference? _themePreference;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final eventDataSource = CalendarEventLocalDataSource(prefs);
    final jobDataSource = JobApplicationLocalDataSource(prefs);
    final notificationPreference = NotificationPreference(prefs: prefs);
    await TodoReminderService.instance.init(
      events: eventDataSource,
      jobs: jobDataSource,
      preference: notificationPreference,
    );
    final themePreference = ThemePreference(prefs: prefs);
    final categoryDataSource = EventCategoryLocalDataSource(prefs);
    final homeViewPreference = HomeViewPreference(prefs: prefs);
    final dayEventsViewPreference = DayEventsViewPreference(prefs: prefs);
    final calendarPreference = CalendarPreference(prefs: prefs);
    final fontPreference = FontPreference(prefs: prefs);
    await HomeScreenWidgetService.instance.init(
      events: eventDataSource,
      jobs: jobDataSource,
      categories: categoryDataSource,
      theme: themePreference,
      homeView: homeViewPreference,
      dayEventsView: dayEventsViewPreference,
      font: fontPreference,
    );

    final jobRepository = JobApplicationRepositoryImpl(jobDataSource);
    final eventRepository = CalendarEventRepositoryImpl(eventDataSource);
    final categoryRepository = EventCategoryRepositoryImpl(categoryDataSource);
    if (!mounted) return;
    setState(() {
      _getJobApplications = GetJobApplications(jobRepository);
      _addJobApplication = AddJobApplication(jobRepository);
      _updateJobApplication = UpdateJobApplication(jobRepository);
      _deleteJobApplication = DeleteJobApplication(jobRepository);
      _reorderJobApplications = ReorderJobApplications(jobRepository);
      _getCalendarEvents = GetCalendarEvents(eventRepository);
      _addCalendarEvent = AddCalendarEvent(eventRepository);
      _updateCalendarEvent = UpdateCalendarEvent(eventRepository);
      _deleteCalendarEvent = DeleteCalendarEvent(eventRepository);
      _reorderCalendarEvents = ReorderCalendarEvents(eventRepository);
      _getEventCategories = GetEventCategories(categoryRepository);
      _addEventCategory = AddEventCategory(categoryRepository);
      _updateEventCategory = UpdateEventCategory(categoryRepository);
      _deleteEventCategory = DeleteEventCategory(categoryRepository);
      _reorderEventCategories = ReorderEventCategories(categoryRepository);
      _jobViewPreference = JobViewPreference(prefs: prefs);
      _homeViewPreference = homeViewPreference;
      _dayEventsViewPreference = dayEventsViewPreference;
      _calendarPreference = calendarPreference;
      _fontPreference = fontPreference;
      _notificationPreference = notificationPreference;
      _themePreference = themePreference;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _afterFirstFrame(notificationPreference);
    });
  }

  Future<void> _afterFirstFrame(NotificationPreference preference) async {
    if (!mounted) return;
    await TodoReminderService.instance.sync();
    if (!mounted) return;
    if (preference.todoReminderLead.isEnabled || preference.summaryEnabled) {
      await TodoReminderService.instance.requestPermission(
        requestExactAlarms: false,
      );
      if (!mounted) return;
      await TodoReminderService.instance.sync();
    }
    await HomeScreenWidgetService.instance.sync();
  }

  @override
  Widget build(BuildContext context) {
    final getApplications = _getJobApplications;
    final addApplication = _addJobApplication;
    final updateApplication = _updateJobApplication;
    final deleteApplication = _deleteJobApplication;
    final reorderApplications = _reorderJobApplications;
    final getEvents = _getCalendarEvents;
    final addEvent = _addCalendarEvent;
    final updateEvent = _updateCalendarEvent;
    final deleteEvent = _deleteCalendarEvent;
    final reorderEvents = _reorderCalendarEvents;
    final getCategories = _getEventCategories;
    final addCategory = _addEventCategory;
    final updateCategory = _updateEventCategory;
    final deleteCategory = _deleteEventCategory;
    final reorderCategory = _reorderEventCategories;
    final jobViewPreference = _jobViewPreference;
    final homeViewPreference = _homeViewPreference;
    final dayEventsViewPreference = _dayEventsViewPreference;
    final calendarPreference = _calendarPreference;
    final fontPreference = _fontPreference;
    final notificationPreference = _notificationPreference;
    final themePreference = _themePreference;

    if (getApplications == null ||
        addApplication == null ||
        updateApplication == null ||
        deleteApplication == null ||
        reorderApplications == null ||
        getEvents == null ||
        addEvent == null ||
        updateEvent == null ||
        deleteEvent == null ||
        reorderEvents == null ||
        getCategories == null ||
        addCategory == null ||
        updateCategory == null ||
        deleteCategory == null ||
        reorderCategory == null ||
        jobViewPreference == null ||
        homeViewPreference == null ||
        dayEventsViewPreference == null ||
        calendarPreference == null ||
        fontPreference == null ||
        notificationPreference == null ||
        themePreference == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AppScope(
      getJobApplications: getApplications,
      addJobApplication: addApplication,
      updateJobApplication: updateApplication,
      deleteJobApplication: deleteApplication,
      reorderJobApplications: reorderApplications,
      getCalendarEvents: getEvents,
      addCalendarEvent: addEvent,
      updateCalendarEvent: updateEvent,
      deleteCalendarEvent: deleteEvent,
      reorderCalendarEvents: reorderEvents,
      getEventCategories: getCategories,
      addEventCategory: addCategory,
      updateEventCategory: updateCategory,
      deleteEventCategory: deleteCategory,
      reorderEventCategories: reorderCategory,
      jobViewPreference: jobViewPreference,
      homeViewPreference: homeViewPreference,
      dayEventsViewPreference: dayEventsViewPreference,
      calendarPreference: calendarPreference,
      fontPreference: fontPreference,
      notificationPreference: notificationPreference,
      themePreference: themePreference,
      child: const _JobPlannerMaterialApp(),
    );
  }
}

class _JobPlannerMaterialApp extends StatelessWidget {
  const _JobPlannerMaterialApp();

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).themePreference;
    final font = AppScope.of(context).fontPreference;
    return ListenableBuilder(
      listenable: Listenable.merge([theme, font]),
      builder: (context, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themed(dark: false, typeface: font.typeface),
          darkTheme: AppTheme.themed(dark: true, typeface: font.typeface),
          themeMode: theme.mode,
          locale: const Locale('ko', 'KR'),
          supportedLocales: const [Locale('ko', 'KR')],
          builder: (context, child) {
            return FontScope(
              typeface: font.typeface,
              todoScale: font.todoScale,
              labelScale: font.labelScale,
              calendarScale: font.calendarScale,
              calendarLabelScale: font.calendarLabelScale,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const ShellScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
