import 'package:shared_preferences/shared_preferences.dart';

class HomeViewPreference {
  HomeViewPreference({SharedPreferences? prefs, bool compact = false})
    : _prefs = prefs,
      _compact = prefs?.getBool(_key) ?? compact;

  static const _key = 'home_events_compact_view';

  final SharedPreferences? _prefs;
  bool _compact;

  bool get isCompact => _compact;

  Future<void> setCompact(bool value) async {
    _compact = value;
    await _prefs?.setBool(_key, value);
  }
}
