import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobViewPreference extends ChangeNotifier {
  JobViewPreference({
    SharedPreferences? prefs,
    bool compact = false,
    bool sortByDate = false,
    bool showRejected = true,
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _sortByDate = prefs?.getBool(_sortKey) ?? sortByDate,
        _showRejected = prefs?.getBool(_showRejectedKey) ?? showRejected;

  static const _compactKey = 'home_compact_view';
  static const _sortKey = 'job_sort_by_date';
  static const _showRejectedKey = 'job_show_rejected';

  final SharedPreferences? _prefs;
  bool _compact;
  bool _sortByDate;
  bool _showRejected;

  bool get isCompact => _compact;
  bool get sortByDate => _sortByDate;
  bool get showRejected => _showRejected;

  Future<void> setCompact(bool value) async {
    if (_compact == value) return;
    _compact = value;
    notifyListeners();
    await _prefs?.setBool(_compactKey, value);
  }

  Future<void> setSortByDate(bool value) async {
    if (_sortByDate == value) return;
    _sortByDate = value;
    notifyListeners();
    await _prefs?.setBool(_sortKey, value);
  }

  Future<void> setShowRejected(bool value) async {
    if (_showRejected == value) return;
    _showRejected = value;
    notifyListeners();
    await _prefs?.setBool(_showRejectedKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _compact = prefs.getBool(_compactKey) ?? _compact;
    _sortByDate = prefs.getBool(_sortKey) ?? _sortByDate;
    _showRejected = prefs.getBool(_showRejectedKey) ?? _showRejected;
    notifyListeners();
  }
}
