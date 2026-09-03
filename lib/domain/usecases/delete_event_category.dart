import 'package:pluto/domain/repositories/event_category_repository.dart';

class DeleteEventCategory {
  const DeleteEventCategory(this._repository);

  final EventCategoryRepository _repository;

  Future<void> call(Iterable<String> ids) {
    return _repository.deleteMany(ids);
  }
}
