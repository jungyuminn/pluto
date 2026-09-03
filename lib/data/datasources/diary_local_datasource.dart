import 'dart:convert';

import 'package:job_planner/data/models/diary_entry_model.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryLocalDataSource {
  DiaryLocalDataSource(this._prefs);

  static const key = 'diary_entries';

  final SharedPreferences _prefs;

  List<DiaryEntry> fetchAll() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => DiaryEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<DiaryEntry> entries) async {
    final payload = jsonEncode(
      entries.map(DiaryEntryModel.toJson).toList(),
    );
    await _prefs.setString(key, payload);
  }
}
