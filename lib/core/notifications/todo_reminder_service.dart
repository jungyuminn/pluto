import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/data/datasources/calendar_event_local_datasource.dart';
import 'package:job_planner/data/datasources/job_application_local_datasource.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class TodoReminderService {
  TodoReminderService._();

  static final instance = TodoReminderService._();

  static const _channelId = 'todo_reminders';
  static const _summaryChannelId = 'daily_summary';
  static const _androidIcon = 'ic_stat_notification';
  static const _maxScheduled = 64;
  static const _summaryIdBase = 91001000;
  static const _summaryDays = 7;

  final _plugin = FlutterLocalNotificationsPlugin();
  CalendarEventLocalDataSource? _events;
  JobApplicationLocalDataSource? _jobs;
  NotificationPreference? _preference;
  var _ready = false;
  var _syncing = false;
  var _queued = false;

  Future<void> init({
    required CalendarEventLocalDataSource events,
    required JobApplicationLocalDataSource jobs,
    required NotificationPreference preference,
  }) async {
    _events = events;
    _jobs = jobs;
    _preference = preference;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      }
      const android = AndroidInitializationSettings('@drawable/ic_stat_notification');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
        ),
      );
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          AppStrings.todoReminderChannelName,
          description: AppStrings.todoReminderChannelDescription,
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _summaryChannelId,
          AppStrings.summaryReminderChannelName,
          description: AppStrings.summaryReminderChannelDescription,
          importance: Importance.high,
        ),
      );
      _ready = true;
      if (preference.todoReminderLead.isEnabled || preference.summaryEnabled) {
        await requestPermission();
      }
    } catch (error, stack) {
      debugPrint('TodoReminderService.init failed: $error\n$stack');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notifications =
        await android?.requestNotificationsPermission() ?? true;
    await android?.requestExactAlarmsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosOk = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return notifications && iosOk;
  }

  Future<void> sync() async {
    if (!_ready) return;
    if (_syncing) {
      _queued = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _queued = false;
        await _syncOnce();
      } while (_queued);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    final events = _events;
    final jobs = _jobs;
    final preference = _preference;
    if (events == null || jobs == null || preference == null) return;
    try {
      await _plugin.cancelAll();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      await _scheduleTodos(events, preference, mode);
      await _scheduleSummaries(events, jobs, preference, mode);
    } catch (error, stack) {
      debugPrint('TodoReminderService.sync failed: $error\n$stack');
    }
  }

  Future<void> _scheduleTodos(
    CalendarEventLocalDataSource events,
    NotificationPreference preference,
    AndroidScheduleMode mode,
  ) async {
    final lead = preference.todoReminderLead;
    if (!lead.isEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final upcoming = <({int id, CalendarEvent event, tz.TZDateTime at})>[];
    for (final event in events.fetchAll()) {
      final at = _fireAt(event, lead.minutes);
      if (at == null || !at.isAfter(now)) continue;
      upcoming.add((id: _idFor(event.id), event: event, at: at));
    }
    upcoming.sort((a, b) => a.at.compareTo(b.at));

    for (final item in upcoming.take(_maxScheduled)) {
      try {
        await _plugin.zonedSchedule(
          item.id,
          item.event.title,
          AppStrings.todoReminderBody(lead.minutes),
          item.at,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              AppStrings.todoReminderChannelName,
              channelDescription: AppStrings.todoReminderChannelDescription,
              icon: _androidIcon,
              color: Color(0xFF3B82F6),
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: mode,
        );
      } catch (error, stack) {
        debugPrint('TodoReminderService.schedule failed: $error\n$stack');
      }
    }
  }

  Future<void> _scheduleSummaries(
    CalendarEventLocalDataSource events,
    JobApplicationLocalDataSource jobs,
    NotificationPreference preference,
    AndroidScheduleMode mode,
  ) async {
    if (!preference.summaryEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      preference.summaryHour,
      preference.summaryMinute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    final allEvents = events.fetchAll();
    final applications = jobs.fetchAll();
    for (var i = 0; i < _summaryDays; i++) {
      final at = next.add(Duration(days: i));
      final day = DateTime(at.year, at.month, at.day);
      final items = calendarEventsOn(
        date: day,
        events: allEvents,
        applications: applications,
      ).where((event) => event.isJob || !event.completed).toList();
      final lines = [
        for (final event in items.take(12)) _summaryLine(event),
      ];
      if (items.length > 12) {
        lines.add('외 ${items.length - 12}개');
      }
      final body = lines.isEmpty
          ? AppStrings.summaryNotificationEmpty
          : lines.join('\n');
      try {
        await _plugin.zonedSchedule(
          _summaryIdBase + i,
          AppStrings.summaryNotificationTitle(items.length),
          body,
          at,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _summaryChannelId,
              AppStrings.summaryReminderChannelName,
              channelDescription: AppStrings.summaryReminderChannelDescription,
              icon: _androidIcon,
              color: const Color(0xFF3B82F6),
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: mode,
        );
      } catch (error, stack) {
        debugPrint('TodoReminderService.summary failed: $error\n$stack');
      }
    }
  }

  String _summaryLine(CalendarEvent event) {
    if (event.isJob || !event.hasTime) return event.title;
    return '${AppStrings.summaryTimeLabel(event.startMinutes!)}  ${event.title}';
  }

  tz.TZDateTime? _fireAt(CalendarEvent event, int leadMinutes) {
    if (event.isJob || event.completed || !event.hasTime) return null;
    final start = event.startMinutes!;
    final day = event.day;
    final at = tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      start ~/ 60,
      start % 60,
    );
    return at.subtract(Duration(minutes: leadMinutes));
  }

  int _idFor(String eventId) => eventId.hashCode & 0x7fffffff;
}
