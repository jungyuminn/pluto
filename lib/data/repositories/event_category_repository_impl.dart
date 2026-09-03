import 'package:pluto/data/datasources/event_category_local_datasource.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class EventCategoryRepositoryImpl implements EventCategoryRepository {
  const EventCategoryRepositoryImpl(this._localDataSource);

  final EventCategoryLocalDataSource _localDataSource;

  @override
  Future<List<EventCategory>> getAll() async {
    return _localDataSource.fetchAll();
  }

  @override
  Future<void> add(EventCategory category) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([...current, category]);
  }

  @override
  Future<void> update(EventCategory category) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id == category.id) category else item,
    ]);
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    final remove = ids.toSet();
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (!remove.contains(item.id)) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<EventCategory> categories) {
    return _localDataSource.saveAll(categories);
  }
}
