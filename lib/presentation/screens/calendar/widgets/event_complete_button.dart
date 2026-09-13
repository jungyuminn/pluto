import 'dart:math' as math;

import 'package:flutter/material.dart';

class EventCompleteButton extends StatefulWidget {
  const EventCompleteButton({
    super.key,
    required this.completed,
    required this.color,
    this.onPressed,
  });

  final bool completed;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<EventCompleteButton> createState() => _EventCompleteButtonState();
}

class _EventCompleteButtonState extends State<EventCompleteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    if (widget.completed) _burst.value = 1;
  }

  @override
  void didUpdateWidget(EventCompleteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.completed && widget.completed) {
      _burst.forward();
    } else if (oldWidget.completed && !widget.completed) {
      _burst.value = 0;
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed == null
          ? null
          : () {
              if (widget.completed) {
                _burst.value = 0;
              } else {
                _burst.forward();
              }
              widget.onPressed!();
            },
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: AnimatedBuilder(
              animation: _burst,
              builder: (context, child) {
                final t = Curves.easeInOutCubic.transform(_burst.value);
                return CustomPaint(
                  painter: _CompletePainter(
                    progress: t,
                    color: widget.color,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletePainter extends CustomPainter {
  const _CompletePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkProgress = progress;
    final circleProgress = (1 - progress * 1.15).clamp(0.0, 1.0);

    if (circleProgress > 0) {
      final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width * 0.30,
      );
      final circle = Path()..addArc(rect, -math.pi / 2, 2 * math.pi);
      final metric = circle.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * circleProgress),
        paint,
      );
    }

    if (checkProgress > 0) {
      final check = Path()
        ..moveTo(size.width * 0.18, size.height * 0.52)
        ..lineTo(size.width * 0.40, size.height * 0.74)
        ..lineTo(size.width * 0.84, size.height * 0.26);
      final metric = check.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkProgress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
