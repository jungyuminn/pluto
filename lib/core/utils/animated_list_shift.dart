import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 인덱스가 바뀌면, 첫 프레임부터 예전 자리에 두고 새 자리로 미끄러진다.
class AnimatedListShift extends StatefulWidget {
  const AnimatedListShift({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
    this.axis = Axis.vertical,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final Widget child;
  final bool enabled;
  final Axis axis;
  final Duration duration;

  @override
  State<AnimatedListShift> createState() => _AnimatedListShiftState();
}

class _AnimatedListShiftState extends State<AnimatedListShift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;
  final _tween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);
  late var _index = widget.index;
  double? _extent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = _tween.animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedListShift oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (!widget.enabled) {
      _controller.stop();
      _tween
        ..begin = Offset.zero
        ..end = Offset.zero;
      _index = widget.index;
      return;
    }
    if (widget.index == _index) return;
    final extent = _extent ?? 0;
    if (extent < 1) {
      _index = widget.index;
      return;
    }
    final current = _controller.isAnimating
        ? (widget.axis == Axis.vertical
            ? _animation.value.dy
            : _animation.value.dx)
        : 0.0;
    final delta = current + (_index - widget.index) * extent;
    _tween
      ..begin = widget.axis == Axis.vertical
          ? Offset(0, delta)
          : Offset(delta, 0)
      ..end = Offset.zero;
    _index = widget.index;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ExtentProbe(
      axis: widget.axis,
      onExtent: (extent) => _extent = extent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset =
              _controller.isAnimating ? _animation.value : Offset.zero;
          return Transform.translate(
            offset: offset,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _ExtentProbe extends SingleChildRenderObjectWidget {
  const _ExtentProbe({
    required this.axis,
    required this.onExtent,
    required super.child,
  });

  final Axis axis;
  final ValueChanged<double> onExtent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ExtentProbeRender(axis: axis, onExtent: onExtent);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _ExtentProbeRender renderObject,
  ) {
    renderObject
      ..axis = axis
      ..onExtent = onExtent;
  }
}

class _ExtentProbeRender extends RenderProxyBox {
  _ExtentProbeRender({required this.axis, required this.onExtent});

  Axis axis;
  ValueChanged<double> onExtent;

  @override
  void performLayout() {
    super.performLayout();
    if (!hasSize) return;
    final extent = axis == Axis.vertical ? size.height : size.width;
    if (extent >= 1) onExtent(extent);
  }
}
