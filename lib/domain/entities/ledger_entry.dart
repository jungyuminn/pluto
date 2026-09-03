import 'package:flutter/material.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/ledger_salary.dart';

enum LedgerKind { expense, consumption, hourly, salary }

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
    this.categoryId,
    this.categoryName = '',
    this.categoryColor = 0,
  });

  static const salaryColor = Color(0xFF22C55E);
  static const hourlyColor = Color(0xFFF59E0B);
  static const consumptionColor = Color(0xFFEF4444);
  static const expenseColor = Color(0xFF38BDF8);

  static Color netColor(int net, Color zero) {
    if (net == 0) return zero;
    return net > 0 ? expenseColor : consumptionColor;
  }

  final String id;
  final DateTime date;
  final String title;
  final int amount;
  final LedgerKind kind;
  final String memo;
  final int sortOrder;
  final LedgerSalaryDetails? salary;
  final String? categoryId;
  final String categoryName;
  final int categoryColor;

  bool get isWage => kind == LedgerKind.salary || kind == LedgerKind.hourly;

  bool get isIncome => isWage || kind == LedgerKind.expense;

  Color get color => switch (kind) {
    LedgerKind.salary => salaryColor,
    LedgerKind.hourly => hourlyColor,
    LedgerKind.consumption => consumptionColor,
    LedgerKind.expense => expenseColor,
  };

  String get displayCategoryName =>
      categoryName.trim().isNotEmpty ? categoryName : kindLabel;

  int get displayCategoryColor =>
      categoryColor != 0 ? categoryColor : colorValue;

  Color get displayColor => Color(displayCategoryColor);

  String get categoryKey {
    final id = categoryId;
    if (id != null && id.isNotEmpty) return id;
    return displayCategoryName;
  }

  int get colorValue => switch (kind) {
    LedgerKind.salary => 0xFF22C55E,
    LedgerKind.hourly => 0xFFF59E0B,
    LedgerKind.consumption => 0xFFEF4444,
    LedgerKind.expense => 0xFF38BDF8,
  };

  DateTime get day => DateTime(date.year, date.month, date.day);

  String get kindLabel => switch (kind) {
    LedgerKind.salary => '월급',
    LedgerKind.hourly => '시급',
    LedgerKind.consumption => '소비',
    LedgerKind.expense => '수입',
  };

  String listSubtitle({bool showKind = true}) {
    final category = categoryName.trim();
    final hasCategory = category.isNotEmpty && category != kindLabel;
    if (!showKind) return hasCategory ? category : '';
    if (!hasCategory) return kindLabel;
    return '$category · $kindLabel';
  }

  String get signedLabel {
    final sign = isIncome ? '+' : '-';
    return '$sign${formatWon(amount)}';
  }

  String calendarLabel({bool showTitle = true, bool showAmount = false}) {
    if (showAmount) return signedLabel;
    if (showTitle) return title.trim();
    return '';
  }

  CalendarEvent toCalendarEvent({
    bool showTitle = true,
    bool showAmount = false,
    bool kindColor = false,
  }) {
    return CalendarEvent(
      id: id,
      title: calendarLabel(showTitle: showTitle, showAmount: showAmount),
      date: day,
      memo: memo,
      categoryName: displayCategoryName,
      categoryColor: kindColor ? colorValue : displayCategoryColor,
      sortOrder: sortOrder,
    );
  }

  static int compareDisplay(LedgerEntry a, LedgerEntry b) {
    return a.sortOrder.compareTo(b.sortOrder);
  }

  static int compareByKind(LedgerEntry a, LedgerEntry b) {
    const order = [
      LedgerKind.salary,
      LedgerKind.hourly,
      LedgerKind.consumption,
      LedgerKind.expense,
    ];
    final byKind = order.indexOf(a.kind).compareTo(order.indexOf(b.kind));
    if (byKind != 0) return byKind;
    return a.sortOrder.compareTo(b.sortOrder);
  }

  static int compareByCategory(
    LedgerEntry a,
    LedgerEntry b, [
    List<String>? order,
  ]) {
    if (order != null && order.isNotEmpty) {
      int indexOf(LedgerEntry entry) {
        final i = order.indexOf(entry.categoryKey);
        return i < 0 ? order.length : i;
      }

      final byOrder = indexOf(a).compareTo(indexOf(b));
      if (byOrder != 0) return byOrder;
    }
    final byName = a.displayCategoryName.compareTo(b.displayCategoryName);
    if (byName != 0) return byName;
    return a.sortOrder.compareTo(b.sortOrder);
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
      'hourly' => LedgerKind.hourly,
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
    String? categoryId,
    String? categoryName,
    int? categoryColor,
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
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }
}
