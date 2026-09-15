class HomeMemo {
  const HomeMemo({
    required this.id,
    required this.title,
    this.body = '',
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String body;
  final int sortOrder;

  String get preview {
    return body.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  HomeMemo copyWith({
    String? title,
    String? body,
    int? sortOrder,
  }) {
    return HomeMemo(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'sortOrder': sortOrder,
    };
  }

  factory HomeMemo.fromJson(Map<String, dynamic> json) {
    return HomeMemo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
