class KoreanHolidays {
  KoreanHolidays._();

  static String? nameOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _forYear(day.year)[day];
  }

  static final _years = <int, Map<DateTime, String>>{};

  static Map<DateTime, String> _forYear(int year) {
    return _years.putIfAbsent(year, () => _build(year));
  }

  static Map<DateTime, String> _build(int year) {
    final holidays = <DateTime, String>{};

    void add(DateTime date, String name) {
      holidays[DateTime(date.year, date.month, date.day)] = name;
    }

    add(DateTime(year, 1, 1), '신정');
    add(DateTime(year, 3, 1), '삼일절');
    add(DateTime(year, 5, 5), '어린이날');
    add(DateTime(year, 6, 6), '현충일');
    add(DateTime(year, 8, 15), '광복절');
    add(DateTime(year, 10, 3), '개천절');
    add(DateTime(year, 10, 9), '한글날');
    add(DateTime(year, 12, 25), '크리스마스');

    final seollal = _seollal[year];
    if (seollal != null) {
      add(seollal.subtract(const Duration(days: 1)), '설날 연휴');
      add(seollal, '설날');
      add(seollal.add(const Duration(days: 1)), '설날 연휴');
    }

    final chuseok = _chuseok[year];
    if (chuseok != null) {
      add(chuseok.subtract(const Duration(days: 1)), '추석 연휴');
      final chuseokDay = DateTime(chuseok.year, chuseok.month, chuseok.day);
      add(
        chuseok,
        holidays.containsKey(chuseokDay) ? '추석/개천절' : '추석',
      );
      add(chuseok.add(const Duration(days: 1)), '추석 연휴');
    }

    final buddha = _buddha[year];
    if (buddha != null) {
      holidays.putIfAbsent(buddha, () => '석가탄신일');
    }

    final substitutes = _substitutes[year];
    if (substitutes != null) {
      for (final entry in substitutes.entries) {
        holidays.putIfAbsent(entry.key, () => entry.value);
      }
    }

    return holidays;
  }

  static final _seollal = {
    2025: DateTime(2025, 1, 29),
    2026: DateTime(2026, 2, 17),
    2027: DateTime(2027, 2, 7),
    2028: DateTime(2028, 1, 26),
    2029: DateTime(2029, 2, 13),
    2030: DateTime(2030, 2, 3),
    2031: DateTime(2031, 1, 23),
    2032: DateTime(2032, 2, 11),
  };

  static final _chuseok = {
    2025: DateTime(2025, 10, 6),
    2026: DateTime(2026, 9, 25),
    2027: DateTime(2027, 9, 15),
    2028: DateTime(2028, 10, 3),
    2029: DateTime(2029, 9, 22),
    2030: DateTime(2030, 9, 12),
    2031: DateTime(2031, 10, 1),
    2032: DateTime(2032, 9, 19),
  };

  static final _substitutes = {
    2026: {
      DateTime(2026, 3, 2): '대체공휴일',
      DateTime(2026, 5, 25): '대체공휴일',
      DateTime(2026, 8, 17): '대체공휴일',
      DateTime(2026, 10, 5): '대체공휴일',
    },
    2027: {
      DateTime(2027, 2, 9): '대체공휴일',
      DateTime(2027, 7, 19): '대체공휴일',
      DateTime(2027, 8, 16): '대체공휴일',
      DateTime(2027, 10, 4): '대체공휴일',
      DateTime(2027, 10, 11): '대체공휴일',
    },
    2028: {
      DateTime(2028, 10, 5): '대체공휴일',
    },
    2029: {
      DateTime(2029, 5, 7): '대체공휴일',
      DateTime(2029, 5, 21): '대체공휴일',
      DateTime(2029, 9, 24): '대체공휴일',
    },
    2030: {
      DateTime(2030, 2, 5): '대체공휴일',
      DateTime(2030, 5, 6): '대체공휴일',
    },
  };

  static final _buddha = {
    2025: DateTime(2025, 5, 5),
    2026: DateTime(2026, 5, 24),
    2027: DateTime(2027, 5, 13),
    2028: DateTime(2028, 5, 2),
    2029: DateTime(2029, 5, 20),
    2030: DateTime(2030, 5, 9),
    2031: DateTime(2031, 5, 28),
    2032: DateTime(2032, 5, 16),
  };
}
