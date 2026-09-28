import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class PcLayout {
  PcLayout._();

  static bool get isPc => kIsWeb;

  static const homeCardWidth = 520.0;
  static const navLift = 20.0;
  static const contentMaxWidth = homeCardWidth + 32;
  static const dayDialogWidth = 260.0;
  static const pcDayDialogWidth = 360.0;
  static const pcAddEventWidth = 560.0;
  static const pcDiaryWidth = 640.0;
  static const dayLabelHeight = 52.0;
  static const pcDayLabelHeight = 56.0;
  static const compactWidth = 720.0;
  static const tabletShortestSide = 600.0;

  static bool isWideOf(BuildContext context) {
    if (isPc) return true;
    return MediaQuery.sizeOf(context).shortestSide >= tabletShortestSide;
  }

  static BorderRadius sheetRadius() => isPc
      ? BorderRadius.circular(24)
      : const BorderRadius.vertical(top: Radius.circular(24));

  static List<BoxShadow>? sheetLift() => isPc
      ? null
      : const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ];

  static bool showCalendarArrowsOf(double width) =>
      isPc && width >= compactWidth;

  static double dayDialogWidthOf(BuildContext context) =>
      isWideOf(context) ? pcDayDialogWidth : dayDialogWidth;

  static double dayDialogHeightOf(BuildContext context, double screenHeight) {
    if (isWideOf(context)) {
      final maxH = math.min(640.0, screenHeight * 0.82);
      final minH = math.min(520.0, screenHeight * 0.62);
      return (screenHeight * 0.68).clamp(minH, maxH).toDouble();
    }
    final maxH = math.min(530.0, screenHeight * 0.82);
    final minH = math.min(420.0, screenHeight * 0.52);
    return (screenHeight * 0.56).clamp(minH, maxH).toDouble();
  }

  static double dayLabelHeightOf() =>
      isPc ? pcDayLabelHeight : dayLabelHeight;

  static double dayLabelExtentOf() => dayLabelHeightOf() + 10;

  static Widget constrainWidth(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isWideOf(context)) return child;
        final aligned = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: child,
          ),
        );
        if (isPc) return _PcGutterScroll(child: aligned);
        final side =
            ((constraints.maxWidth - contentMaxWidth) / 2).clamp(0.0, double.infinity);
        return _PadGutterScroll(side: side, child: aligned);
      },
    );
  }

  static Widget pinBottomToast({
    required double bottom,
    required Widget child,
    double side = 24,
  }) {
    return _pinToast(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.fromLTRB(side, 0, side, bottom),
      child: child,
    );
  }

  static Widget pinTopToast({
    required double top,
    required Widget child,
    double side = 24,
  }) {
    return _pinToast(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.fromLTRB(side, top, side, 0),
      child: child,
    );
  }

  static Widget _pinToast({
    required Alignment alignment,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isPc ? contentMaxWidth : double.infinity,
            ),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}

class _PcGutterScroll extends StatelessWidget {
  const _PcGutterScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        GestureBinding.instance.pointerSignalResolver.register(event, (event) {
          _scrollVertical(context, (event as PointerScrollEvent).scrollDelta.dy);
        });
      },
      child: child,
    );
  }

  static void _scrollVertical(BuildContext context, double delta) {
    ScrollableState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        final position = state.position;
        if (position.axis == Axis.vertical &&
            position.hasPixels &&
            position.maxScrollExtent > position.minScrollExtent) {
          found = state;
          return;
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    found?.position.pointerScroll(delta);
  }
}

class _PadGutterScroll extends StatefulWidget {
  const _PadGutterScroll({required this.child, required this.side});

  final Widget child;
  final double side;

  @override
  State<_PadGutterScroll> createState() => _PadGutterScrollState();
}

class _PadGutterScrollState extends State<_PadGutterScroll> {
  Drag? _drag;
  ScrollHoldController? _hold;

  ScrollPosition? _position() {
    ScrollPosition? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        if (position.axis == Axis.vertical &&
            position.hasPixels &&
            position.maxScrollExtent > position.minScrollExtent) {
          found = position;
          return;
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  void _dragStart(DragStartDetails details) {
    final position = _position();
    if (position == null) return;
    _hold?.cancel();
    _drag?.cancel();
    _hold = position.hold(() {});
    _drag = position.drag(details, () {
      _drag = null;
      _hold = null;
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    _drag?.update(details);
  }

  void _dragEnd(DragEndDetails details) {
    _drag?.end(details);
    _drag = null;
    _hold = null;
  }

  void _dragCancel() {
    _drag?.cancel();
    _hold?.cancel();
    _drag = null;
    _hold = null;
  }

  @override
  void dispose() {
    _dragCancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget gutter() {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _dragStart,
        onVerticalDragUpdate: _dragUpdate,
        onVerticalDragEnd: _dragEnd,
        onVerticalDragCancel: _dragCancel,
      );
    }

    return Stack(
      children: [
        widget.child,
        if (widget.side > 0) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: widget.side,
            child: gutter(),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: widget.side,
            child: gutter(),
          ),
        ],
      ],
    );
  }
}

