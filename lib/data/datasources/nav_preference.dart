import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavPreference extends ChangeNotifier {
  NavPreference({
    SharedPreferences? prefs,
    bool jobMode = false,
    bool showStatsTab = true,
  })  : _prefs = prefs,
        _jobMode = _readJobMode(prefs, jobMode),
        _showStatsTab = _readBool(prefs, _statsTabKey, showStatsTab);

  static const _jobModeKey = 'nav_job_mode';
  static const _dailyModeKey = 'nav_daily_mode';
  static const _statsTabKey = 'nav_stats_tab';

  final SharedPreferences? _prefs;
  bool _jobMode;
  bool _showStatsTab;

  bool get jobMode => _jobMode;
  bool get showJobTab => _jobMode;
  bool get showStatsTab => _showStatsTab;

  static bool _readBool(
    SharedPreferences? prefs,
    String key,
    bool fallback,
  ) {
    if (prefs == null) return fallback;
    return prefs.getBool(key) ?? fallback;
  }

  static bool _readJobMode(SharedPreferences? prefs, bool fallback) {
    if (prefs == null) return fallback;
    if (prefs.containsKey(_jobModeKey)) {
      return prefs.getBool(_jobModeKey) ?? fallback;
    }
    if (prefs.containsKey(_dailyModeKey)) {
      return !(prefs.getBool(_dailyModeKey) ?? false);
    }
    return fallback;
  }

  Future<void> setJobMode(bool value) async {
    if (_jobMode == value) return;
    _jobMode = value;
    notifyListeners();
    await _prefs?.setBool(_jobModeKey, value);
    await _prefs?.remove(_dailyModeKey);
  }

  Future<void> setShowStatsTab(bool value) async {
    if (_showStatsTab == value) return;
    _showStatsTab = value;
    notifyListeners();
    await _prefs?.setBool(_statsTabKey, value);
  }

  void hydrate() {
    final nextJob = _readJobMode(_prefs, _jobMode);
    final nextStats = _readBool(_prefs, _statsTabKey, _showStatsTab);
    if (nextJob == _jobMode && nextStats == _showStatsTab) return;
    _jobMode = nextJob;
    _showStatsTab = nextStats;
    notifyListeners();
  }
}
