import 'dart:convert';

import 'package:job_planner/data/models/event_category_model.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventCategoryLocalDataSource {
  EventCategoryLocalDataSource(this._prefs);

  static const _key = 'event_categories';

  final SharedPreferences _prefs;

  List<EventCategory> fetchAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return List.of(EventCategory.presets);

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded
        .map((item) => EventCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
    if (items.length == 1 && items.first.id == EventCategory.defaultId) {
      return List.of(EventCategory.presets);
    }
    return items;
  }

  Future<void> saveAll(List<EventCategory> categories) {
    final payload = jsonEncode(
      categories.map(EventCategoryModel.toJson).toList(),
    );
    return _prefs.setString(_key, payload);
  }
}
