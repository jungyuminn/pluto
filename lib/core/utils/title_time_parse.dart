class TitleTimeParseResult {
  const TitleTimeParseResult({
    required this.title,
    required this.startMinutes,
  });

  final String title;
  final int startMinutes;
}

class TitleTimeMatch {
  const TitleTimeMatch({
    required this.start,
    required this.end,
    required this.startMinutes,
  });

  final int start;
  final int end;
  final int startMinutes;
}

class TitleTimeParse {
  TitleTimeParse._();

  static final _amPmSi = RegExp(
    r'(오전|오후)\s*(\d{1,2})\s*시(?:\s*(\d{1,2})\s*분)?(?!간)에?',
  );
  static final _amPmColon = RegExp(
    r'(오전|오후)\s*(\d{1,2}):(\d{2})에?',
  );
  static final _hour24Si = RegExp(
    r'(?<!\d)(1[3-9]|2[0-3])\s*시(?:\s*(\d{1,2})\s*분)?(?!간)에?',
  );
  static final _hour24Colon = RegExp(
    r'(?<!\d)([01]\d|2[0-3]):([0-5]\d)에?',
  );
  static final _hourSi = RegExp(
    r'(?<!\d)(1[01]|[1-9])\s*시(?:\s*(\d{1,2})\s*분)?(?!간)에?',
  );

  static TitleTimeMatch? match(String raw) {
    final hits = <TitleTimeMatch>[
      ..._hits(_amPmSi, raw, _amPmFromSi),
      ..._hits(_amPmColon, raw, _amPmFromColon),
      ..._hits(_hour24Si, raw, _hour24FromSi),
      ..._hits(_hour24Colon, raw, _hour24FromColon),
      ..._hits(_hourSi, raw, _hourFromSi),
    ];
    if (hits.isEmpty) return null;
    hits.sort((a, b) => a.start.compareTo(b.start));
    return hits.first;
  }

  static TitleTimeParseResult? of(String raw) {
    final hit = match(raw);
    if (hit == null) return null;
    final title = raw.replaceRange(hit.start, hit.end, ' ').replaceAll(
          RegExp(r'\s+'),
          ' ',
        ).trim();
    if (title.isEmpty) return null;
    return TitleTimeParseResult(title: title, startMinutes: hit.startMinutes);
  }

  static List<TitleTimeMatch> _hits(
    RegExp pattern,
    String raw,
    int? Function(RegExpMatch match) minutesOf,
  ) {
    final match = pattern.firstMatch(raw);
    if (match == null) return const [];
    final minutes = minutesOf(match);
    if (minutes == null) return const [];
    return [
      TitleTimeMatch(
        start: match.start,
        end: match.end,
        startMinutes: minutes,
      ),
    ];
  }

  static int? _amPmFromSi(RegExpMatch match) {
    return _amPmMinutes(
      match.group(1)!,
      int.parse(match.group(2)!),
      int.parse(match.group(3) ?? '0'),
    );
  }

  static int? _amPmFromColon(RegExpMatch match) {
    return _amPmMinutes(
      match.group(1)!,
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static int? _hour24FromSi(RegExpMatch match) {
    return _clockMinutes(
      int.parse(match.group(1)!),
      int.parse(match.group(2) ?? '0'),
    );
  }

  static int? _hour24FromColon(RegExpMatch match) {
    return _clockMinutes(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  static int? _hourFromSi(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    if (hour < 1 || hour > 11) return null;
    return _clockMinutes(hour, int.parse(match.group(2) ?? '0'));
  }

  static int? _amPmMinutes(String period, int hour, int minute) {
    if (hour < 1 || hour > 12) return null;
    if (minute < 0 || minute > 59) return null;
    var clock = hour % 12;
    if (period == '오후') clock += 12;
    return clock * 60 + minute;
  }

  static int? _clockMinutes(int hour, int minute) {
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }
}
