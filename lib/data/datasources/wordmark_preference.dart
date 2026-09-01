import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WordmarkSlot { home, job, license }

class WordmarkPreference extends ChangeNotifier {
  WordmarkPreference({SharedPreferences? prefs})
      : _prefs = prefs,
        _home = _read(prefs, _homeKey),
        _job = _read(prefs, _jobKey),
        _license = _read(prefs, _licenseKey);

  static const _homeKey = 'wordmark_home';
  static const _jobKey = 'wordmark_job';
  static const _licenseKey = 'wordmark_license';

  final SharedPreferences? _prefs;
  String? _home;
  String? _job;
  String? _license;

  String? customOf(WordmarkSlot slot) {
    return switch (slot) {
      WordmarkSlot.home => _home,
      WordmarkSlot.job => _job,
      WordmarkSlot.license => _license,
    };
  }

  Future<void> setCustom(WordmarkSlot slot, String value) async {
    final stored = value.trim();
    final next = stored.isEmpty ? null : stored;
    switch (slot) {
      case WordmarkSlot.home:
        if (_home == next) return;
        _home = next;
        await _write(_homeKey, next);
      case WordmarkSlot.job:
        if (_job == next) return;
        _job = next;
        await _write(_jobKey, next);
      case WordmarkSlot.license:
        if (_license == next) return;
        _license = next;
        await _write(_licenseKey, next);
    }
    notifyListeners();
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _home = _read(prefs, _homeKey);
    _job = _read(prefs, _jobKey);
    _license = _read(prefs, _licenseKey);
    notifyListeners();
  }

  static String? _read(SharedPreferences? prefs, String key) {
    final value = prefs?.getString(key)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> _write(String key, String? value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value);
  }
}
