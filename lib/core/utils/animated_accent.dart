import 'package:flutter/material.dart';

/// 액센트 색이 바뀔 때 이전 색에서 다음 색으로 보간한다.
class AnimatedAccent extends ImplicitlyAnimatedWidget {
  const AnimatedAccent({
    super.key,
    required this.color,
    required this.builder,
    super.duration = const Duration(milliseconds: 280),
    super.curve = Curves.easeOutCubic,
  });

  final Color color;
  final Widget Function(BuildContext context, Color color) builder;

  @override
  AnimatedWidgetBaseState<AnimatedAccent> createState() =>
      _AnimatedAccentState();
}

class _AnimatedAccentState extends AnimatedWidgetBaseState<AnimatedAccent> {
  ColorTween? _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = visitor(
      _color,
      widget.color,
      (value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _color?.evaluate(animation) ?? widget.color,
    );
  }
}
