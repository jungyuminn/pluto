import 'dart:convert';

import 'package:job_planner/data/models/ledger_entry_model.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LedgerLocalDataSource {
  LedgerLocalDataSource(this._prefs);

  static const key = 'ledger_entries';

  final SharedPreferences _prefs;

  List<LedgerEntry> fetchAll() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => LedgerEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<LedgerEntry> entries) async {
    final payload = jsonEncode(
      entries.map(LedgerEntryModel.toJson).toList(),
    );
    await _prefs.setString(key, payload);
  }
}
