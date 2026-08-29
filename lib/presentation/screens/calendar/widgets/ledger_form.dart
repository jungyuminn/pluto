import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/ledger_salary.dart';
import 'package:job_planner/domain/ledger_salary_calc.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_time_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_title_field.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_salary_fields.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:job_planner/presentation/widgets/sliding_kind_bar.dart';

class LedgerForm extends StatefulWidget {
  const LedgerForm({
    super.key,
    required this.date,
    this.initial,
  });

  final DateTime date;
  final LedgerEntry? initial;

  @override
  State<LedgerForm> createState() => _LedgerFormState();
}

class _LedgerFormState extends State<LedgerForm>
    with TickerProviderStateMixin {
  late final PlainTextEditingController _title;
  late final PlainTextEditingController _amount;
  final _titleFocus = FocusNode();
  final _amountFocus = FocusNode();
  late final AnimationController _kindAnimation;
  late final CurvedAnimation _kindFade;
  late final AnimationController _salaryAnimation;
  late final CurvedAnimation _salaryFade;
  late final Animation<double> _salaryOpacity;
  late final Animation<Offset> _salarySlide;
  late DateTime _date;
  late LedgerKind _kind;
  late LedgerSalaryDetails _salary;
  var _breakEdited = false;
  var _saving = false;
  var _kindOpen = true;
  var _kindToggling = false;
  Animation<double>? _sheetAnimation;

  bool get _isSalary => _kind == LedgerKind.salary;

  Color get _accent => switch (_kind) {
        LedgerKind.salary => LedgerEntry.salaryColor,
        LedgerKind.consumption => LedgerEntry.consumptionColor,
        LedgerKind.expense => LedgerEntry.expenseColor,
      };

  int get _amountValue {
    final digits = _amount.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  LedgerSalaryDetails get _salaryWithWage {
    if (_salary.isMonthlyWage) {
      return _salary.copyWith(monthlyWage: _amountValue);
    }
    return _salary.copyWith(hourlyWage: _amountValue);
  }

  LedgerSalaryResult get _salaryResult =>
      LedgerSalaryCalc.compute(_salaryWithWage);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final date = initial?.date ?? widget.date;
    _date = DateTime(date.year, date.month, date.day);
    _kind = initial?.kind ?? LedgerKind.consumption;
    _salary = initial?.salary ??
        LedgerSalaryDetails(
          weekday: _date.weekday,
          monthDay: _date.day,
          monthDay2: _date.day >= 20 ? 10 : 25,
          monthWeek: SalaryMonthDate.weekOf(_date),
        );
    _breakEdited = initial?.salary != null;
    final amountText = _isSalary
        ? (_salary.isMonthlyWage ? _salary.monthlyWage : _salary.hourlyWage)
        : (initial?.amount ?? 0);
    _title = PlainTextEditingController(text: initial?.title ?? '');
    _amount = PlainTextEditingController(
      text: amountText <= 0 ? '' : LedgerEntry.formatWon(amountText),
    );
    _kindAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
      value: 1,
    );
    _kindFade = CurvedAnimation(
      parent: _kindAnimation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _salaryAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      reverseDuration: const Duration(milliseconds: 360),
      value: _kind == LedgerKind.salary ? 1 : 0,
    );
    _salaryFade = CurvedAnimation(
      parent: _salaryAnimation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _salaryOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _salaryAnimation,
        curve: const Interval(0.28, 1, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0, 0.72, curve: Curves.easeInCubic),
      ),
    );
    _salarySlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _salaryAnimation,
        curve: const Interval(0.12, 1, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0, 0.8, curve: Curves.easeInCubic),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sheetAnimation = ModalRoute.of(context)?.animation;
      final animation = _sheetAnimation;
      if (animation == null || animation.isCompleted) {
        _titleFocus.requestFocus();
      } else {
        animation.addStatusListener(_onSheetOpened);
      }
    });
  }

  void _onSheetOpened(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    if (mounted) _titleFocus.requestFocus();
  }

  @override
  void dispose() {
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    _kindFade.dispose();
    _kindAnimation.dispose();
    _salaryFade.dispose();
    _salaryAnimation.dispose();
    _titleFocus.dispose();
    _amountFocus.dispose();
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _formatAmount(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted =
        digits.isEmpty ? '' : LedgerEntry.formatWon(int.parse(digits));
    if (formatted != _amount.text) {
      _amount.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _setKind(LedgerKind kind) {
    if (kind == _kind) return;
    final wasSalary = _kind == LedgerKind.salary;
    setState(() => _kind = kind);
    if (kind == LedgerKind.salary) {
      _salaryAnimation.forward();
    } else if (wasSalary) {
      _salaryAnimation.reverse();
    }
  }

  Future<void> _toggleKind() async {
    if (_kindToggling) return;
    _kindToggling = true;
    _titleFocus.unfocus();
    _amountFocus.unfocus();
    if (_kindOpen) {
      setState(() => _kindOpen = false);
      await _kindAnimation.reverse();
    } else {
      setState(() => _kindOpen = true);
      await _kindAnimation.forward();
    }
    if (!mounted) return;
    _kindToggling = false;
  }

  String _kindLabel(LedgerKind kind) {
    return switch (kind) {
      LedgerKind.expense => AppStrings.ledgerExpense,
      LedgerKind.consumption => AppStrings.ledgerConsumption,
      LedgerKind.salary => AppStrings.ledgerSalary,
    };
  }

  void _onSalaryChanged(LedgerSalaryDetails next, {bool fromTime = false}) {
    var details = next;
    var date = _date;
    if (next.usesMonthPayDay && next.monthRule != _salary.monthRule) {
      if (next.monthRule == SalaryMonthRule.weekday) {
        details = next.copyWith(
          weekday: _date.weekday,
          monthWeek: SalaryMonthDate.weekOf(_date),
        );
      } else {
        details = next.copyWith(monthDay: _date.day);
      }
    } else if (next.cycle.selectableCycle == SalaryPayCycle.weekly &&
        next.weekday != _salary.weekday) {
      date = _dateWithWeekday(_date, next.weekday);
    } else if (next.usesMonthWeekday &&
        (next.weekday != _salary.weekday ||
            next.monthWeek != _salary.monthWeek)) {
      date = _dateWithMonthWeekday(_date, next.monthWeek, next.weekday);
    } else if (next.usesMonthDay && next.monthDay != _salary.monthDay) {
      date = _dateWithMonthDay(_date, next.monthDay);
    } else if (next.cycle == SalaryPayCycle.twiceMonthly) {
      if (next.monthDay != _salary.monthDay) {
        date = _dateWithMonthDay(_date, next.monthDay);
      } else if (next.monthDay2 != _salary.monthDay2) {
        date = _dateWithMonthDay(_date, next.monthDay2);
      }
    }
    setState(() {
      if (!fromTime && details.breakMinutes != _salary.breakMinutes) {
        _breakEdited = true;
      }
      _salary = details;
      _date = date;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showAppCalendarSheet(
      context,
      date: _date,
      dates: [_date],
      mode: AppCalendarMode.single,
      color: _accent,
      showModes: false,
    );
    if (picked == null || !mounted) return;
    final date = picked.date;
    setState(() {
      _date = DateTime(date.year, date.month, date.day);
      _salary = _salary.copyWith(
        weekday: _date.weekday,
        monthDay: _salary.cycle == SalaryPayCycle.twiceMonthly
            ? _salary.monthDay
            : _date.day,
        monthWeek: SalaryMonthDate.weekOf(_date),
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showEventTimeSheet(
      context,
      startMinutes: _salary.startMinutes,
      endMinutes: _salary.endMinutes,
      color: _accent,
    );
    if (picked == null || !mounted) return;
    if (picked.isCleared) {
      _onSalaryChanged(_salary.copyWith(clearTime: true, breakMinutes: 0), fromTime: true);
      return;
    }
    final work = LedgerSalaryCalc.workMinutesOf(
      picked.startMinutes,
      picked.endMinutes,
    );
    final brk = _breakEdited
        ? _salary.breakMinutes
        : LedgerSalaryCalc.statutoryBreakMinutes(work);
    _onSalaryChanged(
      _salary.copyWith(
        startMinutes: picked.startMinutes,
        endMinutes: picked.endMinutes,
        breakMinutes: brk,
      ),
      fromTime: true,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (_isSalary) {
      final salary = _salaryWithWage;
      final result = LedgerSalaryCalc.compute(salary);
      final missingTime = !salary.isMonthlyWage &&
          (salary.startMinutes == null || salary.endMinutes == null);
      if (title.isEmpty ||
          result.net <= 0 ||
          (salary.isMonthlyWage ? salary.monthlyWage <= 0 : missingTime)) {
        await showMissingFieldsDialog(
          context,
          body: salary.isMonthlyWage
              ? AppStrings.missingLedgerSalaryMonthlyBody
              : AppStrings.missingLedgerSalaryBody,
        );
        return;
      }
      await _persist(
        title: title,
        amount: result.net,
        salary: salary,
      );
      return;
    }
    if (title.isEmpty || _amountValue <= 0) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.missingLedgerBody,
      );
      return;
    }
    await _persist(title: title, amount: _amountValue);
  }

  Future<void> _persist({
    required String title,
    required int amount,
    LedgerSalaryDetails? salary,
  }) async {
    setState(() => _saving = true);
    final initial = widget.initial;
    final now = DateTime.now().millisecondsSinceEpoch;
    await AppScope.of(context).saveLedger(
      LedgerEntry(
        id: initial?.id ?? '$now',
        date: _date,
        title: title,
        amount: amount,
        kind: _kind,
        memo: initial?.memo ?? '',
        sortOrder: initial?.sortOrder ?? now,
        salary: _isSalary ? salary : null,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.tint(_accent),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, _isSalary ? 24 : 28),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventTitleField(
              controller: _title,
              focusNode: _titleFocus,
              autofocus: false,
              hintText: _isSalary
                  ? AppStrings.ledgerWorkplaceHint
                  : AppStrings.ledgerTitleHint,
            ),
            const SizedBox(height: 6),
            _AmountField(
              controller: _amount,
              focusNode: _amountFocus,
              accent: _accent,
              hintText: _isSalary
                  ? (_salary.isMonthlyWage
                      ? AppStrings.ledgerMonthlyHint
                      : AppStrings.ledgerHourlyHint)
                  : AppStrings.ledgerAmountHint,
              suffixText: _isSalary
                  ? '${AppStrings.ledgerAmountSuffix} (${_salary.isMonthlyWage ? AppStrings.ledgerWageMonthly : AppStrings.ledgerWageHourly})'
                  : AppStrings.ledgerAmountSuffix,
              onChanged: _formatAmount,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        EventActionIcon(
                          label: AppStrings.longGoalKindAction,
                          text: _kindLabel(_kind),
                          color: _accent,
                          selected: _kindOpen,
                          size: 14,
                          onPressed: _toggleKind,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 14, height: 14),
                          ),
                        ),
                        const SizedBox(width: 4),
                        EventDateChip(
                          date: _date,
                          color: _accent,
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SaveCompanyButton(
                  onPressed: _saving ? () {} : _save,
                  color: _accent,
                ),
              ],
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _kindFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _kindFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IgnorePointer(
                      ignoring: !_kindOpen,
                      child: SlidingKindBar(
                        values: const [
                          LedgerKind.consumption,
                          LedgerKind.expense,
                          LedgerKind.salary,
                        ],
                        selected: _kind,
                        labelOf: _kindLabel,
                        accent: _accent,
                        onChanged: _setKind,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _salaryFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _salaryOpacity,
                  child: SlideTransition(
                    position: _salarySlide,
                    child: IgnorePointer(
                      ignoring: !_isSalary && !_salaryAnimation.isAnimating,
                      child: LedgerSalaryFields(
                        details: _salaryWithWage,
                        result: _salaryResult,
                        accent: _accent,
                        onChanged: _onSalaryChanged,
                        onPickTime: _pickTime,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.hintText,
    required this.suffixText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final String hintText;
  final String suffixText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.of(context);
    final colors = AppColors.of(context);
    const size = 18.0;
    final style = TextStyle(
      fontFamily: font,
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.2,
      letterSpacing: 0,
      color: accent,
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasAmount = controller.text.isNotEmpty;
        return LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: controller.text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1,
            )..layout();
            final textWidth = painter.width;
            painter.dispose();

            return Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  cursorWidth: 1.2,
                  style: style,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: font,
                      color: colors.hint,
                      fontWeight: FontWeight.w600,
                      fontSize: size,
                      height: 1.2,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (hasAmount)
                  Positioned(
                    left: textWidth,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(suffixText, style: style),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

DateTime _dateWithWeekday(DateTime date, int weekday) {
  var delta = weekday - date.weekday;
  if (delta < 0) delta += 7;
  return date.add(Duration(days: delta));
}

DateTime _dateWithMonthDay(DateTime date, int day) {
  DateTime inMonth(int year, int month) {
    final last = DateTime(year, month + 1, 0).day;
    final resolved = day <= 0 ? last : day.clamp(1, last);
    return DateTime(year, month, resolved);
  }

  final candidate = inMonth(date.year, date.month);
  if (candidate.isBefore(date)) {
    return inMonth(date.year, date.month + 1);
  }
  return candidate;
}

DateTime _dateWithMonthWeekday(
  DateTime date,
  SalaryMonthWeek week,
  int weekday,
) {
  DateTime inMonth(int year, int month) {
    return SalaryMonthDate.weekdayInMonth(
      year: year,
      month: month,
      weekday: weekday,
      week: week,
    );
  }

  final candidate = inMonth(date.year, date.month);
  if (candidate.isBefore(date)) {
    return inMonth(date.year, date.month + 1);
  }
  return candidate;
}
