import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/home_memo.dart';
import 'package:pluto/presentation/screens/home/widgets/home_memo_edit_sheet.dart';

class HomeMemoCard extends StatefulWidget {
  const HomeMemoCard({
    super.key,
    required this.memos,
    required this.onChanged,
  });

  static const _gap = 8.0;
  static const _minSize = 80.0;
  static const _slotAnim = Duration(milliseconds: 240);
  static const _addKey = '__add__';

  final List<HomeMemo> memos;
  final VoidCallback onChanged;

  @override
  State<HomeMemoCard> createState() => _HomeMemoCardState();
}

class _HomeMemoCardState extends State<HomeMemoCard> {
  final _gridKey = GlobalKey();
  late var _memos = List.of(widget.memos);
  final _reveals = <String, double>{};
  String? _draggingId;
  var _size = HomeMemoCard._minSize;
  var _columns = 1;

  @override
  void initState() {
    super.initState();
    for (final memo in _memos) {
      _reveals[memo.id] = 1;
    }
  }

  @override
  void didUpdateWidget(HomeMemoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingId != null) return;
    _syncMemos(List.of(widget.memos));
  }

  void _syncMemos(List<HomeMemo> next) {
    final prevById = {for (final memo in _memos) memo.id: memo};
    final appearing = <String>[];
    for (final memo in next) {
      if (prevById.containsKey(memo.id)) {
        _reveals[memo.id] = 1;
        continue;
      }
      _reveals[memo.id] = 0;
      appearing.add(memo.id);
    }
    _memos = next;
    setState(() {});
    if (appearing.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var changed = false;
      for (final id in appearing) {
        if (_reveals[id] == 1) continue;
        _reveals[id] = 1;
        changed = true;
      }
      if (changed) setState(() {});
    });
  }

  Future<void> _open({HomeMemo? initial}) async {
    final saved = await showHomeMemoEditSheet(context, initial: initial);
    if (saved) widget.onChanged();
  }

  HomeMemo? get _dragged {
    final id = _draggingId;
    if (id == null) return null;
    for (final memo in _memos) {
      if (memo.id == id) return memo;
    }
    return null;
  }

  void _onDragStarted(HomeMemo memo) {
    setState(() => _draggingId = memo.id);
  }

  void _onDragUpdate(Offset global) {
    if (_dragged == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveTo(_indexAt(box.globalToLocal(global)));
  }

  Future<void> _onDragEnded() async {
    final shouldSave = _draggingId != null;
    setState(() => _draggingId = null);
    if (!shouldSave || !mounted) return;
    await AppScope.of(context).memoStore.reorder(_memos);
    widget.onChanged();
  }

  int _indexAt(Offset local) {
    if (_memos.isEmpty) return 0;
    final stride = _size + HomeMemoCard._gap;
    final col = (local.dx / stride).floor().clamp(0, _columns - 1);
    final row = (local.dy / stride).floor().clamp(0, 1000);
    var index = (row * _columns + col).clamp(0, _memos.length - 1);
    final from = _memos.indexWhere((memo) => memo.id == _draggingId);
    if (from < 0 || from == index) return index;
    final fromCol = from % _columns;
    final fromRow = from ~/ _columns;
    final left = fromCol * stride - _size * 0.18;
    final top = fromRow * stride - _size * 0.18;
    if (local.dx >= left &&
        local.dx < left + _size * 1.36 &&
        local.dy >= top &&
        local.dy < top + _size * 1.36) {
      return from;
    }
    return index;
  }

  void _moveTo(int to) {
    final from = _memos.indexWhere((memo) => memo.id == _draggingId);
    if (from < 0) return;
    final nextTo = to.clamp(0, _memos.length - 1);
    if (from == nextTo) return;
    final next = List<HomeMemo>.of(_memos);
    final moved = next.removeAt(from);
    next.insert(nextTo, moved);
    setState(() => _memos = next);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : HomeMemoCard._minSize;
        _columns = ((width + HomeMemoCard._gap) /
                (HomeMemoCard._minSize + HomeMemoCard._gap))
            .floor()
            .clamp(1, 6);
        _size = (width - HomeMemoCard._gap * (_columns - 1)) / _columns;
        final count = _memos.length + 1;
        final rows = (count / _columns).ceil().clamp(1, 1000);
        final height =
            rows * _size + HomeMemoCard._gap * (rows - 1);
        return AnimatedContainer(
          key: _gridKey,
          duration: HomeMemoCard._slotAnim,
          curve: Curves.easeOutCubic,
          height: height,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _memos.length; i++)
                _slot(
                  key: ValueKey(_memos[i].id),
                  index: i,
                  child: _draggableMemo(_memos[i]),
                ),
              _slot(
                key: const ValueKey(HomeMemoCard._addKey),
                index: _memos.length,
                child: _addTile(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _slot({
    required Key key,
    required int index,
    required Widget child,
  }) {
    final col = index % _columns;
    final row = index ~/ _columns;
    final stride = _size + HomeMemoCard._gap;
    return AnimatedPositioned(
      key: key,
      duration: HomeMemoCard._slotAnim,
      curve: Curves.easeOutCubic,
      left: col * stride,
      top: row * stride,
      width: _size,
      height: _size,
      child: child,
    );
  }

  Widget _draggableMemo(HomeMemo memo) {
    final reveal = _reveals[memo.id] ?? 1;
    final tile = _MemoTile(
      size: _size,
      onPressed: () => _open(initial: memo),
      child: _memoBody(memo),
    );
    return AnimatedScale(
      duration: HomeMemoCard._slotAnim,
      curve: Curves.easeOutCubic,
      scale: reveal < 1 ? 0.88 : 1,
      child: AnimatedOpacity(
        duration: HomeMemoCard._slotAnim,
        curve: Curves.easeOutCubic,
        opacity: reveal,
        child: IgnorePointer(
          ignoring: reveal < 1,
          child: LongPressDraggable<String>(
            data: memo.id,
            delay: const Duration(milliseconds: 400),
            hapticFeedbackOnStart: true,
            rootOverlay: true,
            maxSimultaneousDrags: 1,
            onDragStarted: () => _onDragStarted(memo),
            onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
            onDragEnd: (_) => _onDragEnded(),
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.03,
                child: _MemoTile(
                  size: _size,
                  child: _memoBody(memo),
                ),
              ),
            ),
            childWhenDragging: _MemoTile(
              size: _size,
              placeholder: true,
            ),
            child: tile,
          ),
        ),
      ),
    );
  }

  Widget _addTile() {
    final colors = AppColors.of(context);
    return _MemoTile(
      size: _size,
      onPressed: () => _open(),
      child: Center(
        child: Semantics(
          button: true,
          label: AppStrings.memoAdd,
          child: Text(
            '+',
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 22,
              height: 1,
              color: colors.hint,
            ),
          ),
        ),
      ),
    );
  }

  Widget _memoBody(HomeMemo memo) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          memo.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 13,
            height: 1.25,
            color: colors.text,
          ),
        ),
        if (memo.preview.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            memo.preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 11,
              height: 1.3,
              color: colors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _MemoTile extends StatelessWidget {
  const _MemoTile({
    required this.size,
    this.onPressed,
    this.child,
    this.placeholder = false,
  });

  final double size;
  final VoidCallback? onPressed;
  final Widget? child;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (placeholder) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.pressed,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(width: size, height: size),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PressBounce(
          onPressed: onPressed,
          color: colors.card,
          pressedColor: Color.lerp(colors.card, Colors.black, 0.08)!,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
