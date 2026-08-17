import 'package:flutter/material.dart';

class SwipeToDelete extends StatefulWidget {
  const SwipeToDelete({
    super.key,
    required this.onSwipeLeft,
    required this.child,
  });

  final Future<bool> Function() onSwipeLeft;
  final Widget child;

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offset;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _offset = AnimationController(
      vsync: this,
      value: 0,
      lowerBound: -800,
      upperBound: 0,
    );
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  Future<void> _snapTo(double target) {
    return _offset.animateTo(
      target,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _offset,
          builder: (context, child) {
            return ClipRect(
              clipBehavior:
                  _offset.value == 0 ? Clip.none : Clip.hardEdge,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  if (_busy) return;
                  _offset.value =
                      (_offset.value + details.delta.dx).clamp(-width, 0);
                },
                onHorizontalDragEnd: (details) async {
                  if (_busy) return;
                  final velocity = details.primaryVelocity ?? 0;
                  final shouldDelete =
                      _offset.value < -width * 0.32 || velocity < -700;
                  if (!shouldDelete) {
                    await _snapTo(0);
                    return;
                  }
                  _busy = true;
                  await _snapTo(-width);
                  final removed = await widget.onSwipeLeft();
                  if (!mounted) return;
                  if (!removed) await _snapTo(0);
                  _busy = false;
                },
                child: Transform.translate(
                  offset: Offset(_offset.value, 0),
                  child: child,
                ),
              ),
            );
          },
          child: widget.child,
        );
      },
    );
  }
}
