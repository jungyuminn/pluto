import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/repositories/diary_repository.dart';

class SaveDiary {
  const SaveDiary(this._repository);

  final DiaryRepository _repository;

  Future<void> call(DiaryEntry entry) => _repository.save(entry);
}
