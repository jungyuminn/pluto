import 'package:shared_preferences/shared_preferences.dart';

class CategorySuggestPreference {
  CategorySuggestPreference({
    SharedPreferences? prefs,
    bool enabled = false,
  })  : _prefs = prefs,
        _enabled = prefs?.getBool(_enabledKey) ?? enabled;

  static const _enabledKey = 'category_suggest_enabled';
  static const syncedKeys = [_enabledKey];
  static const defaultBools = {_enabledKey: false};

  final SharedPreferences? _prefs;
  bool _enabled;

  bool get enabled => _prefs?.getBool(_enabledKey) ?? _enabled;

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs?.setBool(_enabledKey, value);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _enabled = prefs.getBool(_enabledKey) ?? _enabled;
  }
}
