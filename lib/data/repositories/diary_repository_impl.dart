import 'package:pluto/data/datasources/diary_local_datasource.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/repositories/diary_repository.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  const DiaryRepositoryImpl(this._localDataSource);

  final DiaryLocalDataSource _localDataSource;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<List<DiaryEntry>> getAll() async {
    return _localDataSource.fetchAll();
  }

  bool _replacesSameDay(DiaryEntry existing, DiaryEntry incoming) {
    if (!_sameDay(existing.day, incoming.day)) return false;
    if (incoming.groupId != null) {
      return existing.groupId == incoming.groupId;
    }
    return existing.groupId == null;
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id != entry.id && !_replacesSameDay(item, entry)) item,
      entry,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id != id) item,
    ]);
  }
}
