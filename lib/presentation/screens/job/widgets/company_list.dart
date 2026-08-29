import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/swipe_to_delete.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/job/widgets/add_company_button.dart';
import 'package:job_planner/presentation/screens/job/widgets/company_card.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';

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

  @override
  State<CompanyList> createState() => _CompanyListState();
}

class _CompanyListState extends State<CompanyList>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listBoxKey = GlobalKey();
  final _heights = <String, double>{};
  late final _items = List.of(widget.applications);
  late final AnimationController _rejectedReveal;
  late final CurvedAnimation _rejectedFade;
  String? _draggingId;
  var _dragY = 0.0;
  double? _grabOffset;

  static const _slotAnim = Duration(milliseconds: 280);

  double get _gap => widget.compact ? 8 : 12;

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
  }

  @override
  void dispose() {
    _rejectedFade.dispose();
    _rejectedReveal.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _sync(List<JobApplication> next) {
    if (_draggingId != null) return;
    final oldIds = [for (final item in _items) item.id];
    final inserted = next.any((item) => !oldIds.contains(item.id));
    final active = [for (final item in next) if (!item.isRejected) item];
    final rejected = [for (final item in next) if (item.isRejected) item];
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

  bool get _allMeasured {
    for (final item in _items) {
      if (!_heights.containsKey(item.id)) return false;
    }
    return true;
  }

  double _heightOf(JobApplication application) {
    return _heights[application.id] ?? (widget.compact ? 64 : 88);
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

  void _onDragStarted(JobApplication application) {
    setState(() {
      _draggingId = application.id;
      _dragY = _topAmong(_activeItems, application.id);
      _grabOffset = null;
    });
  }

  void _onDragUpdate(Offset global) {
    final dragged = _draggedItem;
    if (dragged == null || dragged.isRejected) return;
    final box = _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final localY = box.globalToLocal(global).dy;
    _grabOffset ??= localY - _dragY;
    final height = _heightOf(dragged);
    final maxTop = math.max(0.0, _sectionHeight(_activeItems) - height);
    final nextY = (localY - _grabOffset!).clamp(0.0, maxTop);

    final active = _activeItems;
    final rejected = _rejectedItems;
    final from = active.indexWhere((item) => item.id == dragged.id);
    final to = _activeIndexAt(nextY + height / 2, dragged);
    var moved = false;
    if (from >= 0 && to != from) {
      final next = [...active];
      final item = next.removeAt(from);
      next.insert(to.clamp(0, next.length), item);
      _items
        ..clear()
        ..addAll([...next, ...rejected]);
      moved = true;
    }

    setState(() => _dragY = nextY);
    if (moved) HapticFeedback.selectionClick();
  }

  void _onDragEnded() {
    final shouldSave = _draggingId != null;
    setState(() {
      _draggingId = null;
      _grabOffset = null;
    });
    if (shouldSave) widget.onReordered?.call(List.of(_items));
  }

  JobApplication? get _draggedItem {
    final id = _draggingId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  int _activeIndexAt(double y, JobApplication dragged) {
    final active = _activeItems;
    if (active.isEmpty) return 0;
    final from = active.indexWhere((item) => item.id == dragged.id);
    var closest = 0;
    var best = double.infinity;
    var acc = 0.0;
    for (var i = 0; i < active.length; i++) {
      final height = _blockHeight(active[i]);
      final dist = (y - (acc + height / 2)).abs();
      if (dist < best) {
        best = dist;
        closest = i;
      }
      acc += height;
    }
    if (from >= 0 && closest != from) {
      final top = _topAmong(active, dragged.id);
      final extent = _blockHeight(dragged);
      if (y >= top - extent * 0.18 && y < top + extent * 1.18) {
        return from;
      }
    }
    return closest;
  }

  Future<void> _explainRejectedLock() {
    HapticFeedback.lightImpact();
    return showMissingFieldsDialog(
      context,
      title: AppStrings.timeSortLockTitle,
      body: AppStrings.rejectedReorderLockBody,
    );
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
    if (_items.isEmpty) return const SizedBox.shrink();
    final active = _activeItems;
    final rejected = _rejectedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty)
          _stack(
            items: active,
            boxKey: _listBoxKey,
            clip: true,
          ),
        if (rejected.isNotEmpty)
          SizeTransition(
            sizeFactor: _rejectedFade,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _rejectedFade,
              child: IgnorePointer(
                ignoring: !widget.showRejected,
                child: _stack(
                  items: rejected,
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
  }) {
    final tops = _tops(items);
    return AnimatedSize(
      duration: _allMeasured ? _slotAnim : Duration.zero,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: boxKey,
        height: _sectionHeight(items),
        child: Stack(
          clipBehavior: clip ? Clip.hardEdge : Clip.none,
          children: [
            for (var i = 0; i < items.length; i++)
              if (items[i].id != _draggingId) _positioned(items[i], tops[i]),
            if (_draggingId != null)
              for (var i = 0; i < items.length; i++)
                if (items[i].id == _draggingId)
                  _positioned(items[i], tops[i]),
          ],
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
      child: _MeasureHeight(
        onHeight: (height) => _setHeight(application.id, height),
        child: Transform.scale(
          scale: dragging ? 1.03 : 1,
          child: _tile(application),
        ),
      ),
    );
  }

  Widget _tile(JobApplication application) {
    final rejected = application.isRejected;
    final canDrag = widget.canReorder && !rejected;
    final card = SwipeToDelete(
      onSwipeLeft: () => widget.onDelete(application),
      child: CompanyCard(
        application: application,
        onPressed: () => widget.onOpen(application),
        onLongPressed: rejected
            ? _explainRejectedLock
            : (canDrag ? null : widget.onReorderLocked),
        compact: widget.compact,
      ),
    );
    if (!canDrag) return card;
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
      childWhenDragging: card,
      child: card,
    );
  }
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
