import 'package:flutter_test/flutter_test.dart';
import 'package:job_planner/data/models/ledger_entry_model.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';

void main() {
  test('옛 월급+시급 내역은 시급으로 옮긴다', () {
    final entry = LedgerEntryModel.fromJson({
      'id': '1',
      'date': '2026-08-30',
      'title': '알바',
      'amount': 80000,
      'kind': 'salary',
      'salary': {'wageType': 'hourly', 'hourlyWage': 10000, 'cycle': 'weekly'},
    });
    expect(entry.kind, LedgerKind.hourly);
    expect(entry.salary?.wageType, SalaryWageType.hourly);
  });

  test('옛 월급+월급 내역은 월급으로 둔다', () {
    final entry = LedgerEntryModel.fromJson({
      'id': '2',
      'date': '2026-08-30',
      'title': '직장',
      'amount': 2500000,
      'kind': 'salary',
      'salary': {
        'wageType': 'monthly',
        'monthlyWage': 2500000,
        'cycle': 'monthly',
      },
    });
    expect(entry.kind, LedgerKind.salary);
    expect(entry.salary?.isMonthlyWage, isTrue);
  });

  test('시급 종류는 그대로 읽는다', () {
    final entry = LedgerEntryModel.fromJson({
      'id': '3',
      'date': '2026-08-30',
      'title': '알바',
      'amount': 80000,
      'kind': 'hourly',
    });
    expect(entry.kind, LedgerKind.hourly);
  });
}
