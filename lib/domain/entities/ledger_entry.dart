import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';

enum LedgerKind { expense, consumption, salary }

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.amount,
    this.kind = LedgerKind.expense,
    this.memo = '',
    this.sortOrder = 0,
    this.salary,
  });

  static const salaryColor = Color(0xFF22C55E);
  static const consumptionColor = Color(0xFFF59E0B);
  static const expenseColor = Color(0xFFEF4444);

  final String id;
  final DateTime date;
  final String title;
  final int amount;
  final LedgerKind kind;
  final String memo;
  final int sortOrder;
  final LedgerSalaryDetails? salary;

  bool get isIncome => kind == LedgerKind.salary;

  Color get color => switch (kind) {
        LedgerKind.salary => salaryColor,
        LedgerKind.consumption => consumptionColor,
        LedgerKind.expense => expenseColor,
      };

  int get colorValue => switch (kind) {
        LedgerKind.salary => 0xFF22C55E,
        LedgerKind.consumption => 0xFFF59E0B,
        LedgerKind.expense => 0xFFEF4444,
      };

  DateTime get day => DateTime(date.year, date.month, date.day);

  String get kindLabel => switch (kind) {
        LedgerKind.salary => '월급',
        LedgerKind.consumption => '소비',
        LedgerKind.expense => '지출',
      };

  String get signedLabel {
    final sign = isIncome ? '+' : '-';
    return '$sign${formatWon(amount)}';
  }

  String get calendarLabel {
    final money = signedLabel;
    final name = title.trim();
    if (name.isEmpty) return money;
    return '$name $money';
  }

  CalendarEvent toCalendarEvent() {
    return CalendarEvent(
      id: id,
      title: calendarLabel,
      date: day,
      memo: memo,
      categoryName: kindLabel,
      categoryColor: colorValue,
      sortOrder: sortOrder,
    );
  }

  static String formatWon(int amount) {
    final raw = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  static LedgerKind kindFrom(String? raw) {
    return switch (raw) {
      'income' || 'salary' => LedgerKind.salary,
      'consumption' => LedgerKind.consumption,
      _ => LedgerKind.expense,
    };
  }

  LedgerEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    int? amount,
    LedgerKind? kind,
    String? memo,
    int? sortOrder,
    LedgerSalaryDetails? salary,
    bool clearSalary = false,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      memo: memo ?? this.memo,
      sortOrder: sortOrder ?? this.sortOrder,
      salary: clearSalary ? null : salary ?? this.salary,
    );
  }
}
