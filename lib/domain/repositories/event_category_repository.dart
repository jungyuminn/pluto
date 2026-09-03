import 'package:pluto/domain/entities/event_category.dart';

abstract class EventCategoryRepository {
  Future<List<EventCategory>> getAll();
  Future<void> add(EventCategory category);
  Future<void> update(EventCategory category);
  Future<void> deleteMany(Iterable<String> ids);
  Future<void> replaceAll(List<EventCategory> categories);
}
