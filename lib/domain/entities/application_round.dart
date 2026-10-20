class ApplicationRound {
  const ApplicationRound({
    this.name = '',
    this.date,
    this.note = '',
    this.completed = false,
  });

  final String name;
  final DateTime? date;
  final String note;
  final bool completed;

  bool get isEmpty => name.isEmpty && date == null && note.isEmpty;

  bool isPast([DateTime? now]) {
    if (date == null) return false;
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(date!.year, date!.month, date!.day);
    return target.isBefore(today);
  }

  String? get dateText {
    if (date == null) return null;
    return '${date!.year}년 ${date!.month}월 ${date!.day}일';
  }

  String? get summary {
    final dateLabel = dateText;
    if (name.isEmpty && dateLabel == null) return null;
    if (name.isNotEmpty && dateLabel != null) return '$name - $dateLabel';
    if (name.isNotEmpty) return name;
    return dateLabel;
  }

  ApplicationRound copyWith({
    String? name,
    DateTime? date,
    String? note,
    bool? completed,
    bool clearDate = false,
  }) {
    return ApplicationRound(
      name: name ?? this.name,
      date: clearDate ? null : (date ?? this.date),
      note: note ?? this.note,
      completed: completed ?? this.completed,
    );
  }
}
