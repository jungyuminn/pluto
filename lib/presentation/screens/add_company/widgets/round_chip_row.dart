import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/domain/entities/application_round.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/presentation/screens/add_company/widgets/add_round_chip_button.dart';
import 'package:pluto/presentation/screens/add_company/widgets/round_chip_button.dart';

class RoundChipRow extends StatefulWidget {
  const RoundChipRow({
    super.key,
    required this.rounds,
    required this.accent,
    required this.onRoundChanged,
    required this.onReordered,
    required this.onAddRound,
    required this.onRemoveRound,
  });

  final List<ApplicationRound> rounds;
  final Color accent;
  final void Function(int index, ApplicationRound round) onRoundChanged;
  final ValueChanged<List<ApplicationRound>> onReordered;
  final VoidCallback onAddRound;
  final VoidCallback onRemoveRound;

  static const _columns = 4;
  static const _gap = 6.0;
  static const _anim = Duration(milliseconds: 260);
  static const _slide = Duration(milliseconds: 180);

  @override
  State<RoundChipRow> createState() => _RoundChipRowState();
}

class _RoundChipRowState extends State<RoundChipRow>
    with SingleTickerProviderStateMixin {
  final _gridKey = GlobalKey();
  late List<ApplicationRound> _shown;
  late List<int> _itemKeys;
  late int _count;
  late final AnimationController _exit;
  late final Animation<double> _hide;
  var _keySeed = 0;
  int? _emergeIndex;
  int? _exitingIndex;
  int? _draggingIndex;
  var _cellWidth = 0.0;
  var _emergeGen = 0;

  int _nextKey() => _keySeed++;

  @override
  void initState() {
    super.initState();
    _shown = [...widget.rounds];
    _itemKeys = [for (var i = 0; i < _shown.length; i++) _nextKey()];
    _count = widget.rounds.length;
    _exit = AnimationController(vsync: this, duration: RoundChipRow._anim);
    _hide = CurvedAnimation(parent: _exit, curve: Curves.easeInOutCubic);
    _exit.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      setState(() {
        _shown = [...widget.rounds];
        if (_itemKeys.length > _shown.length) {
          _itemKeys = _itemKeys.sublist(0, _shown.length);
        }
        _exitingIndex = null;
      });
      _exit.reset();
    });
  }

  @override
  void didUpdateWidget(covariant RoundChipRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.rounds.length;
    if (next > _count) {
      _exit.stop();
      _exit.reset();
      _shown = [...widget.rounds];
      while (_itemKeys.length < _shown.length) {
        _itemKeys.add(_nextKey());
      }
      _emergeIndex = next - 1;
      _exitingIndex = null;
      _draggingIndex = null;
      _count = next;
      _clearEmergeAfterAnim();
    } else if (next < _count) {
      _exit.stop();
      final ghost = _exitingIndex != null ? _shown.last : _shown[_count - 1];
      _shown = [...widget.rounds, ghost];
      _exitingIndex = next;
      _emergeIndex = null;
      _draggingIndex = null;
      _count = next;
      _exit.forward(from: 0);
    } else if (_exitingIndex != null) {
      _shown = [...widget.rounds, _shown.last];
    } else if (_draggingIndex == null) {
      _shown = [...widget.rounds];
    }
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  void _clearEmergeAfterAnim() {
    final gen = ++_emergeGen;
    Future<void>.delayed(RoundChipRow._anim, () {
      if (!mounted || gen != _emergeGen) return;
      if (_emergeIndex == null) return;
      setState(() => _emergeIndex = null);
    });
  }

  void _onDragStarted(int index) {
    _emergeIndex = null;
    setState(() => _draggingIndex = index);
  }

  void _onDragUpdate(Offset global) {
    if (_draggingIndex == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveToIndex(_indexAt(box.globalToLocal(global), box.size));
  }

  void _onDragEnded() {
    setState(() => _draggingIndex = null);
    widget.onReordered([..._shown]);
  }

  int _indexAt(Offset local, Size size) {
    final count = _shown.length;
    if (count == 0) return 0;
    final cell = _cellWidth > 0
        ? _cellWidth
        : (size.width - RoundChipRow._gap * (RoundChipRow._columns - 1)) /
              RoundChipRow._columns;
    final strideX = cell + RoundChipRow._gap;
    final strideY = RoundChipButton.height + RoundChipRow._gap;
    if (strideX <= 0 || strideY <= 0) return 0;
    final maxRow = (count - 1) ~/ RoundChipRow._columns;
    final from = _draggingIndex ?? 0;
    var col = (local.dx / strideX).floor().clamp(0, RoundChipRow._columns - 1);
    var row = (local.dy / strideY).floor().clamp(0, maxRow);
    final curCol = from % RoundChipRow._columns;
    final curRow = from ~/ RoundChipRow._columns;
    final dx = local.dx / strideX - curCol;
    final dy = local.dy / strideY - curRow;
    if (dx >= -0.18 && dx < 1.18 && dy >= -0.18 && dy < 1.18) {
      col = curCol;
      row = curRow;
    }
    return (row * RoundChipRow._columns + col).clamp(0, count - 1);
  }

  void _moveToIndex(int to) {
    final from = _draggingIndex;
    if (from == null || from == to) return;
    setState(() {
      final round = _shown.removeAt(from);
      final key = _itemKeys.removeAt(from);
      _shown.insert(to, round);
      _itemKeys.insert(to, key);
      _draggingIndex = to;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.rounds.length;
    final canAdd = count < JobApplication.maxRoundCount;
    final canRemove = count > JobApplication.minRoundCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _cellWidth =
                  (constraints.maxWidth -
                      RoundChipRow._gap * (RoundChipRow._columns - 1)) /
                  RoundChipRow._columns;
              final shown = _shown.length;
              final rows = shown == 0
                  ? 0
                  : (shown / RoundChipRow._columns).ceil();
              final height = rows == 0
                  ? 0.0
                  : rows * RoundChipButton.height +
                        (rows - 1) * RoundChipRow._gap;
              return AnimatedSize(
                duration: _draggingIndex == null
                    ? RoundChipRow._anim
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  key: _gridKey,
                  height: height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < shown; i++)
                        AnimatedPositioned(
                          key: ValueKey(_itemKeys[i]),
                          duration: _draggingIndex == null
                              ? Duration.zero
                              : RoundChipRow._slide,
                          curve: Curves.easeOutCubic,
                          left:
                              (i % RoundChipRow._columns) *
                              (_cellWidth + RoundChipRow._gap),
                          top:
                              (i ~/ RoundChipRow._columns) *
                              (RoundChipButton.height + RoundChipRow._gap),
                          width: _cellWidth,
                          height: RoundChipButton.height,
                          child: _slot(i),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: RoundChipRow._gap),
        SizedBox(
          height: RoundChipButton.height,
          child: Column(
            children: [
              AddRoundChipButton(
                enabled: canAdd,
                onPressed: widget.onAddRound,
              ),
              const SizedBox(height: RoundChipRow._gap),
              AddRoundChipButton(
                icon: Icons.remove,
                enabled: canRemove,
                onPressed: widget.onRemoveRound,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slot(int index) {
    final fromAbove = index % RoundChipRow._columns == 0;
    final exiting = _exitingIndex == index;
    final emerging = _emergeIndex == index;
    final dragging = _draggingIndex == index;
    Widget chip = RoundChipButton(
      round: _shown[index],
      accent: widget.accent,
      onChanged: exiting
          ? (_) {}
          : (round) => widget.onRoundChanged(index, round),
    );
    if (emerging && !fromAbove) {
      chip = _Reveal(
        key: ValueKey('in-$index-${_shown.length}'),
        progress: null,
        fromAbove: false,
        child: chip,
      );
    } else if (emerging && fromAbove) {
      chip = _Reveal(
        key: ValueKey('row-in-$index-${_shown.length}'),
        progress: null,
        fromAbove: true,
        child: chip,
      );
    } else if (exiting && !fromAbove) {
      chip = IgnorePointer(
        child: _Reveal(
          progress: Tween<double>(begin: 1, end: 0).animate(_hide),
          fromAbove: false,
          child: chip,
        ),
      );
    } else if (exiting && fromAbove) {
      chip = IgnorePointer(
        child: _Reveal(
          progress: Tween<double>(begin: 1, end: 0).animate(_hide),
          fromAbove: true,
          child: chip,
        ),
      );
    }
    if (exiting || emerging) return chip;
    return LongPressDraggable<int>(
      data: _itemKeys[index],
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      rootOverlay: true,
      maxSimultaneousDrags: 1,
      onDragStarted: () => _onDragStarted(index),
      onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
      onDragEnd: (_) => _onDragEnded(),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: _cellWidth,
          height: RoundChipButton.height,
          child: Transform.scale(
            scale: 1.04,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: IgnorePointer(
                child: RoundChipButton(
                  round: _shown[index],
                  accent: widget.accent,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.32,
        child: IgnorePointer(child: chip),
      ),
      child: dragging ? IgnorePointer(child: chip) : chip,
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    super.key,
    required this.fromAbove,
    required this.child,
    this.progress,
  });

  final bool fromAbove;
  final Widget child;
  final Animation<double>? progress;

  @override
  Widget build(BuildContext context) {
    final animation = progress;
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) => _paint(animation.value, child!),
        child: child,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: RoundChipRow._anim,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => _paint(t, child!),
      child: child,
    );
  }

  Widget _paint(double t, Widget child) {
    final value = t.clamp(0.0, 1.0);
    return ClipRect(
      child: Align(
        alignment: fromAbove ? Alignment.topCenter : Alignment.centerLeft,
        heightFactor: fromAbove ? value : 1,
        child: FractionalTranslation(
          translation: fromAbove ? Offset.zero : Offset(value - 1, 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        ),
      ),
    );
  }
}
