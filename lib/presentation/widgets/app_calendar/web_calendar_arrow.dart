import 'package:flutter/material.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class WebCalendarArrowHost extends StatefulWidget {
  const WebCalendarArrowHost({
    super.key,
    required this.child,
    required this.onPrevious,
    required this.onNext,
  });

  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  State<WebCalendarArrowHost> createState() => _WebCalendarArrowHostState();
}

class _WebCalendarArrowHostState extends State<WebCalendarArrowHost> {
  var _left = false;
  var _right = false;

  void _update(Offset local, Size size) {
    final left = local.dx <= WebCalendarArrow.stripWidth;
    final right = local.dx >= size.width - WebCalendarArrow.stripWidth;
    if (left == _left && right == _right) return;
    setState(() {
      _left = left;
      _right = right;
    });
  }

  void _clear() {
    if (!_left && !_right) return;
    setState(() {
      _left = false;
      _right = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = PcLayout.showCalendarArrowsOf(
      MediaQuery.sizeOf(context).width,
    );
    return MouseRegion(
      onExit: (_) => _clear(),
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        _update(event.localPosition, box.size);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: widget.child),
          if (PcLayout.isPc) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: WebCalendarArrow(
                  left: true,
                  visible: visible,
                  hovered: _left,
                  onPressed: widget.onPrevious,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: WebCalendarArrow(
                  left: false,
                  visible: visible,
                  hovered: _right,
                  onPressed: widget.onNext,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WebCalendarArrow extends StatefulWidget {
  const WebCalendarArrow({
    super.key,
    required this.left,
    required this.onPressed,
    required this.visible,
    this.hovered = false,
  });

  final bool left;
  final VoidCallback onPressed;
  final bool visible;
  final bool hovered;

  static const stripWidth = 80.0;
  static const restOpacity = 0.22;

  @override
  State<WebCalendarArrow> createState() => _WebCalendarArrowState();
}

class _WebCalendarArrowState extends State<WebCalendarArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _pop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 360),
      value: widget.visible ? 1 : 0,
    );
    _pop = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(WebCalendarArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final t = _pop.value.clamp(0.0, 1.35);
        return IgnorePointer(
          ignoring: t < 0.05,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            opacity: widget.hovered ? 1 : WebCalendarArrow.restOpacity,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: t,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Material(
        color: colors.card,
        elevation: 4,
        shadowColor: colors.shadow,
        shape: const CircleBorder(),
        child: PressBounce(
          onPressed: widget.onPressed,
          pressedScale: 0.92,
          color: colors.card,
          pressedColor: colors.pressed,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              widget.left
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 28,
              color: colors.icon,
            ),
          ),
        ),
      ),
    );
  }
}
