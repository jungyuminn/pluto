import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_category_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';

Future<EventCategory?> showCategoryPickerSheet(
  BuildContext context, {
  String? selectedId,
  bool startModifying = false,
  bool selectable = true,
  CategoryKind kind = CategoryKind.event,
}) {
  return showModalBottomSheet<EventCategory>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: CategoryPickerSheet(
        selectedId: selectedId,
        startModifying: startModifying,
        selectable: selectable,
        kind: kind,
      ),
    ),
  );
}

class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    this.selectedId,
    this.startModifying = false,
    this.selectable = true,
    this.kind = CategoryKind.event,
  });

  final String? selectedId;
  final bool startModifying;
  final bool selectable;
  final CategoryKind kind;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet>
    with SingleTickerProviderStateMixin {
  var _categories = <EventCategory>[];
  var _loading = true;
  var _editing = false;
  String? _draggingId;
  List<EventCategory>? _orderBeforeDrag;
  final _marked = <String>{};
  final _gridKey = GlobalKey();
  final _sheetKey = GlobalKey();
  final _discarding = ValueNotifier(false);
  final _exiting = <String>{};
  final _appearIds = <String>{};
  final _seenIds = <String>{};
  late String? _selectedId;
  late final AnimationController _jiggle;

  static const _gridAnim = Duration(milliseconds: 220);
  static const _slotAnim = Duration(milliseconds: 240);
  static const _columns = 5;
  static const _gap = 8.0;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _jiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.startModifying) _enterEdit(null);
      _reload();
    });
  }

  @override
  void dispose() {
    _discarding.dispose();
    _jiggle.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final categories = await AppScope.of(context).fetchCategories(widget.kind);
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _categories = categories;
          _seenIds.addAll(categories.map((item) => item.id));
          _loading = false;
        });
        return;
      }
      await _applyCategories(categories);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _applyCategories(List<EventCategory> next) async {
    final nextIds = {for (final item in next) item.id};
    final removed = [
      for (final item in _categories)
        if (!nextIds.contains(item.id)) item.id,
    ];
    if (removed.isNotEmpty) {
      setState(() {
        _exiting
          ..clear()
          ..addAll(removed);
        _marked.removeWhere((id) => !nextIds.contains(id));
      });
      await Future<void>.delayed(_slotAnim + const Duration(milliseconds: 40));
      if (!mounted) return;
    }
    final added = [
      for (final item in next)
        if (!_seenIds.contains(item.id)) item.id,
    ];
    setState(() {
      _categories = List.of(next);
      _exiting.clear();
      _appearIds
        ..clear()
        ..addAll(added);
      _marked.removeWhere(
        (id) => _categories.every((category) => category.id != id),
      );
    });
    _seenIds
      ..removeAll(removed)
      ..addAll(added);
  }

  void _enterEdit(EventCategory? category) {
    if (_editing) return;
    _jiggle.repeat();
    setState(() {
      _editing = true;
      _marked.clear();
      if (category != null) {
        _marked.add(category.id);
      }
    });
  }

  void _exitEdit() {
    _jiggle
      ..stop()
      ..value = 0;
    setState(() {
      _editing = false;
      _marked.clear();
    });
  }

  void _toggleEdit() {
    if (_editing) {
      _exitEdit();
      return;
    }
    _enterEdit(null);
  }

  void _onTap(EventCategory category) {
    if (_editing) {
      setState(() {
        if (_marked.contains(category.id)) {
          _marked.remove(category.id);
        } else {
          _marked.add(category.id);
        }
      });
      return;
    }
    if (!widget.selectable) return;
    Navigator.of(context).pop(category);
  }

  Future<void> _editCategory(EventCategory category) async {
    final saved = await showAddCategorySheet(
      context,
      initial: category,
      kind: widget.kind,
    );
    if (saved && mounted) await _reload();
  }

  Future<void> _editMarked() async {
    if (_marked.length != 1) return;
    EventCategory? target;
    for (final category in _categories) {
      if (!_marked.contains(category.id)) continue;
      target = category;
      break;
    }
    if (target == null) return;
    await _editCategory(target);
  }

  Future<void> _add() async {
    final created = await showAddCategorySheet(context, kind: widget.kind);
    if (created && mounted) await _reload();
  }

  Future<void> _deleteMarked() async {
    if (_marked.isEmpty) return;
    final confirmed = await showDeleteEventDialog(
      context,
      title: '',
      message: AppStrings.deleteSelectedCategoriesBody,
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).removeCategories(widget.kind, _marked);
    if (!mounted) return;
    await _reload();
    if (_categories.isEmpty) {
      _exitEdit();
    }
  }

  void _onDragStarted(EventCategory category) {
    _discarding.value = false;
    _orderBeforeDrag = List.of(_categories);
    setState(() => _draggingId = category.id);
  }

  void _onDragUpdate(Offset global) {
    if (_draggingId == null) return;
    final outside = _isOutsideSheet(global);
    if (outside != _discarding.value) {
      _discarding.value = outside;
      setState(() {
        if (outside && _orderBeforeDrag != null) {
          _categories = List.of(_orderBeforeDrag!);
        }
      });
      HapticFeedback.mediumImpact();
    }
    if (outside) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveToIndex(_indexAt(box.globalToLocal(global), box.size));
  }

  bool _isOutsideSheet(Offset global) {
    final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final local = box.globalToLocal(global);
    final rect = Offset.zero & box.size;
    return !rect.contains(local);
  }

  Future<void> _onDragEnded() async {
    final id = _draggingId;
    final discard = _discarding.value;
    _discarding.value = false;
    setState(() => _draggingId = null);
    if (id == null) return;
    if (discard) {
      await _deleteDragged(id);
      return;
    }
    _orderBeforeDrag = null;
    await _persistOrder();
  }

  Future<void> _deleteDragged(String id) async {
    EventCategory? target;
    for (final category in _categories) {
      if (category.id == id) {
        target = category;
        break;
      }
    }
    if (target == null) return;
    final confirmed = await showDeleteEventDialog(
      context,
      title: target.name,
      body: AppStrings.deleteCategoryBody,
    );
    if (!confirmed || !mounted) {
      if (mounted) _restoreOrderBeforeDrag();
      return;
    }
    await AppScope.of(context).removeCategories(widget.kind, {id});
    _orderBeforeDrag = null;
    if (!mounted) return;
    await _reload();
    if (_categories.isEmpty && _editing) _exitEdit();
  }

  double _cellSize(double width) {
    if (!width.isFinite || width <= 0) return 48;
    return ((width - _gap * (_columns - 1)) / _columns).clamp(24.0, 200.0);
  }

  int _indexAt(Offset local, Size size) {
    if (_categories.isEmpty) return 0;
    final cell = _cellSize(size.width);
    final stride = cell + _gap;
    if (stride <= 0) return 0;
    final maxRow = (_categories.length - 1) ~/ _columns;
    final from =
        _categories.indexWhere((category) => category.id == _draggingId);
    var col = (local.dx / stride).floor().clamp(0, _columns - 1);
    var row = (local.dy / stride).floor().clamp(0, maxRow);
    if (from >= 0) {
      final curCol = from % _columns;
      final curRow = from ~/ _columns;
      final dx = local.dx / stride - curCol;
      final dy = local.dy / stride - curRow;
      if (dx >= -0.18 && dx < 1.18 && dy >= -0.18 && dy < 1.18) {
        col = curCol;
        row = curRow;
      }
    }
    return (row * _columns + col).clamp(0, _categories.length - 1);
  }

  void _moveToIndex(int to) {
    final from =
        _categories.indexWhere((category) => category.id == _draggingId);
    if (from < 0 || from == to) return;
    setState(() {
      final item = _categories.removeAt(from);
      _categories.insert(to, item);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _persistOrder() async {
    if (!mounted) return;
    await AppScope.of(context).replaceCategories(
      widget.kind,
      List.of(_categories),
    );
  }

  void _restoreOrderBeforeDrag() {
    final original = _orderBeforeDrag;
    _orderBeforeDrag = null;
    if (original == null) return;
    setState(() => _categories = List.of(original));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final colors = AppColors.of(context);

    return PopScope(
      canPop: !_editing || widget.startModifying,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_editing) _exitEdit();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AnimatedContainer(
          key: _sheetKey,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _discarding.value
                ? colors.tint(colors.danger, 0.2)
                : colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      _headerAction(
                        editing: _editing,
                        idleLabel: AppStrings.edit,
                        editLabel: AppStrings.modify,
                        idleColor: colors.accent,
                        editColor: colors.accent,
                        idlePressed: colors.rangeFill,
                        editPressed: colors.rangeFill,
                        visible: !_editing || _marked.length <= 1,
                        onPressed: _editing ? _editMarked : _toggleEdit,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            AppStrings.categoryAction,
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                      _headerAction(
                        editing: _editing,
                        idleLabel: AppStrings.addCategory,
                        editLabel: AppStrings.delete,
                        idleColor: colors.accent,
                        editColor: colors.danger,
                        idlePressed: colors.rangeFill,
                        editPressed: colors.tint(colors.danger, 0.22),
                        onPressed: _editing ? _deleteMarked : _add,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                    ),
                    child: AnimatedSize(
                      duration: _gridAnim,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        physics: _draggingId == null
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: _buildGrid(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerAction({
    required bool editing,
    required String idleLabel,
    required String editLabel,
    required Color idleColor,
    required Color editColor,
    required Color idlePressed,
    required Color editPressed,
    required VoidCallback onPressed,
    bool visible = true,
  }) {
    final label = editing ? editLabel : idleLabel;
    final color = editing ? editColor : idleColor;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      opacity: visible ? 1 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
        scale: visible ? 1 : 0.4,
        child: IgnorePointer(
          ignoring: !visible,
          child: PressBounce(
            onPressed: onPressed,
            pressedScale: 0.96,
            color: Colors.transparent,
            pressedColor: editing ? editPressed : idlePressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  layoutBuilder: (current, previous) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ...previous,
                        if (current != null) current,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.45, 1, curve: Curves.easeOut),
                        reverseCurve: const Interval(0, 0.4, curve: Curves.easeIn),
                      ),
                      child: child,
                    );
                  },
                  child: Text(label, key: ValueKey(label)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final raw = constraints.maxWidth;
        final width = raw.isFinite && raw > 0
            ? raw
            : MediaQuery.sizeOf(context).width - 40;
        final cell = _cellSize(width);
        final rows = math.max(1, (_categories.length / _columns).ceil());
        final height = rows * cell + (rows - 1) * _gap;
        return SizedBox(
          key: _gridKey,
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _categories.length; i++)
                AnimatedPositioned(
                  key: ValueKey(_categories[i].id),
                  duration: _slotAnim,
                  curve: Curves.easeOutCubic,
                  left: (i % _columns) * (cell + _gap),
                  top: (i ~/ _columns) * (cell + _gap),
                  width: cell,
                  height: cell,
                  child: _GridTile(
                    appear: _appearIds.contains(_categories[i].id),
                    exiting: _exiting.contains(_categories[i].id),
                    duration: _slotAnim,
                    child: _slot(_categories[i], cell),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _slot(EventCategory category, double cell) {
    return _Jiggle(
      animation: _jiggle,
      phase: category.id.hashCode * 0.17,
      enabled: _editing &&
          _draggingId != category.id &&
          !_exiting.contains(category.id),
      child: LongPressDraggable<String>(
        data: category.id,
        delay: const Duration(milliseconds: 400),
        hapticFeedbackOnStart: true,
        rootOverlay: true,
        maxSimultaneousDrags: _exiting.contains(category.id) ? 0 : 1,
        onDragStarted: () => _onDragStarted(category),
        onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
        onDragEnd: (_) => _onDragEnded(),
        feedback: Material(
          color: Colors.transparent,
          child: ValueListenableBuilder<bool>(
            valueListenable: _discarding,
            builder: (context, discarding, child) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                scale: discarding ? 0.86 : 1.06,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: discarding ? 0.72 : 1,
                  child: SizedBox(
                    width: cell,
                    height: cell,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: discarding
                                ? const Color(0x66EF4444)
                                : const Color(0x33000000),
                            blurRadius: discarding ? 16 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _card(category, interactive: false),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        childWhenDragging: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.of(context).pressed,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: _card(category),
      ),
    );
  }

  Widget _card(
    EventCategory category, {
    bool forceMarked = false,
    bool interactive = true,
  }) {
    final marked = forceMarked || _marked.contains(category.id);
    return _CategoryCard(
      category: category,
      selected: _editing ? marked : category.id == _selectedId,
      editing: _editing || forceMarked,
      marked: _editing && marked,
      onPressed: interactive ? () => _onTap(category) : null,
    );
  }
}

class _GridTile extends StatefulWidget {
  const _GridTile({
    required this.appear,
    required this.exiting,
    required this.duration,
    required this.child,
  });

  final bool appear;
  final bool exiting;
  final Duration duration;
  final Widget child;

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  late var _shown = !widget.appear;

  @override
  void initState() {
    super.initState();
    if (!widget.appear) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _shown && !widget.exiting;
    return AnimatedOpacity(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      opacity: visible ? 1 : 0,
      child: AnimatedScale(
        duration: widget.duration,
        curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
        scale: visible ? 1 : 0.84,
        child: widget.child,
      ),
    );
  }
}

class _Jiggle extends StatelessWidget {
  const _Jiggle({
    required this.animation,
    required this.phase,
    required this.enabled,
    required this.child,
  });

  final Animation<double> animation;
  final double phase;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final angle =
            math.sin((animation.value * 2 * math.pi) + phase) * 0.045;
        return Transform.rotate(angle: angle, child: child);
      },
      child: child,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.editing,
    required this.marked,
    this.onPressed,
  });

  final EventCategory category;
  final bool selected;
  final bool editing;
  final bool marked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      expand: true,
      color: selected
          ? Color.lerp(colors.card, category.tint, 0.18)!
          : colors.background,
      pressedColor: Color.lerp(colors.card, category.tint, 0.28)!,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: category.tint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      leadingDistribution: TextLeadingDistribution.even,
                      color: selected
                          ? category.tint
                          : colors.text,
                    ),
                  ),
                ],
              ),
            ),
            if (editing)
              Positioned(
                top: 4,
                right: 4,
                child: _SelectMark(marked: marked),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.marked});

  final bool marked;

  static const _size = 14.0;
  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      width: _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: marked ? colors.danger : colors.card,
        shape: BoxShape.circle,
        border: Border.all(
          color: marked ? colors.danger : colors.border,
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: marked ? 1 : 0.2,
        duration: _duration,
        curve: marked ? Curves.easeOutBack : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: marked ? 1 : 0,
          duration: const Duration(milliseconds: 140),
          curve: marked ? Curves.easeOut : Curves.easeIn,
          child: const Icon(
            Icons.check,
            size: 10,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
