import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/utils/category_history.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_time_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_time_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_memo_field.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_title_field.dart';
import 'package:pluto/presentation/widgets/ai_category_chip.dart';
import 'package:pluto/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:pluto/presentation/widgets/category_suggest_session.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class AddEventForm extends StatefulWidget {
  const AddEventForm({
    super.key,
    required this.date,
    this.rangeEnd,
    this.initial,
    this.someday = false,
  });

  final DateTime date;
  final DateTime? rangeEnd;
  final CalendarEvent? initial;
  final bool someday;

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm>
    with SingleTickerProviderStateMixin {
  late final PlainTextEditingController _title;
  late final PlainTextEditingController _memo;
  final _titleFocus = FocusNode();
  final _memoFocus = FocusNode();
  late final AnimationController _memoAnimation;
  late final CurvedAnimation _memoFade;
  late DateTime _date;
  var _dateMode = AppCalendarMode.single;
  var _dates = <DateTime>[];
  var _memoOpen = false;
  var _memoToggling = false;
  var _saving = false;
  late String? _categoryId;
  String? _categoryName;
  int? _categoryColor;
  int? _startMinutes;
  int? _endMinutes;
  Animation<double>? _sheetAnimation;
  CategorySuggestSession? _suggest;
  var _suggestOn = false;
  var _suggesting = false;

  bool get _isSomeday =>
      widget.someday || (widget.initial?.someday ?? false);

  bool get _hasCategory =>
      _categoryId != null && (_categoryName?.trim().isNotEmpty ?? false);

  Color get _accent => Color(_categoryColor ?? EventCategory.fallback.color);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = PlainTextEditingController(text: initial?.title ?? '');
    _memo = PlainTextEditingController(text: initial?.memo ?? '');
    final travel = EventCategory.presets.first;
    _categoryId = initial?.categoryId ?? travel.id;
    _categoryName = initial?.categoryName ?? travel.name;
    _categoryColor = initial?.categoryColor ?? travel.color;
    _startMinutes = (initial?.someday ?? false) ? null : initial?.startMinutes;
    _endMinutes = (initial?.someday ?? false) ? null : initial?.endMinutes;
    final date = initial?.date ?? widget.date;
    _date = DateTime(date.year, date.month, date.day);
    final rangeEnd = widget.rangeEnd;
    if (initial == null &&
        rangeEnd != null &&
        (rangeEnd.year != _date.year ||
            rangeEnd.month != _date.month ||
            rangeEnd.day != _date.day)) {
      final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
      final first = _date.isBefore(end) ? _date : end;
      final last = _date.isBefore(end) ? end : _date;
      _dateMode = AppCalendarMode.range;
      _dates = [first, last];
      _date = first;
    } else {
      _dates = [_date];
    }
    _title.addListener(_onTitleChanged);
    _memoOpen = initial?.memo.trim().isNotEmpty ?? false;
    _memoAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      value: _memoOpen ? 1 : 0,
    );
    _memoFade = CurvedAnimation(
      parent: _memoAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
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
      _loadLastCategory();
      if (!widget.someday && !(widget.initial?.someday ?? false)) {
        _loadGroup();
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
    _memoFade.dispose();
    _memoAnimation.dispose();
    _suggest?.dispose();
    _title.removeListener(_onTitleChanged);
    _titleFocus.dispose();
    _memoFocus.dispose();
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _loadLastCategory() async {
    if (widget.initial != null) return;
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final categories = await scope.getEventCategories();
    if (!mounted) return;

    EventCategory? last;
    if (events.isNotEmpty) {
      final newest = events.reduce(
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
    final suggestOn = CategorySuggestSession.isOn(
      context,
      editing: widget.initial != null,
    );
    _suggest?.dispose();
    _suggest = suggestOn
        ? CategorySuggestSession(
            categories: categories,
            records: [
              for (final event in events)
                if ((event.categoryId ?? '').isNotEmpty)
                  CategoryHistoryRecord(event.title, event.categoryId!),
            ],
            fallback: selected,
            onUpdate: _applySuggest,
          )
        : null;
    if (_categoryId == selected.id &&
        _categoryName == selected.name &&
        _categoryColor == selected.color &&
        _suggestOn == suggestOn) {
      if (suggestOn) _suggest?.onTitle(_title.text);
      return;
    }
    setState(() {
      _suggestOn = suggestOn;
      _categoryId = selected.id;
      _categoryName = selected.name;
      _categoryColor = selected.color;
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

  Future<void> _loadGroup() async {
    final groupId = widget.initial?.groupId;
    if (groupId == null) return;
    final events = await AppScope.of(context).getCalendarEvents();
    final days = events
        .where((event) => event.groupId == groupId)
        .map((event) => DateTime(event.date.year, event.date.month, event.date.day))
        .toList()
      ..sort((a, b) => a.compareTo(b));
    if (!mounted || days.length < 2) return;
    setState(() {
      _dateMode = AppCalendarMode.range;
      _dates = [days.first, days.last];
      _date = days.first;
    });
  }

  bool get _isRange =>
      _dateMode == AppCalendarMode.range && _dates.length >= 2;

  bool get _isMultiple =>
      _dateMode == AppCalendarMode.multiple && _dates.length >= 2;

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
    if (_isRange) return _daysOn(_dates.first, _dates.last);
    if (_dateMode == AppCalendarMode.multiple) {
      final days = {
        for (final date in _dates) _dateOnly(date),
      }.toList()
        ..sort((a, b) => a.compareTo(b));
      if (days.isNotEmpty) return days;
    }
    if (_dateMode == AppCalendarMode.repeat && _dates.isNotEmpty) {
      return [..._dates]..sort((a, b) => a.compareTo(b));
    }
    return [_date];
  }

  Future<void> _pickCategory() async {
    _titleFocus.unfocus();
    _memoFocus.unfocus();
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

  Future<void> _pickDate() async {
    final picked = await showAppCalendarSheet(
      context,
      date: _date,
      dates: _dates,
      mode: _dateMode,
      color: _accent,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateMode = picked.mode;
      _dates = picked.dates;
      _date = picked.date;
    });
  }

  Future<void> _pickTime() async {
    _titleFocus.unfocus();
    _memoFocus.unfocus();
    final picked = await showEventTimeSheet(
      context,
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
      color: _accent,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startMinutes = picked.startMinutes;
      _endMinutes = picked.endMinutes;
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

  Future<void> _save() async {
    final title = _title.text.trim();
    final days = _daysToSave();
    if (title.isEmpty || days.isEmpty || !_hasCategory) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.missingEventBody,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final initial = widget.initial;
    final memo = _memo.text.trim();
    final categoryId = _categoryId;
    final categoryName = _categoryName!;
    final categoryColor = _categoryColor!;
    final scope = AppScope.of(context);
    final previous = await scope.getCalendarEvents();
    final initialRepeatId = initial?.repeatId;
    final editingInPlace = initial != null &&
        initial.groupId == null &&
        !_isRange &&
        !_isMultiple &&
        _dateMode != AppCalendarMode.repeat &&
        days.length == 1;
    if (editingInPlace) {
      await scope.updateCalendarEvent.instance(
        initial.copyWith(
          title: title,
          date: days.first,
          memo: memo,
          categoryId: categoryId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          startMinutes: _isSomeday ? null : _startMinutes,
          endMinutes: _isSomeday ? null : _endMinutes,
          someday: _isSomeday,
          clearTime: _isSomeday ||
              _startMinutes == null ||
              _endMinutes == null,
        ),
      );
      if (initialRepeatId != null && title != initial.title) {
        await scope.updateCalendarEvent.repeatTitles(initialRepeatId, title);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    final completedByDay = {
      for (final event in previous)
        if (initial != null &&
            (event.id == initial.id ||
                (initial.groupId != null && event.groupId == initial.groupId) ||
                (initialRepeatId != null && event.repeatId == initialRepeatId)))
          DateTime(event.date.year, event.date.month, event.date.day):
              event.completed,
    };
    if (initial != null) {
      if (initialRepeatId != null) {
        await scope.deleteCalendarEvent.allRepeats(initialRepeatId);
      } else {
        await scope.deleteCalendarEvent(initial);
      }
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    final groupId = _isRange ? (initial?.groupId ?? '$now') : null;
    final repeatId = _dateMode == AppCalendarMode.repeat
        ? (initialRepeatId ?? '$now')
        : null;
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      await scope.addCalendarEvent(
        CalendarEvent(
          id: '${now}_$i',
          title: title,
          date: day,
          memo: memo,
          categoryId: categoryId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          completed: completedByDay[day] ?? false,
          groupId: groupId,
          repeatId: repeatId,
          sortOrder: i == 0 && initial != null ? initial.sortOrder : now + i,
          startMinutes: _isSomeday ? null : _startMinutes,
          endMinutes: _isSomeday ? null : _endMinutes,
          someday: _isSomeday,
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AccentSelectionTheme(
      color: _accent,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.of(context).tint(_accent, 0.14),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventTitleField(
              controller: _title,
              focusNode: _titleFocus,
              autofocus: false,
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
            const SizedBox(height: 5),
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
                        if (!_isSomeday) ...[
                          const SizedBox(width: 4),
                          EventDateChip(
                            date: _date,
                            color: _accent,
                            label: _isRange
                                ? AppStrings.rangeEventLabel
                                : _isMultiple
                                ? AppStrings.multipleEventLabel
                                : _dateMode == AppCalendarMode.repeat ||
                                      widget.initial?.repeatId != null
                                ? AppStrings.repeatEventLabel
                                : null,
                            onPressed: _pickDate,
                          ),
                          const SizedBox(width: 4),
                          EventTimeChip(
                            color: _accent,
                            startMinutes: _startMinutes,
                            endMinutes: _endMinutes,
                            onPressed: _pickTime,
                          ),
                        ],
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.memoAction,
                          color: _accent,
                          selected: _memoOpen,
                          onPressed: _toggleMemo,
                          child: AppAssetImage(
                            asset: _memoOpen
                                ? AppIcons.memo
                                : AppIcons.memoOutlined,
                            width: 20,
                            height: 20,
                          ),
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
          ],
        ),
      ),
      ),
    );
  }
}
