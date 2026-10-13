import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobViewPreference extends ChangeNotifier {
  JobViewPreference({
    SharedPreferences? prefs,
    bool compact = false,
    bool sortByDate = false,
    bool sortByStatus = false,
    bool showRejected = true,
    bool categoryView = false,
    bool showLicense = false,
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _sortByDate = prefs?.getBool(_sortKey) ?? sortByDate,
        _sortByStatus = prefs?.getBool(_statusSortKey) ?? sortByStatus,
        _showRejected = prefs?.getBool(_showRejectedKey) ?? showRejected,
        _categoryView = prefs?.getBool(_categoryViewKey) ?? categoryView,
        _showLicense = prefs?.getBool(_showLicenseKey) ?? showLicense;

  static const _compactKey = 'home_compact_view';
  static const _sortKey = 'job_sort_by_date';
  static const _statusSortKey = 'job_sort_by_status';
  static const _showRejectedKey = 'job_show_rejected';
  static const _categoryViewKey = 'job_category_view';
  static const _showLicenseKey = 'job_show_license';
  static const syncedKeys = [
    _compactKey,
    _sortKey,
    _statusSortKey,
    _showRejectedKey,
    _categoryViewKey,
    _showLicenseKey,
  ];
  static const defaultBools = {
    _compactKey: false,
    _sortKey: false,
    _statusSortKey: false,
    _showRejectedKey: true,
    _categoryViewKey: false,
    _showLicenseKey: false,
  };

  final SharedPreferences? _prefs;
  bool _compact;
  bool _sortByDate;
  bool _sortByStatus;
  bool _showRejected;
  bool _categoryView;
  bool _showLicense;

  bool get isCompact => _compact;
  bool get sortByDate => _sortByDate;
  bool get sortByStatus => _sortByStatus;
  bool get showRejected => _showRejected;
  bool get categoryView => _categoryView;
  bool get showLicense => _showLicense;

  Future<void> setCompact(bool value) async {
    if (_compact == value) return;
    _compact = value;
    notifyListeners();
    await _prefs?.setBool(_compactKey, value);
  }

  Future<void> setSortByDate(bool value) async {
    if (_sortByDate == value && (!value || !_sortByStatus)) return;
    _sortByDate = value;
    if (value && _sortByStatus) {
      _sortByStatus = false;
      await _prefs?.setBool(_statusSortKey, false);
    }
    notifyListeners();
    await _prefs?.setBool(_sortKey, value);
  }

  Future<void> setSortByStatus(bool value) async {
    if (_sortByStatus == value && (!value || !_sortByDate)) return;
    _sortByStatus = value;
    if (value && _sortByDate) {
      _sortByDate = false;
      await _prefs?.setBool(_sortKey, false);
    }
    notifyListeners();
    await _prefs?.setBool(_statusSortKey, value);
  }

  Future<void> setShowRejected(bool value) async {
    if (_showRejected == value) return;
    _showRejected = value;
    notifyListeners();
    await _prefs?.setBool(_showRejectedKey, value);
  }

  Future<void> setCategoryView(bool value) async {
    if (_categoryView == value) return;
    _categoryView = value;
    notifyListeners();
    await _prefs?.setBool(_categoryViewKey, value);
  }

  Future<void> setShowLicense(bool value) async {
    if (_showLicense == value) return;
    _showLicense = value;
    notifyListeners();
    await _prefs?.setBool(_showLicenseKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _compact = prefs.getBool(_compactKey) ?? _compact;
    _sortByDate = prefs.getBool(_sortKey) ?? _sortByDate;
    _sortByStatus = prefs.getBool(_statusSortKey) ?? _sortByStatus;
    _showRejected = prefs.getBool(_showRejectedKey) ?? _showRejected;
    _categoryView = prefs.getBool(_categoryViewKey) ?? _categoryView;
    _showLicense = prefs.getBool(_showLicenseKey) ?? _showLicense;
    notifyListeners();
  }
}
