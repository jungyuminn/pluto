import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';

Future<bool> showAddCategorySheet(
  BuildContext context, {
  EventCategory? initial,
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
    builder: (context) => AddCategorySheet(initial: initial),
  );
  return saved == true;
}

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key, this.initial});

  final EventCategory? initial;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  late final PlainTextEditingController _name;
  late int _color;
  var _saving = false;
  final _usedColors = <int>{};

  static const _colors = [
    0xFF3B82F6,
    0xFF0EA5E9,
    0xFF06B6D4,
    0xFF14B8A6,
    0xFF22C55E,
    0xFF84CC16,
    0xFFF59E0B,
    0xFFF97316,
    0xFFEF4444,
    0xFFE11D48,
    0xFFEC4899,
    0xFF8B5CF6,
    0xFF6366F1,
    0xFF64748B,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = PlainTextEditingController(text: initial?.name ?? '');
    _color = initial?.color ?? EventCategory.fallback.color;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsedColors());
  }

  Future<void> _loadUsedColors() async {
    final categories = await AppScope.of(context).getEventCategories();
    if (!mounted) return;
    final editingId = widget.initial?.id;
    setState(() {
      _usedColors
        ..clear()
        ..addAll([
          for (final category in categories)
            if (category.id != editingId) category.color,
        ]);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.missingCategoryBody,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final initial = widget.initial;
    final category = EventCategory(
      id: initial?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: _color,
    );
    final scope = AppScope.of(context);
    if (initial == null) {
      await scope.addEventCategory(category);
    } else {
      await scope.updateEventCategory(category);
      final events = await scope.getCalendarEvents();
      for (final event in events) {
        if (event.categoryId != category.id) continue;
        await scope.updateCalendarEvent.instance(
          event.copyWith(
            categoryName: category.name,
            categoryColor: category.color,
          ),
        );
      }
      final store = scope.longGoalStore;
      for (final goal in store.goals) {
        if (goal.categoryId != category.id) continue;
        await store.upsertGoal(goal.copyWith(color: category.color));
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = Color(_color);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colors.tint(accent),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.categoryNameHint,
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.of(context),
                    color: colors.hint,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final value in _colors)
                          PressBounce(
                            onPressed: () => setState(() => _color = value),
                            pressedScale: 0.9,
                            color: Colors.transparent,
                            pressedColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: Semantics(
                              selected: _color == value,
                              label: _usedColors.contains(value)
                                  ? AppStrings.categoryColorInUse
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(value),
                                  shape: BoxShape.circle,
                                  border: _color == value
                                      ? Border.all(color: colors.card, width: 3)
                                      : Border.all(
                                          color: Colors.transparent,
                                          width: 3,
                                        ),
                                  boxShadow: _color == value
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : const [],
                                ),
                                child: _usedColors.contains(value)
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
