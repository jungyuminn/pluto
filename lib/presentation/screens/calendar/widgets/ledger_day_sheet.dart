import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/layout/pc_layout.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/core/utils/swipe_to_delete.dart';
import 'package:job_planner/data/datasources/day_emoji_store.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/ledger_salary_repeat.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_emoji_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_sticker_image.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_kind_stats.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_sheet.dart';
import 'package:job_planner/presentation/widgets/app_bar_pill.dart';

Future<void> showLedgerDaySheet(
  BuildContext context, {
  required DateTime date,
  required List<LedgerEntry> entries,
  Rect? origin,
}) {
  CalendarDayDropTarget.reset();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x00000000),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return LedgerDaySheet(date: date, initial: entries);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final t = Curves.easeOutCubic.transform(animation.value);
      final fade = (0.25 + animation.value * 1.5).clamp(0.0, 1.0);
      final source = origin;
      Widget dialog = child;
      if (source == null || source.isEmpty) {
        dialog = Opacity(
          opacity: fade,
          child: Transform.scale(scale: lerpDouble(0.92, 1, t)!, child: child),
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
                        onTap: () => Navigator.of(context).maybePop(),
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
        ],
      );
    },
  );
}

class LedgerDaySheet extends StatefulWidget {
  const LedgerDaySheet({super.key, required this.date, required this.initial});

  final DateTime date;
  final List<LedgerEntry> initial;

  @override
  State<LedgerDaySheet> createState() => _LedgerDaySheetState();
}

class _LedgerDaySheetState extends State<LedgerDaySheet>
    with SingleTickerProviderStateMixin {
  final _listController = ScrollController();
  final _listBoxKey = GlobalKey();
  final _dialogKey = GlobalKey();
  late List<LedgerEntry> _entries;
  var _items = <_ListEntry>[];
  var _categories = <EventCategory>[];
  var _compact = false;
  var _kindColorView = false;
  var _showKind = true;
  var _initialized = false;
  String? _emoji;
  var _emojiPop = false;
  var _animateEmojiSlot = false;
  String? _draggingId;
  var _draggingOutside = false;
  final _reveals = <String, double>{};
  late final AnimationController _statsAnimation;
  late final CurvedAnimation _statsFade;
  var _statsConsumption = 0;
  var _statsExpense = 0;
  var _statsSalary = 0;
  var _statsNet = 0;
  var _statsShowSalary = false;

  static const _headerExtent = 24.0;
  static const _headerGap = 6.0;
  static const _slotAnim = Duration(milliseconds: 240);

  double get _eventExtent => PcLayout.dayLabelExtentOf();
  double get _labelHeight => PcLayout.dayLabelHeightOf();

  @override
  void initState() {
    super.initState();
    _entries = [...widget.initial]..sort(LedgerEntry.compareDisplay);
    _items = _itemsForView;
    if (_entries.isNotEmpty) _captureStats();
    _statsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
      value: _entries.isEmpty ? 0 : 1,
    );
    _statsFade = CurvedAnimation(
      parent: _statsAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final scope = AppScope.of(context);
    _compact = scope.dayEventsViewPreference.categoryView;
    _kindColorView = scope.dayEventsViewPreference.ledgerKindColor;
    _showKind = scope.dayEventsViewPreference.showLedgerKind;
    final sticker = scope.dayEmojiStore.on(
      widget.date,
      layer: DayStickerLayer.ledger,
    );
    _emoji = DayStickers.isAsset(sticker) ? sticker : null;
    _entries.sort(_compare);
    _items = _itemsForView;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await AppScope.of(
      context,
    ).fetchCategories(CategoryKind.ledger);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _entries.sort(_compare);
      _items = _itemsForView;
    });
  }

  Color _labelColor(LedgerEntry entry) {
    return _kindColorView ? entry.color : entry.displayColor;
  }

  int _compare(LedgerEntry a, LedgerEntry b) {
    if (!_compact) return LedgerEntry.compareDisplay(a, b);
    return LedgerEntry.compareByCategory(a, b, _categoryOrder);
  }

  List<String> get _categoryOrder => [
    for (final category in _categories) category.id,
  ];

  @override
  void dispose() {
    CalendarDayDropTarget.clear();
    _statsFade.dispose();
    _statsAnimation.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _captureStats() {
    _statsConsumption = _consumption;
    _statsExpense = _expense;
    _statsSalary = _salaryTotal;
    _statsNet = _net;
    _statsShowSalary = _entries.any((e) => e.isWage);
  }

  void _syncStats() {
    if (_entries.isNotEmpty) _captureStats();
    if (_entries.isEmpty) {
      _statsAnimation.reverse();
    } else {
      _statsAnimation.forward();
    }
  }

  String get _title {
    final date = widget.date;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    final dayLabel =
        '${date.month}${AppStrings.monthSuffix} ${date.day}${AppStrings.daySuffix} ($weekday)';
    if (date.year == DateTime.now().year) return dayLabel;
    return '${date.year}${AppStrings.yearSuffix} $dayLabel';
  }

  int get _daysFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
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

  int get _salaryTotal =>
      _entries.where((e) => e.isWage).fold(0, (sum, e) => sum + e.amount);

  int get _consumption => _entries
      .where((e) => e.kind == LedgerKind.consumption)
      .fold(0, (sum, e) => sum + e.amount);

  int get _expense => _entries
      .where((e) => e.kind == LedgerKind.expense)
      .fold(0, (sum, e) => sum + e.amount);

  int get _net => _salaryTotal + _expense - _consumption;

  List<_ListEntry> get _itemsForView {
    if (!_compact) {
      return [for (final entry in _entries) _ListEntry.entry(entry)];
    }

    final groups = <String, List<LedgerEntry>>{};
    for (final entry in _entries) {
      groups.putIfAbsent(entry.categoryKey, () => []).add(entry);
    }

    final items = <_ListEntry>[];
    final used = <String>{};
    var firstHeader = true;

    void addSection({
      required String key,
      required String name,
      required Color color,
      required List<LedgerEntry> section,
    }) {
      items.add(
        _ListEntry.header(
          key: key,
          name: name,
          color: color,
          showTopGap: !firstHeader,
        ),
      );
      firstHeader = false;
      items.addAll([for (final entry in section) _ListEntry.entry(entry)]);
    }

    for (final category in _categories) {
      final section = groups[category.id];
      if (section == null || section.isEmpty) continue;
      used.add(category.id);
      addSection(
        key: category.id,
        name: category.name,
        color: category.tint,
        section: section,
      );
    }
    for (final entry in _entries) {
      final key = entry.categoryKey;
      if (used.contains(key)) continue;
      final section = groups[key];
      if (section == null || section.isEmpty) continue;
      used.add(key);
      addSection(
        key: key,
        name: entry.displayCategoryName,
        color: entry.displayColor,
        section: section,
      );
    }
    return items;
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
    setState(() => _items = next);
    _syncStats();
    if (appearing.isEmpty || !animate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final id in appearing) {
          _reveals[id] = 1;
        }
      });
    });
  }

  Future<void> _reload({bool animate = true}) async {
    final scope = AppScope.of(context);
    final all = await scope.getLedgers();
    final categories = await scope.fetchCategories(CategoryKind.ledger);
    final day = DateTime(widget.date.year, widget.date.month, widget.date.day);
    if (!mounted) return;
    _categories = categories;
    _entries = [
      for (final entry in all)
        if (LedgerSalaryRepeat.occursOn(entry, day))
          LedgerSalaryRepeat.onDay(entry, day),
    ]..sort(_compare);
    _syncItems(_itemsForView, animate: animate);
  }

  Future<void> _pickEmoji() async {
    final picked = await showDayEmojiSheet(context, selected: _emoji);
    if (picked == null || !mounted) return;
    await AppScope.of(context).dayEmojiStore.set(
      widget.date,
      picked.isEmpty ? null : picked,
      layer: DayStickerLayer.ledger,
    );
    if (!mounted) return;
    setState(() {
      final next = AppScope.of(context).dayEmojiStore.on(
        widget.date,
        layer: DayStickerLayer.ledger,
      );
      _emoji = DayStickers.isAsset(next) ? next : null;
      _emojiPop = _emoji != null;
      _animateEmojiSlot = true;
    });
    if (_emoji != null) return;
    Future<void>.delayed(DayStickerImage.popDuration, () {
      if (!mounted || _emoji != null) return;
      setState(() => _animateEmojiSlot = false);
    });
  }

  Future<void> _open([LedgerEntry? entry]) async {
    LedgerEntry? initial = entry;
    if (entry != null) {
      final all = await AppScope.of(context).getLedgers();
      for (final item in all) {
        if (item.id == entry.id) {
          initial = item;
          break;
        }
      }
      if (!mounted) return;
    }
    final saved = await showLedgerSheet(
      context,
      date: widget.date,
      initial: initial,
    );
    if (saved && mounted) await _reload(animate: entry == null);
  }

  Future<bool> _confirmDelete(LedgerEntry entry) async {
    final confirmed = await showDeleteEventDialog(
      context,
      title: entry.title.trim().isEmpty
          ? entry.displayCategoryName
          : entry.title,
      body: LedgerSalaryRepeat.isRepeating(entry)
          ? AppStrings.deleteLedgerRepeatBody
          : AppStrings.deleteLedgerBody,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteLedger(entry.id);
    await _reload();
    return true;
  }

  bool _sameGroup(LedgerEntry dragged, _ListEntry item) {
    final entry = item.entry;
    if (entry == null) return false;
    if (!_compact) return true;
    return entry.categoryKey == dragged.categoryKey;
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

  double _offsetOfEntry(String id) {
    var y = 0.0;
    for (final item in _items) {
      if (item.entry?.id == id) return y;
      y += _layoutExtent(item);
    }
    return y;
  }

  bool _contains(GlobalKey key, Offset global) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (box.localToGlobal(Offset.zero) & box.size).contains(global);
  }

  LedgerEntry? get _draggedEntry {
    final id = _draggingId;
    if (id == null) return null;
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  void _onDragStarted(LedgerEntry entry) {
    setState(() {
      _draggingId = entry.id;
      _draggingOutside = false;
    });
  }

  void _onDragUpdate(Offset global) {
    final dragged = _draggedEntry;
    if (dragged == null) return;

    if (!_draggingOutside) {
      final insideDialog = _contains(_dialogKey, global);
      final insideList = insideDialog && _contains(_listBoxKey, global);
      if (insideList) {
        CalendarDayDropTarget.clear();
        final box =
            _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        _moveInGroup(
          dragged,
          _groupIndexAt(box.globalToLocal(global).dy, dragged),
        );
        return;
      }
      if (insideDialog) {
        CalendarDayDropTarget.clear();
        return;
      }
      if (LedgerSalaryRepeat.isRepeating(dragged)) {
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

  Future<void> _onDragEnded() async {
    final entry = _draggedEntry;
    final dropDate = CalendarDayDropTarget.highlighted.value;
    final shouldSaveOrder = _draggingId != null;
    final moving =
        entry != null &&
        !LedgerSalaryRepeat.isRepeating(entry) &&
        dropDate != null &&
        !CalendarDayDropTarget.isSameDay(dropDate, widget.date);
    CalendarDayDropTarget.clear();
    if (!moving) CalendarDayDropTarget.setScrimHidden(false);
    if (!mounted) return;
    setState(() {
      _draggingId = null;
      _draggingOutside = false;
    });
    if (moving) {
      await _moveToDate(entry, dropDate);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (shouldSaveOrder) await _persistOrder();
  }

  Future<void> _moveToDate(LedgerEntry entry, DateTime date) async {
    var original = entry;
    final all = await AppScope.of(context).getLedgers();
    for (final item in all) {
      if (item.id == entry.id) {
        original = item;
        break;
      }
    }
    if (!mounted) return;
    await AppScope.of(context).saveLedger(
      original.copyWith(date: DateTime(date.year, date.month, date.day)),
    );
  }

  int _groupIndexAt(double y, LedgerEntry dragged) {
    final group = [
      for (final item in _items)
        if (_sameGroup(dragged, item)) item.entry!,
    ];
    if (group.isEmpty) return 0;
    final from = group.indexWhere((entry) => entry.id == dragged.id);
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
      final top = _offsetOfEntry(dragged.id);
      if (y >= top - _eventExtent * 0.18 && y < top + _eventExtent * 1.18) {
        return from;
      }
    }
    return closest;
  }

  void _moveInGroup(LedgerEntry dragged, int to) {
    final group = [
      for (final entry in _entries)
        if (!_compact || entry.categoryKey == dragged.categoryKey) entry,
    ];
    final from = group.indexWhere((entry) => entry.id == dragged.id);
    if (from < 0 || to < 0 || from == to) return;
    final nextTo = to.clamp(0, group.length - 1);
    if (from == nextTo) return;
    final moved = group.removeAt(from);
    group.insert(nextTo, moved);

    if (_compact) {
      var gi = 0;
      final ids = {for (final entry in group) entry.id};
      for (var i = 0; i < _entries.length; i++) {
        if (!ids.contains(_entries[i].id)) continue;
        _entries[i] = group[gi++];
      }
    } else {
      _entries
        ..clear()
        ..addAll(group);
    }

    setState(() => _items = _itemsForView);
    HapticFeedback.selectionClick();
  }

  Future<void> _persistOrder() async {
    if (!mounted) return;
    final all = await AppScope.of(context).getLedgers();
    if (!mounted) return;
    final byId = {for (final entry in all) entry.id: entry};
    for (var i = 0; i < _entries.length; i++) {
      final original = byId[_entries[i].id];
      if (original == null || original.sortOrder == i) continue;
      await AppScope.of(context).saveLedger(original.copyWith(sortOrder: i));
      if (!mounted) return;
    }
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
                            AppBarPill(
                              asset: AppIcons.emoji,
                              label: AppStrings.emojiAction,
                              onPressed: _pickEmoji,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Expanded(child: _buildList()),
                        ClipRect(
                          child: SizeTransition(
                            sizeFactor: _statsFade,
                            axisAlignment: -1,
                            child: FadeTransition(
                              opacity: _statsFade,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  right: 8,
                                ),
                                child: LedgerKindStats(
                                  consumption: _statsConsumption,
                                  expense: _statsExpense,
                                  salary: _statsSalary,
                                  net: _statsNet,
                                  showSalary: _statsShowSalary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AddEventButton(
                            label: AppStrings.addLedger,
                            onPressed: () => _open(),
                          ),
                        ),
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
      ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

    final entry = item.entry!;
    final title = entry.title.trim().isEmpty
        ? entry.displayCategoryName
        : entry.title.trim();
    final subtitle = entry.listSubtitle(showKind: _showKind);
    final label = DayEventLabel(
      title: title,
      categoryName: subtitle,
      color: _labelColor(entry),
      showCategory: subtitle.isNotEmpty,
      memo: entry.memo,
      trailingText: '${entry.signedLabel}원',
      isRepeat: LedgerSalaryRepeat.isRepeating(entry),
      showAccent: false,
      height: _labelHeight,
      onPressed: () => _open(entry),
    );
    final body = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwipeToDelete(
        onSwipeLeft: () => _confirmDelete(entry),
        child: label,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return LongPressDraggable<String>(
          data: entry.id,
          delay: const Duration(milliseconds: 400),
          hapticFeedbackOnStart: true,
          rootOverlay: true,
          maxSimultaneousDrags: 1,
          onDragStarted: () => _onDragStarted(entry),
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
                    title: title,
                    categoryName: subtitle,
                    color: _labelColor(entry),
                    showCategory: subtitle.isNotEmpty,
                    memo: entry.memo,
                    trailingText: '${entry.signedLabel}원',
                    isRepeat: LedgerSalaryRepeat.isRepeating(entry),
                    showAccent: false,
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
  const _ListEntry.entry(this.entry)
    : headerKey = null,
      headerName = null,
      headerColor = null,
      showTopGap = false;

  const _ListEntry.header({
    required String key,
    required String name,
    required Color color,
    this.showTopGap = false,
  }) : entry = null,
       headerKey = key,
       headerName = name,
       headerColor = color;

  final LedgerEntry? entry;
  final String? headerKey;
  final String? headerName;
  final Color? headerColor;
  final bool showTopGap;

  bool get isHeader => entry == null;

  String get id => entry != null ? 'e:${entry!.id}' : 'h:$headerKey';
}
