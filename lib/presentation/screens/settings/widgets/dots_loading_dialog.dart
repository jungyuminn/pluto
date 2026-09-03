import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class DotsLoadingDialog extends StatelessWidget {
  const DotsLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Center(child: _DotsLoader()),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(context).accentBright;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Transform.translate(
                offset: Offset(0, -4 * _bounce(i)),
                child: Opacity(
                  opacity: 0.35 + 0.65 * _bounce(i),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 10, height: 10),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _bounce(int index) {
    final t = (_controller.value - index / 3) % 1;
    return math.sin(t * math.pi).clamp(0, 1);
  }
}
