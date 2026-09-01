enum DiaryCover {
  basic,
  lined,
  grid,
  dotted,
  kraft,
  sky,
  rose,
  mint,
  blank;

  static const fallback = basic;

  static DiaryCover fromId(String? id) {
    for (final cover in values) {
      if (cover.id == id) return cover;
    }
    return fallback;
  }

  static List<DiaryCover> ordered(Iterable<String>? ids) {
    final remaining = List<DiaryCover>.of(values);
    final result = <DiaryCover>[];
    for (final id in ids ?? const <String>[]) {
      final index = remaining.indexWhere((cover) => cover.id == id);
      if (index < 0) continue;
      result.add(remaining.removeAt(index));
    }
    result.addAll(remaining);
    return result;
  }

  String get id => name;
}
