import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/diary_cover.dart';
import 'package:pluto/presentation/screens/calendar/widgets/diary_cover_style.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

Future<DiaryCover?> showDiaryCoverSheet(
  BuildContext context, {
  required DiaryCover selected,
  Color color = const Color(0xFF3B82F6),
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<DiaryCover>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    builder: (context) => DiaryCoverSheet(selected: selected, color: color),
  );
}

class DiaryCoverSheet extends StatefulWidget {
  const DiaryCoverSheet({
    super.key,
    required this.selected,
    required this.color,
  });

  final DiaryCover selected;
  final Color color;

  @override
  State<DiaryCoverSheet> createState() => _DiaryCoverSheetState();
}

class _DiaryCoverSheetState extends State<DiaryCoverSheet> {
  static const _columns = 3;
  static const _gap = 10.0;
  static const _aspect = 0.72;
  static const _slotAnim = Duration(milliseconds: 240);

  final _gridKey = GlobalKey();
  var _covers = List<DiaryCover>.of(DiaryCover.values);
  var _loaded = false;
  String? _draggingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _covers = List.of(AppScope.of(context).calendarPreference.diaryCovers);
  }

  Future<void> _persist() async {
    if (!mounted) return;
    await AppScope.of(context).calendarPreference.setDiaryCoverOrder(_covers);
  }

  void _onDragStarted(DiaryCover cover) {
    HapticFeedback.mediumImpact();
    setState(() => _draggingId = cover.id);
  }

  void _onDragUpdate(Offset global) {
    if (_draggingId == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveToIndex(_indexAt(box.globalToLocal(global), box.size));
  }

  Future<void> _onDragEnded() async {
    setState(() => _draggingId = null);
    await _persist();
  }

  double _cellWidth(double width) {
    if (!width.isFinite || width <= 0) return 96;
    return ((width - _gap * (_columns - 1)) / _columns).clamp(64.0, 200.0);
  }

  double _cellHeight(double width) => _cellWidth(width) / _aspect;

  int _indexAt(Offset local, Size size) {
    if (_covers.isEmpty) return 0;
    final cellW = _cellWidth(size.width);
    final cellH = _cellHeight(size.width);
    final strideX = cellW + _gap;
    final strideY = cellH + _gap;
    if (strideX <= 0 || strideY <= 0) return 0;
    final maxRow = (_covers.length - 1) ~/ _columns;
    final from = _covers.indexWhere((cover) => cover.id == _draggingId);
    var col = (local.dx / strideX).floor().clamp(0, _columns - 1);
    var row = (local.dy / strideY).floor().clamp(0, maxRow);
    if (from >= 0) {
      final curCol = from % _columns;
      final curRow = from ~/ _columns;
      final dx = local.dx / strideX - curCol;
      final dy = local.dy / strideY - curRow;
      if (dx >= -0.18 && dx < 1.18 && dy >= -0.18 && dy < 1.18) {
        col = curCol;
        row = curRow;
      }
    }
    return (row * _columns + col).clamp(0, _covers.length - 1);
  }

  void _moveToIndex(int to) {
    final from = _covers.indexWhere((cover) => cover.id == _draggingId);
    if (from < 0 || from == to) return;
    setState(() {
      final item = _covers.removeAt(from);
      _covers.insert(to, item);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.muted.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox(width: 36, height: 4),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final raw = constraints.maxWidth;
                  final width = raw.isFinite && raw > 0
                      ? raw
                      : MediaQuery.sizeOf(context).width - 40;
                  final cellW = _cellWidth(width);
                  final cellH = _cellHeight(width);
                  final rows = math.max(1, (_covers.length / _columns).ceil());
                  final height = rows * cellH + (rows - 1) * _gap;
                  return SizedBox(
                    key: _gridKey,
                    width: width,
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < _covers.length; i++)
                          AnimatedPositioned(
                            key: ValueKey(_covers[i].id),
                            duration: _draggingId == null
                                ? Duration.zero
                                : _slotAnim,
                            curve: Curves.easeOutCubic,
                            left: (i % _columns) * (cellW + _gap),
                            top: (i ~/ _columns) * (cellH + _gap),
                            width: cellW,
                            height: cellH,
                            child: _slot(_covers[i], cellW, cellH),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slot(DiaryCover cover, double width, double height) {
    final tile = _CoverTile(
      cover: cover,
      selected: cover == widget.selected,
      accent: widget.color,
      onPressed: _draggingId == null
          ? () => Navigator.of(context).pop(cover)
          : null,
    );
    return LongPressDraggable<String>(
      data: cover.id,
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      rootOverlay: true,
      onDragStarted: () => _onDragStarted(cover),
      onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
      onDragEnd: (_) => _onDragEnded(),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: width,
          height: height,
          child: Transform.scale(scale: 1.06, child: tile),
        ),
      ),
      childWhenDragging: const SizedBox.expand(),
      child: tile,
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.cover,
    required this.selected,
    required this.accent,
    required this.onPressed,
  });

  final DiaryCover cover;
  final bool selected;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: Colors.transparent,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Expanded(
            child: Opacity(
              opacity: selected ? 1 : 0.72,
              child: DiaryCoverPreview(cover: cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DiaryCoverLook.label(cover),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? accent : colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class DiaryCoverChip extends StatelessWidget {
  const DiaryCoverChip({
    super.key,
    required this.color,
    required this.name,
    required this.onPressed,
  });

  final Color color;
  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      color: AppColors.of(context).card,
      pressedColor: AppColors.of(context).pressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: AppAssetImage(
                asset: AppIcons.diary,
                width: 20,
                height: 20,
                semanticLabel: name,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
