import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/category_history.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/diary_photo_storage.dart';
import 'package:pluto/domain/entities/diary_cover.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/diary_cover_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/diary_cover_style.dart';
import 'package:pluto/presentation/screens/calendar/widgets/diary_photo_field.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:pluto/presentation/widgets/ai_category_chip.dart';
import 'package:pluto/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:pluto/presentation/widgets/category_suggest_session.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class DiaryForm extends StatefulWidget {
  const DiaryForm({super.key, required this.date, this.rangeEnd, this.initial});

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
  late DiaryCover _cover;
  var _saving = false;
  Animation<double>? _sheetAnimation;
  CategorySuggestSession? _suggest;
  var _suggestOn = false;
  var _suggesting = false;

  bool get _hasCategory =>
      _categoryId != null && (_categoryName?.trim().isNotEmpty ?? false);

  Color get _accent => Color(_categoryColor ?? EventCategory.fallback.color);

  bool get _isRange => _daysToSave().length >= 2;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = PlainTextEditingController(text: initial?.title ?? '');
    _title.addListener(_onTitleChanged);
    _body = PlainTextEditingController(text: initial?.body ?? '');
    final date = initial?.date ?? widget.date;
    _date = DateTime(date.year, date.month, date.day);
    _photoPath = initial?.photoPath;
    _photoFileName = initial?.photoFileName;
    final travel = EventCategory.presets.first;
    _categoryId = initial?.categoryId ?? travel.id;
    _categoryName = initial?.categoryName ?? travel.name;
    _categoryColor = initial?.categoryColor ?? travel.color;
    _cover = initial?.cover ?? DiaryCover.fallback;
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
      if (widget.initial == null) {
        if (animation == null || animation.isCompleted) {
          _titleFocus.requestFocus();
        } else {
          animation.addStatusListener(_onSheetOpened);
        }
      }
      _loadGroup();
      _loadLastDefaults();
    });
  }

  void _onSheetOpened(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    if (mounted && widget.initial == null) _titleFocus.requestFocus();
  }

  @override
  void dispose() {
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    _suggest?.dispose();
    _title.removeListener(_onTitleChanged);
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
    final days =
        diaries
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

  Future<void> _loadLastDefaults() async {
    if (widget.initial != null) return;
    final scope = AppScope.of(context);
    final diaries = await scope.getDiaries();
    final categories = await scope.getEventCategories();
    if (!mounted) return;

    EventCategory? last;
    var cover = DiaryCover.fallback;
    if (diaries.isNotEmpty) {
      final newest = diaries.reduce(
        (a, b) => a.id.compareTo(b.id) >= 0 ? a : b,
      );
      cover = newest.cover;
      for (final category in categories) {
        if (category.id == newest.categoryId) {
          last = category;
          break;
        }
      }
    }
    final EventCategory selected;
    if (last != null) {
      selected = last;
    } else {
      EventCategory? travel;
      final travelId = EventCategory.presets.first.id;
      for (final category in categories) {
        if (category.id == travelId) {
          travel = category;
          break;
        }
      }
      selected =
          travel ??
          (categories.isNotEmpty
              ? categories.first
              : EventCategory.presets.first);
    }

    final suggestOn = CategorySuggestSession.isOn(
      context,
      editing: widget.initial != null,
    );
    _suggest?.dispose();
    _suggest = suggestOn
        ? CategorySuggestSession(
            categories: categories,
            records: [
              for (final diary in diaries)
                if ((diary.categoryId ?? '').isNotEmpty)
                  CategoryHistoryRecord(diary.title, diary.categoryId!),
            ],
            onUpdate: _applySuggest,
          )
        : null;
    if (_categoryId == selected.id &&
        _categoryName == selected.name &&
        _categoryColor == selected.color &&
        _cover == cover &&
        _suggestOn == suggestOn) {
      if (suggestOn) _suggest?.onTitle(_title.text);
      return;
    }
    setState(() {
      _suggestOn = suggestOn;
      _categoryId = selected.id;
      _categoryName = selected.name;
      _categoryColor = selected.color;
      _cover = cover;
    });
    if (suggestOn) _suggest?.onTitle(_title.text);
  }

  void _onTitleChanged() {
    _suggest?.onTitle(_title.text);
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

  Future<void> _pickCategory() async {
    _titleFocus.unfocus();
    _bodyFocus.unfocus();
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
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

  Future<void> _pickCover() async {
    _titleFocus.unfocus();
    _bodyFocus.unfocus();
    final picked = await showDiaryCoverSheet(
      context,
      selected: _cover,
      color: _accent,
    );
    if (picked == null || !mounted) return;
    setState(() => _cover = picked);
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
    final days = _daysToSave();
    if (title.isEmpty || days.isEmpty || !_hasCategory) {
      await showMissingFieldsDialog(context, body: AppStrings.missingDiaryBody);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _persist(title: title, body: body, days: days);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persist({
    required String title,
    required String body,
    required List<DateTime> days,
  }) async {
    final scope = AppScope.of(context);
    final savedCategory = await scope.ensureCategory(
      CategoryKind.event,
      id: _categoryId,
      name: _categoryName!,
      color: _categoryColor!,
    );
    if (!mounted) return;
    _categoryId = savedCategory.id;
    _categoryName = savedCategory.name;
    _categoryColor = savedCategory.color;
    final initial = widget.initial;
    final previous = await scope.getDiaries();
    final editing = <DiaryEntry>[];
    if (initial != null) {
      final groupId = initial.groupId;
      if (groupId != null) {
        editing.addAll(previous.where((diary) => diary.groupId == groupId));
      } else {
        editing.add(initial);
      }
    }
    final writingDays = {for (final day in days) day};
    final idByDay = {for (final diary in editing) diary.day: diary.id};

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
          cover: _cover,
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
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final accent = _accent;
    final look = DiaryCoverLook.of(
      _cover,
      colors,
      Theme.of(context).brightness,
    );
    final rule = look.rule;
    return AccentSelectionTheme(
      color: accent,
      child: SizedBox(
      width: double.infinity,
      child: DiaryCoverPaper(
        look: look,
        elevation: PcLayout.isPc ? 0 : 12,
        radius: PcLayout.isPc ? 24 : 20,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, look.torn ? 28 : 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                focusNode: _titleFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _bodyFocus.requestFocus(),
                style: TextStyle(
                  fontFamily: font,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.3,
                  color: colors.text,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.diaryTitleHint,
                  hintStyle: TextStyle(
                    fontFamily: font,
                    color: colors.hint,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                ),
              ),
              ColoredBox(
                color: rule,
                child: const SizedBox(height: 1, width: double.infinity),
              ),
              const SizedBox(height: 12),
              DiaryPhotoField(
                path: _previewPath,
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
              const SizedBox(height: 12),
              _LinedDiaryBody(
                controller: _body,
                focusNode: _bodyFocus,
                cover: _cover,
                lineColor: rule,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AiCategoryChip(
                            name: _categoryName ?? AppStrings.categoryAction,
                            color: _hasCategory ? accent : colors.muted,
                            selected: _hasCategory,
                            active: _suggestOn,
                            loading: _suggesting,
                            onPressed: _pickCategory,
                          ),
                          const SizedBox(width: 4),
                          EventDateChip(
                            date: _date,
                            color: accent,
                            label: _isRange ? AppStrings.rangeDiaryLabel : null,
                            onPressed: _pickDate,
                          ),
                          const SizedBox(width: 4),
                          DiaryCoverChip(
                            color: accent,
                            name: DiaryCoverLook.label(_cover),
                            onPressed: _pickCover,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.initial != null) ...[
                    const SizedBox(width: 8),
                    _DeleteDiaryButton(onPressed: _saving ? null : _delete),
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
      ),
      ),
    );
  }
}

class _LinedDiaryBody extends StatelessWidget {
  const _LinedDiaryBody({
    required this.controller,
    required this.focusNode,
    required this.cover,
    required this.lineColor,
  });

  static const _line = 28.0;

  final TextEditingController controller;
  final FocusNode focusNode;
  final DiaryCover cover;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final closeOnDone = Theme.of(context).platform == TargetPlatform.iOS;
    return CustomPaint(
      painter: DiaryCoverPatternPainter(
        cover: cover,
        color: lineColor,
        lineHeight: _line,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        minLines: 4,
        maxLines: 12,
        keyboardType: closeOnDone
            ? TextInputType.text
            : TextInputType.multiline,
        textInputAction: closeOnDone
            ? TextInputAction.done
            : TextInputAction.newline,
        onSubmitted: closeOnDone ? (_) => focusNode.unfocus() : null,
        style: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: _line / 16,
          color: colors.text,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.diaryBodyHint,
          hintStyle: TextStyle(
            fontFamily: font,
            color: colors.hint,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: _line / 16,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 4),
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
              child: AppAssetImage(
                asset: AppIcons.trashCan,
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
