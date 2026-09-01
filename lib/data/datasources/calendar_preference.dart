import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarPreference extends ChangeNotifier {
  CalendarPreference({
    SharedPreferences? prefs,
    bool startMonday = false,
    bool showLunar = false,
    bool showTodos = true,
    bool showCompanies = true,
  })  : _prefs = prefs,
        _startMonday = prefs?.getBool(_mondayKey) ?? startMonday,
        _showLunar = prefs?.getBool(_lunarKey) ?? showLunar,
        _showTodos = prefs?.getBool(_todosKey) ?? showTodos,
        _showCompanies = prefs?.getBool(_companiesKey) ?? showCompanies;

  static const _mondayKey = 'calendar_start_monday';
  static const _lunarKey = 'calendar_show_lunar';
  static const _todosKey = 'calendar_show_todos';
  static const _companiesKey = 'calendar_show_companies';

  final SharedPreferences? _prefs;
  bool _startMonday;
  bool _showLunar;
  bool _showTodos;
  bool _showCompanies;

  bool get startMonday => _startMonday;
  bool get showLunar => _showLunar;
  bool get showTodos => _showTodos;
  bool get showCompanies => _showCompanies;

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

  Future<void> setShowTodos(bool value) async {
    if (_showTodos == value) return;
    _showTodos = value;
    notifyListeners();
    await _prefs?.setBool(_todosKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  Future<void> setShowCompanies(bool value) async {
    if (_showCompanies == value) return;
    _showCompanies = value;
    notifyListeners();
    await _prefs?.setBool(_companiesKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _startMonday = prefs.getBool(_mondayKey) ?? _startMonday;
    _showLunar = prefs.getBool(_lunarKey) ?? _showLunar;
    _showTodos = prefs.getBool(_todosKey) ?? _showTodos;
    _showCompanies = prefs.getBool(_companiesKey) ?? _showCompanies;
    notifyListeners();
  }
}
