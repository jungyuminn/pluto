import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/data/datasources/calendar_complete.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/core/utils/drop_in.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/core/utils/swipe_to_delete.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/presentation/screens/add_company/widgets/add_company_sheet.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/calendar/calendar_day_events.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_repeat_event_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_emoji_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_sticker_image.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:pluto/presentation/tutorial/tutorial_hint.dart';
import 'package:pluto/presentation/widgets/app_bar_pill.dart';

Future<void> showDayEventsDialog(
  BuildContext context, {
  required DateTime date,
  required List<CalendarEvent> events,
  VoidCallback? onEventsChanged,
  Rect? origin,
  bool readOnly = false,
  String? sticker,
}) async {
  CalendarDayDropTarget.reset();
  final tutorial = TutorialController.find(context);
  tutorial?.setCovered(true);
  try {
    await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x00000000),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      Widget dialog = DayEventsDialog(
        date: date,
        initialEvents: events,
        onEventsChanged: onEventsChanged,
        readOnly: readOnly,
        sticker: sticker,
      );
      if (readOnly) {
        dialog = Theme(
          data: AppTheme.themed(
            dark: Theme.of(context).brightness == Brightness.dark,
            skin: AppSkin.classic,
          ),
          child: dialog,
        );
      }
      return dialog;
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final handle = TutorialController.maybeOf(context)?.step.action ==
          TutorialAction.handleEvent;
      final t = Curves.easeOutCubic.transform(animation.value);
      final fade = (0.25 + animation.value * 1.5).clamp(0.0, 1.0);
      final source = origin;
      Widget dialog = child;
      if (source == null || source.isEmpty) {
        dialog = Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: lerpDouble(0.92, 1, t)!,
            child: child,
          ),
        );
      } else {
        final size = MediaQuery.sizeOf(context);
        final dialogWidth = PcLayout.dayDialogWidthOf();
        final dialogHeight = PcLayout.dayDialogHeightOf(size.height);
        final beginScale =
            ((source.width / dialogWidth + source.height / dialogHeight) / 2)
                .clamp(0.12, 0.38);
        final delta = source.center - Offset(size.width / 2, size.height / 2);
        dialog = Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: delta * (1 - t),
            child: Transform.scale(
              scale: lerpDouble(beginScale, 1, t)!,
              child: child,
            ),
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: animation,
              child: ValueListenableBuilder<bool>(
                valueListenable: CalendarDayDropTarget.hidingScrim,
                builder: (context, hiding, _) {
                  return IgnorePointer(
                    ignoring: hiding,
                    child: AnimatedOpacity(
                      opacity: hiding ? 0 : 1,
                      duration: const Duration(milliseconds: 140),
                      child: GestureDetector(
                        onTap: handle
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        behavior: HitTestBehavior.opaque,
                        child: const ColoredBox(color: Color(0x33000000)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          dialog,
          if (handle)
            Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: animation,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: const TutorialHandleCard(),
                  ),
                ),
              ),
            ),
        ],
      );
    },
    );
  } finally {
    tutorial?.setCovered(false);
    tutorial?.noteDayClosed();
  }
}

class DayEventsDialog extends StatefulWidget {
  const DayEventsDialog({
    super.key,
    required this.date,
    required this.initialEvents,
    this.onEventsChanged,
    this.readOnly = false,
    this.sticker,
  });

  final DateTime date;
  final List<CalendarEvent> initialEvents;
  final VoidCallback? onEventsChanged;
  final bool readOnly;
  final String? sticker;

  @override
  State<DayEventsDialog> createState() => _DayEventsDialogState();
}

class _DayEventsDialogState extends State<DayEventsDialog> {
  final _listController = ScrollController();
  final _listBoxKey = GlobalKey();
  final _dialogKey = GlobalKey();
  late final List<CalendarEvent> _events;
  var _items = <_ListEntry>[];
  var _categories = <EventCategory>[];
  var _compact = false;
  var _sortByTime = false;
  var _showTime = false;
  var _hour24 = true;
  var _initialized = false;
  String? _emoji;
  var _emojiPop = false;
  var _animateEmojiSlot = false;
  String? _draggingId;
  String? _settlingId;
  Offset _settleFrom = Offset.zero;
  var _settleGen = 0;
  var _draggingOutside = false;
  var _triedReorder = false;
  final _reveals = <String, double>{};

  static const _headerExtent = 24.0;
  static const _headerGap = 6.0;
  static const _slotAnim = Duration(milliseconds: 240);

  double get _eventExtent => PcLayout.dayLabelExtentOf();
  double get _labelHeight => PcLayout.dayLabelHeightOf();

  @override
  void initState() {
    super.initState();
    _events = List.of(widget.initialEvents);
    _items = _itemsForView;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final scope = AppScope.of(context);
    _compact = scope.dayEventsViewPreference.categoryView;
    _sortByTime = scope.dayEventsViewPreference.sortByTime;
    _showTime = scope.dayEventsViewPreference.showTime;
    _hour24 = scope.dayEventsViewPreference.hour24;
    if (widget.readOnly) {
      _emoji = DayStickers.isAsset(widget.sticker) ? widget.sticker : null;
    } else {
      final sticker = scope.dayEmojiStore.on(
        widget.date,
        layer: DayStickerLayer.event,
      );
      _emoji = DayStickers.isAsset(sticker) ? sticker : null;
    }
    _items = _itemsForView;
    _loadCategories();
  }

  @override
  void dispose() {
    CalendarDayDropTarget.clear();
    _listController.dispose();
    super.dispose();
  }

  String get _title {
    final date = widget.date;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.month}${AppStrings.monthSuffix} ${date.day}${AppStrings.daySuffix} ($weekday)';
  }

  int get _daysFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(widget.date.year, widget.date.month, widget.date.day);
    return target.difference(today).inDays;
  }

  String get _dDayLabel {
    final days = _daysFromToday;
    if (days == 0) return 'D-Day';
    if (days > 0) return 'D-$days';
    return 'D+${-days}';
  }

  Color _dDayColor(AppColors colors) {
    return _daysFromToday < 0 ? colors.accent : colors.danger;
  }

  String? _timeText(CalendarEvent event) {
    if (!_showTime) return null;
    return event.labelTime(hour24: _hour24) ??
        (event.isJob ? null : AppStrings.allDayLabel);
  }

  List<_ListEntry> get _itemsForView {
    if (!_compact) {
      final events = _sortByTime
          ? CalendarEvent.withLockedThenStartTime(_events)
          : _events;
      return [for (final event in events) _ListEntry.event(event)];
    }

    final jobs = [for (final event in _events) if (event.isJob) event];
    final todos = [for (final event in _events) if (!event.isJob) event];
    final groups = <String, List<CalendarEvent>>{};
    for (final event in todos) {
      final key = event.categoryId ?? event.categoryName;
      groups.putIfAbsent(key, () => []).add(event);
    }

    final items = <_ListEntry>[];
    final used = <String>{};
    var firstHeader = true;

    void addSection({
      required String key,
      required String name,
      required Color color,
      required List<CalendarEvent> events,
    }) {
      final section = _sortByTime
          ? CalendarEvent.withLockedThenStartTime(events)
          : events;
      items.add(
        _ListEntry.header(
          key: key,
          name: name,
          color: color,
          showTopGap: !firstHeader,
        ),
      );
      firstHeader = false;
      for (final event in section) {
        items.add(_ListEntry.event(event));
      }
    }

    if (jobs.isNotEmpty) {
      addSection(
        key: 'job',
        name: AppStrings.companySection,
        color: jobs.first.color,
        events: jobs,
      );
    }

    for (final category in _categories) {
      final grouped = groups[category.id];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(category.id);
      addSection(
        key: category.id,
        name: category.name,
        color: category.tint,
        events: grouped,
      );
    }
    for (final event in todos) {
      final key = event.categoryId ?? event.categoryName;
      if (used.contains(key)) continue;
      final grouped = groups[key];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(key);
      addSection(
        key: key,
        name: event.categoryName,
        color: event.color,
        events: grouped,
      );
    }
    return items;
  }

  Future<void> _loadCategories() async {
    final categories = await AppScope.of(context).getEventCategories();
    if (!mounted) return;
    _categories = categories;
    if (_compact) _syncItems(_itemsForView, animate: false);
  }

  Future<void> _reload({bool animate = true}) async {
    if (widget.readOnly) return;
    final scope = AppScope.of(context);
    final calendarPrefs = scope.calendarPreference;
    final events = calendarPrefs.showTodos
        ? await scope.getCalendarEvents()
        : const <CalendarEvent>[];
    final applications = (calendarPrefs.showCompanies &&
            scope.navPreference.showJobTab)
        ? await scope.getJobApplications()
        : const <JobApplication>[];
    final companyCategories = applications.isEmpty
        ? const <EventCategory>[]
        : await scope.fetchCategories(CategoryKind.company);
    if (!mounted) return;
    _events
      ..clear()
      ..addAll(
        calendarEventsOn(
          date: widget.date,
          events: events,
          applications: applications,
          companyCategories: companyCategories,
          includeRejected: false,
        ),
      );
    _syncItems(_itemsForView, animate: animate);
  }

  void _syncItems(List<_ListEntry> next, {required bool animate}) {
    final oldIds = {for (final item in _items) item.id};
    final appearing = <String>[];
    for (final item in next) {
      if (!animate || oldIds.contains(item.id)) {
        _reveals[item.id] = 1;
        continue;
      }
      _reveals[item.id] = 0;
      appearing.add(item.id);
    }
    final insertedRange = next.any(
      (item) => appearing.contains(item.id) && (item.event?.isRange ?? false),
    );
    setState(() => _items = next);
    if (appearing.isEmpty || !animate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final id in appearing) {
          _reveals[id] = 1;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_listController.hasClients) return;
        _listController.animateTo(
          insertedRange
              ? _listController.position.minScrollExtent
              : _listController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  Future<void> _pickEmoji() async {
    if (widget.readOnly) return;
    final picked = await showDayEmojiSheet(context, selected: _emoji);
    if (picked == null || !mounted) return;
    await AppScope.of(context).dayEmojiStore.set(
      widget.date,
      picked.isEmpty ? null : picked,
      layer: DayStickerLayer.event,
    );
    if (!mounted) return;
    setState(() {
      final next = AppScope.of(context).dayEmojiStore.on(
        widget.date,
        layer: DayStickerLayer.event,
      );
      _emoji = DayStickers.isAsset(next) ? next : null;
      _emojiPop = _emoji != null;
      _animateEmojiSlot = true;
    });
    widget.onEventsChanged?.call();
    if (_emoji != null) return;
    Future<void>.delayed(DayStickerImage.popDuration, () {
      if (!mounted || _emoji != null) return;
      setState(() => _animateEmojiSlot = false);
    });
  }

  Future<void> _add() async {
    if (widget.readOnly) return;
    final saved = await showAddEventSheet(context, date: widget.date);
    if (saved && mounted) await _reload();
    if (saved) widget.onEventsChanged?.call();
  }

  Future<void> _edit(CalendarEvent event) async {
    if (widget.readOnly) return;
    if (event.isJob) {
      await _openJob(event);
      return;
    }
    final saved = await showAddEventSheet(
      context,
      date: event.date,
      event: event,
    );
    if (saved && mounted) await _reload(animate: false);
    if (saved) widget.onEventsChanged?.call();
  }

  Future<void> _openJob(CalendarEvent event) async {
    final id = event.jobApplicationId;
    if (id == null) return;
    final applications = await AppScope.of(context).getJobApplications();
    JobApplication? application;
    for (final item in applications) {
      if (item.id == id) {
        application = item;
        break;
      }
    }
    if (application == null || !mounted) return;
    final saved = await showAddCompanySheet(
      context,
      application: application,
    );
    if (saved && mounted) await _reload(animate: false);
    if (saved) widget.onEventsChanged?.call();
  }

  Future<bool> _delete(CalendarEvent event) async {
    if (widget.readOnly) return false;
    if (event.isRepeat) {
      final scope = await showDeleteRepeatEventDialog(context);
      if (scope == null || !mounted) return false;
      final deleter = AppScope.of(context).deleteCalendarEvent;
      switch (scope) {
        case RepeatDeleteScope.thisOnly:
          await deleter.thisOnly(event);
        case RepeatDeleteScope.thisAndAfter:
          await deleter.thisAndAfter(event);
        case RepeatDeleteScope.all:
          await deleter.allRepeats(event.repeatId!);
      }
      if (mounted) await _reload();
      widget.onEventsChanged?.call();
      return true;
    }
    final confirmed = await showDeleteEventDialog(
      context,
      title: event.title,
    );
    if (!confirmed || !mounted) return false;
    await _remove(event);
    return true;
  }

  Future<void> _remove(CalendarEvent event) async {
    await AppScope.of(context).deleteCalendarEvent(event);
    if (mounted) await _reload();
    widget.onEventsChanged?.call();
  }

  Future<void> _toggleComplete(CalendarEvent event) async {
    if (widget.readOnly) return;
    final tutorial = TutorialController.find(context);
    final next = await saveCompleteToggle(
      updater: AppScope.of(context).updateCalendarEvent,
      event: event,
    );
    tutorial?.noteCompleted(completed: next.completed);
    if (mounted) await _reload(animate: false);
    widget.onEventsChanged?.call();
  }

  Future<void> _explainTimeSortLock() {
    HapticFeedback.lightImpact();
    return showMissingFieldsDialog(
      context,
      title: AppStrings.timeSortLockTitle,
      body: AppStrings.timeSortLockBody,
    );
  }

  bool _sameGroup(CalendarEvent dragged, _ListEntry item) {
    final event = item.event;
    if (event == null || event.isLockedOrder) return false;
    if (!_compact) return true;
    return (event.categoryId ?? event.categoryName) ==
        (dragged.categoryId ?? dragged.categoryName);
  }

  double _extent(_ListEntry item) {
    if (item.isHeader) {
      return _headerExtent + (item.showTopGap ? _headerGap : 0);
    }
    return _eventExtent;
  }

  double _layoutExtent(_ListEntry item) {
    return _extent(item) * (_reveals[item.id] ?? 1);
  }

  double _offsetOfEvent(String id) {
    var y = 0.0;
    for (final item in _items) {
      if (item.event?.id == id) return y;
      y += _layoutExtent(item);
    }
    return y;
  }

  bool _contains(GlobalKey key, Offset global) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (box.localToGlobal(Offset.zero) & box.size).contains(global);
  }

  void _onDragStarted(CalendarEvent event) {
    setState(() {
      _draggingId = event.id;
      _draggingOutside = false;
      _triedReorder = false;
    });
  }

  void _onDragUpdate(Offset global) {
    final dragged = _draggedEvent;
    if (dragged == null) return;

    if (!_draggingOutside) {
      final insideDialog = _contains(_dialogKey, global);
      final insideList = insideDialog && _contains(_listBoxKey, global);
      if (insideList) {
        CalendarDayDropTarget.clear();
        final box =
            _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final to = _groupIndexAt(box.globalToLocal(global).dy, dragged);
        if (!_sortByTime) {
          _moveInGroup(dragged, to);
        } else if (!_triedReorder) {
          final from = _groupIndexOf(dragged);
          if (from >= 0 && to >= 0 && from != to) {
            _triedReorder = true;
          }
        }
        return;
      }
      if (insideDialog) {
        CalendarDayDropTarget.clear();
        return;
      }
      setState(() => _draggingOutside = true);
      CalendarDayDropTarget.setScrimHidden(true);
    }

    final overDate = CalendarDayDropTarget.dateAt(global);
    if (overDate != null &&
        !CalendarDayDropTarget.isSameDay(overDate, widget.date)) {
      final was = CalendarDayDropTarget.highlighted.value;
      CalendarDayDropTarget.highlight(overDate);
      if (was == null || !CalendarDayDropTarget.isSameDay(was, overDate)) {
        HapticFeedback.selectionClick();
      }
      return;
    }
    CalendarDayDropTarget.clear();
  }

  Offset? _slotOrigin(String id) {
    final box = _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset(0, _offsetOfEvent(id)));
  }

  Future<void> _onDragEnded(DraggableDetails details) async {
    final event = _draggedEvent;
    final dropDate = CalendarDayDropTarget.highlighted.value;
    final shouldSaveOrder = _draggingId != null && !_sortByTime;
    final triedReorder = _triedReorder;
    final moving = event != null &&
        dropDate != null &&
        !CalendarDayDropTarget.isSameDay(dropDate, widget.date);
    CalendarDayDropTarget.clear();
    if (!moving) CalendarDayDropTarget.setScrimHidden(false);
    if (!mounted) return;
    final origin = event == null || moving ? null : _slotOrigin(event.id);
    final delta = origin == null ? Offset.zero : details.offset - origin;
    setState(() {
      if (!moving && event != null && delta.distance > 2) {
        _settlingId = event.id;
        _settleFrom = delta;
        _settleGen++;
      } else {
        _settlingId = null;
      }
      _draggingId = null;
      _draggingOutside = false;
      _triedReorder = false;
    });
    if (moving) {
      await _moveToDate(event, dropDate);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (shouldSaveOrder) await _persistTodoOrder();
    if (_sortByTime && triedReorder && mounted) {
      await _explainTimeSortLock();
    }
  }

  Future<void> _moveToDate(CalendarEvent event, DateTime date) async {
    final target = DateTime(date.year, date.month, date.day);
    if (event.isShared) {
      await _moveSharedToDate(event, target);
      widget.onEventsChanged?.call();
      return;
    }
    final updater = AppScope.of(context).updateCalendarEvent;
    final groupId = event.groupId;
    if (groupId != null) {
      await updater.moveGroup(groupId, target);
    } else if (event.isRepeat) {
      await updater.instance(event.copyWith(date: target));
    } else {
      await updater(event.copyWith(date: target));
    }
    widget.onEventsChanged?.call();
  }

  Future<void> _moveSharedToDate(CalendarEvent event, DateTime target) async {
    final events = await AppScope.of(context).getCalendarEvents();
    final sharedId = event.sharedId ?? '';
    final siblings = [
      for (final item in events)
        if ((item.sharedId ?? '') == sharedId) item,
    ]..sort((a, b) => a.day.compareTo(b.day));
    if (event.isRange && siblings.length >= 2) {
      final first = siblings.first.day;
      final delta = target.difference(first).inDays;
      final days = [
        for (final item in siblings)
          DateTime(item.day.year, item.day.month, item.day.day + delta),
      ];
      await FriendService.instance.editShared(
        event.copyWith(date: days.first),
        days: days,
        dateMode: 'range',
      );
      return;
    }
    if (siblings.length > 1) {
      final days = [
        for (final item in siblings)
          item.id == event.id ? target : item.day,
      ]..sort((a, b) => a.compareTo(b));
      await FriendService.instance.editShared(
        event.copyWith(date: target),
        days: days,
        dateMode: event.isRepeat ? 'repeat' : 'multiple',
      );
      return;
    }
    await FriendService.instance.editShared(
      event.copyWith(date: target),
      days: [target],
    );
  }

  CalendarEvent? get _draggedEvent {
    final id = _draggingId;
    if (id == null) return null;
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  int _groupIndexOf(CalendarEvent dragged) {
    var index = 0;
    for (final item in _items) {
      if (!_sameGroup(dragged, item)) continue;
      if (item.event?.id == dragged.id) return index;
      index++;
    }
    return -1;
  }

  int _groupIndexAt(double y, CalendarEvent dragged) {
    final group = [
      for (final item in _items)
        if (_sameGroup(dragged, item)) item.event!,
    ];
    if (group.isEmpty) return 0;
    final from = group.indexWhere((event) => event.id == dragged.id);
    var closest = 0;
    var best = double.infinity;
    var acc = 0.0;
    var gi = 0;
    for (final item in _items) {
      final height = _extent(item);
      if (_sameGroup(dragged, item)) {
        final dist = (y - (acc + height / 2)).abs();
        if (dist < best) {
          best = dist;
          closest = gi;
        }
        gi++;
      }
      acc += height;
    }
    if (from >= 0 && closest != from) {
      final top = _offsetOfEvent(dragged.id);
      if (y >= top - _eventExtent * 0.18 && y < top + _eventExtent * 1.18) {
        return from;
      }
    }
    return closest;
  }

  void _moveInGroup(CalendarEvent dragged, int to) {
    final group = [
      for (final event in _events)
        if (!event.isLockedOrder &&
            (!_compact ||
                (event.categoryId ?? event.categoryName) ==
                    (dragged.categoryId ?? dragged.categoryName)))
          event,
    ];
    final from = group.indexWhere((event) => event.id == dragged.id);
    if (from < 0 || to < 0 || from == to) return;
    final nextTo = to.clamp(0, group.length - 1);
    if (from == nextTo) return;
    final moved = group.removeAt(from);
    group.insert(nextTo, moved);

    final jobs = [for (final event in _events) if (event.isJob) event];
    final ranges = [for (final event in _events) if (event.isRange) event];
    final todos = [for (final event in _events) if (!event.isLockedOrder) event];
    if (_compact) {
      var gi = 0;
      final ids = {for (final event in group) event.id};
      for (var i = 0; i < todos.length; i++) {
        if (!ids.contains(todos[i].id)) continue;
        todos[i] = group[gi++];
      }
    } else {
      todos
        ..clear()
        ..addAll(group);
    }

    setState(() {
      _events
        ..clear()
        ..addAll([...ranges, ...jobs, ...todos]);
      _items = _itemsForView;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _persistTodoOrder() async {
    if (!mounted) return;
    final todos = [
      for (final event in _events)
        if (!event.isLockedOrder) event,
    ];
    await AppScope.of(context).reorderCalendarEvents(todos);
    widget.onEventsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final height = PcLayout.dayDialogHeightOf(MediaQuery.sizeOf(context).height);

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: AnimatedOpacity(
        opacity: _draggingOutside ? 0 : 1,
        duration: const Duration(milliseconds: 140),
        child: IgnorePointer(
          ignoring: _draggingOutside,
          child: Dialog(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                key: _dialogKey,
                height: height,
                width: PcLayout.dayDialogWidthOf(),
                child: AppSkinBackground(
                  color: colors.card,
                  skin: widget.readOnly ? AppSkin.classic : null,
                  liftForNav: false,
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_emoji != null || _animateEmojiSlot)
                          ClipRect(
                            child: AnimatedContainer(
                              duration: _animateEmojiSlot
                                  ? DayStickerImage.popDuration
                                  : Duration.zero,
                              curve: Curves.easeOutCubic,
                              width: _emoji == null ? 0 : 50,
                              height: _emoji == null ? 0 : 43,
                              alignment: Alignment.centerLeft,
                              child: _emoji == null
                                  ? null
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        top: 1,
                                      ),
                                      child: PressBounce(
                                        onPressed: _pickEmoji,
                                        pressedScale: 0.92,
                                        child: DayStickerImage(
                                          key: ValueKey(_emoji),
                                          asset: _emoji!,
                                          width: 42,
                                          height: 42,
                                          pop: _emojiPop,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dDayLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: _dDayColor(colors),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.readOnly)
                          AppBarPill(
                            asset: AppIcons.emoji,
                            label: AppStrings.emojiAction,
                            onPressed: _pickEmoji,
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: _buildList(),
                    ),
                    if (!widget.readOnly) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AddEventButton(onPressed: _add),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildList() {
    var height = 0.0;
    final tops = <double>[];
    for (final item in _items) {
      tops.add(height);
      height += _layoutExtent(item);
    }
    return SingleChildScrollView(
      controller: _listController,
      physics: _draggingId == null
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: AnimatedContainer(
        key: _listBoxKey,
        duration: _slotAnim,
        curve: Curves.easeOutCubic,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _items.length; i++)
              AnimatedPositioned(
                key: ValueKey(_items[i].id),
                duration: _slotAnim,
                curve: Curves.easeOutCubic,
                top: tops[i],
                left: 0,
                right: 0,
                height: _layoutExtent(_items[i]),
                child: _slotBody(_items[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _slotBody(_ListEntry item) {
    final settling = item.event?.id == _settlingId;
    final body = AnimatedOpacity(
      duration: _slotAnim,
      curve: Curves.easeOutCubic,
      opacity: _reveals[item.id] ?? 1,
      child: IgnorePointer(
        ignoring: settling || (_reveals[item.id] ?? 1) < 1,
        child: _tile(item),
      ),
    );
    final clipped = settling ? body : ClipRect(child: body);
    if (!settling) return clipped;
    return DropIn(
      key: ValueKey(_settleGen),
      from: _settleFrom,
      onDone: () {
        if (!mounted || _settlingId != item.event?.id) return;
        setState(() => _settlingId = null);
      },
      child: clipped,
    );
  }

  Widget _tile(_ListEntry item) {
    if (item.isHeader) {
      return Padding(
        padding: EdgeInsets.only(
          top: item.showTopGap ? _headerGap : 0,
          bottom: 8,
        ),
        child: SizedBox(
          height: 16,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.headerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.headerName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    color: AppColors.of(context).text,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final event = item.event!;
    final timeText = _timeText(event);
    final readOnly = widget.readOnly;
    final label = event.isJob
        ? DayEventLabel(
            title: event.title,
            categoryName: event.categoryName,
            color: event.color,
            isJob: true,
            showAccent: !event.isBeforeToday,
            memo: event.memo,
            timeText: timeText,
            height: _labelHeight,
            onPressed: readOnly ? null : () => _edit(event),
          )
        : DayEventLabel(
            title: event.title,
            categoryName: event.categoryName,
            color: event.color,
            completed: event.completed,
            waiting: event.isSharedWaiting,
            shared: event.isShared,
            peerCompleted: event.sharedPeer,
            isRepeat: event.isRepeat,
            isRange: event.isRange,
            memo: event.memo,
            timeText: timeText,
            height: _labelHeight,
            onPressed: readOnly ? null : () => _edit(event),
            showComplete: true,
            onCompletePressed:
                readOnly ? null : () => _toggleComplete(event),
          );

    final body = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: event.isJob || readOnly
          ? label
          : SwipeToDelete(
              onSwipeLeft: () => _delete(event),
              child: label,
            ),
    );

    if (event.isJob || readOnly) return body;

    return LayoutBuilder(
      builder: (context, constraints) {
        return LongPressDraggable<String>(
          data: event.id,
          delay: const Duration(milliseconds: 400),
          hapticFeedbackOnStart: true,
          rootOverlay: true,
          maxSimultaneousDrags: 1,
          onDragStarted: () => _onDragStarted(event),
          onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
          onDragEnd: (details) => unawaited(_onDragEnded(details)),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Transform.scale(
                scale: 1.03,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: DayEventLabel(
                    title: event.title,
                    categoryName: event.categoryName,
                    color: event.color,
                    completed: event.completed,
                    waiting: event.isSharedWaiting,
                    shared: event.isShared,
                    peerCompleted: event.sharedPeer,
                    isRepeat: event.isRepeat,
                    isRange: event.isRange,
                    memo: event.memo,
                    timeText: timeText,
                    height: _labelHeight,
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.of(context).pressed,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: SizedBox(
                height: _labelHeight,
                width: double.infinity,
              ),
            ),
          ),
          child: body,
        );
      },
    );
  }
}

class _ListEntry {
  const _ListEntry.event(this.event)
      : headerKey = null,
        headerName = null,
        headerColor = null,
        showTopGap = false;

  const _ListEntry.header({
    required String key,
    required String name,
    required Color color,
    this.showTopGap = false,
  })  : event = null,
        headerKey = key,
        headerName = name,
        headerColor = color;

  final CalendarEvent? event;
  final String? headerKey;
  final String? headerName;
  final Color? headerColor;
  final bool showTopGap;

  bool get isHeader => event == null;

  String get id => event != null ? 'e:${event!.id}' : 'h:$headerKey';
}
