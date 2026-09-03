import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';

class ReorderCalendarEvents {
  const ReorderCalendarEvents(this._repository);

  final CalendarEventRepository _repository;

  Future<void> call(List<CalendarEvent> ordered) async {
    final orders = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    if (orders.isEmpty) return;
    final current = await _repository.getAll();
    await _repository.replaceAll([
      for (final event in current)
        if (orders.containsKey(event.id))
          event.copyWith(sortOrder: orders[event.id])
        else
          event,
    ]);
  }
}
