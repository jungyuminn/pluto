import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/repositories/calendar_event_repository.dart';

class GetCalendarEvents {
  const GetCalendarEvents(this._repository);

  final CalendarEventRepository _repository;

  Future<List<CalendarEvent>> call() => _repository.getAll();
}
