import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarPreference extends ChangeNotifier {
  CalendarPreference({SharedPreferences? prefs, bool startMonday = false})
      : _prefs = prefs,
        _startMonday = prefs?.getBool(_key) ?? startMonday;

  static const _key = 'calendar_start_monday';

  final SharedPreferences? _prefs;
  bool _startMonday;

  bool get startMonday => _startMonday;

  Future<void> setStartMonday(bool value) async {
    if (_startMonday == value) return;
    _startMonday = value;
    notifyListeners();
    await _prefs?.setBool(_key, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _startMonday = prefs.getBool(_key) ?? _startMonday;
    notifyListeners();
  }
}
