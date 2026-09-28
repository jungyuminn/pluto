import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/live_category.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class GetCalendarEvents {
  const GetCalendarEvents(this._repository, [this._categories]);

  final CalendarEventRepository _repository;
  final EventCategoryRepository? _categories;

  Future<List<CalendarEvent>> call() async {
    final events = await _repository.getAll();
    final categories = await _categories?.getAll();
    if (categories == null || categories.isEmpty) return events;
    return LiveCategory.events(events, categories);
  }
}
