import 'dart:async';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayEventsViewPreference {
  DayEventsViewPreference({
    SharedPreferences? prefs,
    bool sortByTime = false,
    bool showTime = false,
    bool categoryView = false,
    bool showLedgerTitle = true,
    bool showLedgerAmount = false,
    bool showLedgerKind = true,
    bool showLedgerMonthStats = true,
    bool ledgerKindColor = false,
  })  : _prefs = prefs,
        _sortByTime = prefs?.getBool(_sortKey) ?? sortByTime,
        _showTime = prefs?.getBool(_showTimeKey) ?? showTime,
        _categoryView = prefs?.getBool(_categoryViewKey) ?? categoryView,
        _showLedgerTitle =
            prefs?.getBool(_ledgerTitleKey) ?? showLedgerTitle,
        _showLedgerAmount =
            prefs?.getBool(_ledgerAmountKey) ?? showLedgerAmount,
        _showLedgerKind =
            prefs?.getBool(_ledgerKindKey) ?? showLedgerKind,
        _showLedgerMonthStats =
            prefs?.getBool(_ledgerMonthStatsKey) ?? showLedgerMonthStats,
        _ledgerKindColor =
            prefs?.getBool(_ledgerKindColorKey) ?? ledgerKindColor;

  static const _sortKey = 'day_events_sort_by_time';
  static const _showTimeKey = 'day_events_show_time';
  static const _categoryViewKey = 'day_events_category_view';
  static const _ledgerTitleKey = 'calendar_show_ledger_title';
  static const _ledgerAmountKey = 'calendar_show_ledger_amount';
  static const _ledgerKindKey = 'calendar_show_ledger_kind';
  static const _ledgerMonthStatsKey = 'calendar_show_ledger_month_stats';
  static const _ledgerKindColorKey = 'calendar_ledger_kind_color';

  final SharedPreferences? _prefs;
  bool _sortByTime;
  bool _showTime;
  bool _categoryView;
  bool _showLedgerTitle;
  bool _showLedgerAmount;
  bool _showLedgerKind;
  bool _showLedgerMonthStats;
  bool _ledgerKindColor;

  bool get sortByTime => _prefs?.getBool(_sortKey) ?? _sortByTime;
  bool get showTime => _prefs?.getBool(_showTimeKey) ?? _showTime;
  bool get categoryView => _prefs?.getBool(_categoryViewKey) ?? _categoryView;
  bool get showLedgerTitle {
    final title = _prefs?.getBool(_ledgerTitleKey) ?? _showLedgerTitle;
    final amount = _prefs?.getBool(_ledgerAmountKey) ?? _showLedgerAmount;
    if (title && amount) return true;
    return title;
  }

  bool get showLedgerAmount {
    final title = _prefs?.getBool(_ledgerTitleKey) ?? _showLedgerTitle;
    final amount = _prefs?.getBool(_ledgerAmountKey) ?? _showLedgerAmount;
    if (title && amount) return false;
    return amount;
  }

  bool get showLedgerKind =>
      _prefs?.getBool(_ledgerKindKey) ?? _showLedgerKind;

  bool get showLedgerMonthStats =>
      _prefs?.getBool(_ledgerMonthStatsKey) ?? _showLedgerMonthStats;

  bool get ledgerKindColor =>
      _prefs?.getBool(_ledgerKindColorKey) ?? _ledgerKindColor;

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

  Future<void> setCategoryView(bool value) async {
    _categoryView = value;
    await _prefs?.setBool(_categoryViewKey, value);
  }

  Future<void> setShowLedgerTitle(bool value) async {
    _showLedgerTitle = value;
    await _prefs?.setBool(_ledgerTitleKey, value);
    if (value && _showLedgerAmount) {
      _showLedgerAmount = false;
      await _prefs?.setBool(_ledgerAmountKey, false);
    }
  }

  Future<void> setShowLedgerAmount(bool value) async {
    _showLedgerAmount = value;
    await _prefs?.setBool(_ledgerAmountKey, value);
    if (value && _showLedgerTitle) {
      _showLedgerTitle = false;
      await _prefs?.setBool(_ledgerTitleKey, false);
    }
  }

  Future<void> setShowLedgerKind(bool value) async {
    _showLedgerKind = value;
    await _prefs?.setBool(_ledgerKindKey, value);
  }

  Future<void> setShowLedgerMonthStats(bool value) async {
    _showLedgerMonthStats = value;
    await _prefs?.setBool(_ledgerMonthStatsKey, value);
  }

  Future<void> setLedgerKindColor(bool value) async {
    _ledgerKindColor = value;
    await _prefs?.setBool(_ledgerKindColorKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _sortByTime = prefs.getBool(_sortKey) ?? _sortByTime;
    _showTime = prefs.getBool(_showTimeKey) ?? _showTime;
    _categoryView = prefs.getBool(_categoryViewKey) ?? _categoryView;
    _showLedgerTitle = prefs.getBool(_ledgerTitleKey) ?? _showLedgerTitle;
    _showLedgerAmount = prefs.getBool(_ledgerAmountKey) ?? _showLedgerAmount;
    _showLedgerKind = prefs.getBool(_ledgerKindKey) ?? _showLedgerKind;
    _showLedgerMonthStats =
        prefs.getBool(_ledgerMonthStatsKey) ?? _showLedgerMonthStats;
    _ledgerKindColor = prefs.getBool(_ledgerKindColorKey) ?? _ledgerKindColor;
  }
}
