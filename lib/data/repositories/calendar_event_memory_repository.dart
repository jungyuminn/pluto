import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/repositories/calendar_event_repository.dart';

class CalendarEventMemoryRepository implements CalendarEventRepository {
  CalendarEventMemoryRepository([List<CalendarEvent>? seed])
    : _items = [...?seed];

  final List<CalendarEvent> _items;

  @override
  Future<List<CalendarEvent>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(CalendarEvent event) async {
    _items.add(event);
  }

  @override
  Future<void> addAll(List<CalendarEvent> events) async {
    _items.addAll(events);
  }

  @override
  Future<void> update(CalendarEvent event) async {
    final index = _items.indexWhere((item) => item.id == event.id);
    if (index < 0) return;
    _items[index] = event;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    final remove = ids.toSet();
    _items.removeWhere((item) => remove.contains(item.id));
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _items.removeWhere((item) => item.groupId == groupId);
  }

  @override
  Future<void> updateGroup(String groupId, CalendarEvent patch) async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.groupId != groupId) continue;
      _items[i] = item.copyWith(
        title: patch.title,
        memo: patch.memo,
        categoryId: patch.categoryId,
        categoryName: patch.categoryName,
        categoryColor: patch.categoryColor,
        completed: patch.completed,
        startMinutes: patch.startMinutes,
        endMinutes: patch.endMinutes,
        clearTime: !patch.hasTime,
      );
    }
  }

  @override
  Future<void> updateRepeatTitles(String repeatId, String title) async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.repeatId != repeatId) continue;
      _items[i] = item.copyWith(title: title);
    }
  }

  @override
  Future<void> deleteRepeat(String repeatId) async {
    _items.removeWhere((item) => item.repeatId == repeatId);
  }

  @override
  Future<void> deleteRepeatFrom(String repeatId, DateTime from) async {
    final start = DateTime(from.year, from.month, from.day);
    _items.removeWhere(
      (item) => item.repeatId == repeatId && !item.day.isBefore(start),
    );
  }

  @override
  Future<void> replaceAll(List<CalendarEvent> events) async {
    _items
      ..clear()
      ..addAll(events);
  }
}
