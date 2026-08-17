import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/repositories/event_category_repository.dart';

class AddEventCategory {
  const AddEventCategory(this._repository);

  final EventCategoryRepository _repository;

  Future<void> call(EventCategory category) => _repository.add(category);
}
