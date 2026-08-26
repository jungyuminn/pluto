enum SalaryPayCycle { sameDay, weekly, biweekly, monthly, twiceMonthly }

enum SalaryInsurance { none, employmentOnly, all }

enum SalaryWageType { hourly, monthly }

class LedgerSalaryDetails {
  const LedgerSalaryDetails({
    this.wageType = SalaryWageType.hourly,
    this.hourlyWage = 0,
    this.monthlyWage = 0,
    this.cycle = SalaryPayCycle.sameDay,
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

  bool get usesMonthDay =>
      cycle == SalaryPayCycle.monthly || cycle == SalaryPayCycle.twiceMonthly;

  LedgerSalaryDetails copyWith({
    SalaryWageType? wageType,
    int? hourlyWage,
    int? monthlyWage,
    SalaryPayCycle? cycle,
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

  static SalaryInsurance _insuranceFrom(String? raw) {
    return switch (raw) {
      'employmentOnly' => SalaryInsurance.employmentOnly,
      'all' => SalaryInsurance.all,
      _ => SalaryInsurance.none,
    };
  }
}
