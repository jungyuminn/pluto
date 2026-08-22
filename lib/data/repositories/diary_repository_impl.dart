import 'package:job_planner/data/datasources/diary_local_datasource.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/repositories/diary_repository.dart';

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

  @override
  Future<void> save(DiaryEntry entry) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id != entry.id && !_sameDay(item.day, entry.day)) item,
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
