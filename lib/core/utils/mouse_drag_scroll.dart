import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// 웹에서 마우스로 PageView를 좌우로 넘긴다.
class MouseDragScroll extends StatefulWidget {
  const MouseDragScroll({
    super.key,
    required this.controller,
    required this.child,
    this.enabled = true,
  });

  final PageController controller;
  final Widget child;
  final bool enabled;

  @override
  State<MouseDragScroll> createState() => _MouseDragScrollState();
}

class _MouseDragScrollState extends State<MouseDragScroll> {
  double? _startPixels;

  void _onStart(DragStartDetails details) {
    if (!widget.controller.hasClients) return;
    _startPixels = widget.controller.position.pixels;
  }

  void _onUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    position.jumpTo(
      (position.pixels - details.delta.dx).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  void _onEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    _snap(details.primaryVelocity ?? 0);
  }

  void _onCancel() {
    _snap(0, cancel: true);
  }

  void _snap(double velocity, {bool cancel = false}) {
    final controller = widget.controller;
    final start = _startPixels;
    _startPixels = null;
    if (!controller.hasClients) return;
    final position = controller.position;
    final viewport = position.viewportDimension;
    if (viewport <= 0) return;
    final startPage = ((start ?? position.pixels) / viewport).round();
    final dragged = position.pixels - (start ?? position.pixels);
    var target = startPage;
    if (!cancel && (dragged.abs() >= 20 || velocity.abs() > 80)) {
      final toNext = dragged > 0 || (dragged.abs() < 20 && velocity < 0);
      target = startPage + (toNext ? 1 : -1);
    }
    final maxPage = (position.maxScrollExtent / viewport).round();
    controller.animateToPage(
      target.clamp(0, maxPage),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _WebMouseHorizontalDrag:
            GestureRecognizerFactoryWithHandlers<_WebMouseHorizontalDrag>(
              () => _WebMouseHorizontalDrag(isEnabled: () => widget.enabled),
              (instance) {
                instance
                  ..onStart = _onStart
                  ..onUpdate = _onUpdate
                  ..onEnd = _onEnd
                  ..onCancel = _onCancel;
              },
            ),
      },
      child: widget.child,
    );
  }
}

/// 웹에서 마우스로 가로 목록을 끈다.
class MouseListDragScroll extends StatefulWidget {
  const MouseListDragScroll({
    super.key,
    required this.controller,
    required this.child,
    this.enabled = true,
  });

  final ScrollController controller;
  final Widget child;
  final bool enabled;

  @override
  State<MouseListDragScroll> createState() => _MouseListDragScrollState();
}

class _MouseListDragScrollState extends State<MouseListDragScroll> {
  void _onUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    position.jumpTo(
      (position.pixels - details.delta.dx).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _WebMouseHorizontalDrag:
            GestureRecognizerFactoryWithHandlers<_WebMouseHorizontalDrag>(
          () => _WebMouseHorizontalDrag(isEnabled: () => widget.enabled),
          (instance) {
            instance.onUpdate = _onUpdate;
          },
        ),
      },
      child: widget.child,
    );
  }
}

/// 웹에서 마우스·휠로 가로 목록을 움직인다.
class MouseDragScrollBehavior extends ScrollBehavior {
  const MouseDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

class HorizontalWheelScroll extends StatelessWidget {
  const HorizontalWheelScroll({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        if (!controller.hasClients) return;
        final pos = controller.position;
        if (pos.maxScrollExtent <= pos.minScrollExtent) return;
        GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
          if (resolved is! PointerScrollEvent) return;
          if (!controller.hasClients) return;
          final current = controller.position;
          final delta = resolved.scrollDelta.dx.abs() >=
                  resolved.scrollDelta.dy.abs()
              ? resolved.scrollDelta.dx
              : resolved.scrollDelta.dy;
          final next = (current.pixels + delta).clamp(
            current.minScrollExtent,
            current.maxScrollExtent,
          );
          if (next != current.pixels) controller.jumpTo(next);
        });
      },
      child: child,
    );
  }
}

class _WebMouseHorizontalDrag extends HorizontalDragGestureRecognizer {
  _WebMouseHorizontalDrag({required this.isEnabled})
    : super(
        supportedDevices: const {
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      );

  final bool Function() isEnabled;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!isEnabled()) return false;
    return super.isPointerAllowed(event);
  }
}
