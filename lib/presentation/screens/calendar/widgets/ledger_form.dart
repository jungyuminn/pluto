import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/category_history.dart';
import 'package:pluto/core/utils/focused_ime_text.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/entities/ledger_salary.dart';
import 'package:pluto/domain/ledger_salary_calc.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_time_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_title_field.dart';
import 'package:pluto/presentation/widgets/ai_category_chip.dart';
import 'package:pluto/presentation/widgets/category_suggest_session.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_salary_fields.dart';
import 'package:pluto/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:pluto/presentation/widgets/sliding_kind_bar.dart';

Future<EventCategory> lastLedgerCategoryOf(BuildContext context) async {
  final scope = AppScope.of(context);
  final entries = await scope.getLedgers();
  final categories = await scope.fetchCategories(CategoryKind.ledger);

  EventCategory? last;
  if (entries.isNotEmpty) {
    final newest = entries.reduce((a, b) => a.id.compareTo(b.id) >= 0 ? a : b);
    for (final category in categories) {
      if (category.id == newest.categoryId) {
        last = category;
        break;
      }
    }
  }
  if (last != null) return last;

  final foodId = EventCategory.ledgerPresets.first.id;
  for (final category in categories) {
    if (category.id == foodId) return category;
  }
  return categories.isNotEmpty
      ? categories.first
      : EventCategory.ledgerPresets.first;
}

class LedgerForm extends StatefulWidget {
  const LedgerForm({
    super.key,
    required this.date,
    this.initial,
    this.lastCategory,
  });

  final DateTime date;
  final LedgerEntry? initial;
  final EventCategory? lastCategory;

  @override
  State<LedgerForm> createState() => _LedgerFormState();
}

class _LedgerFormState extends State<LedgerForm> with TickerProviderStateMixin {
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
  late LedgerKind _wageKind;
  late LedgerSalaryDetails _salary;
  var _breakEdited = false;
  var _saving = false;
  var _kindOpen = true;
  var _kindToggling = false;
  late String? _categoryId;
  String? _categoryName;
  int? _categoryColor;
  Animation<double>? _sheetAnimation;
  CategorySuggestSession? _suggest;
  var _suggestOn = false;
  var _suggesting = false;
  var _pendingTitle = '';

  bool get _isHourly => _kind == LedgerKind.hourly;

  bool get _isSalary => _kind == LedgerKind.salary;

  bool get _isWage => _isHourly || _isSalary;

  bool get _hasCategory =>
      _categoryId != null && (_categoryName?.trim().isNotEmpty ?? false);

  Color get _kindColor => switch (_kind) {
    LedgerKind.salary => LedgerEntry.salaryColor,
    LedgerKind.hourly => LedgerEntry.hourlyColor,
    LedgerKind.consumption => LedgerEntry.consumptionColor,
    LedgerKind.expense => LedgerEntry.expenseColor,
  };

  Color get _accent => _hasCategory ? Color(_categoryColor!) : _kindColor;

  int get _amountValue {
    final digits = _amount.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  LedgerSalaryDetails get _salaryWithWage => _salary.copyWith(
    wageType: SalaryWageType.hourly,
    hourlyWage: _amountValue,
  );

  LedgerSalaryDetails get _salaryDetails {
    if (_wageKind == LedgerKind.salary) {
      return _salary.copyWith(
        wageType: SalaryWageType.monthly,
        monthlyWage: _amountValue,
        cycle: SalaryPayCycle.monthly,
      );
    }
    return _salaryWithWage;
  }

  LedgerSalaryResult get _salaryResult =>
      LedgerSalaryCalc.compute(_salaryDetails);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final date = initial?.date ?? widget.date;
    _date = DateTime(date.year, date.month, date.day);
    _kind = initial?.kind ?? LedgerKind.consumption;
    _wageKind = _isSalary ? LedgerKind.salary : LedgerKind.hourly;
    var salary =
        initial?.salary ??
        LedgerSalaryDetails(
          weekday: _date.weekday,
          monthDay: _date.day,
          monthDay2: _date.day >= 20 ? 10 : 25,
          monthWeek: SalaryMonthDate.weekOf(_date),
        );
    if (_isHourly) {
      salary = salary.copyWith(wageType: SalaryWageType.hourly);
    } else if (_isSalary) {
      salary = salary.copyWith(
        wageType: SalaryWageType.monthly,
        cycle: SalaryPayCycle.monthly,
      );
    }
    _salary = salary;
    _breakEdited = initial?.salary != null;
    final amountText = _isHourly ? _salary.hourlyWage : (initial?.amount ?? 0);
    _title = PlainTextEditingController(text: initial?.title ?? '');
    _title.addListener(_onTitleChanged);
    _amount = PlainTextEditingController(
      text: amountText <= 0 ? '' : LedgerEntry.formatWon(amountText),
    );
    final preset = widget.lastCategory ?? EventCategory.ledgerPresets.first;
    _categoryId = initial?.categoryId ?? preset.id;
    _categoryName = (initial?.categoryName.trim().isNotEmpty ?? false)
        ? initial!.categoryName
        : preset.name;
    _categoryColor = (initial != null && initial.categoryColor != 0)
        ? initial.categoryColor
        : preset.color;
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
      value: _isWage ? 1 : 0,
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
    _salarySlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(
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
      _prepareSuggest();
    });
  }

  Future<void> _prepareSuggest() async {
    if (!CategorySuggestSession.isOn(
      context,
      editing: widget.initial != null,
    )) {
      return;
    }
    final scope = AppScope.of(context);
    final entries = await scope.getLedgers();
    final categories = await scope.fetchCategories(CategoryKind.ledger);
    if (!mounted) return;
    final fallback = EventCategory(
      id: _categoryId ?? EventCategory.ledgerPresets.first.id,
      name: _categoryName ?? EventCategory.ledgerPresets.first.name,
      color: _categoryColor ?? EventCategory.ledgerPresets.first.color,
    );
    _suggest?.dispose();
    _suggest = CategorySuggestSession(
      categories: categories,
      records: [
        for (final entry in entries)
          if ((entry.categoryId ?? '').isNotEmpty)
            CategoryHistoryRecord(entry.title, entry.categoryId!),
      ],
      fallback: fallback,
      onUpdate: _applySuggest,
    );
    setState(() => _suggestOn = true);
    _suggest?.onTitle(_titleForSuggest());
  }

  String _titleForSuggest() {
    return mergeSuggestTitle(
      flutter: _pendingTitle.isNotEmpty ? _pendingTitle : _title.text,
      ime: _titleFocus.hasFocus ? focusedImeText() : null,
    );
  }

  void _feedTitle(String text) {
    _pendingTitle = text;
    _suggest?.onTitle(text);
  }

  void _onTitleChanged() {
    _feedTitle(_titleForSuggest());
  }

  void _applySuggest(EventCategory? category, {required bool loading}) {
    if (!mounted) return;
    setState(() {
      _suggesting = loading;
      if (category == null) return;
      _categoryId = category.id;
      _categoryName = category.name;
      _categoryColor = category.color;
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
    _suggest?.dispose();
    _title.removeListener(_onTitleChanged);
    _titleFocus.dispose();
    _amountFocus.dispose();
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _formatAmount(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = digits.isEmpty
        ? ''
        : LedgerEntry.formatWon(int.parse(digits));
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
    final wasWage = _isWage;
    setState(() {
      _kind = kind;
      if (kind == LedgerKind.hourly || kind == LedgerKind.salary) {
        _wageKind = kind;
      }
      if (kind == LedgerKind.hourly) {
        _salary = _salary.copyWith(wageType: SalaryWageType.hourly);
      } else if (kind == LedgerKind.salary) {
        _salary = _salary.copyWith(
          wageType: SalaryWageType.monthly,
          cycle: SalaryPayCycle.monthly,
        );
      }
    });
    if (_isWage) {
      _salaryAnimation.forward();
    } else if (wasWage) {
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
      await Future.wait([
        _kindAnimation.reverse(),
        if (_isWage) _salaryAnimation.reverse(),
      ]);
    } else {
      setState(() => _kindOpen = true);
      await Future.wait([
        _kindAnimation.forward(),
        if (_isWage) _salaryAnimation.forward(),
      ]);
    }
    if (!mounted) return;
    _kindToggling = false;
  }

  String _kindLabel(LedgerKind kind) {
    return switch (kind) {
      LedgerKind.expense => AppStrings.ledgerExpense,
      LedgerKind.consumption => AppStrings.ledgerConsumption,
      LedgerKind.hourly => AppStrings.ledgerHourly,
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

  Future<void> _pickCategory() async {
    _titleFocus.unfocus();
    _amountFocus.unfocus();
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
      kind: CategoryKind.ledger,
    );
    if (picked == null || !mounted) return;
    _suggest?.userPicked();
    setState(() {
      _suggesting = false;
      _categoryId = picked.id;
      _categoryName = picked.name;
      _categoryColor = picked.color;
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
      _onSalaryChanged(
        _salary.copyWith(clearTime: true, breakMinutes: 0),
        fromTime: true,
      );
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
    if (_isHourly) {
      final salary = _salaryDetails;
      final result = LedgerSalaryCalc.compute(salary);
      final missingTime =
          salary.startMinutes == null || salary.endMinutes == null;
      if (title.isEmpty ||
          result.net <= 0 ||
          !_hasCategory ||
          salary.hourlyWage <= 0 ||
          missingTime) {
        await showMissingFieldsDialog(
          context,
          body: AppStrings.missingLedgerSalaryBody,
        );
        return;
      }
      await _persist(title: title, amount: result.net, salary: salary);
      return;
    }
    if (title.isEmpty || _amountValue <= 0 || !_hasCategory) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.missingLedgerBody,
      );
      return;
    }
    await _persist(
      title: title,
      amount: _amountValue,
      salary: _isSalary ? _salaryDetails : null,
    );
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
        salary: _isWage ? salary : null,
        categoryId: _categoryId,
        categoryName: _categoryName ?? '',
        categoryColor: _categoryColor ?? 0,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AccentSelectionTheme(
      color: _accent,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      clipBehavior: PcLayout.isPc ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: colors.tint(_accent, 0.14),
        borderRadius: PcLayout.sheetRadius(),
        boxShadow: PcLayout.sheetLift(),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, _isWage ? 24 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventTitleField(
            controller: _title,
            focusNode: _titleFocus,
            autofocus: false,
            hintText: _isWage
                ? AppStrings.ledgerWorkplaceHint
                : AppStrings.ledgerTitleHint,
            onChanged: _feedTitle,
          ),
          const SizedBox(height: 6),
          _AmountField(
            controller: _amount,
            focusNode: _amountFocus,
            hintText: _isHourly
                ? AppStrings.ledgerHourlyHint
                : _isSalary
                ? AppStrings.ledgerMonthlyHint
                : AppStrings.ledgerAmountHint,
            suffixText: _isHourly
                ? '${AppStrings.ledgerAmountSuffix} (${AppStrings.ledgerHourly})'
                : _isSalary
                ? '${AppStrings.ledgerAmountSuffix} (${AppStrings.ledgerSalary})'
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
                      AiCategoryChip(
                        name: _categoryName ?? AppStrings.categoryAction,
                        color: _hasCategory
                            ? _accent
                            : AppColors.of(context).muted,
                        selected: _hasCategory,
                        active: _suggestOn,
                        loading: _suggesting,
                        onPressed: _pickCategory,
                      ),
                      const SizedBox(width: 4),
                      EventActionIcon(
                        label: AppStrings.longGoalKindAction,
                        text: _kindLabel(_kind),
                        color: _accent,
                        selected: _kindOpen,
                        onPressed: _toggleKind,
                        child: AppAssetImage(
                          asset: _kindOpen
                              ? AppIcons.wallet
                              : AppIcons.walletOutlined,
                          width: 20,
                          height: 20,
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
                        LedgerKind.hourly,
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
                    ignoring: !_isWage || !_kindOpen,
                    child: LedgerSalaryFields(
                      details: _salaryDetails,
                      result: _salaryResult,
                      accent: _accent,
                      onChanged: _onSalaryChanged,
                      onPickTime: _pickTime,
                      payCycleOnly: _wageKind == LedgerKind.salary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.suffixText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String suffixText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.of(context);
    final colors = AppColors.of(context);
    final style = TextStyle(
      fontFamily: font,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      letterSpacing: 0,
      color: colors.secondary,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
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
                        child: Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(suffixText, style: style),
                        ),
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
  return date.add(Duration(days: weekday - date.weekday));
}

DateTime _dateWithMonthDay(DateTime date, int day) {
  final last = DateTime(date.year, date.month + 1, 0).day;
  final resolved = day <= 0 ? last : day.clamp(1, last);
  return DateTime(date.year, date.month, resolved);
}

DateTime _dateWithMonthWeekday(
  DateTime date,
  SalaryMonthWeek week,
  int weekday,
) {
  return SalaryMonthDate.weekdayInMonth(
    year: date.year,
    month: date.month,
    weekday: weekday,
    week: week,
  );
}
