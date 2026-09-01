import 'dart:async';
import 'dart:convert';

import 'package:job_planner/data/models/license_model.dart';
import 'package:job_planner/domain/entities/license.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseLocalDataSource {
  LicenseLocalDataSource(this._prefs);

  static const key = 'licenses';

  final SharedPreferences _prefs;

  List<License> fetchAll() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded
        .map((item) => LicenseModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final migrated = [for (final item in items) _migrateCategory(item)];
    final changed = [
      for (var i = 0; i < items.length; i++)
        if (migrated[i].categoryId != items[i].categoryId) i,
    ].isNotEmpty;
    if (changed) unawaited(saveAll(migrated));
    return migrated;
  }

  License _migrateCategory(License license) {
    return switch (license.categoryId) {
      'license_national' => license.copyWith(
          categoryId: 'license_engineer',
          categoryName: '기사',
          categoryColor: 0xFF00ACC1,
        ),
      'license_it' || 'license_other' => license.copyWith(
          categoryId: 'license_craftsman',
          categoryName: '기능사',
          categoryColor: 0xFF7CB342,
        ),
      _ => license,
    };
  }

  Future<void> saveAll(List<License> licenses) async {
    final payload = jsonEncode(
      licenses.map(LicenseModel.toJson).toList(),
    );
    await _prefs.setString(key, payload);
  }
}
