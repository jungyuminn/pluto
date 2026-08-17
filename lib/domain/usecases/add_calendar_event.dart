import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/repositories/calendar_event_repository.dart';

class AddCalendarEvent {
  const AddCalendarEvent(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(CalendarEvent event) => _repository.add(event);
}
