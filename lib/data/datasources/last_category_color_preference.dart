import 'package:shared_preferences/shared_preferences.dart';

class LastCategoryColorPreference {
  LastCategoryColorPreference({SharedPreferences? prefs}) : _prefs = prefs;

  static const key = 'last_added_category_color';
  static const syncedKeys = [key];

  final SharedPreferences? _prefs;

  int? get color => _prefs?.getInt(key);

  Future<void> setColor(int value) async {
    await _prefs?.setInt(key, value);
  }
}
