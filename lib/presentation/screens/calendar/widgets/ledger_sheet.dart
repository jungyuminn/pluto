import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_form.dart';

Future<bool> showLedgerSheet(
  BuildContext context, {
  required DateTime date,
  LedgerEntry? initial,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => LedgerSheet(date: date, initial: initial),
  );
  return saved == true;
}

class LedgerSheet extends StatelessWidget {
  const LedgerSheet({super.key, required this.date, this.initial});

  final DateTime date;
  final LedgerEntry? initial;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: LedgerForm(date: date, initial: initial),
        ),
      ),
    );
  }
}
