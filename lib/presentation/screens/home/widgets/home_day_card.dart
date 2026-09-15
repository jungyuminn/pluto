import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/swipe_to_delete.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/presentation/screens/add_company/widgets/add_company_sheet.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_emoji_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_sticker_image.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_repeat_event_dialog.dart';
import 'package:pluto/presentation/widgets/app_bar_pill.dart';

class HomeDayCard extends StatefulWidget {
  const HomeDayCard({
    super.key,
    required this.title,
    this.date,
    required this.events,
    required this.categories,
    this.categoryView = false,
    this.sortByTime = false,
    this.showTime = false,
    required this.onEventsChanged,
    this.showAddButton = true,
    this.showEventDates = false,
    this.someday = false,
    this.dateLabel,
    this.groupDates,
  });

  final String title;
  final DateTime? date;
  final List<CalendarEvent> events;
  final List<EventCategory> categories;
  final bool categoryView;
  final bool sortByTime;
  final bool showTime;
  final VoidCallback onEventsChanged;
  final bool showAddButton;
  final bool showEventDates;
  final bool someday;
  final String? dateLabel;
  final List<DateTime>? groupDates;

  @override
  State<HomeDayCard> createState() => _HomeDayCardState();
}

class _HomeDayCardState extends State<HomeDayCard> {
  final _listBoxKey = GlobalKey();
  late var _events = List.of(widget.events);
  late var _items = _itemsForView;
  final _reveals = <String, double>{};
  final _liveIds = <String>{};
  String? _draggingId;
  DayEmojiStore? _emojiStore;
  String? _emoji;
  var _emojiPop = false;
  var _animateEmojiSlot = false;

  static const _labelHeight = 52.0;
  static const _eventGap = 10.0;
  static const _headerExtent = 24.0;
  static const _headerGap = 6.0;
  static const _dateHeaderExtent = 28.0;
  static const _dateHeaderGap = 14.0;
  static const _slotAnim = Duration(milliseconds: 240);

  String? get _dateLabel {
    if (widget.dateLabel != null) return widget.dateLabel;
    final date = widget.date;
    if (date == null) return null;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.month}. ${date.day}. ($weekday)';
  }

  String _eventDateLabel(CalendarEvent event) {
    final date = event.day;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.month}. ${date.day}. ($weekday)';
  }

  String? _timeText(CalendarEvent event) {
    if (!widget.showTime || event.someday) return null;
    return event.timeLabel ?? (event.isJob ? null : AppStrings.allDayLabel);
  }

  String _dayHeaderName(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day == _today) return AppStrings.todayTitle;
    if (day == _tomorrow) return AppStrings.tomorrowTitle;
    if (day == _today.add(const Duration(days: 2))) {
      return AppStrings.dayAfterTomorrowTitle;
    }
    final weekday = AppStrings.weekdays[day.weekday % 7];
    return '${day.month}. ${day.day}. ($weekday)';
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _tomorrow => _today.add(const Duration(days: 1));

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_ListEntry> get _itemsForView {
    final dates = widget.groupDates;
    if (dates == null || dates.isEmpty) {
      return _itemsForEvents(_events);
    }

    final items = <_ListEntry>[];
    var firstDate = true;
    for (final date in dates) {
      final day = DateTime(date.year, date.month, date.day);
      final dayEvents = [
        for (final event in _events)
          if (_isSameDay(event.day, day)) event,
      ];
      if (dayEvents.isEmpty) continue;
      items.add(
        _ListEntry.dateHeader(
          key: 'd:${day.millisecondsSinceEpoch}',
          name: _dayHeaderName(day),
          showTopGap: !firstDate,
        ),
      );
      firstDate = false;
      items.addAll(
        _itemsForEvents(
          dayEvents,
          headerKeyPrefix: '${day.millisecondsSinceEpoch}:',
        ),
      );
    }
    return items;
  }

  List<_ListEntry> _itemsForEvents(
    List<CalendarEvent> source, {
    String headerKeyPrefix = '',
  }) {
    if (!widget.categoryView) {
      final events = widget.sortByTime
          ? CalendarEvent.withLockedThenStartTime(source)
          : source;
      return [for (final event in events) _ListEntry.event(event)];
    }

    final jobs = [for (final event in source) if (event.isJob) event];
    final todos = [for (final event in source) if (!event.isJob) event];
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
      final section = widget.sortByTime
          ? CalendarEvent.withLockedThenStartTime(events)
          : events;
      items.add(
        _ListEntry.header(
          key: '$headerKeyPrefix$key',
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

    for (final category in widget.categories) {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppScope.of(context).dayEmojiStore;
    if (identical(store, _emojiStore)) return;
    _emojiStore?.removeListener(_onEmojiStore);
    _emojiStore = store;
    store.addListener(_onEmojiStore);
    _applyEmoji(_readSticker(), animate: false);
  }

  @override
  void dispose() {
    _emojiStore?.removeListener(_onEmojiStore);
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDate = oldWidget.date;
    final date = widget.date;
    if (oldDate?.year != date?.year ||
        oldDate?.month != date?.month ||
        oldDate?.day != date?.day) {
      _applyEmoji(_readSticker(), animate: false);
    }
    if (_draggingId != null) return;
    _events = List.of(widget.events);
    _syncItems(_itemsForView);
  }

  void _syncItems(List<_ListEntry> next) {
    final prev = _items;
    final prevById = {for (final item in prev) item.id: item};
    final nextIds = {for (final item in next) item.id};
    _liveIds
      ..clear()
      ..addAll(nextIds);

    final outgoing = [
      for (final item in prev)
        if (!nextIds.contains(item.id)) item,
    ];
    final outgoingIndex = {
      for (var i = 0; i < prev.length; i++)
        if (!nextIds.contains(prev[i].id)) prev[i].id: i,
    };

    final merged = [...next];
    final inserted = outgoingIndex.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in inserted) {
      final item = prevById[entry.key];
      if (item == null) continue;
      merged.insert(entry.value.clamp(0, merged.length), item);
      _reveals[item.id] = 0;
    }

    final appearing = <String>[];
    for (final item in next) {
      if (prevById.containsKey(item.id)) {
        _reveals[item.id] = 1;
        continue;
      }
      _reveals[item.id] = 0;
      appearing.add(item.id);
    }

    _items = merged;
    setState(() {});

    if (appearing.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var changed = false;
        for (final id in appearing) {
          if (!_liveIds.contains(id)) continue;
          if (_reveals[id] == 1) continue;
          _reveals[id] = 1;
          changed = true;
        }
        if (changed) setState(() {});
      });
    }

    if (outgoing.isEmpty) return;
    Future<void>.delayed(_slotAnim, () {
      if (!mounted) return;
      final before = _items.length;
      _items.removeWhere((item) {
        return !_liveIds.contains(item.id) && (_reveals[item.id] ?? 1) == 0;
      });
      if (_items.length == before) return;
      setState(() {});
    });
  }

  double get _eventExtent {
    return _labelHeight * AppFonts.labelScaleOf(context) + _eventGap;
  }

  double _layoutExtent(_ListEntry item) {
    return _extent(item) * (_reveals[item.id] ?? 1);
  }

  Future<void> _add() async {
    final now = DateTime.now();
    final saved = widget.someday
        ? await showAddEventSheet(
            context,
            date: DateTime(now.year, now.month, now.day),
            someday: true,
          )
        : widget.date == null
            ? false
            : await showAddEventSheet(context, date: widget.date!);
    if (saved) widget.onEventsChanged();
  }

  Future<void> _edit(CalendarEvent event) async {
    if (event.isJob) {
      await _openJob(event);
      return;
    }
    final saved = await showAddEventSheet(
      context,
      date: event.date,
      event: event,
      someday: event.someday,
    );
    if (saved) widget.onEventsChanged();
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
    if (saved) widget.onEventsChanged();
  }

  Future<bool> _delete(CalendarEvent event) async {
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
      widget.onEventsChanged();
      return true;
    }
    final confirmed = await showDeleteEventDialog(
      context,
      title: event.title,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteCalendarEvent(event);
    widget.onEventsChanged();
    return true;
  }

  Future<void> _toggleComplete(CalendarEvent event) async {
    final updater = AppScope.of(context).updateCalendarEvent;
    final next = event.copyWith(completed: !event.completed);
    if (event.isRepeat) {
      await updater.instance(next);
    } else {
      await updater(next);
    }
    widget.onEventsChanged();
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
    if (widget.groupDates != null && !_isSameDay(event.day, dragged.day)) {
      return false;
    }
    if (!widget.categoryView) return true;
    return (event.categoryId ?? event.categoryName) ==
        (dragged.categoryId ?? dragged.categoryName);
  }

  double _extent(_ListEntry item) {
    if (item.isDateHeader) {
      return _dateHeaderExtent + (item.showTopGap ? _dateHeaderGap : 0);
    }
    if (item.isHeader) {
      return _headerExtent + (item.showTopGap ? _headerGap : 0);
    }
    return _eventExtent;
  }

  double _offsetOfEvent(String id) {
    var y = 0.0;
    for (final item in _items) {
      if (item.event?.id == id) return y;
      y += _layoutExtent(item);
    }
    return y;
  }

  void _onDragStarted(CalendarEvent event) {
    setState(() => _draggingId = event.id);
  }

  void _onDragUpdate(Offset global) {
    final dragged = _draggedEvent;
    if (dragged == null) return;
    final box = _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveInGroup(dragged, _groupIndexAt(box.globalToLocal(global).dy, dragged));
  }

  void _onDragEnded() {
    final shouldSave = _draggingId != null;
    setState(() => _draggingId = null);
    if (shouldSave) _persistTodoOrder();
  }

  CalendarEvent? get _draggedEvent {
    final id = _draggingId;
    if (id == null) return null;
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
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
      final height = _layoutExtent(item);
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
        if (!event.isLockedOrder && _inDragGroup(dragged, event)) event,
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
    if (widget.categoryView || widget.groupDates != null) {
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
        ..addAll([...jobs, ...ranges, ...todos]);
      _items = _itemsForView;
    });
    HapticFeedback.selectionClick();
  }

  bool _inDragGroup(CalendarEvent dragged, CalendarEvent event) {
    if (widget.groupDates != null && !_isSameDay(event.day, dragged.day)) {
      return false;
    }
    if (!widget.categoryView) return true;
    return (event.categoryId ?? event.categoryName) ==
        (dragged.categoryId ?? dragged.categoryName);
  }

  Future<void> _persistTodoOrder() async {
    if (!mounted) return;
    final todos = [
      for (final event in _events)
        if (!event.isLockedOrder) event,
    ];
    await AppScope.of(context).reorderCalendarEvents(todos);
    widget.onEventsChanged();
  }

  Future<void> _pickEmoji(DateTime date) async {
    final store = AppScope.of(context).dayEmojiStore;
    final current = store.on(date, layer: DayStickerLayer.event);
    final picked = await showDayEmojiSheet(
      context,
      selected: DayStickers.isAsset(current) ? current : null,
    );
    if (picked == null || !mounted) return;
    await store.set(
      date,
      picked.isEmpty ? null : picked,
      layer: DayStickerLayer.event,
    );
  }

  String? _readSticker() {
    final date = widget.date;
    if (date == null) return null;
    final value = AppScope.of(context).dayEmojiStore.on(
      date,
      layer: DayStickerLayer.event,
    );
    return DayStickers.isAsset(value) ? value : null;
  }

  void _onEmojiStore() => _applyEmoji(_readSticker(), animate: true);

  void _applyEmoji(String? next, {required bool animate}) {
    if (next == _emoji) return;
    setState(() {
      _emoji = next;
      _emojiPop = animate && next != null;
      _animateEmojiSlot = animate;
    });
    if (next != null || !animate) return;
    Future<void>.delayed(DayStickerImage.popDuration, () {
      if (!mounted || _emoji != null) return;
      setState(() => _animateEmojiSlot = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, colors),
            const SizedBox(height: 16),
            _buildList(),
            if (widget.showAddButton) AddEventButton(onPressed: _add),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors colors) {
    final date = widget.date;
    if (date == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleText(context, colors),
          if (_dateLabel != null) ...[
            const SizedBox(height: 4),
            _dateText(context, colors),
          ],
        ],
      );
    }

    return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_emoji != null || _animateEmojiSlot)
              ClipRect(
                child: AnimatedContainer(
                  duration: _animateEmojiSlot
                      ? DayStickerImage.popDuration
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  width: _emoji == null ? 0 : 58,
                  height: _emoji == null ? 0 : 48,
                  alignment: Alignment.centerLeft,
                  child: _emoji == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: DayStickerImage(
                            key: ValueKey(_emoji),
                            asset: _emoji!,
                            width: 48,
                            height: 48,
                            pop: _emojiPop,
                          ),
                        ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleText(context, colors),
                  if (_dateLabel != null) ...[
                    const SizedBox(height: 4),
                    _dateText(context, colors),
                  ],
                ],
              ),
            ),
            AppBarPill(
              asset: AppIcons.emoji,
              label: AppStrings.emojiAction,
              onPressed: () => _pickEmoji(date),
            ),
          ],
        );
  }

  Widget _titleText(BuildContext context, AppColors colors) {
    return Text(
      widget.title,
      style: TextStyle(
        fontFamily: AppFonts.of(context),
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: colors.text,
      ),
    );
  }

  Widget _dateText(BuildContext context, AppColors colors) {
    return Text(
      _dateLabel!,
      style: TextStyle(
        fontFamily: AppFonts.of(context),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: colors.muted,
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) return const SizedBox.shrink();
    var height = 0.0;
    final tops = <double>[];
    for (final item in _items) {
      tops.add(height);
      height += _layoutExtent(item);
    }
    return AnimatedContainer(
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
              child: ClipRect(
                child: AnimatedOpacity(
                  duration: _slotAnim,
                  curve: Curves.easeOutCubic,
                  opacity: _reveals[_items[i].id] ?? 1,
                  child: IgnorePointer(
                    ignoring: (_reveals[_items[i].id] ?? 1) < 1,
                    child: _tile(_items[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(_ListEntry item) {
    if (item.isDateHeader) {
      return Padding(
        padding: EdgeInsets.only(
          top: item.showTopGap ? _dateHeaderGap : 0,
          bottom: 8,
        ),
        child: SizedBox(
          height: 20,
          child: Text(
            item.headerName ?? '',
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1,
              color: AppColors.of(context).text,
            ),
          ),
        ),
      );
    }
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
              Text(
                item.headerName ?? '',
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  color: AppColors.of(context).text,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final event = item.event!;
    final timeText = _timeText(event);
    final categoryName = widget.showEventDates
        ? _eventDateLabel(event)
        : event.categoryName;
    final label = event.isJob
        ? DayEventLabel(
            title: event.title,
            categoryName: event.categoryName,
            color: event.color,
            isJob: true,
            memo: event.memo,
            timeText: timeText,
            onPressed: () => _edit(event),
          )
        : DayEventLabel(
            title: event.title,
            categoryName: categoryName,
            color: event.color,
            completed: event.completed,
            isRepeat: event.isRepeat,
            isRange: event.isRange,
            memo: event.memo,
            timeText: timeText,
            onPressed: () => _edit(event),
            onLongPressed:
                widget.sortByTime ? _explainTimeSortLock : null,
            onCompletePressed: () => _toggleComplete(event),
          );

    final body = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: event.isJob
          ? label
          : SwipeToDelete(
              onSwipeLeft: () => _delete(event),
              child: label,
            ),
    );

    if (event.isLockedOrder || widget.sortByTime) return body;

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
          onDragEnd: (_) => _onDragEnded(),
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
                    categoryName: categoryName,
                    color: event.color,
                    completed: event.completed,
                    isRepeat: event.isRepeat,
                    isRange: event.isRange,
                    memo: event.memo,
                    timeText: timeText,
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
                height: _labelHeight * AppFonts.labelScaleOf(context),
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
        showTopGap = false,
        isDateHeader = false;

  const _ListEntry.header({
    required String key,
    required String name,
    required Color color,
    this.showTopGap = false,
  })  : event = null,
        headerKey = key,
        headerName = name,
        headerColor = color,
        isDateHeader = false;

  const _ListEntry.dateHeader({
    required String key,
    required String name,
    this.showTopGap = false,
  })  : event = null,
        headerKey = key,
        headerName = name,
        headerColor = null,
        isDateHeader = true;

  final CalendarEvent? event;
  final String? headerKey;
  final String? headerName;
  final Color? headerColor;
  final bool showTopGap;
  final bool isDateHeader;

  bool get isHeader => event == null && !isDateHeader;

  String get id => event != null ? 'e:${event!.id}' : 'h:$headerKey';
}
