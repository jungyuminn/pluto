import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/data/datasources/diary_photo_storage.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/diary_photo_field.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_memo_field.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_title_field.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar.dart';

class DiaryForm extends StatefulWidget {
  const DiaryForm({
    super.key,
    required this.date,
    this.initial,
  });

  final DateTime date;
  final DiaryEntry? initial;

  @override
  State<DiaryForm> createState() => _DiaryFormState();
}

class _DiaryFormState extends State<DiaryForm> {
  late final PlainTextEditingController _title;
  late final PlainTextEditingController _body;
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  late DateTime _date;
  String? _photoPath;
  String? _photoFileName;
  String? _pickedSource;
  late String? _categoryId;
  String? _categoryName;
  int? _categoryColor;
  var _saving = false;
  Animation<double>? _sheetAnimation;

  bool get _hasCategory =>
      _categoryId != null && (_categoryName?.trim().isNotEmpty ?? false);

  Color get _accent => Color(_categoryColor ?? EventCategory.fallback.color);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = PlainTextEditingController(text: initial?.title ?? '');
    _body = PlainTextEditingController(text: initial?.body ?? '');
    final date = initial?.date ?? widget.date;
    _date = DateTime(date.year, date.month, date.day);
    _photoPath = initial?.photoPath;
    _photoFileName = initial?.photoFileName;
    final travel = EventCategory.presets.first;
    _categoryId = initial?.categoryId ?? travel.id;
    _categoryName = initial?.categoryName ?? travel.name;
    _categoryColor = initial?.categoryColor ?? travel.color;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sheetAnimation = ModalRoute.of(context)?.animation;
      final animation = _sheetAnimation;
      if (animation == null || animation.isCompleted) {
        _titleFocus.requestFocus();
      } else {
        animation.addStatusListener(_onSheetOpened);
      }
      _loadLastCategory();
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
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  String? get _previewPath => _pickedSource ?? _photoPath;

  Future<void> _loadLastCategory() async {
    if (widget.initial != null) return;
    final scope = AppScope.of(context);
    final diaries = await scope.getDiaries();
    final categories = await scope.getEventCategories();
    if (!mounted) return;

    EventCategory? last;
    if (diaries.isNotEmpty) {
      final newest = diaries.reduce(
        (a, b) => a.id.compareTo(b.id) >= 0 ? a : b,
      );
      for (final category in categories) {
        if (category.id == newest.categoryId) {
          last = category;
          break;
        }
      }
    }
    if (last == null) {
      final travelId = EventCategory.presets.first.id;
      for (final category in categories) {
        if (category.id == travelId) {
          last = category;
          break;
        }
      }
      last ??= categories.isNotEmpty
          ? categories.first
          : EventCategory.presets.first;
    }

    final selected = last!;
    if (_categoryId == selected.id &&
        _categoryName == selected.name &&
        _categoryColor == selected.color) {
      return;
    }
    setState(() {
      _categoryId = selected.id;
      _categoryName = selected.name;
      _categoryColor = selected.color;
    });
  }

  Future<void> _pickCategory() async {
    _titleFocus.unfocus();
    _bodyFocus.unfocus();
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _categoryId = picked.id;
      _categoryName = picked.name;
      _categoryColor = picked.color;
    });
  }

  Future<void> _pickDate() async {
    _titleFocus.unfocus();
    _bodyFocus.unfocus();
    final picked = await showAppCalendarSheet(
      context,
      date: _date,
      dates: [_date],
      mode: AppCalendarMode.single,
      color: _accent,
      showModes: false,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(
          picked.date.year,
          picked.date.month,
          picked.date.day,
        ));
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    final hasPhoto = (_pickedSource ?? _photoPath)?.isNotEmpty ?? false;
    if ((title.isEmpty && !hasPhoto) || !_hasCategory) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.missingDiaryBody,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final scope = AppScope.of(context);
    final initial = widget.initial;
    final id = initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    var photoPath = _photoPath;
    var photoFileName = _photoFileName;
    const storage = DiaryPhotoStorage();
    final picked = _pickedSource;
    if (picked != null) {
      photoPath = await storage.save(
        id: id,
        sourcePath: picked,
        fileName: _photoFileName ?? 'photo.jpg',
      );
      if (initial?.photoPath != null && initial!.photoPath != photoPath) {
        await storage.delete(initial.photoPath);
      }
    } else if (photoPath == null && initial?.photoPath != null) {
      await storage.delete(initial!.photoPath);
    }

    await scope.saveDiary(
      DiaryEntry(
        id: id,
        date: _date,
        title: title,
        body: body,
        photoPath: photoPath,
        photoFileName: photoFileName,
        categoryId: _categoryId,
        categoryName: _categoryName!,
        categoryColor: _categoryColor!,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.of(context).tint(accent),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventTitleField(
              controller: _title,
              focusNode: _titleFocus,
              autofocus: false,
              hintText: AppStrings.diaryTitleHint,
            ),
            const SizedBox(height: 12),
            DiaryPhotoField(
              path: _previewPath,
              accent: accent,
              onPicked: (file) {
                setState(() {
                  _pickedSource = file.path;
                  _photoFileName = file.name;
                });
              },
              onCleared: () {
                setState(() {
                  _pickedSource = null;
                  _photoPath = null;
                  _photoFileName = null;
                });
              },
            ),
            const SizedBox(height: 10),
            EventMemoField(
              controller: _body,
              focusNode: _bodyFocus,
              hintText: AppStrings.diaryBodyHint,
              minLines: 4,
              maxLines: 10,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        EventCategoryChip(
                          name: _categoryName ?? AppStrings.categoryAction,
                          color: _hasCategory
                              ? accent
                              : AppColors.of(context).muted,
                          selected: _hasCategory,
                          onPressed: _pickCategory,
                        ),
                        const SizedBox(width: 4),
                        EventDateChip(
                          date: _date,
                          color: accent,
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SaveCompanyButton(
                  onPressed: _saving ? () {} : _save,
                  color: accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
