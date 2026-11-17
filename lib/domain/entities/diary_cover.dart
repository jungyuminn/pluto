enum DiaryCover {
  blank,
  basic,
  lined,
  grid,
  dotted,
  kraft,
  sky,
  rose,
  mint;

  static const fallback = blank;

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
    result.remove(blank);
    result.insert(0, blank);
    return result;
  }

  String get id => name;
}
