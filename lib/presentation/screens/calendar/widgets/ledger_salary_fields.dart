import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';
import 'package:job_planner/domain/ledger_salary_calc.dart';
import 'package:job_planner/presentation/widgets/sliding_kind_bar.dart';

class LedgerSalaryFields extends StatelessWidget {
  const LedgerSalaryFields({
    super.key,
    required this.details,
    required this.result,
    required this.accent,
    required this.onChanged,
    required this.onPickTime,
  });

  final LedgerSalaryDetails details;
  final LedgerSalaryResult result;
  final Color accent;
  final ValueChanged<LedgerSalaryDetails> onChanged;
  final VoidCallback onPickTime;

  bool get _showWageType =>
      details.cycle == SalaryPayCycle.monthly ||
      details.cycle == SalaryPayCycle.twiceMonthly;

  String get _workTimeLabel {
    final start = details.startMinutes;
    final end = details.endMinutes;
    if (start == null || end == null) return AppStrings.ledgerWorkTime;
    return '${CalendarEvent.formatMinutes(start)}–${CalendarEvent.formatMinutes(end)}';
  }

  String get _breakLabel => details.breakMinutes <= 0
      ? AppStrings.ledgerBreakNone
      : AppStrings.ledgerBreakMinutes(details.breakMinutes);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          label: AppStrings.ledgerPayCycleLabel,
          child: SlidingKindBar(
            values: SalaryPayCycle.values,
            selected: details.cycle,
            labelOf: _cycleLabel,
            accent: accent,
            onChanged: _setCycle,
          ),
        ),
        if (_showWageType)
          _Section(
            label: AppStrings.ledgerWageTypeLabel,
            child: SlidingKindBar(
              values: SalaryWageType.values,
              selected: details.wageType,
              labelOf: _wageLabel,
              accent: accent,
              onChanged: (value) => onChanged(details.copyWith(wageType: value)),
            ),
          ),
        if (details.usesWeekday)
          _Section(
            label: AppStrings.ledgerPayDayLabel,
            child: SlidingKindBar(
              values: const [
                DateTime.monday,
                DateTime.tuesday,
                DateTime.wednesday,
                DateTime.thursday,
                DateTime.friday,
                DateTime.saturday,
                DateTime.sunday,
              ],
              selected: details.weekday,
              labelOf: (weekday) => AppStrings.weekdays[weekday % 7],
              accent: accent,
              onChanged: (weekday) =>
                  onChanged(details.copyWith(weekday: weekday)),
            ),
          ),
        if (details.usesMonthDay)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                _ValueRow(
                  label: details.cycle == SalaryPayCycle.twiceMonthly
                      ? AppStrings.ledgerPayDayFirst
                      : AppStrings.ledgerPayDayLabel,
                  value: AppStrings.ledgerMonthDay(details.monthDay),
                  accent: accent,
                  onPressed: () => _pickMonthDay(context, first: true),
                ),
                if (details.cycle == SalaryPayCycle.twiceMonthly)
                  _ValueRow(
                    label: AppStrings.ledgerPayDaySecond,
                    value: AppStrings.ledgerMonthDay(details.monthDay2),
                    accent: accent,
                    onPressed: () => _pickMonthDay(context, first: false),
                  ),
              ],
            ),
          ),
        if (!details.isMonthlyWage)
          _Section(
            label: AppStrings.ledgerWorkLabel,
            child: Column(
              children: [
                _ValueRow(
                  label: AppStrings.ledgerWorkTime,
                  value: _workTimeLabel,
                  accent: accent,
                  placeholder: details.startMinutes == null,
                  onPressed: onPickTime,
                ),
                _ValueRow(
                  label: AppStrings.ledgerBreak,
                  value: _breakLabel,
                  accent: accent,
                  onPressed: () => _pickBreak(context),
                ),
              ],
            ),
          ),
        _Section(
          label: AppStrings.ledgerDeductionLabel,
          child: Column(
            children: [
              SlidingKindBar(
                values: SalaryInsurance.values,
                selected: details.insurance,
                labelOf: _insuranceLabel,
                accent: accent,
                onChanged: (value) =>
                    onChanged(details.copyWith(insurance: value)),
              ),
              const SizedBox(height: 4),
              _SwitchLine(
                label: AppStrings.ledgerTax,
                value: details.tax,
                onChanged: (value) => onChanged(details.copyWith(tax: value)),
              ),
              if (!details.isMonthlyWage)
                _SwitchLine(
                  label: AppStrings.ledgerWeeklyHoliday,
                  value: details.weeklyHoliday,
                  onChanged: (value) =>
                      onChanged(details.copyWith(weeklyHoliday: value)),
                ),
            ],
          ),
        ),
        if (result.net > 0) ...[
          const SizedBox(height: 8),
          _ResultCard(result: result, accent: accent),
        ],
      ],
      ),
    );
  }

  void _setCycle(SalaryPayCycle cycle) {
    final hourlyOnly = cycle == SalaryPayCycle.sameDay ||
        cycle == SalaryPayCycle.weekly ||
        cycle == SalaryPayCycle.biweekly;
    onChanged(
      details.copyWith(
        cycle: cycle,
        wageType: hourlyOnly ? SalaryWageType.hourly : details.wageType,
      ),
    );
  }

  Future<void> _pickBreak(BuildContext context) async {
    const options = [0, 15, 30, 45, 60, 90];
    final picked = await _showChoiceSheet<int>(
      context,
      children: [
        for (final minutes in options)
          _ChoiceChip(
            label: minutes == 0
                ? AppStrings.ledgerBreakNone
                : AppStrings.ledgerBreakMinutes(minutes),
            selected: details.breakMinutes == minutes,
            accent: accent,
            onPressed: () => Navigator.of(context).pop(minutes),
          ),
      ],
    );
    if (picked == null) return;
    onChanged(details.copyWith(breakMinutes: picked));
  }

  Future<void> _pickMonthDay(BuildContext context, {required bool first}) async {
    final current = first ? details.monthDay : details.monthDay2;
    final picked = await _showChoiceSheet<int>(
      context,
      children: [
        for (var day = 1; day <= 31; day++)
          _ChoiceChip(
            label: AppStrings.ledgerMonthDay(day),
            selected: current == day,
            accent: accent,
            onPressed: () => Navigator.of(context).pop(day),
          ),
        _ChoiceChip(
          label: AppStrings.ledgerPayLastDay,
          selected: current <= 0,
          accent: accent,
          onPressed: () => Navigator.of(context).pop(0),
        ),
      ],
    );
    if (picked == null) return;
    onChanged(
      first
          ? details.copyWith(monthDay: picked)
          : details.copyWith(monthDay2: picked),
    );
  }

  static Future<T?> _showChoiceSheet<T>(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x40000000),
      builder: (context) {
        final colors = AppColors.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  static String _cycleLabel(SalaryPayCycle cycle) {
    return switch (cycle) {
      SalaryPayCycle.sameDay => AppStrings.ledgerPaySameDay,
      SalaryPayCycle.weekly => AppStrings.ledgerPayWeekly,
      SalaryPayCycle.biweekly => AppStrings.ledgerPayBiweekly,
      SalaryPayCycle.monthly => AppStrings.ledgerPayMonthly,
      SalaryPayCycle.twiceMonthly => AppStrings.ledgerPayTwiceMonthlyShort,
    };
  }

  static String _wageLabel(SalaryWageType type) {
    return switch (type) {
      SalaryWageType.hourly => AppStrings.ledgerWageHourly,
      SalaryWageType.monthly => AppStrings.ledgerWageMonthly,
    };
  }

  static String _insuranceLabel(SalaryInsurance insurance) {
    return switch (insurance) {
      SalaryInsurance.none => AppStrings.ledgerInsuranceNone,
      SalaryInsurance.employmentOnly => AppStrings.ledgerInsuranceEmployment,
      SalaryInsurance.all => AppStrings.ledgerInsuranceAll,
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.accent,
    required this.onPressed,
    this.placeholder = false,
  });

  final String label;
  final String value;
  final Color accent;
  final VoidCallback onPressed;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: Colors.transparent,
      pressedColor: colors.pressed.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: placeholder ? colors.hint : accent,
              ),
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
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(!value),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).text,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: FittedBox(
              child: CupertinoSwitch(
                value: value,
                activeTrackColor: AppColors.of(context).accentBright,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.accent});

  final LedgerSalaryResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final lines = <(String, String, bool)>[
      (
        AppStrings.ledgerBasePay,
        LedgerEntry.formatWon(result.basePay),
        false,
      ),
      if (result.holidayPay > 0)
        (
          AppStrings.ledgerHolidayPay,
          '+${LedgerEntry.formatWon(result.holidayPay)}',
          false,
        ),
      if (result.tax > 0)
        (AppStrings.ledgerTax, '-${LedgerEntry.formatWon(result.tax)}', true),
      if (result.pension > 0)
        (
          AppStrings.ledgerPension,
          '-${LedgerEntry.formatWon(result.pension)}',
          true,
        ),
      if (result.health > 0)
        (
          AppStrings.ledgerHealth,
          '-${LedgerEntry.formatWon(result.health)}',
          true,
        ),
      if (result.longTermCare > 0)
        (
          AppStrings.ledgerLongTermCare,
          '-${LedgerEntry.formatWon(result.longTermCare)}',
          true,
        ),
      if (result.employment > 0)
        (
          AppStrings.ledgerEmploymentInsurance,
          '-${LedgerEntry.formatWon(result.employment)}',
          true,
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  AppStrings.ledgerNetPay,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  '${LedgerEntry.formatWon(result.net)}${AppStrings.ledgerAmountSuffix}',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text(
                        line.$1,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        line.$2,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: line.$3 ? colors.muted : colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: selected ? accent : colors.background,
      pressedColor: selected
          ? Color.lerp(accent, Colors.black, 0.12)!
          : colors.pressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : colors.text,
          ),
        ),
      ),
    );
  }
}
