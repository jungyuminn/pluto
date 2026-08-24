import 'dart:async';

import 'package:flutter/material.dart';

/// 화면 공통으로 쓰는 페이드 인 등장 효과.
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 12),
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    void start() {
      if (mounted) _controller.forward();
    }

    if (widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    } else {
      _startTimer = Timer(widget.delay, start);
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          return Transform.translate(offset: _slide.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
