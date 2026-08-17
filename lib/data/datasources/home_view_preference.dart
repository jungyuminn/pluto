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
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _showLeftover = prefs?.getBool(_leftoverKey) ?? showLeftover,
        _showToday = prefs?.getBool(_todayKey) ?? showToday,
        _showTomorrow = prefs?.getBool(_tomorrowKey) ?? showTomorrow,
        _showWeek = prefs?.getBool(_weekKey) ?? showWeek,
        _showMonth = prefs?.getBool(_monthKey) ?? showMonth;

  static const _compactKey = 'home_events_compact_view';
  static const _leftoverKey = 'home_show_leftover';
  static const _todayKey = 'home_show_today';
  static const _tomorrowKey = 'home_show_tomorrow';
  static const _weekKey = 'home_show_week';
  static const _monthKey = 'home_show_month';

  final SharedPreferences? _prefs;
  bool _compact;
  bool _showLeftover;
  bool _showToday;
  bool _showTomorrow;
  bool _showWeek;
  bool _showMonth;

  bool get isCompact => _compact;
  bool get showLeftover => _showLeftover;
  bool get showToday => _showToday;
  bool get showTomorrow => _showTomorrow;
  bool get showWeek => _showWeek;
  bool get showMonth => _showMonth;

  Future<void> setCompact(bool value) async {
    _compact = value;
    await _prefs?.setBool(_compactKey, value);
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
}
