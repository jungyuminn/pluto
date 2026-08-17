import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreference extends ChangeNotifier {
  ThemePreference({SharedPreferences? prefs, bool dark = false})
      : _prefs = prefs,
        _dark = prefs?.getBool(_key) ?? dark;

  static const _key = 'app_dark_mode';

  final SharedPreferences? _prefs;
  bool _dark;

  bool get isDark => _dark;

  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDark(bool value) async {
    if (_dark == value) return;
    _dark = value;
    notifyListeners();
    await _prefs?.setBool(_key, value);
  }
}
