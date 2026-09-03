import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/repositories/ledger_repository.dart';

class GetLedgers {
  const GetLedgers(this._repository);

  final LedgerRepository _repository;

  Future<List<LedgerEntry>> call() => _repository.getAll();
}
