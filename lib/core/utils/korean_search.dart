class KoreanSearch {
  KoreanSearch._();

  static const _choseongs = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';

  static bool matches(String text, String query) {
    final compactQuery = compact(query);
    if (compactQuery.isEmpty) return true;
    final compactText = compact(text);
    if (compactText.contains(compactQuery)) return true;
    if (choseongsOf(compactText).contains(compactQuery)) return true;
    return _mixedMatch(compactText, compactQuery);
  }

  static bool matchesAny(Iterable<String> texts, String query) {
    return texts.any((text) => matches(text, query));
  }

  static String compact(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  static String choseongsOf(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      buffer.write(_choseongChar(value.codeUnitAt(i)) ?? value[i]);
    }
    return buffer.toString();
  }

  static bool _mixedMatch(String text, String query) {
    for (var start = 0; start < text.length; start++) {
      var ti = start;
      var qi = 0;
      while (qi < query.length && ti < text.length) {
        final textCode = text.codeUnitAt(ti);
        final queryCode = query.codeUnitAt(qi);
        if (textCode == queryCode) {
          ti++;
          qi++;
          continue;
        }
        final textChoseong = _choseongChar(textCode);
        if (textChoseong != null &&
            textChoseong.codeUnitAt(0) == queryCode) {
          ti++;
          qi++;
          continue;
        }
        break;
      }
      if (qi == query.length) return true;
    }
    return false;
  }

  static String? _choseongChar(int code) {
    final compat = _choseongs.indexOf(String.fromCharCode(code));
    if (compat >= 0) return _choseongs[compat];
    if (code < 0xAC00 || code > 0xD7A3) return null;
    return _choseongs[(code - 0xAC00) ~/ 588];
  }
}
