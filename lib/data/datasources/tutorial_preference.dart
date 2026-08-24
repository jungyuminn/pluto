import 'package:shared_preferences/shared_preferences.dart';

class TutorialPreference {
  TutorialPreference({SharedPreferences? this._prefs});

  static const _key = 'tutorial_completed';

  final SharedPreferences? _prefs;

  bool get completed => _prefs?.getBool(_key) ?? true;

  bool get shouldAutoStart {
    if (_prefs == null) return false;
    if (_prefs.containsKey(_key)) return !_prefs.getBool(_key)!;
    return true;
  }

  Future<void> markCompleted() async {
    await _prefs?.setBool(_key, true);
  }

  Future<void> markSkippedForExistingUser() async {
    await _prefs?.setBool(_key, true);
  }
}
