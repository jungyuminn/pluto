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
        _summaryMinutes = _readMinutes(prefs?.getInt(_summaryHourKey));

  static const defaultSummaryHour = 7;
  static const defaultSummaryMinutes = defaultSummaryHour * 60;
  static const _todoLeadKey = 'todo_reminder_lead_minutes';
  static const _summaryEnabledKey = 'summary_reminder_enabled';
  static const _summaryHourKey = 'summary_reminder_hour';

  static List<int> get summaryTimeOptions {
    final times = [for (var hour = 0; hour < 24; hour++) hour * 60];
    times.addAll([for (var minute = 30; minute <= 40; minute++) 21 * 60 + minute]);
    times.sort();
    return times;
  }

  final SharedPreferences? _prefs;
  TodoReminderLead _todoReminderLead;
  bool _summaryEnabled;
  int _summaryMinutes;

  TodoReminderLead get todoReminderLead => _todoReminderLead;
  bool get summaryEnabled => _summaryEnabled;
  int get summaryMinutes => _summaryMinutes;
  int get summaryHour => _summaryMinutes ~/ 60;
  int get summaryMinute => _summaryMinutes % 60;

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

  static int _readMinutes(int? stored) {
    if (stored == null) return defaultSummaryMinutes;
    if (stored <= 23) return stored * 60;
    return stored.clamp(0, 24 * 60 - 1);
  }
}
