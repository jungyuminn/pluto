import 'package:flutter/material.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class WebCalendarArrow extends StatefulWidget {
  const WebCalendarArrow({
    super.key,
    required this.left,
    required this.onPressed,
    required this.visible,
  });

  final bool left;
  final VoidCallback onPressed;
  final bool visible;

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
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: t,
              child: child,
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
