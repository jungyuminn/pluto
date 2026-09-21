import 'package:pluto/data/datasources/calendar_event_local_datasource.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/repositories/calendar_event_repository.dart';

class CalendarEventRepositoryImpl implements CalendarEventRepository {
  const CalendarEventRepositoryImpl(this._localDataSource);

  final CalendarEventLocalDataSource _localDataSource;

  @override
  Future<List<CalendarEvent>> getAll() async {
    return _localDataSource.fetchAll();
  }

  @override
  Future<void> add(CalendarEvent event) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([...current, event]);
  }

  @override
  Future<void> addAll(List<CalendarEvent> events) async {
    if (events.isEmpty) return;
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([...current, ...events]);
  }

  @override
  Future<void> update(CalendarEvent event) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id == event.id) event else item,
    ]);
  }

  Future<void> _forgetShared(Iterable<CalendarEvent> events) async {
    for (final event in events) {
      final sharedId = event.sharedId?.trim() ?? '';
      if (sharedId.isEmpty) continue;
      await FriendService.instance.removeShared(sharedId);
    }
  }

  @override
  Future<void> delete(String id) async {
    final current = _localDataSource.fetchAll();
    await _forgetShared([
      for (final item in current)
        if (item.id == id) item,
    ]);
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    final remove = ids.toSet();
    if (remove.isEmpty) return;
    final current = _localDataSource.fetchAll();
    await _forgetShared([
      for (final item in current)
        if (remove.contains(item.id)) item,
    ]);
    await _localDataSource.saveAll([
      for (final item in current)
        if (!remove.contains(item.id)) item,
    ]);
  }

  @override
  Future<void> deleteBySharedId(String sharedId) async {
    final id = sharedId.trim();
    if (id.isEmpty) return;
    await FriendService.instance.removeShared(id);
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if ((item.sharedId ?? '').trim() != id) item,
    ]);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final current = _localDataSource.fetchAll();
    await _forgetShared([
      for (final item in current)
        if (item.groupId == groupId) item,
    ]);
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.groupId != groupId) item,
    ]);
  }

  @override
  Future<void> updateGroup(String groupId, CalendarEvent patch) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.groupId == groupId)
          item.copyWith(
            title: patch.title,
            memo: patch.memo,
            categoryId: patch.categoryId,
            categoryName: patch.categoryName,
            categoryColor: patch.categoryColor,
            completed: patch.completed,
            startMinutes: patch.startMinutes,
            endMinutes: patch.endMinutes,
            clearTime: !patch.hasTime,
            clearEnd: patch.hasTime && patch.endMinutes == null,
          )
        else
          item,
    ]);
  }

  @override
  Future<void> updateRepeatTitles(String repeatId, String title) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.repeatId == repeatId) item.copyWith(title: title) else item,
    ]);
  }

  @override
  Future<void> deleteRepeat(String repeatId) async {
    final current = _localDataSource.fetchAll();
    await _forgetShared([
      for (final item in current)
        if (item.repeatId == repeatId) item,
    ]);
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.repeatId != repeatId) item,
    ]);
  }

  @override
  Future<void> deleteRepeatFrom(String repeatId, DateTime from) async {
    final start = DateTime(from.year, from.month, from.day);
    final current = _localDataSource.fetchAll();
    final removing = [
      for (final item in current)
        if (item.repeatId == repeatId && !item.day.isBefore(start)) item,
    ];
    final sharedId = removing
        .map((item) => item.sharedId?.trim() ?? '')
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    if (sharedId.isNotEmpty) {
      await deleteBySharedId(sharedId);
      return;
    }
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.repeatId != repeatId || item.day.isBefore(start)) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<CalendarEvent> events) {
    return _localDataSource.saveAll(events);
  }
}
