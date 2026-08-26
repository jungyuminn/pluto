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
  static const dailyTaxExemption = 150000;

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
      final dailyStyle = details.cycle == SalaryPayCycle.sameDay &&
          details.insurance != SalaryInsurance.all;
      tax = dailyStyle ? _dailyWorkerTax(gross) : _monthlyWithholding(gross);
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

  static int _dailyWorkerTax(int dailyGross) {
    final taxable = dailyGross - dailyTaxExemption;
    if (taxable <= 0) return 0;
    final income = _round(taxable * 0.06 * 0.45);
    return income + _round(income * 0.1);
  }

  static int _monthlyWithholding(int monthlyPay) {
    if (monthlyPay < 1060000) return 0;
    final income = _annualizedIncomeTax(monthlyPay);
    return income + _round(income * 0.1);
  }

  static int _annualizedIncomeTax(int monthlyPay) {
    final annual = monthlyPay * 12;
    final earned = _earnedIncomeDeduction(annual);
    const personal = 1500000;
    final taxable = (annual - earned - personal).clamp(0, annual);
    final raw = _progressiveTax(taxable);
    final credited = (raw - _earnedTaxCredit(raw, annual)).clamp(0, raw);
    return _round(credited / 12);
  }

  static int _earnedIncomeDeduction(int annual) {
    if (annual <= 5000000) return _round(annual * 0.7);
    if (annual <= 15000000) {
      return 3500000 + _round((annual - 5000000) * 0.4);
    }
    if (annual <= 45000000) {
      return 7500000 + _round((annual - 15000000) * 0.15);
    }
    if (annual <= 100000000) {
      return 12000000 + _round((annual - 45000000) * 0.05);
    }
    final extra = 14750000 + _round((annual - 100000000) * 0.02);
    return extra > 20000000 ? 20000000 : extra;
  }

  static int _progressiveTax(int taxable) {
    if (taxable <= 14000000) return _round(taxable * 0.06);
    if (taxable <= 50000000) {
      return 840000 + _round((taxable - 14000000) * 0.15);
    }
    if (taxable <= 88000000) {
      return 6240000 + _round((taxable - 50000000) * 0.24);
    }
    if (taxable <= 150000000) {
      return 15360000 + _round((taxable - 88000000) * 0.35);
    }
    if (taxable <= 300000000) {
      return 37060000 + _round((taxable - 150000000) * 0.38);
    }
    if (taxable <= 500000000) {
      return 94060000 + _round((taxable - 300000000) * 0.40);
    }
    if (taxable <= 1000000000) {
      return 174060000 + _round((taxable - 500000000) * 0.42);
    }
    return 384060000 + _round((taxable - 1000000000) * 0.45);
  }

  static int _earnedTaxCredit(int tax, int annual) {
    final credit = tax <= 1300000
        ? _round(tax * 0.55)
        : 715000 + _round((tax - 1300000) * 0.30);
    final cap = annual <= 33000000 ? 740000 : 660000;
    return credit > cap ? cap : credit;
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
