import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/utils/category_history.dart';
import 'package:pluto/core/utils/focused_ime_text.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/title_time_parse.dart';
import 'package:pluto/data/datasources/last_event_category_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/todo_request.dart';
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
import 'package:pluto/presentation/screens/friends/friends_toast.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:pluto/presentation/tutorial/tutorial_hint.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddEventForm extends StatefulWidget {
  const AddEventForm({
    super.key,
    required this.date,
    this.rangeEnd,
    this.initial,
    this.someday = false,
    this.shareWith,
  });

  final DateTime date;
  final DateTime? rangeEnd;
  final CalendarEvent? initial;
  final bool someday;
  final FriendProfile? shareWith;

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
  var _pendingTitle = '';
  late bool _isSomeday;

  bool get _hasCategory =>
      _categoryId != null && (_categoryName?.trim().isNotEmpty ?? false);

  bool get _shared => widget.initial?.isShared == true;

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
    _isSomeday = widget.shareWith == null &&
        (widget.someday || (initial?.someday ?? false));
    _startMinutes = _isSomeday ? null : initial?.startMinutes;
    _endMinutes = _isSomeday ? null : initial?.endMinutes;
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
    _titleFocus.addListener(_onTitleFocus);
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
      _beginSuggest();
      _loadLastCategory();
      if (!widget.someday && !(widget.initial?.someday ?? false)) {
        if (widget.initial?.isShared == true) {
          _loadSharedDates();
        } else {
          _loadGroup();
        }
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
    _titleFocus.removeListener(_onTitleFocus);
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
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    EventCategory? last = LastEventCategoryPreference.resolve(
      events: events,
      categories: categories,
      storedId: LastEventCategoryPreference(prefs: prefs).id,
    );
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
      if (suggestOn) _suggest?.onTitle(_titleForSuggest());
      return;
    }
    setState(() {
      _suggestOn = suggestOn;
      _categoryId = selected.id;
      _categoryName = selected.name;
      _categoryColor = selected.color;
    });
    if (suggestOn) _suggest?.onTitle(_titleForSuggest());
  }

  void _beginSuggest() {
    if (widget.initial != null) return;
    if (_suggest != null) return;
    if (!CategorySuggestSession.isOn(context, editing: false)) return;
    var fallback = EventCategory.presets.first;
    for (final category in EventCategory.presets) {
      if (category.id == _categoryId) {
        fallback = category;
        break;
      }
    }
    _suggest = CategorySuggestSession(
      categories: EventCategory.presets,
      records: const [],
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
    _syncTitleTimeHighlight();
    TutorialController.find(context)
        ?.noteAddTitle(_title.text.trim().isNotEmpty);
  }

  void _syncTitleTimeHighlight({bool force = false}) {
    if (!mounted) return;
    TextRange? range;
    if (!_isSomeday &&
        AppScope.of(context).dayEventsViewPreference.parseTitleTime) {
      final match = TitleTimeParse.match(_title.text);
      if (match != null) {
        range = TextRange(start: match.start, end: match.end);
      }
    }
    _title.setHighlight(range, force: force);
  }

  void _onTitleFocus() {
    if (_titleFocus.hasFocus) return;
    _syncTitleTimeHighlight(force: true);
  }

  void _applyTitleTime() {
    if (_isSomeday) return;
    if (!AppScope.of(context).dayEventsViewPreference.parseTitleTime) return;
    final parsed = TitleTimeParse.of(_title.text);
    if (parsed == null) return;
    _title.value = TextEditingValue(
      text: parsed.title,
      selection: TextSelection.collapsed(offset: parsed.title.length),
    );
    final end = _endMinutes;
    setState(() {
      _startMinutes = parsed.startMinutes;
      if (end != null && end <= parsed.startMinutes) _endMinutes = null;
    });
    _syncTitleTimeHighlight();
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
    _syncTitleTimeHighlight(force: true);
  }

  Future<void> _loadSharedDates() async {
    final initial = widget.initial;
    final sharedId = initial?.sharedId?.trim() ?? '';
    if (sharedId.isEmpty) return;
    final events = await AppScope.of(context).getCalendarEvents();
    final days = [
      for (final event in events)
        if ((event.sharedId ?? '') == sharedId)
          DateTime(event.date.year, event.date.month, event.date.day),
    ]..sort((a, b) => a.compareTo(b));
    if (!mounted || days.isEmpty) return;
    setState(() {
      if (initial!.isRange && days.length >= 2) {
        _dateMode = AppCalendarMode.range;
        _dates = [days.first, days.last];
      } else if (initial.isRepeat) {
        _dateMode = AppCalendarMode.repeat;
        _dates = days;
      } else if (days.length >= 2) {
        _dateMode = AppCalendarMode.multiple;
        _dates = days;
      } else {
        _dateMode = AppCalendarMode.single;
        _dates = [days.first];
      }
      _date = days.first;
    });
  }

  String get _sharedDateMode {
    if (_isRange) return 'range';
    if (_isMultiple) return 'multiple';
    if (_dateMode == AppCalendarMode.repeat) return 'repeat';
    return 'single';
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
    late final List<DateTime> days;
    if (_isRange) {
      days = _daysOn(_dates.first, _dates.last);
    } else if (_dateMode == AppCalendarMode.multiple) {
      days = {
        for (final date in _dates) _dateOnly(date),
      }.toList()
        ..sort((a, b) => a.compareTo(b));
      if (days.isEmpty) days.add(_date);
    } else if (_dateMode == AppCalendarMode.repeat && _dates.isNotEmpty) {
      days = [..._dates]..sort((a, b) => a.compareTo(b));
    } else {
      days = [_date];
    }
    if ((_shared || widget.shareWith != null) &&
        days.length > TodoRequestItem.maxDays) {
      return days.sublist(0, TodoRequestItem.maxDays);
    }
    return days;
  }

  bool _allowsAdd(TutorialAction needed) {
    final tutorial = TutorialController.find(context);
    if (tutorial == null || tutorial.allowsAddInteract(needed)) return true;
    showFriendsToast(context, tutorial.step.body, top: true);
    return false;
  }

  Future<void> _pickCategory() async {
    if (!_allowsAdd(TutorialAction.composeEvent)) return;
    _titleFocus.unfocus();
    _memoFocus.unfocus();
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
    );
    if (picked == null || !mounted) {
      if (mounted) _syncTitleTimeHighlight(force: true);
      return;
    }
    _suggest?.userPicked();
    setState(() {
      _suggesting = false;
      _categoryId = picked.id;
      _categoryName = picked.name;
      _categoryColor = picked.color;
    });
    TutorialController.find(context)?.noteCategoryPicked();
    _syncTitleTimeHighlight(force: true);
  }

  Future<void> _pickDate() async {
    if (!_allowsAdd(TutorialAction.pickDateMode)) return;
    _titleFocus.unfocus();
    _memoFocus.unfocus();
    final picked = await showAppCalendarSheet(
      context,
      date: _date,
      dates: _dates,
      mode: _dateMode,
      color: _accent,
    );
    if (picked != null && mounted) {
      setState(() {
        _isSomeday = false;
        _dateMode = picked.mode;
        _dates = picked.dates;
        _date = picked.date;
      });
    }
    if (!mounted) return;
    TutorialController.find(context)?.noteDateMode();
    _syncTitleTimeHighlight(force: true);
  }

  Future<void> _pickTime() async {
    if (!_allowsAdd(TutorialAction.none)) return;
    _titleFocus.unfocus();
    _memoFocus.unfocus();
    final picked = await showEventTimeSheet(
      context,
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
      color: _accent,
    );
    if (picked == null || !mounted) {
      if (mounted) _syncTitleTimeHighlight(force: true);
      return;
    }
    setState(() {
      _startMinutes = picked.startMinutes;
      _endMinutes = picked.endMinutes;
    });
    _syncTitleTimeHighlight(force: true);
  }

  Future<void> _toggleMemo() async {
    if (!_allowsAdd(TutorialAction.none)) return;
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

  Future<void> _sendShared(String title, {required String memo}) async {
    final friend = widget.shareWith;
    if (friend == null) return;
    try {
      await FriendService.instance.sendTodo(
        to: friend,
        title: title,
        date: _date,
        memo: memo,
        categoryName: _categoryName ?? CalendarEvent.defaultCategoryName,
        categoryColor: _categoryColor ?? CalendarEvent.defaultCategoryColor,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        days: _daysToSave(),
        dateMode: _sharedDateMode,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showMissingFieldsDialog(
        context,
        body: FriendService.instance.messageOf(error),
      );
    }
  }

  Future<void> _save() async {
    if (!_allowsAdd(TutorialAction.saveEvent)) return;
    _applyTitleTime();
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
    if (widget.shareWith != null) {
      await _sendShared(title, memo: _memo.text.trim());
      return;
    }
    if (_shared) {
      final initial = widget.initial!;
      final categoryId = _categoryId;
      if (categoryId != null) {
        final prefs = await SharedPreferences.getInstance();
        await LastEventCategoryPreference(prefs: prefs).setId(categoryId);
        if (!mounted) return;
      }
      final next = initial.copyWith(
        title: title,
        date: days.first,
        memo: _memo.text.trim(),
        categoryId: categoryId,
        categoryName: _categoryName,
        categoryColor: _categoryColor,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        clearTime: _startMinutes == null,
        clearEnd: _startMinutes != null && _endMinutes == null,
      );
      await FriendService.instance.editShared(
        next,
        days: days,
        dateMode: _sharedDateMode,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    final initial = widget.initial;
    final memo = _memo.text.trim();
    final categoryId = _categoryId;
    final categoryName = _categoryName!;
    final categoryColor = _categoryColor!;
    if (categoryId != null) {
      final prefs = await SharedPreferences.getInstance();
      await LastEventCategoryPreference(prefs: prefs).setId(categoryId);
      if (!mounted) return;
    }
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
          clearTime: _isSomeday || _startMinutes == null,
          clearEnd: !_isSomeday &&
              _startMinutes != null &&
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
    final tutorial = TutorialController.maybeOf(context);
    final allowTitle =
        tutorial?.allowsAddInteract(TutorialAction.composeEvent) ?? true;
    final allowExtra =
        tutorial?.allowsAddInteract(TutorialAction.none) ?? true;
    if (!allowTitle && (_titleFocus.hasFocus || _memoFocus.hasFocus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _titleFocus.unfocus();
        _memoFocus.unfocus();
      });
    }
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      tween: ColorTween(end: _accent),
      builder: (context, color, child) {
        return AccentSelectionTheme(
          color: color ?? _accent,
          child: child!,
        );
      },
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      clipBehavior: PcLayout.isPc ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.of(context).tint(_accent, 0.14),
        borderRadius: PcLayout.sheetRadius(),
        boxShadow: PcLayout.sheetLift(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TutorialSheetHint(color: _accent),
            TutorialPulse(
              active: tutorial?.step.action == TutorialAction.composeEvent,
              radius: 16,
              color: _accent,
              child: EventTitleField(
                controller: _title,
                focusNode: _titleFocus,
                autofocus: false,
                readOnly: !allowTitle,
                onChanged: _feedTitle,
                onTap: allowTitle
                    ? null
                    : () => _allowsAdd(TutorialAction.composeEvent),
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
                        readOnly: !allowExtra,
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
                        TutorialPulse(
                          active: tutorial?.step.action ==
                              TutorialAction.composeEvent,
                          color: _hasCategory
                              ? _accent
                              : AppColors.of(context).muted,
                          child: AiCategoryChip(
                            name: _categoryName ?? AppStrings.categoryAction,
                            color: _hasCategory
                                ? _accent
                                : AppColors.of(context).muted,
                            selected: _hasCategory,
                            active: _suggestOn,
                            loading: _suggesting,
                            onPressed: _pickCategory,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TutorialPulse(
                          active: tutorial?.step.action ==
                              TutorialAction.pickDateMode,
                          color: _accent,
                          child: EventDateChip(
                            date: _date,
                            color: _accent,
                            label: _isSomeday
                                ? AppStrings.somedayTitle
                                : _isRange
                                ? AppStrings.rangeEventLabel
                                : _isMultiple
                                ? AppStrings.multipleEventLabel
                                : _dateMode == AppCalendarMode.repeat ||
                                      widget.initial?.repeatId != null
                                ? AppStrings.repeatEventLabel
                                : null,
                            onPressed: _pickDate,
                          ),
                        ),
                        if (!_isSomeday) ...[
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
                TutorialPulse(
                  active: tutorial?.step.action == TutorialAction.saveEvent,
                  color: _accent,
                  child: SaveCompanyButton(
                    onPressed: _saving ? () {} : _save,
                    color: _accent,
                  ),
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
