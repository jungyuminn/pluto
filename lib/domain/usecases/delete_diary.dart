import 'package:job_planner/domain/repositories/diary_repository.dart';

class DeleteDiary {
  const DeleteDiary(this._repository);

  final DiaryRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
