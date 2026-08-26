import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/core/utils/swipe_to_delete.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_sheet.dart';
import 'package:job_planner/app_scope.dart';

Future<bool> showLedgerDaySheet(
  BuildContext context, {
  required DateTime date,
  required List<LedgerEntry> entries,
}) async {
  if (entries.isEmpty) {
    return showLedgerSheet(context, date: date);
  }
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    builder: (context) => LedgerDaySheet(date: date, initial: entries),
  );
  return changed == true;
}

class LedgerDaySheet extends StatefulWidget {
  const LedgerDaySheet({
    super.key,
    required this.date,
    required this.initial,
  });

  final DateTime date;
  final List<LedgerEntry> initial;

  @override
  State<LedgerDaySheet> createState() => _LedgerDaySheetState();
}

class _LedgerDaySheetState extends State<LedgerDaySheet> {
  late List<LedgerEntry> _entries;
  var _changed = false;

  @override
  void initState() {
    super.initState();
    _entries = [...widget.initial]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  int get _salaryTotal => _entries
      .where((e) => e.kind == LedgerKind.salary)
      .fold(0, (sum, e) => sum + e.amount);

  int get _consumption => _entries
      .where((e) => e.kind == LedgerKind.consumption)
      .fold(0, (sum, e) => sum + e.amount);

  int get _expense => _entries
      .where((e) => e.kind == LedgerKind.expense)
      .fold(0, (sum, e) => sum + e.amount);

  int get _net => _salaryTotal - _consumption - _expense;

  Future<void> _reload() async {
    final all = await AppScope.of(context).getLedgers();
    final day = DateTime(widget.date.year, widget.date.month, widget.date.day);
    if (!mounted) return;
    setState(() {
      _entries = [
        for (final entry in all)
          if (entry.day == day) entry,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _changed = true;
    });
  }

  Future<void> _open([LedgerEntry? entry]) async {
    final saved = await showLedgerSheet(
      context,
      date: widget.date,
      initial: entry,
    );
    if (saved && mounted) await _reload();
  }

  Future<bool> _confirmDelete(LedgerEntry entry) async {
    final confirmed = await showDeleteEventDialog(
      context,
      title: AppStrings.deleteTitle,
      body: AppStrings.deleteLedgerBody,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteLedger(entry.id);
    await _reload();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final weekday = AppStrings.weekdays[widget.date.weekday % 7];
    final dateLabel =
        '${widget.date.month}. ${widget.date.day}. ($weekday)';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppStrings.ledgerSalary} ${LedgerEntry.formatWon(_salaryTotal)} · ${AppStrings.ledgerConsumption} ${LedgerEntry.formatWon(_consumption)} · ${AppStrings.ledgerExpense} ${LedgerEntry.formatWon(_expense)} · ${AppStrings.ledgerNet} ${_net >= 0 ? '+' : '-'}${LedgerEntry.formatWon(_net.abs())}',
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                if (_entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      AppStrings.ledgerEmptyDay,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.muted,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return SwipeToDelete(
                          onSwipeLeft: () => _confirmDelete(entry),
                          child: _LedgerRow(
                            entry: entry,
                            onPressed: () => _open(entry),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                AddEventButton(
                  label: AppStrings.addLedger,
                  onPressed: () => _open(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.onPressed});

  final LedgerEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.tint(entry.color, 0.18),
      pressedColor: colors.tint(entry.color, 0.28),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  if (entry.memo.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.memo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              entry.signedLabel,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: entry.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
