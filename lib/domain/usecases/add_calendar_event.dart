import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';

class AddCalendarEvent {
  const AddCalendarEvent(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent event) => _repository.add(event);

  Future<void> many(List<CalendarEvent> events) => _repository.addAll(events);
}
