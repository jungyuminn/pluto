import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/drop_in.dart';
import 'package:pluto/core/utils/swipe_to_delete.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/presentation/screens/job/widgets/add_company_button.dart';
import 'package:pluto/presentation/screens/job/widgets/company_card.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';

class CompanyList extends StatefulWidget {
  const CompanyList({
    super.key,
    required this.applications,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
    this.onReordered,
    this.onReorderLocked,
    this.canReorder = true,
    this.compact = false,
    this.showRejected = true,
    this.categoryView = false,
    this.categories = const [],
    this.paddingTop = 0,
  });

  final List<JobApplication> applications;
  final VoidCallback onAdd;
  final ValueChanged<JobApplication> onOpen;
  final Future<bool> Function(JobApplication application) onDelete;
  final ValueChanged<List<JobApplication>>? onReordered;
  final VoidCallback? onReorderLocked;
  final bool canReorder;
  final bool compact;
  final bool showRejected;
  final bool categoryView;
  final List<EventCategory> categories;
  final double paddingTop;

  @override
  State<CompanyList> createState() => CompanyListState();
}

class CompanyListState extends State<CompanyList>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listBoxKey = GlobalKey();
  final _rejectedBoxKey = GlobalKey();
  final _heights = <String, double>{};
  late final _items = List.of(widget.applications);
  late final AnimationController _rejectedReveal;
  late final CurvedAnimation _rejectedFade;
  final _headerReveal = <String, double>{};
  final _entering = <String>{};
  String? _draggingId;
  final _drop = DropSettle();
  var _dragY = 0.0;
  double? _grabOffset;

  static const _slotAnim = Duration(milliseconds: 280);
  static const _headerLabel = 16.0;
  static const _headerBottom = 8.0;
  static const _headerTopGap = 12.0;

  double get _gap => widget.compact ? 10 : 12;

  @override
  void initState() {
    super.initState();
    _rejectedReveal = AnimationController(
      vsync: this,
      duration: _slotAnim,
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.showRejected ? 1 : 0,
    );
    _rejectedFade = CurvedAnimation(
      parent: _rejectedReveal,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(CompanyList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showRejected != widget.showRejected) {
      if (widget.showRejected) {
        _rejectedReveal.forward();
      } else {
        _rejectedReveal.reverse();
      }
    }
    _sync(widget.applications);
    _primeHeaderReveals(oldWidget.categoryView != widget.categoryView);
  }

  @override
  void dispose() {
    _rejectedFade.dispose();
    _rejectedReveal.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _sync(List<JobApplication> next) {
    if (_draggingId != null) return;
    final oldIds = [for (final item in _items) item.id];
    final arriving = [
      for (final item in next)
        if (!oldIds.contains(item.id)) item.id,
    ];
    final inserted = arriving.isNotEmpty;
    final active = [for (final item in next) if (!item.isRejected) item];
    final rejected = [for (final item in next) if (item.isRejected) item];
    _entering.addAll(arriving);
    _items
      ..clear()
      ..addAll([...active, ...rejected]);
    setState(() {});
    if (!inserted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _primeHeaderReveals(bool viewChanged) {
    if (!widget.categoryView) {
      _headerReveal.clear();
      return;
    }
    final keys = {
      for (final section in _sectionsOf(_activeItems)) section.key,
    };
    var appeared = false;
    for (final key in keys) {
      if (_headerReveal.containsKey(key)) continue;
      _headerReveal[key] = viewChanged ? 0 : 1;
      appeared = viewChanged;
    }
    _headerReveal.removeWhere((key, _) => !keys.contains(key));
    if (!appeared) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.categoryView) return;
      setState(() {
        for (final key in keys) {
          _headerReveal[key] = 1;
        }
      });
    });
  }

  bool get _allMeasured {
    for (final item in _items) {
      if (!_heights.containsKey(item.id)) return false;
    }
    return true;
  }

  double _heightOf(JobApplication application) {
    return _heights[application.id] ??
        (widget.compact ? CompanyCard.compactHeight : 88);
  }

  double _blockHeight(JobApplication application) {
    return _heightOf(application) + _gap;
  }

  double _sectionHeight(List<JobApplication> items) {
    var y = 0.0;
    for (final item in items) {
      y += _blockHeight(item);
    }
    return y;
  }

  List<double> _tops(List<JobApplication> items) {
    final tops = <double>[];
    var y = 0.0;
    for (final item in items) {
      tops.add(y);
      y += _blockHeight(item);
    }
    return tops;
  }

  double _topAmong(List<JobApplication> items, String id) {
    var y = 0.0;
    for (final item in items) {
      if (item.id == id) return y;
      y += _blockHeight(item);
    }
    return y;
  }

  void _setHeight(String id, double height) {
    final current = _heights[id];
    if (current != null && (current - height).abs() < 0.5) return;
    setState(() => _heights[id] = height);
  }

  List<JobApplication> get _activeItems {
    return [for (final item in _items) if (!item.isRejected) item];
  }

  List<JobApplication> get _rejectedItems {
    return [for (final item in _items) if (item.isRejected) item];
  }

  List<_JobSection> _sectionsOf(List<JobApplication> items) {
    final groups = <String, List<JobApplication>>{};
    for (final item in items) {
      groups.putIfAbsent(item.categoryKey, () => []).add(item);
    }
    final sections = <_JobSection>[];
    final used = <String>{};
    for (final category in widget.categories) {
      final grouped = groups[category.id];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(category.id);
      sections.add(
        _JobSection(
          key: category.id,
          name: category.name,
          color: category.tint,
          items: grouped,
        ),
      );
    }
    for (final item in items) {
      final key = item.categoryKey;
      if (used.contains(key)) continue;
      final grouped = groups[key];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(key);
      sections.add(
        _JobSection(
          key: key,
          name: item.categoryName.trim().isEmpty
              ? AppStrings.categoryAction
              : item.categoryName,
          color: item.categoryColor != null
              ? Color(item.categoryColor!)
              : AppColors.of(context).accent,
          items: grouped,
        ),
      );
    }
    return sections;
  }

  void _onDragStarted(JobApplication application) {
    final group = application.isRejected ? _rejectedItems : _activeItems;
    setState(() {
      _draggingId = application.id;
      _dragY = _topAmong(group, application.id);
      _grabOffset = null;
    });
  }

  void _onDragUpdate(Offset global) {
    final dragged = _draggedItem;
    if (dragged == null) return;
    final rejected = dragged.isRejected;
    final group = rejected ? _rejectedItems : _activeItems;
    final boxKey = rejected ? _rejectedBoxKey : _listBoxKey;
    final box = boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final localY = box.globalToLocal(global).dy;
    _grabOffset ??= localY - _dragY;
    final height = _heightOf(dragged);
    final maxTop = math.max(0.0, _sectionHeight(group) - height);
    final nextY = (localY - _grabOffset!).clamp(0.0, maxTop);

    final active = _activeItems;
    final rejectedItems = _rejectedItems;
    final from = group.indexWhere((item) => item.id == dragged.id);
    final to = _indexAt(group, nextY + height / 2, dragged);
    var moved = false;
    if (from >= 0 && to != from) {
      final next = [...group];
      final item = next.removeAt(from);
      next.insert(to.clamp(0, next.length), item);
      _items
        ..clear()
        ..addAll(rejected ? [...active, ...next] : [...next, ...rejectedItems]);
      moved = true;
    }

    setState(() => _dragY = nextY);
    if (moved) HapticFeedback.selectionClick();
  }

  double _slotTopOf(
    String id,
    List<JobApplication> items, {
    required bool grouped,
  }) {
    final slots = grouped
        ? _slotsOf(items)
        : [for (final item in items) _JobSlot.card(item)];
    var y = 0.0;
    for (final slot in slots) {
      if (slot.item?.id == id) return y;
      y += _slotHeight(slot);
    }
    return y;
  }

  void _onDragEnded() {
    final id = _draggingId;
    final item = _draggedItem;
    final rejected = item?.isRejected ?? false;
    final group = rejected ? _rejectedItems : _activeItems;
    final slotTop = id == null
        ? 0.0
        : _slotTopOf(id, group, grouped: !rejected && widget.categoryView);
    setState(() {
      _drop.arm(id, Offset(0, _dragY - slotTop));
      _draggingId = null;
      _grabOffset = null;
    });
    if (id != null) widget.onReordered?.call(List.of(_items));
  }

  JobApplication? get _draggedItem {
    final id = _draggingId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  int _indexAt(List<JobApplication> items, double y, JobApplication dragged) {
    if (items.isEmpty) return 0;
    final from = items.indexWhere((item) => item.id == dragged.id);
    var closest = 0;
    var best = double.infinity;
    var acc = 0.0;
    for (var i = 0; i < items.length; i++) {
      final height = _blockHeight(items[i]);
      final dist = (y - (acc + height / 2)).abs();
      if (dist < best) {
        best = dist;
        closest = i;
      }
      acc += height;
    }
    if (from >= 0 && closest != from) {
      final top = _topAmong(items, dragged.id);
      final extent = _blockHeight(dragged);
      if (y >= top - extent * 0.18 && y < top + extent * 1.18) {
        return from;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scroll,
      physics: _draggingId == null
          ? null
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, widget.paddingTop, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildList()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverToBoxAdapter(
            child: TutorialAnchor(
              id: TutorialAnchorId.jobAdd,
              child: AddCompanyButton(onPressed: widget.onAdd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stack(
          items: _activeItems,
          boxKey: _listBoxKey,
          clip: true,
          grouped: widget.categoryView,
        ),
        SizeTransition(
          sizeFactor: _rejectedFade,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _rejectedFade,
            child: IgnorePointer(
              ignoring: !widget.showRejected,
              child: _stack(
                items: _rejectedItems,
                boxKey: _rejectedBoxKey,
                clip: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stack({
    required List<JobApplication> items,
    Key? boxKey,
    required bool clip,
    bool grouped = false,
  }) {
    final slots = grouped
        ? _slotsOf(items)
        : [for (final item in items) _JobSlot.card(item)];
    final tops = <double>[];
    var height = 0.0;
    for (final slot in slots) {
      tops.add(height);
      height += _slotHeight(slot);
    }
    final animate = _allMeasured;
    return AnimatedSize(
      duration: animate ? _slotAnim : Duration.zero,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: boxKey,
        height: height,
        child: Stack(
          clipBehavior: clip && _drop.id == null ? Clip.hardEdge : Clip.none,
          children: [
            for (var i = 0; i < slots.length; i++)
              if (slots[i].header != null)
                _headerAt(
                  slots[i].header!,
                  tops[i],
                  first: slots[i].firstHeader,
                )
              else if (slots[i].item?.id != _draggingId)
                _positioned(slots[i].item!, tops[i]),
            if (_draggingId != null)
              for (var i = 0; i < slots.length; i++)
                if (slots[i].item?.id == _draggingId)
                  _positioned(slots[i].item!, tops[i]),
          ],
        ),
      ),
    );
  }

  List<_JobSlot> _slotsOf(List<JobApplication> items) {
    final sections = _sectionsOf(items);
    return [
      for (var i = 0; i < sections.length; i++) ...[
        _JobSlot.header(sections[i], firstHeader: i == 0),
        for (final item in sections[i].items) _JobSlot.card(item),
      ],
    ];
  }

  double _slotHeight(_JobSlot slot) {
    final header = slot.header;
    if (header == null) return _blockHeight(slot.item!);
    final reveal = _headerReveal[header.key] ?? 1;
    final gap = slot.firstHeader ? 0.0 : _headerTopGap;
    return (_headerLabel + _headerBottom + gap) * reveal;
  }

  Widget _headerAt(_JobSection section, double top, {required bool first}) {
    final reveal = _headerReveal[section.key] ?? 1;
    final gap = first ? 0.0 : _headerTopGap;
    return AnimatedPositioned(
      key: ValueKey('header-${section.key}'),
      duration: _allMeasured ? _slotAnim : Duration.zero,
      curve: Curves.easeOutCubic,
      top: top,
      left: 0,
      right: 0,
      height: (_headerLabel + _headerBottom + gap) * math.max(reveal, 0.0001),
      child: ClipRect(
        child: AnimatedOpacity(
          duration: _allMeasured ? _slotAnim : Duration.zero,
          curve: Curves.easeOutCubic,
          opacity: reveal,
          child: Padding(
            padding: EdgeInsets.only(top: gap, bottom: _headerBottom),
            child: SizedBox(
              height: _headerLabel,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: section.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      section.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
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
          ),
        ),
      ),
    );
  }

  Widget _positioned(JobApplication application, double slotTop) {
    final dragging = _draggingId == application.id;
    return AnimatedPositioned(
      key: ValueKey(application.id),
      duration: dragging || !_allMeasured ? Duration.zero : _slotAnim,
      curve: Curves.easeOutCubic,
      top: dragging ? _dragY : slotTop,
      left: 0,
      right: 0,
      child: _drop.wrap(
        itemId: application.id,
        onDone: () {
          if (!mounted || _drop.id != application.id) return;
          setState(_drop.clear);
        },
        child: _MeasureHeight(
          onHeight: (height) => _setHeight(application.id, height),
          child: Transform.scale(
            scale: dragging ? 1.03 : 1,
            child: _tile(application),
          ),
        ),
      ),
    );
  }

  Widget _tile(JobApplication application) {
    final canDrag = widget.canReorder;
    final card = SwipeToDelete(
      onSwipeLeft: () => widget.onDelete(application),
      child: CompanyCard(
        application: application,
        onPressed: () => widget.onOpen(application),
        onLongPressed: canDrag ? null : widget.onReorderLocked,
        compact: widget.compact,
      ),
    );
    final entering = _entering.contains(application.id)
        ? TweenAnimationBuilder<double>(
            key: ValueKey('enter-${application.id}'),
            tween: Tween(begin: 0, end: 1),
            duration: _slotAnim,
            curve: Curves.easeOutCubic,
            onEnd: () {
              if (!mounted) return;
              setState(() => _entering.remove(application.id));
            },
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: card,
          )
        : card;
    if (!canDrag) return entering;
    return LongPressDraggable<String>(
      data: application.id,
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      rootOverlay: true,
      maxSimultaneousDrags: 1,
      onDragStarted: () => _onDragStarted(application),
      onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
      onDragEnd: (_) => _onDragEnded(),
      feedback: const SizedBox.shrink(),
      childWhenDragging: entering,
      child: entering,
    );
  }
}

class _JobSlot {
  const _JobSlot.card(this.item)
      : header = null,
        firstHeader = false;

  const _JobSlot.header(this.header, {this.firstHeader = false}) : item = null;

  final JobApplication? item;
  final _JobSection? header;
  final bool firstHeader;
}

class _JobSection {
  const _JobSection({
    required this.key,
    required this.name,
    required this.color,
    required this.items,
  });

  final String key;
  final String name;
  final Color color;
  final List<JobApplication> items;
}

class _MeasureHeight extends StatefulWidget {
  const _MeasureHeight({
    required this.onHeight,
    required this.child,
  });

  final ValueChanged<double> onHeight;
  final Widget child;

  @override
  State<_MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<_MeasureHeight> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  void _report() {
    if (!mounted) return;
    final height = context.size?.height;
    if (height == null) return;
    widget.onHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _report());
        return true;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }
}
