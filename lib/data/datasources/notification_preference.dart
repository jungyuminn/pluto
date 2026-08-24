import 'package:shared_preferences/shared_preferences.dart';

enum TodoReminderLead {
  off(0),
  minutes5(5),
  minutes10(10),
  minutes30(30),
  hours1(60);

  const TodoReminderLead(this.minutes);
  final int minutes;

  bool get isEnabled => minutes > 0;

  static TodoReminderLead fromMinutes(int value) {
    return TodoReminderLead.values.firstWhere(
      (lead) => lead.minutes == value,
      orElse: () => TodoReminderLead.off,
    );
  }
}

class NotificationPreference {
  NotificationPreference({
    SharedPreferences? prefs,
    TodoReminderLead todoReminderLead = TodoReminderLead.off,
  })  : _prefs = prefs,
        _todoReminderLead = TodoReminderLead.fromMinutes(
          prefs?.getInt(_todoLeadKey) ?? todoReminderLead.minutes,
        ),
        _summaryEnabled = prefs?.getBool(_summaryEnabledKey) ?? true,
        _summaryMinutes = _readMinutes(prefs?.getInt(_summaryHourKey)),
        _leftoverEnabled = prefs?.getBool(_leftoverEnabledKey) ?? true,
        _leftoverMinutes = _readLeftoverMinutes(
          prefs?.getInt(_leftoverMinutesKey),
        );

  static const defaultSummaryHour = 7;
  static const defaultSummaryMinutes = defaultSummaryHour * 60;
  static const defaultLeftoverHour = 21;
  static const defaultLeftoverMinutes = defaultLeftoverHour * 60;
  static const _todoLeadKey = 'todo_reminder_lead_minutes';
  static const _summaryEnabledKey = 'summary_reminder_enabled';
  static const _summaryHourKey = 'summary_reminder_hour';
  static const _leftoverEnabledKey = 'leftover_reminder_enabled';
  static const _leftoverMinutesKey = 'leftover_reminder_minutes';

  static List<int> get summaryTimeOptions =>
      [for (var hour = 0; hour < 24; hour++) hour * 60];

  static List<int> get leftoverTimeOptions => summaryTimeOptions;

  final SharedPreferences? _prefs;
  TodoReminderLead _todoReminderLead;
  bool _summaryEnabled;
  int _summaryMinutes;
  bool _leftoverEnabled;
  int _leftoverMinutes;

  TodoReminderLead get todoReminderLead => _todoReminderLead;
  bool get summaryEnabled => _summaryEnabled;
  int get summaryMinutes => _summaryMinutes;
  int get summaryHour => _summaryMinutes ~/ 60;
  int get summaryMinute => _summaryMinutes % 60;
  bool get leftoverEnabled => _leftoverEnabled;
  int get leftoverMinutes => _leftoverMinutes;
  int get leftoverHour => _leftoverMinutes ~/ 60;
  int get leftoverMinute => _leftoverMinutes % 60;

  Future<void> setTodoReminderLead(TodoReminderLead value) async {
    _todoReminderLead = value;
    await _prefs?.setInt(_todoLeadKey, value.minutes);
  }

  Future<void> setSummaryEnabled(bool value) async {
    _summaryEnabled = value;
    await _prefs?.setBool(_summaryEnabledKey, value);
  }

  Future<void> setSummaryMinutes(int minutes) async {
    _summaryMinutes = minutes.clamp(0, 24 * 60 - 1);
    _summaryEnabled = true;
    await _prefs?.setInt(_summaryHourKey, _summaryMinutes);
    await _prefs?.setBool(_summaryEnabledKey, true);
  }

  Future<void> setLeftoverEnabled(bool value) async {
    _leftoverEnabled = value;
    await _prefs?.setBool(_leftoverEnabledKey, value);
  }

  Future<void> setLeftoverMinutes(int minutes) async {
    _leftoverMinutes = minutes.clamp(0, 24 * 60 - 1);
    _leftoverEnabled = true;
    await _prefs?.setInt(_leftoverMinutesKey, _leftoverMinutes);
    await _prefs?.setBool(_leftoverEnabledKey, true);
  }

  static int _readMinutes(int? stored) {
    if (stored == null) return defaultSummaryMinutes;
    if (stored <= 23) return stored * 60;
    final minutes = stored.clamp(0, 24 * 60 - 1);
    return (minutes ~/ 60) * 60;
  }

  static int _readLeftoverMinutes(int? stored) {
    if (stored == null) return defaultLeftoverMinutes;
    final minutes = stored.clamp(0, 24 * 60 - 1);
    if (minutes % 60 != 0) return defaultLeftoverMinutes;
    return minutes;
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _todoReminderLead = TodoReminderLead.fromMinutes(
      prefs.getInt(_todoLeadKey) ?? _todoReminderLead.minutes,
    );
    _summaryEnabled = prefs.getBool(_summaryEnabledKey) ?? _summaryEnabled;
    _summaryMinutes = _readMinutes(prefs.getInt(_summaryHourKey));
    _leftoverEnabled = prefs.getBool(_leftoverEnabledKey) ?? _leftoverEnabled;
    _leftoverMinutes = _readLeftoverMinutes(prefs.getInt(_leftoverMinutesKey));
  }
}
