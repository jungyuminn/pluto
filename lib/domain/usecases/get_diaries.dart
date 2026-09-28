import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/live_category.dart';
import 'package:pluto/domain/repositories/diary_repository.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class GetDiaries {
  const GetDiaries(this._repository, [this._categories]);

  final DiaryRepository _repository;
  final EventCategoryRepository? _categories;

  Future<List<DiaryEntry>> call() async {
    final items = await _repository.getAll();
    final categories = await _categories?.getAll();
    if (categories == null || categories.isEmpty) return items;
    return LiveCategory.diaries(items, categories);
  }
}
