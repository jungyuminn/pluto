import 'dart:async';
import 'dart:convert';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/data/models/calendar_event_model.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEventLocalDataSource {
  CalendarEventLocalDataSource(this._prefs);

  static const _key = 'calendar_events';

  final SharedPreferences _prefs;

  List<CalendarEvent> fetchAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => CalendarEventModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<CalendarEvent> events) async {
    final payload = jsonEncode(
      events.map(CalendarEventModel.toJson).toList(),
    );
    await _prefs.setString(_key, payload);
    unawaited(_syncSideEffects());
  }

  Future<void> _syncSideEffects() async {
    await TodoReminderService.instance.sync();
    await HomeScreenWidgetService.instance.sync();
  }
}
