import 'package:pluto/domain/entities/event_category.dart';

class CategoryHistoryRecord {
  const CategoryHistoryRecord(this.title, this.categoryId);

  final String title;
  final String categoryId;
}

abstract final class CategoryHistory {
  static String normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static EventCategory? match({
    required String title,
    required List<EventCategory> categories,
    required List<CategoryHistoryRecord> records,
  }) {
    final key = normalize(title);
    if (key.isEmpty || categories.isEmpty) return null;

    final byId = {for (final category in categories) category.id: category};
    String? lastId;
    for (final record in records) {
      if (record.categoryId.isEmpty) continue;
      if (normalize(record.title) == key) lastId = record.categoryId;
    }
    final exact = byId[lastId];
    if (exact != null) return exact;

    EventCategory? named;
    var namedLen = 0;
    for (final category in categories) {
      final name = normalize(category.name);
      if (name.length < 2 || !key.contains(name)) continue;
      if (name.length > namedLen) {
        named = category;
        namedLen = name.length;
      }
    }
    return named;
  }
}
