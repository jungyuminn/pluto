import 'package:pluto/data/datasources/ledger_local_datasource.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/repositories/ledger_repository.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  const LedgerRepositoryImpl(this._localDataSource);

  final LedgerLocalDataSource _localDataSource;

  @override
  Future<List<LedgerEntry>> getAll() async {
    return _localDataSource.fetchAll();
  }

  @override
  Future<void> save(LedgerEntry entry) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([
      for (final item in current)
        if (item.id != entry.id) item,
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
