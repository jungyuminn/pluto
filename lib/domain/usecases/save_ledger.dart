import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/repositories/ledger_repository.dart';

class SaveLedger {
  const SaveLedger(this._repository);

  final LedgerRepository _repository;

  Future<void> call(LedgerEntry entry) => _repository.save(entry);
}
