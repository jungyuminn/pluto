import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/repositories/diary_repository.dart';

class SaveDiary {
  const SaveDiary(this._repository);

  final DiaryRepository _repository;

  Future<void> call(DiaryEntry entry) => _repository.save(entry);
}
