import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';

class UpdateCalendarEvent {
  const UpdateCalendarEvent(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent event) {
    final groupId = event.groupId;
    if (groupId != null) return _repository.updateGroup(groupId, event);
    return _repository.update(event);
  }

  Future<void> instance(CalendarEvent event) {
    return _repository.update(event);
  }

  Future<void> moveGroup(String groupId, DateTime start) async {
    final target = DateTime(start.year, start.month, start.day);
    final current = await _repository.getAll();
    DateTime? first;
    for (final event in current) {
      if (event.groupId != groupId) continue;
      if (first == null || event.day.isBefore(first)) first = event.day;
    }
    if (first == null) return;
    final days = target.difference(first).inDays;
    if (days == 0) return;
    await _repository.replaceAll([
      for (final event in current)
        if (event.groupId == groupId)
          event.copyWith(
            date: DateTime(
              event.day.year,
              event.day.month,
              event.day.day + days,
            ),
          )
        else
          event,
    ]);
  }

  Future<void> repeatTitles(String repeatId, String title) {
    return _repository.updateRepeatTitles(repeatId, title);
  }
}
