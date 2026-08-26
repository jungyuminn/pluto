import 'package:job_planner/domain/entities/ledger_entry.dart';

abstract class LedgerRepository {
  Future<List<LedgerEntry>> getAll();
  Future<void> save(LedgerEntry entry);
  Future<void> delete(String id);
}
