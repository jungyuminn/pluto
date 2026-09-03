import 'package:pluto/domain/repositories/ledger_repository.dart';

class DeleteLedger {
  const DeleteLedger(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
