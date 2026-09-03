import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/repositories/diary_repository.dart';

class DiaryMemoryRepository implements DiaryRepository {
  DiaryMemoryRepository([List<DiaryEntry>? seed]) : _items = [...?seed];

  final List<DiaryEntry> _items;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<List<DiaryEntry>> getAll() async => List.unmodifiable(_items);

  bool _replacesSameDay(DiaryEntry existing, DiaryEntry incoming) {
    if (!_sameDay(existing.day, incoming.day)) return false;
    if (incoming.groupId != null) {
      return existing.groupId == incoming.groupId;
    }
    return existing.groupId == null;
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    _items.removeWhere(
      (item) => item.id == entry.id || _replacesSameDay(item, entry),
    );
    _items.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
