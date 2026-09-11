import 'package:shared_preferences/shared_preferences.dart';

class TutorialPreference {
  TutorialPreference({SharedPreferences? this._prefs});

  static const _key = 'tutorial_completed';
  static const _featureIntroEligibleKey = 'feature_intro_eligible';
  static const _featureIntroDismissedKey = 'feature_intro_dismissed';

  final SharedPreferences? _prefs;

  bool get completed => _prefs?.getBool(_key) ?? true;

  bool get shouldAutoStart {
    if (_prefs == null) return false;
    if (_prefs.containsKey(_key)) return !_prefs.getBool(_key)!;
    return true;
  }

  bool get featureIntroDismissed =>
      _prefs?.getBool(_featureIntroDismissedKey) ?? false;

  bool get featureIntroEligible =>
      _prefs?.getBool(_featureIntroEligibleKey) ?? false;

  bool get featureIntroVisible {
    if (_prefs == null || featureIntroDismissed) return false;
    return featureIntroEligible;
  }

  Future<void> markCompleted() async {
    await _prefs?.setBool(_key, true);
  }

  Future<void> markSkippedForExistingUser() async {
    await _prefs?.setBool(_key, true);
  }

  Future<void> markFeatureIntroEligible() async {
    await _prefs?.setBool(_featureIntroEligibleKey, true);
  }

  Future<void> skipFeatureIntro() async {
    await _prefs?.setBool(_featureIntroDismissedKey, true);
  }
}
