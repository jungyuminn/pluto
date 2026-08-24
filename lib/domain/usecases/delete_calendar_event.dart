import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/repositories/calendar_event_repository.dart';

class DeleteCalendarEvent {
  const DeleteCalendarEvent(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent event) {
    final groupId = event.groupId;
    if (groupId != null) return _repository.deleteGroup(groupId);
    return _repository.delete(event.id);
  }

  Future<void> thisOnly(CalendarEvent event) {
    return _repository.delete(event.id);
  }

  Future<void> thisAndAfter(CalendarEvent event) {
    final repeatId = event.repeatId;
    if (repeatId == null) return _repository.delete(event.id);
    return _repository.deleteRepeatFrom(repeatId, event.day);
  }

  Future<void> allRepeats(String repeatId) {
    return _repository.deleteRepeat(repeatId);
  }

  Future<void> many(Iterable<String> ids) {
    return _repository.deleteMany(ids);
  }
}
