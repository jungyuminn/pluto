import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';

class LedgerEntryModel {
  LedgerEntryModel._();

  static LedgerEntry fromJson(Map<String, dynamic> json) {
    final salaryJson = json['salary'];
    final salary = salaryJson is Map<String, dynamic>
        ? LedgerSalaryDetails.fromJson(salaryJson)
        : null;
    var kind = LedgerEntry.kindFrom(json['kind'] as String?);
    if (kind == LedgerKind.salary && salary != null && !salary.isMonthlyWage) {
      kind = LedgerKind.hourly;
    }
    return LedgerEntry(
      id: json['id'] as String,
      date: _parseDate(json['date'] as String),
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      kind: kind,
      memo: json['memo'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      salary: salary,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ?? '',
      categoryColor: (json['categoryColor'] as num?)?.toInt() ?? 0,
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
      'categoryId': entry.categoryId,
      'categoryName': entry.categoryName,
      'categoryColor': entry.categoryColor,
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
