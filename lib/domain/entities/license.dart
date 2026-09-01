class License {
  const License({
    required this.id,
    required this.name,
    this.issuer = '',
    this.number = '',
    this.grade = '',
    this.acquiredAt,
    this.expiresAt,
    this.memo = '',
    this.filePath,
    this.fileName,
    this.sortOrder = 0,
    this.categoryId,
    this.categoryName = '',
    this.categoryColor,
  });

  final String id;
  final String name;
  final String issuer;
  final String number;
  final String grade;
  final DateTime? acquiredAt;
  final DateTime? expiresAt;
  final String memo;
  final String? filePath;
  final String? fileName;
  final int sortOrder;
  final String? categoryId;
  final String categoryName;
  final int? categoryColor;

  bool get hasFile {
    final name = fileName?.trim() ?? '';
    return name.isNotEmpty;
  }

  bool get hasCategory =>
      (categoryId?.isNotEmpty ?? false) && categoryName.trim().isNotEmpty;

  String get categoryKey {
    if (categoryId != null && categoryId!.isNotEmpty) return categoryId!;
    return categoryName;
  }

  bool isExpired([DateTime? now]) {
    final end = expiresAt;
    if (end == null) return false;
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final last = DateTime(end.year, end.month, end.day);
    return last.isBefore(today);
  }

  static int _compareExpired(License a, License b) {
    final aExpired = a.isExpired();
    final bExpired = b.isExpired();
    if (aExpired != bExpired) return aExpired ? 1 : -1;
    return 0;
  }

  static int compareDateOrder(License a, License b) {
    final expired = _compareExpired(a, b);
    if (expired != 0) return expired;
    final aDate = a.acquiredAt;
    final bDate = b.acquiredAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }

  static int compareListOrder(License a, License b) {
    final expired = _compareExpired(a, b);
    if (expired != 0) return expired;
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    if (byOrder != 0) return byOrder;
    return compareDateOrder(a, b);
  }

  License copyWith({
    String? name,
    String? issuer,
    String? number,
    String? grade,
    DateTime? acquiredAt,
    DateTime? expiresAt,
    String? memo,
    String? filePath,
    String? fileName,
    int? sortOrder,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    bool clearAcquiredAt = false,
    bool clearExpiresAt = false,
    bool clearFile = false,
    bool clearCategory = false,
  }) {
    return License(
      id: id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      number: number ?? this.number,
      grade: grade ?? this.grade,
      acquiredAt: clearAcquiredAt ? null : (acquiredAt ?? this.acquiredAt),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      memo: memo ?? this.memo,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      sortOrder: sortOrder ?? this.sortOrder,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? '' : (categoryName ?? this.categoryName),
      categoryColor:
          clearCategory ? null : (categoryColor ?? this.categoryColor),
    );
  }
}
