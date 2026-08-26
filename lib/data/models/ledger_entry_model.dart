import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';

class LedgerEntryModel {
  LedgerEntryModel._();

  static LedgerEntry fromJson(Map<String, dynamic> json) {
    final salaryJson = json['salary'];
    return LedgerEntry(
      id: json['id'] as String,
      date: _parseDate(json['date'] as String),
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      kind: LedgerEntry.kindFrom(json['kind'] as String?),
      memo: json['memo'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      salary: salaryJson is Map<String, dynamic>
          ? LedgerSalaryDetails.fromJson(salaryJson)
          : null,
    );
  }

  static Map<String, dynamic> toJson(LedgerEntry entry) {
    return {
      'id': entry.id,
      'date': _formatDate(entry.day),
      'title': entry.title,
      'amount': entry.amount,
      'kind': entry.kind.name,
      'memo': entry.memo,
      'sortOrder': entry.sortOrder,
      if (entry.salary != null) 'salary': entry.salary!.toJson(),
    };
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime _parseDate(String raw) {
    final parsed = DateTime.parse(raw);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
