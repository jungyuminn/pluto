import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';

class FlatSnapPicker extends StatefulWidget {
  const FlatSnapPicker({
    super.key,
    required this.itemCount,
    required this.index,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onChanged,
    this.loop = false,
    this.visibleCount = 5,
  });

  final int itemCount;
  final int index;
  final double itemExtent;
  final Widget Function(BuildContext context, int index, bool selected)
  itemBuilder;
  final ValueChanged<int> onChanged;
  final bool loop;
  final int visibleCount;

  static const loops = 10000;

  @override
  State<FlatSnapPicker> createState() => _FlatSnapPickerState();
}

class _FlatSnapPickerState extends State<FlatSnapPicker> {
  late final ScrollController _controller;
  late int _index;
  var _programmatic = false;
  var _wheel = 0.0;

  int get _count => widget.itemCount;

  int get _childCount => widget.loop ? _count * FlatSnapPicker.loops : _count;

  double get _extent => widget.itemExtent;

  int _logical(int index) => index % _count;

  int _fromOffset(double offset) {
    if (_extent <= 0) return 0;
    return (offset / _extent).round().clamp(0, _childCount - 1);
  }

  int _centered(int logical) {
    if (!widget.loop) return logical.clamp(0, _count - 1);
    final current = _controller.hasClients
        ? _fromOffset(_controller.offset)
        : _index;
    final base = current - _logical(current);
    final a = base + logical;
    final b = a - _count;
    final c = a + _count;
    final da = (a - current).abs();
    final db = (b - current).abs();
    final dc = (c - current).abs();
    if (db < da && db <= dc) return b.clamp(0, _childCount - 1);
    if (dc < da) return c.clamp(0, _childCount - 1);
    return a.clamp(0, _childCount - 1);
  }

  @override
  void initState() {
    super.initState();
    final logical = widget.index.clamp(0, math.max(_count - 1, 0)).toInt();
    _index = widget.loop
        ? (FlatSnapPicker.loops ~/ 2) * _count + logical
        : logical;
    _controller = ScrollController(initialScrollOffset: _index * _extent);
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(FlatSnapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index) return;
    final next = _centered(widget.index.clamp(0, _count - 1));
    if (_controller.hasClients && _fromOffset(_controller.offset) == next) {
      _index = next;
      return;
    }
    _animateTo(next);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final next = _fromOffset(_controller.offset);
    if (next == _index) return;
    setState(() => _index = next);
    if (_programmatic) return;
    HapticFeedback.selectionClick();
    widget.onChanged(_logical(next));
  }

  void _animateTo(int index) {
    _programmatic = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        _programmatic = false;
        return;
      }
      final target = index * _extent;
      if ((_controller.offset - target).abs() < 0.5) {
        _programmatic = false;
        if (_index != index) setState(() => _index = index);
        return;
      }
      final delta = (index - _fromOffset(_controller.offset)).abs();
      final ms = (200 + delta * 28).clamp(200, 520);
      _controller
          .animateTo(
            target,
            duration: Duration(milliseconds: ms),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
            if (mounted) _programmatic = false;
          });
    });
  }

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    widget.onChanged(_logical(index));
    _animateTo(index);
  }

  void _onWheel(PointerScrollEvent event) {
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent) return;
      if (!mounted || !_controller.hasClients) return;
      _wheel += resolved.scrollDelta.dy;
      if (_wheel.abs() < _extent * 0.35) return;
      final dir = _wheel > 0 ? 1 : -1;
      _wheel = 0;
      final next = (_index + dir).clamp(0, _childCount - 1);
      _select(next);
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = _extent * ((widget.visibleCount - 1) / 2);
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) _onWheel(event);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _programmatic = false;
          }
          return false;
        },
        child: ScrollConfiguration(
          behavior: const MouseDragScrollBehavior().copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          child: ListView.builder(
            controller: _controller,
            primary: false,
            physics: _SnapScrollPhysics(
              itemExtent: _extent,
              parent: const ClampingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(vertical: pad),
            itemExtent: _extent,
            itemCount: _childCount,
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _select(index),
                child: widget.itemBuilder(
                  context,
                  _logical(index),
                  index == _index,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  double _snap(double pixels, ScrollMetrics position) {
    final item = (pixels / itemExtent).roundToDouble();
    return (item * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final proposed = super.createBallisticSimulation(position, velocity);
    final end = proposed == null ? position.pixels : proposed.x(double.infinity);
    final target = _snap(end, position);

    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
