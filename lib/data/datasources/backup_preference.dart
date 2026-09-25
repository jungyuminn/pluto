import 'package:shared_preferences/shared_preferences.dart';

enum AutoBackupInterval {
  off(0),
  daily(1),
  every3Days(3),
  weekly(7),
  monthly(30);

  const AutoBackupInterval(this.days);
  final int days;

  bool get isEnabled => days > 0;

  static AutoBackupInterval fromDays(int value) {
    return AutoBackupInterval.values.firstWhere(
      (interval) => interval.days == value,
      orElse: () => AutoBackupInterval.off,
    );
  }
}

class BackupPreference {
  BackupPreference({
    SharedPreferences? prefs,
    AutoBackupInterval interval = AutoBackupInterval.off,
  })  : _prefs = prefs,
        _interval = prefs == null
            ? interval
            : AutoBackupInterval.fromDays(
                prefs.getInt(_intervalKey) ?? AutoBackupInterval.off.days,
              ),
        _lastBackupAt = DateTime.tryParse(
          prefs?.getString(_lastAtKey) ?? '',
        );

  static const _intervalKey = 'auto_backup_interval_days';
  static const _lastAtKey = 'auto_backup_last_at';

  final SharedPreferences? _prefs;
  AutoBackupInterval _interval;
  DateTime? _lastBackupAt;

  AutoBackupInterval get interval => _interval;
  DateTime? get lastBackupAt => _lastBackupAt;

  bool get isDue {
    if (_prefs == null || !_interval.isEnabled) return false;
    final last = _lastBackupAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= Duration(days: _interval.days);
  }

  Future<void> setInterval(AutoBackupInterval value) async {
    final wasOff = !_interval.isEnabled;
    _interval = value;
    await _prefs?.setInt(_intervalKey, value.days);
    if (wasOff && value.isEnabled) {
      _lastBackupAt = null;
      await _prefs?.remove(_lastAtKey);
    }
  }

  Future<void> markBackedUp([DateTime? now]) async {
    final stamp = now ?? DateTime.now();
    _lastBackupAt = stamp;
    await _prefs?.setString(_lastAtKey, stamp.toIso8601String());
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _interval = AutoBackupInterval.fromDays(
      prefs.getInt(_intervalKey) ?? _interval.days,
    );
    _lastBackupAt = DateTime.tryParse(prefs.getString(_lastAtKey) ?? '');
  }
}
