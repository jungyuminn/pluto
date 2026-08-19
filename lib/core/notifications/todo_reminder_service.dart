import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  var _canSchedule = false;
  var _syncing = false;
  var _queued = false;

  Future<void> init({
    required CalendarEventLocalDataSource events,
    required JobApplicationLocalDataSource jobs,
    required NotificationPreference preference,
    bool canSchedule = true,
  }) async {
    _events = events;
    _jobs = jobs;
    _preference = preference;
    try {
      await _configureLocalTimezone();
      var android = const AndroidInitializationSettings('@drawable/ic_stat_notification');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      try {
        await _plugin.initialize(
          InitializationSettings(android: android, iOS: darwin),
        );
      } catch (_) {
        android = const AndroidInitializationSettings('@mipmap/ic_launcher');
        await _plugin.initialize(
          InitializationSettings(android: android, iOS: darwin),
        );
      }
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
      _canSchedule = canSchedule;
    } catch (error, stack) {
      debugPrint('TodoReminderService.init failed: $error\n$stack');
    }
  }

  Future<bool> requestPermission({bool requestExactAlarms = true}) async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notifications =
        await android?.requestNotificationsPermission() ?? true;
    if (requestExactAlarms) {
      await android?.requestExactAlarmsPermission();
    }
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
    if (!_ready || !_canSchedule) return;
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

  Future<void> _configureLocalTimezone() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  }

  Future<void> _syncOnce() async {
    final events = _events;
    final jobs = _jobs;
    final preference = _preference;
    if (events == null || jobs == null || preference == null) return;
    try {
      final previous = await _plugin.pendingNotificationRequests();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      final scheduled = <int>{};
      scheduled.addAll(await _scheduleTodos(events, preference, mode));
      scheduled.addAll(await _scheduleSummaries(events, jobs, preference, mode));
      for (final item in previous) {
        if (!scheduled.contains(item.id)) {
          await _plugin.cancel(item.id);
        }
      }
    } catch (error, stack) {
      debugPrint('TodoReminderService.sync failed: $error\n$stack');
    }
  }

  Future<Set<int>> _scheduleTodos(
    CalendarEventLocalDataSource events,
    NotificationPreference preference,
    AndroidScheduleMode mode,
  ) async {
    final lead = preference.todoReminderLead;
    if (!lead.isEnabled) return {};

    final now = _now;
    final upcoming = <({int id, CalendarEvent event, tz.TZDateTime at})>[];
    for (final event in events.fetchAll()) {
      final at = _fireAt(event, lead.minutes);
      if (at == null || !at.isAfter(now)) continue;
      upcoming.add((id: _idFor(event.id), event: event, at: at));
    }
    upcoming.sort((a, b) => a.at.compareTo(b.at));

    final scheduled = <int>{};
    for (final item in upcoming.take(_maxScheduled)) {
      final ok = await _schedule(
        id: item.id,
        title: item.event.title,
        body: AppStrings.todoReminderBody(lead.minutes),
        at: item.at,
        channelId: _channelId,
        channelName: AppStrings.todoReminderChannelName,
        channelDescription: AppStrings.todoReminderChannelDescription,
        mode: mode,
      );
      if (ok) scheduled.add(item.id);
    }
    return scheduled;
  }

  Future<Set<int>> _scheduleSummaries(
    CalendarEventLocalDataSource events,
    JobApplicationLocalDataSource jobs,
    NotificationPreference preference,
    AndroidScheduleMode mode,
  ) async {
    if (!preference.summaryEnabled) return {};

    final now = _now;
    var next = _wallTime(
      now,
      hour: preference.summaryHour,
      minute: preference.summaryMinute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    final allEvents = events.fetchAll();
    final applications = jobs.fetchAll();
    final scheduled = <int>{};
    for (var i = 0; i < _summaryDays; i++) {
      final at = next.add(Duration(days: i));
      final day = DateTime(at.year, at.month, at.day);
      final items = CalendarEvent.withLockedThenStartTime(
        calendarEventsOn(
          date: day,
          events: allEvents,
          applications: applications,
        ).where((event) => event.isJob || !event.completed),
      );
      final lines = [
        for (final event in items.take(12)) _summaryLine(event),
      ];
      if (items.length > 12) {
        lines.add('외 ${items.length - 12}개');
      }
      final body = lines.isEmpty
          ? AppStrings.summaryNotificationEmpty
          : lines.join('\n');
      final id = _summaryIdBase + i;
      final ok = await _schedule(
        id: id,
        title: AppStrings.summaryNotificationTitle(items.length),
        body: body,
        at: at,
        channelId: _summaryChannelId,
        channelName: AppStrings.summaryReminderChannelName,
        channelDescription: AppStrings.summaryReminderChannelDescription,
        mode: mode,
        bigText: true,
      );
      if (ok) scheduled.add(id);
    }
    return scheduled;
  }

  Future<bool> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required AndroidScheduleMode mode,
    bool bigText = false,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        icon: _androidIcon,
        color: const Color(0xFF3B82F6),
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: bigText ? BigTextStyleInformation(body) : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    Future<void> run(AndroidScheduleMode scheduleMode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        at,
        details,
        androidScheduleMode: scheduleMode,
      );
    }

    try {
      await run(mode);
      return true;
    } catch (error, stack) {
      debugPrint('TodoReminderService.schedule failed: $error\n$stack');
      if (mode == AndroidScheduleMode.inexactAllowWhileIdle) return false;
      try {
        await run(AndroidScheduleMode.inexactAllowWhileIdle);
        return true;
      } catch (retryError, retryStack) {
        debugPrint(
          'TodoReminderService.schedule retry failed: $retryError\n$retryStack',
        );
        return false;
      }
    }
  }

  String _summaryLine(CalendarEvent event) {
    if (event.isJob || !event.hasTime) return event.title;
    return '${AppStrings.summaryTimeLabel(event.startMinutes!)}  ${event.title}';
  }

  tz.Location get _seoul => tz.getLocation('Asia/Seoul');

  tz.TZDateTime get _now => tz.TZDateTime.now(_seoul);

  tz.TZDateTime _wallTime(
    DateTime day, {
    int hour = 0,
    int minute = 0,
  }) {
    return tz.TZDateTime(_seoul, day.year, day.month, day.day, hour, minute);
  }

  tz.TZDateTime? _fireAt(CalendarEvent event, int leadMinutes) {
    if (event.isJob || event.completed || !event.hasTime) return null;
    final start = event.startMinutes!;
    final at = _wallTime(
      event.day,
      hour: start ~/ 60,
      minute: start % 60,
    );
    return at.subtract(Duration(minutes: leadMinutes));
  }

  int _idFor(String eventId) => eventId.hashCode & 0x7fffffff;
}
