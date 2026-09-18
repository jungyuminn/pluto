import 'package:flutter/material.dart';
import 'package:pluto/core/layout/compose_sheet.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_form.dart';

Future<bool> showLedgerSheet(
  BuildContext context, {
  required DateTime date,
  LedgerEntry? initial,
}) async {
  EventCategory? lastCategory;
  if (initial == null) {
    lastCategory = await lastLedgerCategoryOf(context);
    if (!context.mounted) return false;
  }
  final saved = await showComposeSheet<bool>(
    context,
    builder: (context) => LedgerSheet(
      date: date,
      initial: initial,
      lastCategory: lastCategory,
    ),
  );
  return saved == true;
}

class LedgerSheet extends StatelessWidget {
  const LedgerSheet({
    super.key,
    required this.date,
    this.initial,
    this.lastCategory,
  });

  final DateTime date;
  final LedgerEntry? initial;
  final EventCategory? lastCategory;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: LedgerForm(
            date: date,
            initial: initial,
            lastCategory: lastCategory,
          ),
        ),
      ),
    );
  }
}
