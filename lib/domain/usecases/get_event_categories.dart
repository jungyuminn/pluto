import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';

class GetEventCategories {
  const GetEventCategories(this._repository);

  final EventCategoryRepository _repository;

  Future<List<EventCategory>> call() => _repository.getAll();
}
