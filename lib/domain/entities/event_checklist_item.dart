class EventChecklistItem {
  const EventChecklistItem({
    required this.id,
    this.text = '',
    this.completed = false,
  });

  final String id;
  final String text;
  final bool completed;

  EventChecklistItem copyWith({
    String? id,
    String? text,
    bool? completed,
  }) {
    return EventChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
    };
  }

  factory EventChecklistItem.fromJson(Map<String, dynamic> json) {
    return EventChecklistItem(
      id: '${json['id'] ?? ''}',
      text: '${json['text'] ?? ''}',
      completed: json['completed'] == true,
    );
  }

  static List<EventChecklistItem> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    final items = <EventChecklistItem>[];
    for (var i = 0; i < raw.length; i++) {
      final value = raw[i];
      if (value is! Map) continue;
      final parsed = EventChecklistItem.fromJson(
        Map<String, dynamic>.from(value),
      );
      final text = parsed.text.trim();
      if (text.isEmpty) continue;
      final id = parsed.id.trim();
      items.add(
        parsed.copyWith(
          id: id.isEmpty ? 'c${items.length}_$i' : id,
          text: text,
        ),
      );
    }
    return items;
  }

  static List<Map<String, dynamic>> listToJson(
    Iterable<EventChecklistItem> items,
  ) {
    return [
      for (final item in items)
        if (item.text.trim().isNotEmpty)
          item.copyWith(text: item.text.trim()).toJson(),
    ];
  }

  static List<EventChecklistItem> cleaned(
    Iterable<EventChecklistItem> items,
  ) {
    return [
      for (final item in items)
        if (item.text.trim().isNotEmpty)
          item.copyWith(text: item.text.trim()),
    ];
  }
}
