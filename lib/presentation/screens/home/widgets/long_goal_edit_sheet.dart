import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/long_goal.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_memo_field.dart';
import 'package:pluto/presentation/widgets/sliding_kind_bar.dart';

Future<bool> showLongGoalEditSheet(
  BuildContext context, {
  LongGoal? initial,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => LongGoalEditSheet(initial: initial),
  );
  return saved == true;
}

class LongGoalEditSheet extends StatefulWidget {
  const LongGoalEditSheet({super.key, this.initial});

  final LongGoal? initial;

  @override
  State<LongGoalEditSheet> createState() => _LongGoalEditSheetState();
}

class _LongGoalEditSheetState extends State<LongGoalEditSheet>
    with TickerProviderStateMixin {
  late final PlainTextEditingController _title;
  late final PlainTextEditingController _target;
  late final PlainTextEditingController _unit;
  late final PlainTextEditingController _memo;
  final _titleFocus = FocusNode();
  final _memoFocus = FocusNode();
  late final AnimationController _memoAnimation;
  late final CurvedAnimation _memoFade;
  late final AnimationController _kindAnimation;
  late final CurvedAnimation _kindFade;
  late int _color;
  late LongGoalKind _kind;
  String? _categoryId;
  String? _categoryName;
  var _saving = false;
  var _filled = false;
  var _memoOpen = false;
  var _memoToggling = false;
  var _kindOpen = true;
  var _kindToggling = false;
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = PlainTextEditingController(text: initial?.title ?? '');
    _target = PlainTextEditingController(
      text: initial == null ? '' : LongGoal.formatNumber(initial.target),
    );
    _unit = PlainTextEditingController(
      text: initial?.unit ?? LongGoalKind.daily.defaultUnit,
    );
    _memo = PlainTextEditingController(text: initial?.memo ?? '');
    _color = initial?.color ?? 0xFF22C55E;
    _kind = initial?.kind ?? LongGoalKind.daily;
    _categoryId = initial?.categoryId;
    _memoOpen = initial?.memo.trim().isNotEmpty ?? false;
    _memoAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: _memoOpen ? 1 : 0,
    );
    _memoFade = CurvedAnimation(
      parent: _memoAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _kindAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _kindFade = CurvedAnimation(
      parent: _kindAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    _fillCategory();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _kindFade.dispose();
    _kindAnimation.dispose();
    _memoFade.dispose();
    _memoAnimation.dispose();
    _titleFocus.dispose();
    _memoFocus.dispose();
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    _memo.dispose();
    super.dispose();
  }

  String get _kindHint {
    return switch (_kind) {
      LongGoalKind.measure => AppStrings.longGoalKindMeasureHint,
      LongGoalKind.sum => AppStrings.longGoalKindSumHint,
      LongGoalKind.daily => AppStrings.longGoalKindDailyHint,
      LongGoalKind.streak => AppStrings.longGoalKindStreakHint,
    };
  }

  bool get _hasCategory =>
      _categoryId != null && (_categoryName?.trim().isNotEmpty ?? false);

  Future<void> _fillCategory() async {
    final scope = AppScope.of(context);
    final categories = await scope.getEventCategories();
    if (!mounted) return;

    if (widget.initial != null) {
      final id = widget.initial!.categoryId;
      if (id == null) return;
      for (final category in categories) {
        if (category.id != id) continue;
        setState(() {
          _categoryId = category.id;
          _categoryName = category.name;
          _color = category.color;
        });
        return;
      }
      return;
    }

    EventCategory? selected;
    for (final goal in scope.longGoalStore.goals.reversed) {
      final id = goal.categoryId;
      if (id == null) continue;
      for (final category in categories) {
        if (category.id != id) continue;
        selected = category;
        break;
      }
      if (selected != null) break;
    }
    if (selected == null) {
      for (final category in categories) {
        if (category.id != 'exercise') continue;
        selected = category;
        break;
      }
    }
    selected ??= categories.isNotEmpty
        ? categories.first
        : EventCategory.presets[1];

    setState(() {
      _categoryId = selected!.id;
      _categoryName = selected.name;
      _color = selected.color;
    });
  }

  Future<void> _pickCategory() async {
    _titleFocus.unfocus();
    _memoFocus.unfocus();
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _categoryId = picked.id;
      _categoryName = picked.name;
      _color = picked.color;
    });
  }

  Future<void> _toggleMemo() async {
    if (_memoToggling) return;
    _memoToggling = true;
    if (_memoOpen) {
      _titleFocus.requestFocus();
      setState(() => _memoOpen = false);
      await _memoAnimation.reverse();
    } else {
      setState(() => _memoOpen = true);
      await _memoAnimation.forward();
      if (!mounted) return;
      _memoFocus.requestFocus();
    }
    if (!mounted) return;
    _memoToggling = false;
  }

  Future<void> _toggleKind() async {
    if (_kindToggling) return;
    _kindToggling = true;
    _titleFocus.unfocus();
    _memoFocus.unfocus();
    if (_kindOpen) {
      _hintTimer?.cancel();
      setState(() {
        _kindOpen = false;
        _hintVisible = false;
      });
      await _kindAnimation.reverse();
    } else {
      setState(() => _kindOpen = true);
      await _kindAnimation.forward();
    }
    if (!mounted) return;
    _kindToggling = false;
  }

  void _setKind(LongGoalKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      final unit = _unit.text.trim();
      if (unit.isEmpty || unit == '회' || unit == '일') {
        _unit.text = kind.defaultUnit;
      }
    });
    _showKindHint();
  }

  void _showKindHint() {
    if (!_kindOpen) return;
    _hintTimer?.cancel();
    setState(() => _hintVisible = true);
    _hintTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  double? _parse(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.longGoalMissingName,
      );
      return;
    }
    final target = _parse(_target.text);
    if (target == null || target <= 0) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.longGoalMissingTarget,
      );
      return;
    }
    if (!_hasCategory) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.longGoalMissingCategory,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final initial = widget.initial;
    final goal = LongGoal(
      id: initial?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      color: _color,
      kind: _kind,
      target: target,
      unit: _unit.text.trim(),
      memo: _memo.text.trim(),
      categoryId: _categoryId,
      sortOrder: initial?.sortOrder ?? DateTime.now().millisecondsSinceEpoch,
      startedAt: initial?.startedAt.isNotEmpty == true
          ? initial!.startedAt
          : LongGoal.dateStamp(
              initial?.startedDay(DateTime.now()) ?? DateTime.now(),
            ),
    );
    await AppScope.of(context).longGoalStore.upsertGoal(goal);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null) return;
    final confirmed = await showDeleteEventDialog(
      context,
      title: initial.title,
      body: AppStrings.longGoalDeleteBody,
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).longGoalStore.deleteGoal(initial.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  InputDecoration _fieldDecoration(
    AppColors colors,
    String? font,
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: font,
        color: colors.hint,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      filled: true,
      fillColor: colors.card.withValues(alpha: 0.55),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = Color(_color);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final font = AppFonts.of(context);
    final fieldStyle = TextStyle(
      fontFamily: font,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colors.tint(accent),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                focusNode: _titleFocus,
                autofocus: widget.initial == null,
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  fontFamily: font,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.longGoalNameHint,
                  hintStyle: TextStyle(
                    fontFamily: font,
                    color: colors.hint,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _memoFade,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _memoFade,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: IgnorePointer(
                        ignoring: !_memoOpen,
                        child: EventMemoField(
                          controller: _memo,
                          focusNode: _memoFocus,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  EventCategoryChip(
                    name: _categoryName ?? AppStrings.categoryAction,
                    color: _hasCategory ? accent : colors.muted,
                    selected: _hasCategory,
                    onPressed: _pickCategory,
                  ),
                  const SizedBox(width: 4),
                  EventActionIcon(
                    label: AppStrings.longGoalKindAction,
                    text: _kindLabel(_kind),
                    color: accent,
                    selected: _kindOpen,
                    size: 14,
                    onPressed: _toggleKind,
                    child: Image.asset(
                      AppIcons.longGoalKind(_kind, filled: _kindOpen),
                      width: 14,
                      height: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  EventActionIcon(
                    label: AppStrings.memoAction,
                    color: accent,
                    selected: _memoOpen,
                    onPressed: _toggleMemo,
                    child: Image.asset(
                      _memoOpen ? AppIcons.memo : AppIcons.memoOutlined,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 12),
                  TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: ColorTween(end: accent),
                    builder: (context, color, child) {
                      return SaveCompanyButton(
                        onPressed: _saving ? () {} : _save,
                        color: color ?? accent,
                      );
                    },
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SlidingKindBar(
                                  values: LongGoalKind.values,
                                  selected: _kind,
                                  labelOf: _kindLabel,
                                  accent: accent,
                                  onChanged: _setKind,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _target,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9.,]'),
                                          ),
                                        ],
                                        textInputAction: TextInputAction.next,
                                        style: fieldStyle,
                                        decoration: _fieldDecoration(
                                          colors,
                                          font,
                                          AppStrings.longGoalTargetHint,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 88,
                                      child: TextField(
                                        controller: _unit,
                                        textInputAction: TextInputAction.done,
                                        style: fieldStyle,
                                        decoration: _fieldDecoration(
                                          colors,
                                          font,
                                          AppStrings.longGoalUnitHint,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 54,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: _hintVisible ? Curves.easeOut : Curves.easeIn,
                        opacity: _kindOpen && _hintVisible ? 1 : 0,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _KindHintToast(
                            key: ValueKey(_kind),
                            text: _kindHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.initial != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PressBounce(
                    onPressed: _delete,
                    pressedColor: Colors.transparent,
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        AppStrings.delete,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(LongGoalKind kind) {
    return switch (kind) {
      LongGoalKind.measure => AppStrings.longGoalKindMeasure,
      LongGoalKind.sum => AppStrings.longGoalKindSum,
      LongGoalKind.daily => AppStrings.longGoalKindDaily,
      LongGoalKind.streak => AppStrings.longGoalKindStreak,
    };
  }
}

class _KindHintToast extends StatelessWidget {
  const _KindHintToast({super.key, required this.text});

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
