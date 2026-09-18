import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastEventCategoryPreference {
  LastEventCategoryPreference({SharedPreferences? prefs}) : _prefs = prefs;

  static const key = 'last_added_event_category_id';
  static const syncedKeys = [key];

  final SharedPreferences? _prefs;

  String? get id => _prefs?.getString(key);

  Future<void> setId(String value) async {
    final id = value.trim();
    if (id.isEmpty) return;
    await _prefs?.setString(key, id);
  }

  static EventCategory? resolve({
    required List<CalendarEvent> events,
    required List<EventCategory> categories,
    String? storedId,
  }) {
    if (storedId != null) {
      for (final category in categories) {
        if (category.id == storedId) return category;
      }
    }
    CalendarEvent? newest;
    var newestStamp = -1;
    for (final event in events) {
      final stamp = _addedStamp(event.id);
      if (stamp == null) continue;
      if ((event.categoryId ?? '').isEmpty) continue;
      if (stamp >= newestStamp) {
        newestStamp = stamp;
        newest = event;
      }
    }
    if (newest == null) return null;
    for (final category in categories) {
      if (category.id == newest.categoryId) return category;
    }
    return null;
  }

  static int? _addedStamp(String id) {
    final head = id.split('_').first;
    return int.tryParse(head);
  }
}
