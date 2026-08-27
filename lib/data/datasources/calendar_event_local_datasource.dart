import 'dart:async';
import 'dart:convert';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/data/models/calendar_event_model.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEventLocalDataSource {
  CalendarEventLocalDataSource(this._prefs);

  static const _key = 'calendar_events';
  static const starterIdPrefix = 'starter_';

  final SharedPreferences _prefs;

  List<CalendarEvent> fetchAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => CalendarEventModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> seedStartersIfNeeded() async {
    if (_prefs.containsKey(_key)) return;
    await saveAll(_starterTodos());
  }

  static List<CalendarEvent> _starterTodos([DateTime? now]) {
    final stamp = now ?? DateTime.now();
    final today = DateTime(stamp.year, stamp.month, stamp.day);
    const titles = [
      AppStrings.starterTodoComplete,
      AppStrings.starterTodoReorder,
      AppStrings.starterTodoMove,
    ];
    final categories = EventCategory.presets;
    return [
      for (var i = 0; i < titles.length; i++)
        CalendarEvent(
          id: '$starterIdPrefix$i',
          title: titles[i],
          date: today,
          categoryId: categories[i].id,
          categoryName: categories[i].name,
          categoryColor: categories[i].color,
          sortOrder: i,
        ),
    ];
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
