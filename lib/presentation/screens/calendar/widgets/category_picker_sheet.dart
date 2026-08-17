import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_category_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';

Future<EventCategory?> showCategoryPickerSheet(
  BuildContext context, {
  String? selectedId,
  bool startModifying = false,
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
    builder: (context) => CategoryPickerSheet(
      selectedId: selectedId,
      startModifying: startModifying,
    ),
  );
}

class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    this.selectedId,
    this.startModifying = false,
  });

  final String? selectedId;
  final bool startModifying;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet>
    with SingleTickerProviderStateMixin {
  var _categories = <EventCategory>[];
  var _loading = true;
  var _editing = false;
  String? _draggingId;
  final _marked = <String>{};
  final _gridKey = GlobalKey();
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
    _jiggle.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final categories = await AppScope.of(context).getEventCategories();
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _categories = categories;
          _loading = false;
        });
        return;
      }
      _syncGrid(categories);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _syncGrid(List<EventCategory> next) {
    setState(() {
      _categories = List.of(next);
      _marked.removeWhere(
        (id) => _categories.every((category) => category.id != id),
      );
    });
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
    Navigator.of(context).pop(category);
  }

  Future<void> _editCategory(EventCategory category) async {
    final saved = await showAddCategorySheet(context, initial: category);
    if (saved && mounted) await _reload();
  }

  Future<void> _editMarked() async {
    if (_marked.length > 1) {
      await showMissingFieldsDialog(
        context,
        title: AppStrings.editOneCategoryTitle,
        body: AppStrings.editOneCategoryBody,
      );
      return;
    }
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
    final created = await showAddCategorySheet(context);
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
    await AppScope.of(context).deleteEventCategory(_marked);
    if (!mounted) return;
    await _reload();
    if (_categories.isEmpty) {
      _exitEdit();
    }
  }

  void _onDragStarted(EventCategory category) {
    setState(() => _draggingId = category.id);
  }

  void _onDragUpdate(Offset global) {
    if (_draggingId == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveToIndex(_indexAt(box.globalToLocal(global), box.size));
  }

  void _onDragEnded() {
    final shouldSave = _draggingId != null;
    setState(() => _draggingId = null);
    if (shouldSave) _persistOrder();
  }

  double _cellSize(double width) {
    return (width - _gap * (_columns - 1)) / _columns;
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
    await AppScope.of(context).reorderEventCategories(List.of(_categories));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final colors = AppColors.of(context);

    return PopScope(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_editing) _exitEdit();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
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
                      _headerButton(
                        label: _editing
                            ? AppStrings.delete
                            : AppStrings.edit,
                        color: _editing ? colors.danger : colors.accent,
                        pressedColor: _editing
                            ? colors.tint(colors.danger, 0.22)
                            : colors.rangeFill,
                        onPressed: _editing ? _deleteMarked : _toggleEdit,
                      ),
                      Expanded(
                        child: Center(
                          child: _editing
                              ? _headerButton(
                                  label: AppStrings.done,
                                  color: colors.text,
                                  pressedColor: colors.pressed,
                                  onPressed: _exitEdit,
                                )
                              : Text(
                                  AppStrings.categoryAction,
                                  style: TextStyle(
                                    fontFamily: AppFonts.pretendard,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: colors.text,
                                  ),
                                ),
                        ),
                      ),
                      _headerButton(
                        label: _editing
                            ? AppStrings.modify
                            : AppStrings.addCategory,
                        color: colors.accent,
                        pressedColor: colors.rangeFill,
                        onPressed: _editing ? _editMarked : _add,
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

  Widget _headerButton({
    required String label,
    required Color color,
    required Color pressedColor,
    required VoidCallback onPressed,
  }) {
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.96,
      color: Colors.transparent,
      pressedColor: pressedColor,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
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
                  child: _slot(_categories[i], cell),
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
      enabled: _editing && _draggingId != category.id,
      child: LongPressDraggable<String>(
        data: category.id,
        delay: const Duration(milliseconds: 400),
        hapticFeedbackOnStart: true,
        rootOverlay: true,
        maxSimultaneousDrags: 1,
        onDragStarted: () => _onDragStarted(category),
        onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
        onDragEnd: (_) => _onDragEnded(),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: cell,
            height: cell,
            child: Transform.scale(
              scale: 1.06,
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
                child: _card(category, interactive: false),
              ),
            ),
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
                      fontFamily: AppFonts.pretendard,
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
