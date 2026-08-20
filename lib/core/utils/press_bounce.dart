import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';

/// 누를 때 살짝 들어갔다가, 손을 떼면 바운스되며 돌아오는 효과.
///
/// 손가락이 닿는 즉시 줄어들고, 아주 짧은 탭이어도 눌림이 끝난 뒤에
/// 튕겨 돌아온다. 스크롤이 이기면 탭은 취소된다.
class PressBounce extends StatefulWidget {
  const PressBounce({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPressed,
    this.pressedScale = 0.95,
    this.color = Colors.transparent,
    this.pressedColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.expand = false,
    this.alignment,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final double pressedScale;
  final Color color;
  final Color? pressedColor;
  final BorderRadius borderRadius;
  final bool expand;
  final Alignment? alignment;

  @override
  State<PressBounce> createState() => _PressBounceState();
}

class _PressBounceState extends State<PressBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  var _pressed = false;
  var _pressSeq = 0;
  Offset? _downPos;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30),
      reverseDuration: const Duration(milliseconds: 50),
    );
    _scale = Tween<double>(begin: 1, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setPressed(bool value, {bool immediate = false}) async {
    if (value) {
      if (_pressed) return;
      _pressed = true;
      if (mounted) setState(() {});
      await _controller.forward();
      return;
    }

    if (!immediate && _controller.status == AnimationStatus.forward) {
      final seq = _pressSeq;
      await _controller.forward();
      if (!mounted || seq != _pressSeq) return;
    }

    if (!_pressed && _controller.isDismissed) return;
    _pressed = false;
    if (mounted) setState(() {});
    _controller.reverse();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pressSeq++;
    _downPos = event.position;
    _setPressed(true);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final down = _downPos;
    if (down == null || !_pressed) return;
    if ((event.position - down).distance <= 18) return;
    _pressSeq++;
    _downPos = null;
    _setPressed(false, immediate: true);
  }

  void _onPointerUp(PointerUpEvent event) {
    _downPos = null;
    _setPressed(false);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pressSeq++;
    _downPos = null;
    _setPressed(false, immediate: true);
  }

  Color _pressedColorOf(BuildContext context) {
    return widget.pressedColor ?? AppColors.of(context).border;
  }

  Color _idleColor(BuildContext context) {
    if (widget.color.a == 0) {
      return _pressedColorOf(context).withValues(alpha: 0);
    }
    return widget.color;
  }

  @override
  Widget build(BuildContext context) {
    final canPress = widget.onPressed != null || widget.onLongPressed != null;
    final pressedColor = _pressedColorOf(context);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: canPress ? _onPointerDown : null,
      onPointerMove: canPress ? _onPointerMove : null,
      onPointerUp: canPress ? _onPointerUp : null,
      onPointerCancel: canPress ? _onPointerCancel : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPressed == null
            ? null
            : () {
                _pressSeq++;
                _setPressed(false, immediate: true);
                widget.onLongPressed!();
              },
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              transformHitTests: false,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: widget.expand ? double.infinity : null,
            height: widget.expand ? double.infinity : null,
            alignment: widget.expand
                ? (widget.alignment ?? Alignment.center)
                : null,
            decoration: BoxDecoration(
              color: _pressed ? pressedColor : _idleColor(context),
              borderRadius: widget.borderRadius,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
