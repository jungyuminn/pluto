import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarPreference extends ChangeNotifier {
  CalendarPreference({
    SharedPreferences? prefs,
    bool startMonday = false,
    bool showLunar = false,
  })  : _prefs = prefs,
        _startMonday = prefs?.getBool(_mondayKey) ?? startMonday,
        _showLunar = prefs?.getBool(_lunarKey) ?? showLunar;

  static const _mondayKey = 'calendar_start_monday';
  static const _lunarKey = 'calendar_show_lunar';

  final SharedPreferences? _prefs;
  bool _startMonday;
  bool _showLunar;

  bool get startMonday => _startMonday;
  bool get showLunar => _showLunar;

  Future<void> setStartMonday(bool value) async {
    if (_startMonday == value) return;
    _startMonday = value;
    notifyListeners();
    await _prefs?.setBool(_mondayKey, value);
  }

  Future<void> setShowLunar(bool value) async {
    if (_showLunar == value) return;
    _showLunar = value;
    notifyListeners();
    await _prefs?.setBool(_lunarKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _startMonday = prefs.getBool(_mondayKey) ?? _startMonday;
    _showLunar = prefs.getBool(_lunarKey) ?? _showLunar;
    notifyListeners();
  }
}
