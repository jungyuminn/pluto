import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSkin {
  classic,
  blossom,
  summerBeach,
  autumnForest,
  snowyWinter,
  squishyBear,
  strawberryMilk,
  onionVillage,
  lovelyBear,
  rainyDay,
  concertDay,
  boyhood,
  interlude,
  fluffyCloud;

  static AppSkin fromId(
    String? id, {
    AppSkin fallback = AppSkin.classic,
  }) {
    for (final value in AppSkin.values) {
      if (value.name == id) return value;
    }
    return fallback;
  }
}

class ThemePreference extends ChangeNotifier {
  ThemePreference({
    SharedPreferences? prefs,
    bool dark = false,
    AppSkin skin = AppSkin.classic,
  })  : _prefs = prefs,
        _dark = prefs?.getBool(_darkKey) ?? dark,
        _skin = AppSkin.fromId(
          prefs?.getString(_skinKey),
          fallback: skin,
        );

  static const _darkKey = 'app_dark_mode';
  static const _skinKey = 'app_skin';

  final SharedPreferences? _prefs;
  bool _dark;
  AppSkin _skin;

  bool get isDark => _dark;

  AppSkin get skin => _skin;

  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDark(bool value) async {
    if (_dark == value) return;
    _dark = value;
    notifyListeners();
    await _prefs?.setBool(_darkKey, value);
  }

  Future<void> setSkin(AppSkin value) async {
    if (_skin == value) return;
    _skin = value;
    notifyListeners();
    await _prefs?.setString(_skinKey, value.name);
  }
}
