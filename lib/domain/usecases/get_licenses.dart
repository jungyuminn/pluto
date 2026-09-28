import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/domain/live_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';
import 'package:pluto/domain/repositories/license_repository.dart';

class GetLicenses {
  const GetLicenses(this._repository, [this._categories]);

  final LicenseRepository _repository;
  final EventCategoryRepository? _categories;

  Future<List<License>> call() async {
    final items = List<License>.from(await _repository.getAll());
    items.sort(License.compareListOrder);
    final categories = await _categories?.getAll();
    if (categories == null || categories.isEmpty) return items;
    return LiveCategory.licenses(items, categories);
  }
}
