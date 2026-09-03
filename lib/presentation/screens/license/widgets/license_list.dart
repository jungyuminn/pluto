import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/swipe_to_delete.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/license/widgets/add_license_button.dart';
import 'package:pluto/presentation/screens/license/widgets/license_card.dart';

class LicenseList extends StatefulWidget {
  const LicenseList({
    super.key,
    required this.licenses,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
    this.onReordered,
    this.onReorderLocked,
    this.canReorder = true,
    this.compact = false,
    this.showExpired = true,
    this.categoryView = false,
    this.categories = const [],
    this.paddingTop = 0,
  });

  final List<License> licenses;
  final VoidCallback onAdd;
  final ValueChanged<License> onOpen;
  final Future<bool> Function(License license) onDelete;
  final ValueChanged<List<License>>? onReordered;
  final VoidCallback? onReorderLocked;
  final bool canReorder;
  final bool compact;
  final bool showExpired;
  final bool categoryView;
  final List<EventCategory> categories;
  final double paddingTop;

  @override
  State<LicenseList> createState() => _LicenseListState();
}

class _LicenseListState extends State<LicenseList>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listBoxKey = GlobalKey();
  final _heights = <String, double>{};
  late final _items = List.of(widget.licenses);
  late final AnimationController _expiredReveal;
  late final CurvedAnimation _expiredFade;
  final _entering = <String>{};
  var _ready = false;
  String? _draggingId;
  var _dragY = 0.0;
  double? _grabOffset;

  static const _slotAnim = Duration(milliseconds: 280);

  double get _gap => widget.compact ? 10 : 12;

  @override
  void initState() {
    super.initState();
    _expiredReveal = AnimationController(
      vsync: this,
      duration: _slotAnim,
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.showExpired ? 1 : 0,
    );
    _expiredFade = CurvedAnimation(
      parent: _expiredReveal,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (_items.isEmpty) _ready = true;
  }

  @override
  void didUpdateWidget(LicenseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showExpired != widget.showExpired) {
      if (widget.showExpired) {
        _expiredReveal.forward();
      } else {
        _expiredReveal.reverse();
      }
    }
    _sync(widget.licenses);
  }

  @override
  void dispose() {
    _expiredFade.dispose();
    _expiredReveal.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _sync(List<License> next) {
    if (_draggingId != null) return;
    final oldIds = [for (final item in _items) item.id];
    final arriving = [
      for (final item in next)
        if (!oldIds.contains(item.id)) item.id,
    ];
    final inserted = arriving.isNotEmpty;
    final active = [for (final item in next) if (!item.isExpired()) item];
    final expired = [for (final item in next) if (item.isExpired()) item];
    _entering.addAll(arriving);
    _items
      ..clear()
      ..addAll([...active, ...expired]);
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

  double _heightOf(License license) {
    return _heights[license.id] ??
        (widget.compact ? LicenseCard.compactHeight : 88);
  }

  double _blockHeight(License license) => _heightOf(license) + _gap;

  double _sectionHeight(List<License> items) {
    var y = 0.0;
    for (final item in items) {
      y += _blockHeight(item);
    }
    return y;
  }

  List<double> _tops(List<License> items) {
    final tops = <double>[];
    var y = 0.0;
    for (final item in items) {
      tops.add(y);
      y += _blockHeight(item);
    }
    return tops;
  }

  double _topAmong(List<License> items, String id) {
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
    setState(() {
      _heights[id] = height;
      if (!_ready && _allMeasured) _ready = true;
    });
  }

  List<License> get _activeItems {
    return [for (final item in _items) if (!item.isExpired()) item];
  }

  List<License> get _expiredItems {
    return [for (final item in _items) if (item.isExpired()) item];
  }

  List<_LicenseSection> _sectionsOf(List<License> items) {
    final groups = <String, List<License>>{};
    for (final item in items) {
      groups.putIfAbsent(item.categoryKey, () => []).add(item);
    }
    final sections = <_LicenseSection>[];
    final used = <String>{};
    for (final category in widget.categories) {
      final grouped = groups[category.id];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(category.id);
      sections.add(
        _LicenseSection(
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
        _LicenseSection(
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

  void _onDragStarted(License license) {
    setState(() {
      _draggingId = license.id;
      _dragY = _topAmong(_activeItems, license.id);
      _grabOffset = null;
    });
  }

  void _onDragUpdate(Offset global) {
    final dragged = _draggedItem;
    if (dragged == null || dragged.isExpired()) return;
    final box = _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final localY = box.globalToLocal(global).dy;
    _grabOffset ??= localY - _dragY;
    final height = _heightOf(dragged);
    final maxTop = math.max(0.0, _sectionHeight(_activeItems) - height);
    final nextY = (localY - _grabOffset!).clamp(0.0, maxTop);
    final active = _activeItems;
    final expired = _expiredItems;
    final from = active.indexWhere((item) => item.id == dragged.id);
    final to = _activeIndexAt(nextY + height / 2, dragged);
    var moved = false;
    if (from >= 0 && to != from) {
      final next = [...active];
      final item = next.removeAt(from);
      next.insert(to.clamp(0, next.length), item);
      _items
        ..clear()
        ..addAll([...next, ...expired]);
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

  License? get _draggedItem {
    final id = _draggingId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  int _activeIndexAt(double y, License dragged) {
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

  Future<void> _explainExpiredLock() {
    HapticFeedback.lightImpact();
    return showMissingFieldsDialog(
      context,
      title: AppStrings.timeSortLockTitle,
      body: AppStrings.expiredReorderLockBody,
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
          padding: EdgeInsets.fromLTRB(20, widget.paddingTop, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildList()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverToBoxAdapter(
            child: AddLicenseButton(onPressed: widget.onAdd),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) return const SizedBox.shrink();
    final active = _activeItems;
    final expired = _expiredItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty)
          if (widget.categoryView)
            _grouped(active)
          else
            _stack(items: active, boxKey: _listBoxKey, clip: true),
        if (expired.isNotEmpty)
          SizeTransition(
            sizeFactor: _expiredFade,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _expiredFade,
              child: IgnorePointer(
                ignoring: !widget.showExpired,
                child: _stack(items: expired, clip: false),
              ),
            ),
          ),
      ],
    );
  }

  Widget _grouped(List<License> items) {
    final sections = _sectionsOf(items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sections[i].color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sections[i].name,
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
          _stack(items: sections[i].items, clip: true),
        ],
      ],
    );
  }

  Widget _stack({
    required List<License> items,
    Key? boxKey,
    required bool clip,
  }) {
    final tops = _tops(items);
    return AnimatedSize(
      duration: _ready ? _slotAnim : Duration.zero,
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

  Widget _positioned(License license, double slotTop) {
    final dragging = _draggingId == license.id;
    return AnimatedPositioned(
      key: ValueKey(license.id),
      duration: dragging || !_ready ? Duration.zero : _slotAnim,
      curve: Curves.easeOutCubic,
      top: dragging ? _dragY : slotTop,
      left: 0,
      right: 0,
      child: _MeasureHeight(
        onHeight: (height) => _setHeight(license.id, height),
        child: Transform.scale(
          scale: dragging ? 1.03 : 1,
          child: _tile(license),
        ),
      ),
    );
  }

  Widget _tile(License license) {
    final expired = license.isExpired();
    final canDrag = widget.canReorder && !expired;
    final card = SwipeToDelete(
      onSwipeLeft: () => widget.onDelete(license),
      child: LicenseCard(
        license: license,
        onPressed: () => widget.onOpen(license),
        onLongPressed: expired
            ? _explainExpiredLock
            : (canDrag ? null : widget.onReorderLocked),
        compact: widget.compact,
      ),
    );
    final entering = _entering.contains(license.id)
        ? TweenAnimationBuilder<double>(
            key: ValueKey('enter-${license.id}'),
            tween: Tween(begin: 0, end: 1),
            duration: _slotAnim,
            curve: Curves.easeOutCubic,
            onEnd: () {
              if (!mounted) return;
              setState(() => _entering.remove(license.id));
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
      data: license.id,
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      rootOverlay: true,
      maxSimultaneousDrags: 1,
      onDragStarted: () => _onDragStarted(license),
      onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
      onDragEnd: (_) => _onDragEnded(),
      feedback: const SizedBox.shrink(),
      childWhenDragging: entering,
      child: entering,
    );
  }
}

class _LicenseSection {
  const _LicenseSection({
    required this.name,
    required this.color,
    required this.items,
  });

  final String name;
  final Color color;
  final List<License> items;
}

class _MeasureHeight extends StatefulWidget {
  const _MeasureHeight({required this.onHeight, required this.child});

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
