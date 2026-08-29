import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';
import 'package:job_planner/domain/ledger_salary_calc.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_deduction_help.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_salary_result_card.dart';
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
      details.cycle.selectableCycle == SalaryPayCycle.monthly;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          label: AppStrings.ledgerPayCycleLabel,
          child: _PayCycleBar(
            details: details,
            accent: accent,
            onChanged: onChanged,
            below: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Reveal(
                  visible: details.usesWeekday,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SlidingKindBar(
                      values: _weekdays,
                      selected: details.weekday,
                      labelOf: (weekday) => AppStrings.weekdays[weekday % 7],
                      accent: accent,
                      onChanged: (weekday) =>
                          onChanged(details.copyWith(weekday: weekday)),
                    ),
                  ),
                ),
                _Reveal(
                  visible: details.usesMonthPayDay,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SlidingKindBar(
                          values: SalaryMonthRule.values,
                          selected: details.monthRule,
                          labelOf: (rule) => rule == SalaryMonthRule.date
                              ? AppStrings.ledgerMonthDay(details.monthDay)
                              : AppStrings.ledgerPayByWeekday,
                          accent: accent,
                          onChanged: (rule) {
                            onChanged(details.copyWith(monthRule: rule));
                            if (rule == SalaryMonthRule.date) {
                              _pickMonthDay(context, first: true);
                            }
                          },
                          onReselected: details.monthRule == SalaryMonthRule.date
                              ? () => _pickMonthDay(context, first: true)
                              : null,
                        ),
                        _Reveal(
                          visible: details.usesMonthWeekday,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                SlidingKindBar(
                                  values: SalaryMonthWeek.values,
                                  selected: details.monthWeek,
                                  labelOf: _monthWeekLabel,
                                  accent: accent,
                                  onChanged: (week) =>
                                      onChanged(details.copyWith(monthWeek: week)),
                                ),
                                const SizedBox(height: 4),
                                SlidingKindBar(
                                  values: _weekdays,
                                  selected: details.weekday,
                                  labelOf: (weekday) =>
                                      AppStrings.weekdays[weekday % 7],
                                  accent: accent,
                                  onChanged: (weekday) =>
                                      onChanged(details.copyWith(weekday: weekday)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _Reveal(
                  visible: _showWageType,
                  child: _Section(
                    label: AppStrings.ledgerWageTypeLabel,
                    child: SlidingKindBar(
                      values: SalaryWageType.values,
                      selected: details.wageType,
                      labelOf: _wageLabel,
                      accent: accent,
                      onChanged: (value) =>
                          onChanged(details.copyWith(wageType: value)),
                    ),
                  ),
                ),
                _Reveal(
                  visible: !details.isMonthlyWage,
                  child: _Section(
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
                ),
                _Section(
                  label: AppStrings.ledgerDeductionLabel,
                  onHelp: () => showLedgerDeductionHelp(
                    context,
                    accent: accent,
                  ),
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
                        accent: accent,
                        onChanged: (value) =>
                            onChanged(details.copyWith(tax: value)),
                      ),
                      _Reveal(
                        visible: !details.isMonthlyWage,
                        child: _SwitchLine(
                          label: AppStrings.ledgerWeeklyHoliday,
                          value: details.weeklyHoliday,
                          accent: accent,
                          onChanged: (value) =>
                              onChanged(details.copyWith(weeklyHoliday: value)),
                        ),
                      ),
                    ],
                  ),
                ),
                _Reveal(
                  visible: result.net > 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LedgerSalaryResultCard(
                      result: result,
                      accent: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickBreak(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x40000000),
      elevation: 0,
      builder: (context) => _BreakSheet(
        minutes: details.breakMinutes,
        accent: accent,
      ),
    );
    if (context.mounted) {
      FocusManager.instance.primaryFocus?.unfocus(
        disposition: UnfocusDisposition.scope,
      );
    }
    if (picked == null) return;
    onChanged(details.copyWith(breakMinutes: picked));
  }

  Future<void> _pickMonthDay(BuildContext context, {required bool first}) async {
    final current = first ? details.monthDay : details.monthDay2;
    final picked = await _showOptionSheet<int>(
      context,
      accent: accent,
      child: _DayGrid(
        current: current,
        accent: accent,
      ),
    );
    if (picked == null) return;
    onChanged(
      details.copyWith(
        monthRule: SalaryMonthRule.date,
        monthDay: first ? picked : details.monthDay,
        monthDay2: first ? details.monthDay2 : picked,
      ),
    );
  }

  static Future<T?> _showOptionSheet<T>(
    BuildContext context, {
    required Color accent,
    String? title,
    required Widget child,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x40000000),
      elevation: 0,
      builder: (context) {
        final colors = AppColors.of(context);
        final bottom = MediaQuery.paddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tint(accent),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 14),
                  if (title != null) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
    if (context.mounted) {
      FocusManager.instance.primaryFocus?.unfocus(
        disposition: UnfocusDisposition.scope,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        FocusManager.instance.primaryFocus?.unfocus(
          disposition: UnfocusDisposition.scope,
        );
      });
    }
    return picked;
  }

  static const _weekdays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static String _monthWeekLabel(SalaryMonthWeek week) {
    return switch (week) {
      SalaryMonthWeek.first => AppStrings.ledgerPayWeekFirst,
      SalaryMonthWeek.second => AppStrings.ledgerPayWeekSecond,
      SalaryMonthWeek.third => AppStrings.ledgerPayWeekThird,
      SalaryMonthWeek.fourth => AppStrings.ledgerPayWeekFourth,
      SalaryMonthWeek.last => AppStrings.ledgerPayWeekLast,
    };
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

class _PayCycleBar extends StatefulWidget {
  const _PayCycleBar({
    required this.details,
    required this.accent,
    required this.onChanged,
    required this.below,
  });

  final LedgerSalaryDetails details;
  final Color accent;
  final ValueChanged<LedgerSalaryDetails> onChanged;
  final Widget below;

  @override
  State<_PayCycleBar> createState() => _PayCycleBarState();
}

class _PayCycleBarState extends State<_PayCycleBar> {
  final _overlay = OverlayPortalController();
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _overlay.show();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _setCycle(SalaryPayCycle cycle) {
    final hourlyOnly = cycle == SalaryPayCycle.sameDay ||
        cycle == SalaryPayCycle.weekly;
    widget.onChanged(
      widget.details.copyWith(
        cycle: cycle.selectableCycle,
        wageType: hourlyOnly ? SalaryWageType.hourly : widget.details.wageType,
      ),
    );
    if (cycle.selectableCycle == SalaryPayCycle.sameDay) {
      _hintTimer?.cancel();
      if (_hintVisible) setState(() => _hintVisible = false);
      return;
    }
    _showHint();
  }

  void _showHint() {
    _hintTimer?.cancel();
    setState(() => _hintVisible = true);
    _hintTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (context) {
        final safe = MediaQuery.paddingOf(context).bottom;
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        return Positioned(
          left: 20,
          right: 20,
          bottom: (keyboard > 0 ? keyboard : safe) + 16,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              curve: _hintVisible ? Curves.easeOut : Curves.easeIn,
              opacity: _hintVisible ? 1 : 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  key: ValueKey(widget.details.cycle.selectableCycle),
                  color: Colors.transparent,
                  child: _RepeatHintToast(
                    text: AppStrings.ledgerSalaryRepeatHint,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SlidingKindBar(
            values: SalaryPayCycleX.selectable,
            selected: widget.details.cycle.selectableCycle,
            labelOf: LedgerSalaryFields._cycleLabel,
            accent: widget.accent,
            onChanged: _setCycle,
          ),
          widget.below,
        ],
      ),
    );
  }
}

class _RepeatHintToast extends StatelessWidget {
  const _RepeatHintToast({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(_Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _fade,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: _fade,
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child, this.onHelp});

  final String label;
  final Widget child;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              if (onHelp != null) ...[
                const SizedBox(width: 2),
                PressBounce(
                  onPressed: onHelp,
                  pressedScale: 0.88,
                  pressedColor: Colors.transparent,
                  child: Semantics(
                    button: true,
                    label: AppStrings.settingsHelpPreview,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        CupertinoIcons.question_circle,
                        size: 16,
                        color: colors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color accent;
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
                activeTrackColor: accent,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakSheet extends StatefulWidget {
  const _BreakSheet({
    required this.minutes,
    required this.accent,
  });

  final int minutes;
  final Color accent;

  static const _options = [0, 15, 30, 45, 60, 90];
  static const _extent = 44.0;
  static const _loops = 10000;

  static int get _count => _options.length;

  @override
  State<_BreakSheet> createState() => _BreakSheetState();
}

class _BreakSheetState extends State<_BreakSheet> {
  late final FixedExtentScrollController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final real = _BreakSheet._options.indexOf(widget.minutes);
    _index = (_BreakSheet._loops ~/ 2) * _BreakSheet._count +
        (real < 0 ? 0 : real);
    _controller = FixedExtentScrollController(initialItem: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final muted = colors.muted;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tint(widget.accent),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 4 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: SaveCompanyButton(
                  onPressed: () => Navigator.of(context).pop(
                    _BreakSheet._options[_index % _BreakSheet._count],
                  ),
                  color: widget.accent,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _BreakSheet._extent * 5,
                child: Stack(
                  children: [
                    Center(
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const SizedBox(
                              height: _BreakSheet._extent,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _controller,
                      itemExtent: _BreakSheet._extent,
                      physics: const FixedExtentScrollPhysics(),
                      diameterRatio: 2.4,
                      perspective: 0.002,
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();
                        setState(() => _index = index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _BreakSheet._count * _BreakSheet._loops,
                        builder: (context, index) {
                          final minutes = _BreakSheet
                              ._options[index % _BreakSheet._count];
                          final selected = index == _index;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                fontFamily: AppFonts.of(context),
                                fontSize: selected ? 20 : 16,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                color: selected
                                    ? widget.accent
                                    : muted.withValues(alpha: 0.7),
                              ),
                              child: Text(
                                minutes == 0
                                    ? AppStrings.ledgerBreakNone
                                    : AppStrings.ledgerBreakMinutes(minutes),
                              ),
                            ),
                          );
                        },
                      ),
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

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.current,
    required this.accent,
  });

  final int current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 5; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _dayCell(context, row * 7 + col),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, int index) {
    if (index > 31) return const SizedBox(height: 40);
    final lastDay = index == 31;
    final day = lastDay ? 0 : index + 1;
    final selected = lastDay ? current <= 0 : current == day;
    final colors = AppColors.of(context);
    final onAccent =
        accent.computeLuminance() > 0.45 ? colors.text : Colors.white;
    return Center(
      child: PressBounce(
        onPressed: () => Navigator.of(context).pop(day),
        color: selected ? accent : Colors.transparent,
        pressedColor: selected
            ? Color.lerp(accent, Colors.black, 0.12)!
            : colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                lastDay ? AppStrings.ledgerPayLastDay : '$day일',
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? onAccent : colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
