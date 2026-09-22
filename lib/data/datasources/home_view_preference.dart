import 'dart:async';

import 'package:pluto/core/home_widget/home_screen_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewPreference {
  HomeViewPreference({
    SharedPreferences? prefs,
    bool compact = false,
    bool showFriends = true,
    bool showLeftover = true,
    bool showMemo = false,
    bool showToday = true,
    bool showTomorrow = true,
    bool showWeek = false,
    bool showMonth = false,
    bool showSomeday = false,
    bool showLongGoal = false,
    bool showMonthlyStats = true,
    bool showWeeklyStats = false,
  })  : _prefs = prefs,
        _compact = prefs?.getBool(_compactKey) ?? compact,
        _showFriends = prefs?.getBool(_friendsKey) ?? showFriends,
        _showLeftover = prefs?.getBool(_leftoverKey) ?? showLeftover,
        _showMemo = prefs?.getBool(_memoKey) ?? showMemo,
        _showToday = prefs?.getBool(_todayKey) ?? showToday,
        _showTomorrow = prefs?.getBool(_tomorrowKey) ?? showTomorrow,
        _showWeek = prefs?.getBool(_weekKey) ?? showWeek,
        _showMonth = prefs?.getBool(_monthKey) ?? showMonth,
        _showSomeday = prefs?.getBool(_somedayKey) ?? showSomeday,
        _showLongGoal = prefs?.getBool(_longGoalKey) ?? showLongGoal,
        _showMonthlyStats =
            prefs?.getBool(_monthlyStatsKey) ?? showMonthlyStats,
        _monthlyStatsSeen = prefs?.getString(_monthlyStatsSeenKey),
        _showWeeklyStats = prefs?.getBool(_weeklyStatsKey) ?? showWeeklyStats,
        _weeklyStatsSeen = prefs?.getString(_weeklyStatsSeenKey),
        _cardOrder = parseCardOrder(prefs?.getString(_cardOrderKey));

  static const _compactKey = 'home_events_compact_view';
  static const _friendsKey = 'home_show_friends';
  static const _leftoverKey = 'home_show_leftover';
  static const _memoKey = 'home_show_memo';
  static const _todayKey = 'home_show_today';
  static const _tomorrowKey = 'home_show_tomorrow';
  static const _weekKey = 'home_show_week';
  static const _monthKey = 'home_show_month';
  static const _somedayKey = 'home_show_someday';
  static const _longGoalKey = 'home_show_long_goal';
  static const _monthlyStatsKey = 'home_show_monthly_stats';
  static const _monthlyStatsSeenKey = 'home_monthly_stats_seen';
  static const _weeklyStatsKey = 'home_show_weekly_stats';
  static const _weeklyStatsSeenKey = 'home_weekly_stats_seen';
  static const _cardOrderKey = 'home_card_order';
  static const cardOrderKey = _cardOrderKey;
  static const syncedKeys = [
    _compactKey,
    _friendsKey,
    _leftoverKey,
    _memoKey,
    _todayKey,
    _tomorrowKey,
    _weekKey,
    _monthKey,
    _somedayKey,
    _longGoalKey,
    _monthlyStatsKey,
    _weeklyStatsKey,
    _cardOrderKey,
  ];
  static const defaultBools = {
    _compactKey: false,
    _friendsKey: true,
    _leftoverKey: true,
    _memoKey: false,
    _todayKey: true,
    _tomorrowKey: true,
    _weekKey: false,
    _monthKey: false,
    _somedayKey: false,
    _longGoalKey: false,
    _monthlyStatsKey: true,
    _weeklyStatsKey: false,
  };

  static bool cardOrderIsDefault(String? raw) {
    if (raw == null || raw.isEmpty) return true;
    final parsed = parseCardOrder(raw);
    if (parsed.length != HomeCardKind.defaults.length) return false;
    for (var i = 0; i < parsed.length; i++) {
      if (parsed[i] != HomeCardKind.defaults[i]) return false;
    }
    return true;
  }

  final SharedPreferences? _prefs;
  bool _compact;
  bool _showFriends;
  bool _showLeftover;
  bool _showMemo;
  bool _showToday;
  bool _showTomorrow;
  bool _showWeek;
  bool _showMonth;
  bool _showSomeday;
  bool _showLongGoal;
  bool _showMonthlyStats;
  String? _monthlyStatsSeen;
  bool _showWeeklyStats;
  String? _weeklyStatsSeen;
  List<HomeCardKind> _cardOrder;

  bool get isCompact => _prefs?.getBool(_compactKey) ?? _compact;
  bool get showFriends => _showFriends;
  bool get showLeftover => _showLeftover;
  bool get showMemo => _showMemo;
  bool get showToday => _showToday;
  bool get showTomorrow => _showTomorrow;
  bool get showWeek => _showWeek;
  bool get showMonth => _showMonth;
  bool get showSomeday => _showSomeday;
  bool get showLongGoal => _showLongGoal;
  bool get showMonthlyStats => _showMonthlyStats;
  bool get showWeeklyStats => _showWeeklyStats;
  List<HomeCardKind> get cardOrder => List.unmodifiable(_cardOrder);

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

  Future<void> setShowFriends(bool value) async {
    _showFriends = value;
    await _prefs?.setBool(_friendsKey, value);
  }

  Future<void> setShowLeftover(bool value) async {
    _showLeftover = value;
    await _prefs?.setBool(_leftoverKey, value);
  }

  Future<void> setShowMemo(bool value) async {
    _showMemo = value;
    await _prefs?.setBool(_memoKey, value);
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

  Future<void> setShowSomeday(bool value) async {
    _showSomeday = value;
    await _prefs?.setBool(_somedayKey, value);
  }

  Future<void> setShowLongGoal(bool value) async {
    _showLongGoal = value;
    await _prefs?.setBool(_longGoalKey, value);
  }

  Future<void> setShowMonthlyStats(bool value) async {
    _showMonthlyStats = value;
    await _prefs?.setBool(_monthlyStatsKey, value);
  }

  Future<void> setShowWeeklyStats(bool value) async {
    _showWeeklyStats = value;
    await _prefs?.setBool(_weeklyStatsKey, value);
  }

  Future<void> setCardOrder(List<HomeCardKind> order) async {
    _cardOrder = parseCardOrder(order.map((kind) => kind.name).join(','));
    await _prefs?.setString(
      _cardOrderKey,
      _cardOrder.map((kind) => kind.name).join(','),
    );
  }

  static List<HomeCardKind> parseCardOrder(String? raw) {
    final found = <HomeCardKind>[];
    if (raw != null && raw.isNotEmpty) {
      for (final part in raw.split(',')) {
        final kind = HomeCardKind.fromName(part);
        if (kind != null && !found.contains(kind)) found.add(kind);
      }
    }
    if (!found.contains(HomeCardKind.memo)) {
      final leftoverIdx = found.indexOf(HomeCardKind.leftover);
      if (leftoverIdx >= 0) {
        found.insert(leftoverIdx + 1, HomeCardKind.memo);
      }
    }
    if (!found.contains(HomeCardKind.someday)) {
      final longIdx = found.indexOf(HomeCardKind.longGoal);
      if (longIdx >= 0) {
        found.insert(longIdx, HomeCardKind.someday);
      }
    }
    for (final kind in HomeCardKind.defaults) {
      if (!found.contains(kind)) found.add(kind);
    }
    return found;
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

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _compact = prefs.getBool(_compactKey) ?? _compact;
    _showFriends = prefs.getBool(_friendsKey) ?? _showFriends;
    _showLeftover = prefs.getBool(_leftoverKey) ?? _showLeftover;
    _showMemo = prefs.getBool(_memoKey) ?? _showMemo;
    _showToday = prefs.getBool(_todayKey) ?? _showToday;
    _showTomorrow = prefs.getBool(_tomorrowKey) ?? _showTomorrow;
    _showWeek = prefs.getBool(_weekKey) ?? _showWeek;
    _showMonth = prefs.getBool(_monthKey) ?? _showMonth;
    _showSomeday = prefs.getBool(_somedayKey) ?? _showSomeday;
    _showLongGoal = prefs.getBool(_longGoalKey) ?? _showLongGoal;
    _showMonthlyStats = prefs.getBool(_monthlyStatsKey) ?? _showMonthlyStats;
    _monthlyStatsSeen = prefs.getString(_monthlyStatsSeenKey);
    _showWeeklyStats = prefs.getBool(_weeklyStatsKey) ?? _showWeeklyStats;
    _weeklyStatsSeen = prefs.getString(_weeklyStatsSeenKey);
    _cardOrder = parseCardOrder(prefs.getString(_cardOrderKey));
  }
}

enum HomeCardKind {
  leftover,
  memo,
  today,
  tomorrow,
  week,
  month,
  someday,
  longGoal;

  static const defaults = [
    leftover,
    memo,
    today,
    tomorrow,
    week,
    month,
    someday,
    longGoal,
  ];

  static HomeCardKind? fromName(String raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}
