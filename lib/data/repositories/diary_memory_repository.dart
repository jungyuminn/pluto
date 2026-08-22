import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/repositories/diary_repository.dart';

class DiaryMemoryRepository implements DiaryRepository {
  DiaryMemoryRepository([List<DiaryEntry>? seed]) : _items = [...?seed];

  final List<DiaryEntry> _items;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<List<DiaryEntry>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> save(DiaryEntry entry) async {
    _items.removeWhere(
      (item) => item.id == entry.id || _sameDay(item.day, entry.day),
    );
    _items.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
