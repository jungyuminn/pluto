import 'package:flutter/material.dart';
import 'package:job_planner/data/datasources/calendar_preference.dart';
import 'package:job_planner/data/datasources/day_events_view_preference.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/home_view_preference.dart';
import 'package:job_planner/data/datasources/job_view_preference.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
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
    required this.getEventCategories,
    required this.addEventCategory,
    required this.updateEventCategory,
    required this.deleteEventCategory,
    required this.reorderEventCategories,
    required this.jobViewPreference,
    required this.homeViewPreference,
    required this.dayEventsViewPreference,
    required this.calendarPreference,
    required this.fontPreference,
    required this.notificationPreference,
    required this.themePreference,
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
  final GetEventCategories getEventCategories;
  final AddEventCategory addEventCategory;
  final UpdateEventCategory updateEventCategory;
  final DeleteEventCategory deleteEventCategory;
  final ReorderEventCategories reorderEventCategories;
  final JobViewPreference jobViewPreference;
  final HomeViewPreference homeViewPreference;
  final DayEventsViewPreference dayEventsViewPreference;
  final CalendarPreference calendarPreference;
  final FontPreference fontPreference;
  final NotificationPreference notificationPreference;
  final ThemePreference themePreference;

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
        getEventCategories != oldWidget.getEventCategories ||
        addEventCategory != oldWidget.addEventCategory ||
        updateEventCategory != oldWidget.updateEventCategory ||
        deleteEventCategory != oldWidget.deleteEventCategory ||
        reorderEventCategories != oldWidget.reorderEventCategories ||
        jobViewPreference != oldWidget.jobViewPreference ||
        homeViewPreference != oldWidget.homeViewPreference ||
        dayEventsViewPreference != oldWidget.dayEventsViewPreference ||
        calendarPreference != oldWidget.calendarPreference ||
        fontPreference != oldWidget.fontPreference ||
        notificationPreference != oldWidget.notificationPreference ||
        themePreference != oldWidget.themePreference;
  }
}
