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
  })  : _prefs = prefs,
        _sortByTime = prefs?.getBool(_sortKey) ?? sortByTime,
        _showTime = prefs?.getBool(_showTimeKey) ?? showTime,
        _categoryView = prefs?.getBool(_categoryViewKey) ?? categoryView,
        _showLedgerTitle =
            prefs?.getBool(_ledgerTitleKey) ?? showLedgerTitle,
        _showLedgerAmount =
            prefs?.getBool(_ledgerAmountKey) ?? showLedgerAmount;

  static const _sortKey = 'day_events_sort_by_time';
  static const _showTimeKey = 'day_events_show_time';
  static const _categoryViewKey = 'day_events_category_view';
  static const _ledgerTitleKey = 'calendar_show_ledger_title';
  static const _ledgerAmountKey = 'calendar_show_ledger_amount';

  final SharedPreferences? _prefs;
  bool _sortByTime;
  bool _showTime;
  bool _categoryView;
  bool _showLedgerTitle;
  bool _showLedgerAmount;

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

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _sortByTime = prefs.getBool(_sortKey) ?? _sortByTime;
    _showTime = prefs.getBool(_showTimeKey) ?? _showTime;
    _categoryView = prefs.getBool(_categoryViewKey) ?? _categoryView;
    _showLedgerTitle = prefs.getBool(_ledgerTitleKey) ?? _showLedgerTitle;
    _showLedgerAmount = prefs.getBool(_ledgerAmountKey) ?? _showLedgerAmount;
  }
}
