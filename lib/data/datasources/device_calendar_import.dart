import 'package:flutter/services.dart';
import 'package:pluto/core/calendar/calendar_years.dart';
import 'package:pluto/data/datasources/device_calendar_mapper.dart';

enum DeviceCalendarPermission {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

class DeviceCalendarImport {
  DeviceCalendarImport._();

  static const _channel = MethodChannel('job_planner/device_calendar');

  static Future<DeviceCalendarPermission> requestPermission() async {
    try {
      final status = await _channel.invokeMethod<String>('requestPermission');
      return switch (status) {
        'granted' => DeviceCalendarPermission.granted,
        'permanentlyDenied' => DeviceCalendarPermission.permanentlyDenied,
        'denied' => DeviceCalendarPermission.denied,
        _ => DeviceCalendarPermission.denied,
      };
    } on MissingPluginException {
      return DeviceCalendarPermission.unavailable;
    } on PlatformException {
      return DeviceCalendarPermission.denied;
    }
  }

  static Future<void> openSettings() {
    return _channel.invokeMethod<void>('openSettings');
  }

  static Future<List<DeviceCalendarInfo>> calendars() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listCalendars');
    return [
      for (final item in raw ?? const [])
        if (item is Map) DeviceCalendarInfo.fromMap(item),
    ];
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _clampDay(DateTime value, DateTime origin) {
    final start = CalendarYears.start();
    final end = DateTime(CalendarYears.max(origin), 12, 31);
    final day = _day(value);
    if (day.isBefore(start)) return start;
    if (day.isAfter(end)) return end;
    return day;
  }

  static Future<List<DeviceCalendarEvent>> events(
    Iterable<String> calendarIds, {
    DateTime? from,
    DateTime? to,
    DateTime? now,
  }) async {
    final origin = now ?? DateTime.now();
    var start = _clampDay(from ?? CalendarYears.start(), origin);
    var last = _clampDay(
      to ?? DateTime(CalendarYears.max(origin), 12, 31),
      origin,
    );
    if (last.isBefore(start)) {
      final swap = start;
      start = last;
      last = swap;
    }
    final end = DateTime(last.year, last.month, last.day, 23, 59, 59, 999);
    final raw = await _channel.invokeMethod<List<dynamic>>('listEvents', {
      'calendarIds': calendarIds.toList(),
      'fromMillis': start.millisecondsSinceEpoch,
      'toMillis': end.millisecondsSinceEpoch,
    });
    return [
      for (final item in raw ?? const [])
        if (item is Map) DeviceCalendarEvent.fromMap(item),
    ];
  }
}
