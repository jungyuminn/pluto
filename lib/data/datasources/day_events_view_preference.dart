import 'dart:async';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayEventsViewPreference {
  DayEventsViewPreference({
    SharedPreferences? prefs,
    bool sortByTime = false,
    bool showTime = false,
  })  : _prefs = prefs,
        _sortByTime = prefs?.getBool(_sortKey) ?? sortByTime,
        _showTime = prefs?.getBool(_showTimeKey) ?? showTime;

  static const _sortKey = 'day_events_sort_by_time';
  static const _showTimeKey = 'day_events_show_time';

  final SharedPreferences? _prefs;
  bool _sortByTime;
  bool _showTime;

  bool get sortByTime => _prefs?.getBool(_sortKey) ?? _sortByTime;
  bool get showTime => _prefs?.getBool(_showTimeKey) ?? _showTime;

  Future<void> setSortByTime(bool value) async {
    _sortByTime = value;
    await _prefs?.setBool(_sortKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  Future<void> setShowTime(bool value) async {
    _showTime = value;
    await _prefs?.setBool(_showTimeKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }
}
