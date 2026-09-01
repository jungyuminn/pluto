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
  static const licenseKey = 'license_categories';

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
    if (_key == licenseKey) {
      final migrated = _migratedLicenseCategories(items);
      if (migrated != null) {
        unawaited(saveAll(migrated));
        return migrated;
      }
    }
    return items;
  }

  List<EventCategory>? _migratedLicenseCategories(List<EventCategory> items) {
    var changed = false;
    final next = <EventCategory>[];
    final seen = <String>{};
    for (final item in items) {
      final mapped = switch (item.id) {
        'license_national' => EventCategory.licensePresets[1],
        'license_it' => EventCategory.licensePresets[2],
        'license_other' => null,
        'license_language' => EventCategory.licensePresets[0],
        _ => item,
      };
      if (mapped == null) {
        changed = true;
        continue;
      }
      if (mapped.id != item.id || mapped.name != item.name) changed = true;
      if (seen.add(mapped.id)) next.add(mapped);
    }
    for (final preset in EventCategory.licensePresets) {
      if (seen.add(preset.id)) {
        next.add(preset);
        changed = true;
      }
    }
    if (!changed) return null;
    return next;
  }

  Future<void> saveAll(List<EventCategory> categories) async {
    final payload = jsonEncode(
      categories.map(EventCategoryModel.toJson).toList(),
    );
    await _prefs.setString(_key, payload);
    if (syncHomeWidget) unawaited(HomeScreenWidgetService.instance.sync());
  }
}
