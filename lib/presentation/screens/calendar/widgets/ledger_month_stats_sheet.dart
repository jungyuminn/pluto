import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/domain/ledger_month_stats.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_kind_stats.dart';

Future<void> showLedgerMonthStatsSheet(
  BuildContext context, {
  required DateTime month,
  required LedgerMonthStats stats,
}) {
  return showModalBottomSheet<void>(
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
