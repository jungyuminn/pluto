import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/repositories/diary_repository.dart';

class GetDiaries {
  const GetDiaries(this._repository);

  final DiaryRepository _repository;

  Future<List<DiaryEntry>> call() => _repository.getAll();
}
