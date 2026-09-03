import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';

class GetCalendarEvents {
  const GetCalendarEvents(this._repository);

  final CalendarEventRepository _repository;

  Future<List<CalendarEvent>> call() => _repository.getAll();
}
