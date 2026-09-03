import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/ledger_salary_calc.dart';

class LedgerSalaryResultCard extends StatelessWidget {
  const LedgerSalaryResultCard({
    super.key,
    required this.result,
    required this.accent,
    this.compact = false,
    this.background,
  });

  final LedgerSalaryResult result;
  final Color accent;
  final bool compact;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final netSize = compact ? 16.0 : 18.0;
    final labelSize = compact ? 14.0 : 15.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? colors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
            : const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    AppStrings.ledgerNetPay,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const Spacer(),
                  _CountingWon(
                    amount: result.net,
                    suffix: AppStrings.ledgerAmountSuffix,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: netSize,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
              _RevealLine(
                visible: result.basePay > 0,
                label: AppStrings.ledgerBasePay,
                amount: result.basePay,
                compact: compact,
                gapAbove: compact ? 6 : 8,
              ),
              _RevealLine(
                visible: result.holidayPay > 0,
                label: AppStrings.ledgerHolidayPay,
                amount: result.holidayPay,
                prefix: '+',
                compact: compact,
              ),
              _RevealLine(
                visible: result.tax > 0,
                label: AppStrings.ledgerTax,
                amount: result.tax,
                prefix: '-',
                muted: true,
                compact: compact,
              ),
              _RevealLine(
                visible: result.pension > 0,
                label: AppStrings.ledgerPension,
                amount: result.pension,
                prefix: '-',
                muted: true,
                compact: compact,
              ),
              _RevealLine(
                visible: result.health > 0,
                label: AppStrings.ledgerHealth,
                amount: result.health,
                prefix: '-',
                muted: true,
                compact: compact,
              ),
              _RevealLine(
                visible: result.longTermCare > 0,
                label: AppStrings.ledgerLongTermCare,
                amount: result.longTermCare,
                prefix: '-',
                muted: true,
                compact: compact,
              ),
              _RevealLine(
                visible: result.employment > 0,
                label: AppStrings.ledgerEmploymentInsurance,
                amount: result.employment,
                prefix: '-',
                muted: true,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountingWon extends StatefulWidget {
  const _CountingWon({
    required this.amount,
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int amount;
  final TextStyle style;
  final String prefix;
  final String suffix;

  @override
  State<_CountingWon> createState() => _CountingWonState();
}

class _CountingWonState extends State<_CountingWon> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.amount;
  }

  @override
  void didUpdateWidget(_CountingWon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _from = oldWidget.amount;
    }
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
          '${widget.prefix}${LedgerEntry.formatWon(value.round())}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

class _RevealLine extends StatefulWidget {
  const _RevealLine({
    required this.visible,
    required this.label,
    required this.amount,
    this.prefix = '',
    this.muted = false,
    this.compact = false,
    this.gapAbove,
  });

  final bool visible;
  final String label;
  final int amount;
  final String prefix;
  final bool muted;
  final bool compact;
  final double? gapAbove;

  @override
  State<_RevealLine> createState() => _RevealLineState();
}

class _RevealLineState extends State<_RevealLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;
  late int _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.amount;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.visible ? 1 : 0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(_RevealLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != 0) _shown = widget.amount;
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _fade,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: EdgeInsets.only(
              top: widget.gapAbove ?? (widget.compact ? 3 : 4),
            ),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
                const Spacer(),
                _CountingWon(
                  amount: _shown,
                  prefix: widget.prefix,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.muted ? colors.muted : colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
