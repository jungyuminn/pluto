import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';

enum LedgerSignMode { plus, minus, signed }

class LedgerKindStats extends StatelessWidget {
  const LedgerKindStats({
    super.key,
    required this.consumption,
    required this.expense,
    required this.salary,
    required this.net,
    required this.showSalary,
  });

  final int consumption;
  final int expense;
  final int salary;
  final int net;
  final bool showSalary;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final netColor = LedgerEntry.netColor(net, colors.muted);
    return Column(
      children: [
        Row(
          children: [
            _cell(
              context,
              AppStrings.ledgerExpense,
              expense,
              LedgerEntry.expenseColor,
              LedgerSignMode.plus,
            ),
            const SizedBox(width: 10),
            _cell(
              context,
              AppStrings.ledgerConsumption,
              consumption,
              LedgerEntry.consumptionColor,
              LedgerSignMode.minus,
            ),
            if (showSalary) ...[
              const SizedBox(width: 10),
              _cell(
                context,
                AppStrings.ledgerPay,
                salary,
                LedgerEntry.salaryColor,
                LedgerSignMode.plus,
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _cell(
              context,
              AppStrings.ledgerNet,
              net,
              netColor,
              LedgerSignMode.signed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    String label,
    int amount,
    Color color,
    LedgerSignMode sign,
  ) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: font,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1,
              color: colors.hint,
            ),
          ),
          const SizedBox(height: 4),
          LedgerStatAmount(
            amount: amount,
            sign: sign,
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class LedgerStatAmount extends StatefulWidget {
  const LedgerStatAmount({
    super.key,
    required this.amount,
    required this.sign,
    required this.style,
  });

  final int amount;
  final LedgerSignMode sign;
  final TextStyle style;

  @override
  State<LedgerStatAmount> createState() => _LedgerStatAmountState();
}

class _LedgerStatAmountState extends State<LedgerStatAmount> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.amount;
  }

  @override
  void didUpdateWidget(LedgerStatAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _from = oldWidget.amount;
    }
  }

  String _label(int value) {
    final won = '${LedgerEntry.formatWon(value.abs())}원';
    if (value == 0) return won;
    return switch (widget.sign) {
      LedgerSignMode.plus => '+$won',
      LedgerSignMode.minus => '-$won',
      LedgerSignMode.signed => '${value > 0 ? '+' : '-'}$won',
    };
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.amount),
      tween: Tween(begin: _from.toDouble(), end: widget.amount.toDouble()),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          _label(value.round()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: widget.style,
        );
      },
    );
  }
}
