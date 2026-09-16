import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/data/datasources/last_category_color_preference.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_color_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> showAddCategorySheet(
  BuildContext context, {
  EventCategory? initial,
  CategoryKind kind = CategoryKind.event,
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
    builder: (context) => AddCategorySheet(initial: initial, kind: kind),
  );
  return saved == true;
}

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({
    super.key,
    this.initial,
    this.kind = CategoryKind.event,
  });

  final EventCategory? initial;
  final CategoryKind kind;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  late final PlainTextEditingController _name;
  late int _color;
  var _saving = false;
  final _usedColors = <int>{};

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = PlainTextEditingController(text: initial?.name ?? '');
    _color = initial?.color ?? EventCategory.fallback.color;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final categories = await AppScope.of(context).fetchCategories(widget.kind);
    var color = _color;
    if (widget.initial == null) {
      final prefs = await SharedPreferences.getInstance();
      final stored = LastCategoryColorPreference(prefs: prefs).color;
      if (stored != null && EventCategory.palette.contains(stored)) {
        color = stored;
      }
    }
    if (!mounted) return;
    final editingId = widget.initial?.id;
    setState(() {
      _color = color;
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
      await scope.addCategory(widget.kind, category);
      final prefs = await SharedPreferences.getInstance();
      await LastCategoryColorPreference(prefs: prefs).setColor(_color);
    } else {
      await scope.saveCategory(widget.kind, category);
      if (widget.kind == CategoryKind.event) {
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
      } else if (widget.kind == CategoryKind.company) {
        final jobs = await scope.getJobApplications();
        for (final job in jobs) {
          if (job.categoryId != category.id) continue;
          await scope.updateJobApplication(
            job.copyWith(
              categoryName: category.name,
              categoryColor: category.color,
            ),
          );
        }
      } else if (widget.kind == CategoryKind.license) {
        final licenses = await scope.getLicenses();
        for (final license in licenses) {
          if (license.categoryId != category.id) continue;
          await scope.updateLicense(
            license.copyWith(
              categoryName: category.name,
              categoryColor: category.color,
            ),
          );
        }
      } else {
        final ledgers = await scope.getLedgers();
        for (final entry in ledgers) {
          if (entry.categoryId != category.id) continue;
          await scope.saveLedger(
            entry.copyWith(
              categoryName: category.name,
              categoryColor: category.color,
            ),
          );
        }
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

    return AccentSelectionTheme(
      color: accent,
      child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colors.tint(accent, 0.14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
              const SizedBox(height: 16),
              CategoryColorPicker(
                selected: _color,
                usedColors: _usedColors,
                onSelected: (value) => setState(() => _color = value),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
