import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/diary_photo_storage.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
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
    this.rangeEnd,
    this.initial,
  });

  final DateTime date;
  final DateTime? rangeEnd;
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
  var _dates = <DateTime>[];
  var _dateMode = AppCalendarMode.single;
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

  bool get _isRange => _daysToSave().length >= 2;

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
    final rangeEnd = widget.rangeEnd;
    if (rangeEnd != null) {
      final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
      if (end != _date) {
        final first = _date.isBefore(end) ? _date : end;
        final last = _date.isBefore(end) ? end : _date;
        _dates = [first, last];
        _date = first;
        _dateMode = AppCalendarMode.range;
      } else {
        _dates = [_date];
      }
    } else {
      _dates = [_date];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sheetAnimation = ModalRoute.of(context)?.animation;
      final animation = _sheetAnimation;
      if (animation == null || animation.isCompleted) {
        _titleFocus.requestFocus();
      } else {
        animation.addStatusListener(_onSheetOpened);
      }
      _loadGroup();
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

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<DateTime> _daysOn(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(last)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  List<DateTime> _daysToSave() {
    if (_dates.length >= 2) {
      final first = _dateOnly(_dates.first);
      final last = _dateOnly(_dates.last);
      final start = first.isBefore(last) ? first : last;
      final end = first.isBefore(last) ? last : first;
      return _daysOn(start, end);
    }
    return [_date];
  }

  Future<void> _loadGroup() async {
    final groupId = widget.initial?.groupId;
    if (groupId == null) return;
    final diaries = await AppScope.of(context).getDiaries();
    final days = diaries
        .where((diary) => diary.groupId == groupId)
        .map((diary) => diary.day)
        .toList()
      ..sort((a, b) => a.compareTo(b));
    if (!mounted || days.length < 2) return;
    setState(() {
      _dates = [days.first, days.last];
      _date = days.first;
      _dateMode = AppCalendarMode.range;
    });
  }

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

    final selected = last ?? EventCategory.presets.first;
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
      dates: _dates,
      mode: _dateMode,
      color: _accent,
      modes: const [AppCalendarMode.single, AppCalendarMode.range],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateMode = picked.mode == AppCalendarMode.range
          ? AppCalendarMode.range
          : AppCalendarMode.single;
      _dates = picked.dates;
      _date = picked.date;
    });
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
    final days = _daysToSave();
    if (days.isEmpty) return;
    if (_saving) return;
    setState(() => _saving = true);

    final scope = AppScope.of(context);
    final initial = widget.initial;
    final previous = await scope.getDiaries();
    final editing = <DiaryEntry>[];
    if (initial != null) {
      final groupId = initial.groupId;
      if (groupId != null) {
        editing.addAll(
          previous.where((diary) => diary.groupId == groupId),
        );
      } else {
        editing.add(initial);
      }
    }
    final writingDays = {for (final day in days) day};
    final idByDay = {
      for (final diary in editing) diary.day: diary.id,
    };

    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final groupId = days.length >= 2 ? (initial?.groupId ?? now) : null;
    final photoId = groupId ?? (editing.isNotEmpty ? editing.first.id : now);
    var photoPath = _photoPath;
    var photoFileName = _photoFileName;
    const storage = DiaryPhotoStorage();
    final picked = _pickedSource;
    if (picked != null) {
      photoPath = await storage.save(
        id: photoId,
        sourcePath: picked,
        fileName: _photoFileName ?? 'photo.jpg',
      );
    }

    for (final item in editing) {
      if (!writingDays.contains(item.day)) {
        await scope.deleteDiary(item.id);
      }
    }

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      await scope.saveDiary(
        DiaryEntry(
          id: idByDay[day] ?? '${now}_$i',
          date: day,
          title: title,
          body: body,
          photoPath: photoPath,
          photoFileName: photoFileName,
          categoryId: _categoryId,
          categoryName: _categoryName!,
          categoryColor: _categoryColor!,
          groupId: groupId,
        ),
      );
    }

    final remaining = await scope.getDiaries();
    final used = {
      for (final diary in remaining)
        if (diary.photoPath != null && diary.photoPath!.isNotEmpty)
          diary.photoPath!,
    };
    final candidates = {
      for (final item in editing)
        if (item.photoPath != null && item.photoPath!.isNotEmpty)
          item.photoPath!,
      if (initial?.photoPath != null && initial!.photoPath!.isNotEmpty)
        initial.photoPath!,
    };
    for (final path in candidates) {
      if (!used.contains(path)) await storage.delete(path);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null || _saving) return;
    final title = _title.text.trim().isEmpty
        ? AppStrings.diaryFallback
        : _title.text.trim();
    final confirmed = await showDeleteEventDialog(
      context,
      title: title,
      body: AppStrings.deleteDiaryBody,
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final previous = await scope.getDiaries();
    final groupId = initial.groupId;
    final targets = groupId == null
        ? [initial]
        : [
            for (final diary in previous)
              if (diary.groupId == groupId) diary,
          ];
    final photos = <String>{};
    for (final diary in targets) {
      final path = diary.photoPath;
      if (path != null && path.isNotEmpty) photos.add(path);
      await scope.deleteDiary(diary.id);
    }
    const storage = DiaryPhotoStorage();
    final remaining = await scope.getDiaries();
    final used = {
      for (final diary in remaining)
        if (diary.photoPath != null && diary.photoPath!.isNotEmpty)
          diary.photoPath!,
    };
    for (final path in photos) {
      if (!used.contains(path)) await storage.delete(path);
    }
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
                          label: _isRange ? AppStrings.rangeDiaryLabel : null,
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.initial != null) ...[
                  const SizedBox(width: 8),
                  _DeleteDiaryButton(
                    onPressed: _saving ? null : _delete,
                  ),
                ],
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

class _DeleteDiaryButton extends StatelessWidget {
  const _DeleteDiaryButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: SaveCompanyButton.size,
          height: SaveCompanyButton.size,
          child: Center(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(colors.danger, BlendMode.srcIn),
              child: Image.asset(
                AppIcons.trashCan,
                width: 22,
                height: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
