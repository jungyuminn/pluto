import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/repositories/calendar_event_repository.dart';

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

  Future<void> repeatTitles(String repeatId, String title) {
    return _repository.updateRepeatTitles(repeatId, title);
  }
}
