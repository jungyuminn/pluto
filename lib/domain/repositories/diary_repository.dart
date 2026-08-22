import 'package:job_planner/domain/entities/diary_entry.dart';

abstract class DiaryRepository {
  Future<List<DiaryEntry>> getAll();
  Future<void> save(DiaryEntry entry);
  Future<void> delete(String id);
}
