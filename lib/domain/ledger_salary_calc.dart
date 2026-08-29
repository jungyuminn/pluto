import 'package:job_planner/domain/entities/ledger_salary.dart';

class LedgerSalaryResult {
  const LedgerSalaryResult({
    required this.workMinutes,
    required this.paidMinutes,
    required this.basePay,
    required this.holidayPay,
    required this.gross,
    required this.pension,
    required this.health,
    required this.longTermCare,
    required this.employment,
    required this.tax,
    required this.net,
  });

  static const empty = LedgerSalaryResult(
    workMinutes: 0,
    paidMinutes: 0,
    basePay: 0,
    holidayPay: 0,
    gross: 0,
    pension: 0,
    health: 0,
    longTermCare: 0,
    employment: 0,
    tax: 0,
    net: 0,
  );

  final int workMinutes;
  final int paidMinutes;
  final int basePay;
  final int holidayPay;
  final int gross;
  final int pension;
  final int health;
  final int longTermCare;
  final int employment;
  final int tax;
  final int net;

  int get insuranceTotal => pension + health + longTermCare + employment;

  int get deductionTotal => insuranceTotal + tax;
}

class LedgerSalaryCalc {
  LedgerSalaryCalc._();

  static const nationalPensionRate = 0.0475;
  static const healthInsuranceRate = 0.03595;
  static const longTermCareRateOfHealth = 0.1314;
  static const employmentInsuranceRate = 0.009;
  static const taxRate = 0.033;

  static int workMinutesOf(int? startMinutes, int? endMinutes) {
    if (startMinutes == null || endMinutes == null) return 0;
    var minutes = endMinutes - startMinutes;
    if (minutes <= 0) minutes += 24 * 60;
    return minutes;
  }

  static int statutoryBreakMinutes(int workMinutes) {
    if (workMinutes >= 8 * 60) return 60;
    if (workMinutes >= 4 * 60) return 30;
    return 0;
  }

  static LedgerSalaryResult compute(LedgerSalaryDetails details) {
    final work = workMinutesOf(details.startMinutes, details.endMinutes);
    final paid = (work - details.breakMinutes).clamp(0, 24 * 60).toInt();

    final basePay = details.isMonthlyWage
        ? _periodMonthlyPay(details)
        : _round(details.hourlyWage * paid / 60);

    var holidayPay = 0;
    if (details.weeklyHoliday &&
        !details.isMonthlyWage &&
        details.hourlyWage > 0 &&
        paid > 0) {
      holidayPay = _round(details.hourlyWage * 8 * (paid / 60) / 40);
    }

    final gross = basePay + holidayPay;
    if (gross <= 0) return LedgerSalaryResult.empty.copyWithWork(work, paid);

    var pension = 0;
    var health = 0;
    var longTermCare = 0;
    var employment = 0;
    switch (details.insurance) {
      case SalaryInsurance.all:
        pension = _round(gross * nationalPensionRate);
        health = _round(gross * healthInsuranceRate);
        longTermCare = _round(health * longTermCareRateOfHealth);
        employment = _round(gross * employmentInsuranceRate);
      case SalaryInsurance.employmentOnly:
        employment = _round(gross * employmentInsuranceRate);
      case SalaryInsurance.none:
        break;
    }

    var tax = 0;
    if (details.tax) {
      tax = _round(gross * taxRate);
    }

    final net = (gross - pension - health - longTermCare - employment - tax)
        .clamp(0, 1 << 30);
    return LedgerSalaryResult(
      workMinutes: work,
      paidMinutes: paid,
      basePay: basePay,
      holidayPay: holidayPay,
      gross: gross,
      pension: pension,
      health: health,
      longTermCare: longTermCare,
      employment: employment,
      tax: tax,
      net: net,
    );
  }

  static int _periodMonthlyPay(LedgerSalaryDetails details) {
    final monthly = details.monthlyWage;
    if (monthly <= 0) return 0;
    if (details.cycle == SalaryPayCycle.twiceMonthly) {
      return _round(monthly / 2);
    }
    return monthly;
  }

  static int _round(num value) => value.round();
}

extension on LedgerSalaryResult {
  LedgerSalaryResult copyWithWork(int workMinutes, int paidMinutes) {
    return LedgerSalaryResult(
      workMinutes: workMinutes,
      paidMinutes: paidMinutes,
      basePay: 0,
      holidayPay: 0,
      gross: 0,
      pension: 0,
      health: 0,
      longTermCare: 0,
      employment: 0,
      tax: 0,
      net: 0,
    );
  }
}
