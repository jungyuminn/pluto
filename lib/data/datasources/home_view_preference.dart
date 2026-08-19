import 'dart:async';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewPreference {
  HomeViewPreference({
    SharedPreferences? prefs,
    bool compact = false,
    bool showLeftover = true,
    bool showToday = true,
    bool showTomorrow = true,
    bool showWeek = false,
    bool showMonth = false,
    bool showMonthlyStats = true,
    bool showWeeklyStats = false,
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _showLeftover = prefs?.getBool(_leftoverKey) ?? showLeftover,
        _showToday = prefs?.getBool(_todayKey) ?? showToday,
        _showTomorrow = prefs?.getBool(_tomorrowKey) ?? showTomorrow,
        _showWeek = prefs?.getBool(_weekKey) ?? showWeek,
        _showMonth = prefs?.getBool(_monthKey) ?? showMonth,
        _showMonthlyStats =
            prefs?.getBool(_monthlyStatsKey) ?? showMonthlyStats,
        _monthlyStatsSeen = prefs?.getString(_monthlyStatsSeenKey),
        _showWeeklyStats = prefs?.getBool(_weeklyStatsKey) ?? showWeeklyStats,
        _weeklyStatsSeen = prefs?.getString(_weeklyStatsSeenKey);

  static const _compactKey = 'home_events_compact_view';
  static const _leftoverKey = 'home_show_leftover';
  static const _todayKey = 'home_show_today';
  static const _tomorrowKey = 'home_show_tomorrow';
  static const _weekKey = 'home_show_week';
  static const _monthKey = 'home_show_month';
  static const _monthlyStatsKey = 'home_show_monthly_stats';
  static const _monthlyStatsSeenKey = 'home_monthly_stats_seen';
  static const _weeklyStatsKey = 'home_show_weekly_stats';
  static const _weeklyStatsSeenKey = 'home_weekly_stats_seen';

  final SharedPreferences? _prefs;
  bool _compact;
  bool _showLeftover;
  bool _showToday;
  bool _showTomorrow;
  bool _showWeek;
  bool _showMonth;
  bool _showMonthlyStats;
  String? _monthlyStatsSeen;
  bool _showWeeklyStats;
  String? _weeklyStatsSeen;

  bool get isCompact => _prefs?.getBool(_compactKey) ?? _compact;
  bool get showLeftover => _showLeftover;
  bool get showToday => _showToday;
  bool get showTomorrow => _showTomorrow;
  bool get showWeek => _showWeek;
  bool get showMonth => _showMonth;
  bool get showMonthlyStats => _showMonthlyStats;
  bool get showWeeklyStats => _showWeeklyStats;

  bool shouldShowMonthlyStats([DateTime? now]) {
    if (!_showMonthlyStats) return false;
    final today = now ?? DateTime.now();
    if (today.day != 1) return false;
    return _monthlyStatsSeen != _monthStamp(today);
  }

  bool shouldShowWeeklyStats([DateTime? now]) {
    if (!_showWeeklyStats) return false;
    final today = now ?? DateTime.now();
    if (today.weekday != DateTime.monday) return false;
    return _weeklyStatsSeen != _weekStamp(today);
  }

  Future<void> setCompact(bool value) async {
    _compact = value;
    await _prefs?.setBool(_compactKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  Future<void> setShowLeftover(bool value) async {
    _showLeftover = value;
    await _prefs?.setBool(_leftoverKey, value);
  }

  Future<void> setShowToday(bool value) async {
    _showToday = value;
    await _prefs?.setBool(_todayKey, value);
  }

  Future<void> setShowTomorrow(bool value) async {
    _showTomorrow = value;
    await _prefs?.setBool(_tomorrowKey, value);
  }

  Future<void> setShowWeek(bool value) async {
    _showWeek = value;
    await _prefs?.setBool(_weekKey, value);
  }

  Future<void> setShowMonth(bool value) async {
    _showMonth = value;
    await _prefs?.setBool(_monthKey, value);
  }

  Future<void> setShowMonthlyStats(bool value) async {
    _showMonthlyStats = value;
    await _prefs?.setBool(_monthlyStatsKey, value);
  }

  Future<void> setShowWeeklyStats(bool value) async {
    _showWeeklyStats = value;
    await _prefs?.setBool(_weeklyStatsKey, value);
  }

  Future<void> dismissMonthlyStats([DateTime? now]) async {
    final today = now ?? DateTime.now();
    _monthlyStatsSeen = _monthStamp(today);
    await _prefs?.setString(_monthlyStatsSeenKey, _monthlyStatsSeen!);
  }

  Future<void> dismissWeeklyStats([DateTime? now]) async {
    final today = now ?? DateTime.now();
    _weeklyStatsSeen = _weekStamp(today);
    await _prefs?.setString(_weeklyStatsSeenKey, _weeklyStatsSeen!);
  }

  static String _monthStamp(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static String _weekStamp(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final month = monday.month.toString().padLeft(2, '0');
    final dayNum = monday.day.toString().padLeft(2, '0');
    return '${monday.year}-$month-$dayNum';
  }
}
