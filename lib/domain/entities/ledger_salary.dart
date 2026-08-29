enum SalaryPayCycle { sameDay, weekly, biweekly, monthly, twiceMonthly }

extension SalaryPayCycleX on SalaryPayCycle {
  static const selectable = [
    SalaryPayCycle.sameDay,
    SalaryPayCycle.weekly,
    SalaryPayCycle.monthly,
  ];

  SalaryPayCycle get selectableCycle => switch (this) {
        SalaryPayCycle.biweekly => SalaryPayCycle.weekly,
        SalaryPayCycle.twiceMonthly => SalaryPayCycle.monthly,
        _ => this,
      };
}

enum SalaryInsurance { none, employmentOnly, all }

enum SalaryWageType { hourly, monthly }

enum SalaryMonthRule { date, weekday }

enum SalaryMonthWeek { first, second, third, fourth, last }

class SalaryMonthDate {
  SalaryMonthDate._();

  static DateTime weekdayInMonth({
    required int year,
    required int month,
    required int weekday,
    required SalaryMonthWeek week,
  }) {
    if (week == SalaryMonthWeek.last) {
      final last = DateTime(year, month + 1, 0);
      var delta = last.weekday - weekday;
      if (delta < 0) delta += 7;
      return last.subtract(Duration(days: delta));
    }
    final first = DateTime(year, month, 1);
    var delta = weekday - first.weekday;
    if (delta < 0) delta += 7;
    return DateTime(year, month, 1 + delta + week.index * 7);
  }

  static SalaryMonthWeek weekOf(DateTime date) {
    final last = weekdayInMonth(
      year: date.year,
      month: date.month,
      weekday: date.weekday,
      week: SalaryMonthWeek.last,
    );
    if (date.year == last.year &&
        date.month == last.month &&
        date.day == last.day) {
      return SalaryMonthWeek.last;
    }
    return SalaryMonthWeek.values[((date.day - 1) ~/ 7).clamp(0, 3)];
  }
}

class LedgerSalaryDetails {
  const LedgerSalaryDetails({
    this.wageType = SalaryWageType.hourly,
    this.hourlyWage = 0,
    this.monthlyWage = 0,
    this.cycle = SalaryPayCycle.sameDay,
    this.monthRule = SalaryMonthRule.date,
    this.monthWeek = SalaryMonthWeek.first,
    this.weekday = DateTime.friday,
    this.monthDay = 25,
    this.monthDay2 = 10,
    this.startMinutes,
    this.endMinutes,
    this.breakMinutes = 0,
    this.tax = false,
    this.insurance = SalaryInsurance.none,
    this.weeklyHoliday = true,
  });

  final SalaryWageType wageType;
  final int hourlyWage;
  final int monthlyWage;
  final SalaryPayCycle cycle;
  final SalaryMonthRule monthRule;
  final SalaryMonthWeek monthWeek;
  final int weekday;
  final int monthDay;
  final int monthDay2;
  final int? startMinutes;
  final int? endMinutes;
  final int breakMinutes;
  final bool tax;
  final SalaryInsurance insurance;
  final bool weeklyHoliday;

  bool get isMonthlyWage => wageType == SalaryWageType.monthly;

  bool get usesWeekday =>
      cycle == SalaryPayCycle.weekly || cycle == SalaryPayCycle.biweekly;

  bool get usesMonthPayDay =>
      cycle.selectableCycle == SalaryPayCycle.monthly;

  bool get usesMonthDay =>
      usesMonthPayDay && monthRule == SalaryMonthRule.date;

  bool get usesMonthWeekday =>
      usesMonthPayDay && monthRule == SalaryMonthRule.weekday;

  LedgerSalaryDetails copyWith({
    SalaryWageType? wageType,
    int? hourlyWage,
    int? monthlyWage,
    SalaryPayCycle? cycle,
    SalaryMonthRule? monthRule,
    SalaryMonthWeek? monthWeek,
    int? weekday,
    int? monthDay,
    int? monthDay2,
    int? startMinutes,
    int? endMinutes,
    int? breakMinutes,
    bool? tax,
    SalaryInsurance? insurance,
    bool? weeklyHoliday,
    bool clearTime = false,
  }) {
    return LedgerSalaryDetails(
      wageType: wageType ?? this.wageType,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      monthlyWage: monthlyWage ?? this.monthlyWage,
      cycle: cycle ?? this.cycle,
      monthRule: monthRule ?? this.monthRule,
      monthWeek: monthWeek ?? this.monthWeek,
      weekday: weekday ?? this.weekday,
      monthDay: monthDay ?? this.monthDay,
      monthDay2: monthDay2 ?? this.monthDay2,
      startMinutes: clearTime ? null : startMinutes ?? this.startMinutes,
      endMinutes: clearTime ? null : endMinutes ?? this.endMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      tax: tax ?? this.tax,
      insurance: insurance ?? this.insurance,
      weeklyHoliday: weeklyHoliday ?? this.weeklyHoliday,
    );
  }

  static LedgerSalaryDetails fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LedgerSalaryDetails();
    return LedgerSalaryDetails(
      wageType: json['wageType'] == 'monthly'
          ? SalaryWageType.monthly
          : SalaryWageType.hourly,
      hourlyWage: (json['hourlyWage'] as num?)?.toInt() ?? 0,
      monthlyWage: (json['monthlyWage'] as num?)?.toInt() ?? 0,
      cycle: _cycleFrom(json['cycle'] as String?),
      monthRule: json['monthRule'] == 'weekday'
          ? SalaryMonthRule.weekday
          : SalaryMonthRule.date,
      monthWeek: _weekFrom(json['monthWeek'] as String?),
      weekday: (json['weekday'] as num?)?.toInt() ?? DateTime.friday,
      monthDay: (json['monthDay'] as num?)?.toInt() ?? 25,
      monthDay2: (json['monthDay2'] as num?)?.toInt() ?? 10,
      startMinutes: (json['startMinutes'] as num?)?.toInt(),
      endMinutes: (json['endMinutes'] as num?)?.toInt(),
      breakMinutes: (json['breakMinutes'] as num?)?.toInt() ?? 0,
      tax: json['tax'] == true,
      insurance: _insuranceFrom(json['insurance'] as String?),
      weeklyHoliday: json['weeklyHoliday'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wageType': isMonthlyWage ? 'monthly' : 'hourly',
      'hourlyWage': hourlyWage,
      'monthlyWage': monthlyWage,
      'cycle': cycle.name,
      'monthRule': monthRule.name,
      'monthWeek': monthWeek.name,
      'weekday': weekday,
      'monthDay': monthDay,
      'monthDay2': monthDay2,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'breakMinutes': breakMinutes,
      'tax': tax,
      'insurance': insurance.name,
      'weeklyHoliday': weeklyHoliday,
    };
  }

  static SalaryPayCycle _cycleFrom(String? raw) {
    return switch (raw) {
      'weekly' => SalaryPayCycle.weekly,
      'biweekly' => SalaryPayCycle.biweekly,
      'monthly' => SalaryPayCycle.monthly,
      'twiceMonthly' => SalaryPayCycle.twiceMonthly,
      _ => SalaryPayCycle.sameDay,
    };
  }

  static SalaryMonthWeek _weekFrom(String? raw) {
    return switch (raw) {
      'second' => SalaryMonthWeek.second,
      'third' => SalaryMonthWeek.third,
      'fourth' => SalaryMonthWeek.fourth,
      'last' => SalaryMonthWeek.last,
      _ => SalaryMonthWeek.first,
    };
  }

  static SalaryInsurance _insuranceFrom(String? raw) {
    return switch (raw) {
      'employmentOnly' => SalaryInsurance.employmentOnly,
      'all' => SalaryInsurance.all,
      _ => SalaryInsurance.none,
    };
  }
}
