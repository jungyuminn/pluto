import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class EventCategoryMemoryRepository implements EventCategoryRepository {
  EventCategoryMemoryRepository([List<EventCategory>? seed])
    : _items = List.of(seed ?? EventCategory.presets);

  final List<EventCategory> _items;

  @override
  Future<List<EventCategory>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(EventCategory category) async {
    _items.add(category);
  }

  @override
  Future<void> update(EventCategory category) async {
    final index = _items.indexWhere((item) => item.id == category.id);
    if (index < 0) return;
    _items[index] = category;
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    final remove = ids.toSet();
    _items.removeWhere((item) => remove.contains(item.id));
  }

  @override
  Future<void> replaceAll(List<EventCategory> categories) async {
    _items
      ..clear()
      ..addAll(categories);
  }
}
