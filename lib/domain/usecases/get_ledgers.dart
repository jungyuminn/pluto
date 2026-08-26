import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/repositories/ledger_repository.dart';

class GetLedgers {
  const GetLedgers(this._repository);

  final LedgerRepository _repository;

  Future<List<LedgerEntry>> call() => _repository.getAll();
}
