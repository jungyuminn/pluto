import 'package:shared_preferences/shared_preferences.dart';

enum TodoReminderLead {
  minutes5(5),
  minutes10(10),
  minutes30(30),
  hours1(60);

  const TodoReminderLead(this.minutes);
  final int minutes;

  static TodoReminderLead fromMinutes(int value) {
    return TodoReminderLead.values.firstWhere(
      (lead) => lead.minutes == value,
      orElse: () => TodoReminderLead.minutes10,
    );
  }
}

class NotificationPreference {
  NotificationPreference({
    SharedPreferences? prefs,
    TodoReminderLead todoReminderLead = TodoReminderLead.minutes10,
  })  : _prefs = prefs,
        _todoReminderLead = TodoReminderLead.fromMinutes(
          prefs?.getInt(_todoLeadKey) ?? todoReminderLead.minutes,
        );

  static const _todoLeadKey = 'todo_reminder_lead_minutes';

  final SharedPreferences? _prefs;
  TodoReminderLead _todoReminderLead;

  TodoReminderLead get todoReminderLead => _todoReminderLead;

  Future<void> setTodoReminderLead(TodoReminderLead value) async {
    _todoReminderLead = value;
    await _prefs?.setInt(_todoLeadKey, value.minutes);
  }
}
