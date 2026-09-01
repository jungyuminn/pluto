import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavPreference extends ChangeNotifier {
  NavPreference({
    SharedPreferences? prefs,
    bool dailyMode = false,
  })  : _prefs = prefs,
        _dailyMode = prefs?.getBool(_dailyModeKey) ?? dailyMode;

  static const _dailyModeKey = 'nav_daily_mode';

  final SharedPreferences? _prefs;
  bool _dailyMode;

  bool get dailyMode => _dailyMode;
  bool get showJobTab => !_dailyMode;

  Future<void> setDailyMode(bool value) async {
    if (_dailyMode == value) return;
    _dailyMode = value;
    notifyListeners();
    await _prefs?.setBool(_dailyModeKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    final next = prefs.getBool(_dailyModeKey) ?? _dailyMode;
    if (next == _dailyMode) return;
    _dailyMode = next;
    notifyListeners();
  }
}
