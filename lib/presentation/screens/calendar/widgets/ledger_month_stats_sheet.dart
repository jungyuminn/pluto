import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/ledger_month_stats.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_kind_stats.dart';
import 'package:pluto/core/utils/press_bounce.dart';

Future<DateTime?> showLedgerMonthStatsSheet(
  BuildContext context, {
  required DateTime month,
  required LedgerMonthStats stats,
}) {
  return showModalBottomSheet<DateTime>(
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
    builder: (context) => LedgerMonthStatsSheet(month: month, stats: stats),
  );
}

class LedgerMonthStatsSheet extends StatelessWidget {
  const LedgerMonthStatsSheet({
    super.key,
    required this.month,
    required this.stats,
  });

  final DateTime month;
  final LedgerMonthStats stats;

  String get _title {
    if (month.year == DateTime.now().year) {
      return AppStrings.ledgerMonthStatsTitle(month.month);
    }
    return AppStrings.ledgerMonthStatsTitleWithYear(month.year, month.month);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Stack(
            children: [
              const Positioned.fill(
                child: AppSkinBackground(
                  liftForNav: false,
                  simple: true,
                  child: SizedBox.expand(),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.muted.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const SizedBox(width: 36, height: 4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _title,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LedgerKindStats(
                      consumption: stats.consumption,
                      expense: stats.expense,
                      salary: stats.salary,
                      net: stats.net,
                      showSalary: stats.hasSalary,
                    ),
                    if (stats.hasHighlights) ...[
                      const SizedBox(height: 20),
                      if (stats.topConsumptionDay != null)
                        _LedgerHighlightRow(
                          label: AppStrings.ledgerTopConsumptionDay,
                          highlight: stats.topConsumptionDay!,
                          color: LedgerEntry.consumptionColor,
                          sign: LedgerSignMode.minus,
                          onPressed: () => Navigator.pop(
                            context,
                            stats.topConsumptionDay!.date,
                          ),
                        ),
                      if (stats.topConsumptionDay != null &&
                          stats.topIncomeDay != null)
                        const SizedBox(height: 14),
                      if (stats.topIncomeDay != null)
                        _LedgerHighlightRow(
                          label: AppStrings.ledgerTopIncomeDay,
                          highlight: stats.topIncomeDay!,
                          color: stats.hasSalary && stats.expense == 0
                              ? LedgerEntry.salaryColor
                              : LedgerEntry.expenseColor,
                          sign: LedgerSignMode.plus,
                          onPressed: () => Navigator.pop(
                            context,
                            stats.topIncomeDay!.date,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerHighlightRow extends StatelessWidget {
  const _LedgerHighlightRow({
    required this.label,
    required this.highlight,
    required this.color,
    required this.sign,
    required this.onPressed,
  });

  final String label;
  final LedgerDayHighlight highlight;
  final Color color;
  final LedgerSignMode sign;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.98,
      alignment: Alignment.centerLeft,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: font,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1,
                color: colors.hint,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.ledgerStatsDayLabel(highlight.date),
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: colors.accent,
                    ),
                  ),
                ),
                LedgerStatAmount(
                  amount: highlight.amount,
                  sign: sign,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
