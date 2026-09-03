import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/ledger_salary.dart';
import 'package:pluto/domain/ledger_salary_calc.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_salary_result_card.dart';
import 'package:pluto/presentation/widgets/sliding_kind_bar.dart';

Future<void> showLedgerDeductionHelp(
  BuildContext context, {
  required Color accent,
}) {
  FocusManager.instance.primaryFocus?.unfocus(
    disposition: UnfocusDisposition.scope,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => LedgerDeductionHelpSheet(accent: accent),
  );
}

class LedgerDeductionHelpSheet extends StatelessWidget {
  const LedgerDeductionHelpSheet({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DeductionPreview(accent: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewFrame {
  const _PreviewFrame({
    required this.caption,
    required this.body,
    required this.sample,
    required this.details,
  });

  final String caption;
  final String body;
  final String sample;
  final LedgerSalaryDetails details;
}

class _DeductionPreview extends StatefulWidget {
  const _DeductionPreview({required this.accent});

  final Color accent;

  @override
  State<_DeductionPreview> createState() => _DeductionPreviewState();
}

class _DeductionPreviewState extends State<_DeductionPreview> {
  var _index = 0;
  Timer? _timer;

  List<_PreviewFrame> get _frames => [
        _PreviewFrame(
          caption: AppStrings.ledgerNetPay,
          body: AppStrings.ledgerDeductionHelpNet,
          sample: AppStrings.ledgerDeductionHelpHourlySample,
          details: _hourly,
        ),
        _PreviewFrame(
          caption: AppStrings.ledgerInsuranceAll,
          body: AppStrings.ledgerDeductionHelpAll,
          sample: AppStrings.ledgerDeductionHelpHourlySample,
          details: _hourly.copyWith(insurance: SalaryInsurance.all),
        ),
        _PreviewFrame(
          caption: AppStrings.ledgerInsuranceEmployment,
          body: AppStrings.ledgerDeductionHelpEmployment,
          sample: AppStrings.ledgerDeductionHelpHourlySample,
          details: _hourly.copyWith(
            insurance: SalaryInsurance.employmentOnly,
          ),
        ),
        _PreviewFrame(
          caption: AppStrings.ledgerTax,
          body: AppStrings.ledgerDeductionHelpTax,
          sample: AppStrings.ledgerDeductionHelpHourlySample,
          details: _hourly.copyWith(tax: true),
        ),
        _PreviewFrame(
          caption: AppStrings.ledgerWeeklyHoliday,
          body: AppStrings.ledgerDeductionHelpHoliday,
          sample: AppStrings.ledgerDeductionHelpHourlySample,
          details: _hourly.copyWith(weeklyHoliday: true),
        ),
      ];

  static const _hourly = LedgerSalaryDetails(
    hourlyWage: 10000,
    startMinutes: 9 * 60,
    endMinutes: 18 * 60,
    breakMinutes: 60,
    tax: false,
    insurance: SalaryInsurance.none,
    weeklyHoliday: false,
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      _goTo(_index + 1);
    });
  }

  void _goTo(int next, {bool fromUser = false}) {
    final length = _frames.length;
    final index = next % length;
    final wrapped = index < 0 ? index + length : index;
    if (wrapped == _index) return;
    setState(() => _index = wrapped);
    if (fromUser) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frames[_index];
    final colors = AppColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 180) return;
        _goTo(velocity < 0 ? _index + 1 : _index - 1, fromUser: true);
      },
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.groupedBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _NavButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: () => _goTo(_index - 1, fromUser: true),
                      ),
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            child: DecoratedBox(
                              key: ValueKey(frame.caption),
                              decoration: BoxDecoration(
                                color: colors.tint(colors.accentBright, 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  frame.caption,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.of(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accentBright,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _NavButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: () => _goTo(_index + 1, fromUser: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      child: _DeductionScene(
                        accent: widget.accent,
                        sample: frame.sample,
                        details: frame.details,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Text(
                frame.body,
                key: ValueKey(frame.body),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: colors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _frames.length; i++)
                PressBounce(
                  onPressed: () => _goTo(i, fromUser: true),
                  pressedScale: 0.9,
                  pressedColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: i == _index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? colors.accentBright
                            : colors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.88,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 26, color: colors.muted),
      ),
    );
  }
}

class _DeductionScene extends StatelessWidget {
  const _DeductionScene({
    required this.accent,
    required this.sample,
    required this.details,
  });

  final Color accent;
  final String sample;
  final LedgerSalaryDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final result = LedgerSalaryCalc.compute(details);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                sample,
                key: ValueKey(sample),
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SlidingKindBar(
              values: SalaryInsurance.values,
              selected: details.insurance,
              labelOf: (insurance) => switch (insurance) {
                SalaryInsurance.none => AppStrings.ledgerInsuranceNone,
                SalaryInsurance.employmentOnly =>
                  AppStrings.ledgerInsuranceEmployment,
                SalaryInsurance.all => AppStrings.ledgerInsuranceAll,
              },
              accent: accent,
              onChanged: (_) {},
              height: 38,
            ),
            const SizedBox(height: 4),
            _SwitchLine(
              label: AppStrings.ledgerTax,
              value: details.tax,
              accent: accent,
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: details.isMonthlyWage
                    ? const SizedBox(width: double.infinity)
                    : _SwitchLine(
                        label: AppStrings.ledgerWeeklyHoliday,
                        value: details.weeklyHoliday,
                        accent: accent,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            LedgerSalaryResultCard(
              result: result,
              accent: accent,
              compact: true,
              background: colors.groupedBackground,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final bool value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).text,
              ),
            ),
          ),
          _FakeSwitch(value: value, accent: accent),
        ],
      ),
    );
  }
}

class _FakeSwitch extends StatelessWidget {
  const _FakeSwitch({required this.value, required this.accent});

  final bool value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? accent : colors.border,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 18, height: 18),
      ),
    );
  }
}
