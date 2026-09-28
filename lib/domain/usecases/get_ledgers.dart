import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/live_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';
import 'package:pluto/domain/repositories/ledger_repository.dart';

class GetLedgers {
  const GetLedgers(this._repository, [this._categories]);

  final LedgerRepository _repository;
  final EventCategoryRepository? _categories;

  Future<List<LedgerEntry>> call() async {
    final items = await _repository.getAll();
    final categories = await _categories?.getAll();
    if (categories == null || categories.isEmpty) return items;
    return LiveCategory.ledgers(items, categories);
  }
}
