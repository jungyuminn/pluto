import 'dart:async';
import 'dart:convert';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/data/models/event_category_model.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventCategoryLocalDataSource {
  EventCategoryLocalDataSource(
    this._prefs, {
    String key = eventKey,
    List<EventCategory>? presets,
    this.syncHomeWidget = true,
  })  : _key = key,
        _presets = List.unmodifiable(presets ?? EventCategory.presets);

  static const eventKey = 'event_categories';
  static const companyKey = 'company_categories';
  static const ledgerKey = 'ledger_categories';

  final SharedPreferences _prefs;
  final String _key;
  final List<EventCategory> _presets;
  final bool syncHomeWidget;

  List<EventCategory> fetchAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return List.of(_presets);

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded
        .map((item) => EventCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
    if (items.length == 1 && items.first.id == EventCategory.defaultId) {
      return List.of(_presets);
    }
    return items;
  }

  Future<void> saveAll(List<EventCategory> categories) async {
    final payload = jsonEncode(
      categories.map(EventCategoryModel.toJson).toList(),
    );
    await _prefs.setString(_key, payload);
    if (syncHomeWidget) unawaited(HomeScreenWidgetService.instance.sync());
  }
}
