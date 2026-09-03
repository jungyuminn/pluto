import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class ReorderEventCategories {
  const ReorderEventCategories(this._repository);

  final EventCategoryRepository _repository;

  Future<void> call(List<EventCategory> categories) {
    return _repository.replaceAll(categories);
  }
}
