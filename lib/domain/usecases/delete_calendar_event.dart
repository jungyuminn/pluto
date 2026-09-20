import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';

class DeleteCalendarEvent {
  const DeleteCalendarEvent(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent event) {
    final sharedId = event.sharedId?.trim() ?? '';
    if (sharedId.isNotEmpty) {
      return _repository.deleteBySharedId(sharedId);
    }
    final groupId = event.groupId;
    if (groupId != null) return _repository.deleteGroup(groupId);
    return _repository.delete(event.id);
  }

  Future<void> thisOnly(CalendarEvent event) {
    final sharedId = event.sharedId?.trim() ?? '';
    if (sharedId.isNotEmpty) {
      return _repository.deleteBySharedId(sharedId);
    }
    return _repository.delete(event.id);
  }

  Future<void> thisAndAfter(CalendarEvent event) {
    final sharedId = event.sharedId?.trim() ?? '';
    if (sharedId.isNotEmpty) {
      return _repository.deleteBySharedId(sharedId);
    }
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
