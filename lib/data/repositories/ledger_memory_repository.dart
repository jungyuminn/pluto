import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/repositories/ledger_repository.dart';

class LedgerMemoryRepository implements LedgerRepository {
  LedgerMemoryRepository([List<LedgerEntry>? seed]) : _items = [...?seed];

  final List<LedgerEntry> _items;

  @override
  Future<List<LedgerEntry>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> save(LedgerEntry entry) async {
    _items.removeWhere((item) => item.id == entry.id);
    _items.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
