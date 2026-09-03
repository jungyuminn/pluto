import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class UpdateEventCategory {
  const UpdateEventCategory(this._repository);

  final EventCategoryRepository _repository;

  Future<void> call(EventCategory category) => _repository.update(category);
}
