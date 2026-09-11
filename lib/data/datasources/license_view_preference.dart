import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseViewPreference extends ChangeNotifier {
  LicenseViewPreference({
    SharedPreferences? prefs,
    bool compact = false,
    bool sortByDate = false,
    bool showExpired = true,
    bool categoryView = false,
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _sortByDate = prefs?.getBool(_sortKey) ?? sortByDate,
        _showExpired = prefs?.getBool(_showExpiredKey) ?? showExpired,
        _categoryView = prefs?.getBool(_categoryViewKey) ?? categoryView;

  static const _compactKey = 'license_compact_view';
  static const _sortKey = 'license_sort_by_date';
  static const _showExpiredKey = 'license_show_expired';
  static const _categoryViewKey = 'license_category_view';
  static const syncedKeys = [
    _compactKey,
    _sortKey,
    _showExpiredKey,
    _categoryViewKey,
  ];
  static const defaultBools = {
    _compactKey: false,
    _sortKey: false,
    _showExpiredKey: true,
    _categoryViewKey: false,
  };

  final SharedPreferences? _prefs;
  bool _compact;
  bool _sortByDate;
  bool _showExpired;
  bool _categoryView;

  bool get isCompact => _compact;
  bool get sortByDate => _sortByDate;
  bool get showExpired => _showExpired;
  bool get categoryView => _categoryView;

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

  Future<void> setShowExpired(bool value) async {
    if (_showExpired == value) return;
    _showExpired = value;
    notifyListeners();
    await _prefs?.setBool(_showExpiredKey, value);
  }

  Future<void> setCategoryView(bool value) async {
    if (_categoryView == value) return;
    _categoryView = value;
    notifyListeners();
    await _prefs?.setBool(_categoryViewKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _compact = prefs.getBool(_compactKey) ?? _compact;
    _sortByDate = prefs.getBool(_sortKey) ?? _sortByDate;
    _showExpired = prefs.getBool(_showExpiredKey) ?? _showExpired;
    _categoryView = prefs.getBool(_categoryViewKey) ?? _categoryView;
    notifyListeners();
  }
}
