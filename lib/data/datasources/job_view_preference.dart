import 'package:shared_preferences/shared_preferences.dart';

class JobViewPreference {
  JobViewPreference({
    SharedPreferences? prefs,
    bool compact = false,
    bool sortByDate = false,
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _sortByDate = prefs?.getBool(_sortKey) ?? sortByDate;

  static const _compactKey = 'home_compact_view';
  static const _sortKey = 'job_sort_by_date';

  final SharedPreferences? _prefs;
  bool _compact;
  bool _sortByDate;

  bool get isCompact => _compact;
  bool get sortByDate => _sortByDate;

  Future<void> setCompact(bool value) async {
    _compact = value;
    await _prefs?.setBool(_compactKey, value);
  }

  Future<void> setSortByDate(bool value) async {
    _sortByDate = value;
    await _prefs?.setBool(_sortKey, value);
  }
}
