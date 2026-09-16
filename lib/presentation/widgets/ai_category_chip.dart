import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class AiCategoryChip extends StatelessWidget {
  const AiCategoryChip({
    super.key,
    required this.name,
    required this.color,
    required this.onPressed,
    this.selected = true,
    this.active = false,
    this.loading = false,
  });

  final String name;
  final Color color;
  final VoidCallback onPressed;
  final bool selected;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ink = EventCategory.labelOf(color);
    return EventCategoryChip(
      name: name,
      color: color,
      selected: selected,
      onPressed: onPressed,
      mark: active ? _AiStar(color: ink, twinkle: loading) : null,
      caption: loading ? AiCategoryDots(color: ink) : null,
    );
  }
}

class AiCategoryDots extends StatefulWidget {
  const AiCategoryDots({super.key, required this.color});

  final Color color;

  @override
  State<AiCategoryDots> createState() => _AiCategoryDotsState();
}

class _AiCategoryDotsState extends State<AiCategoryDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        return SizedBox(
          height: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Transform.translate(
                  offset: Offset(0, 1.5 - 3 * _bounce(t, i)),
                  child: Opacity(
                    opacity: 0.35 + 0.65 * _bounce(t, i),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double _bounce(double t, int index) {
    final phase = (t - index / 3) % 1;
    return math.sin(phase * math.pi).clamp(0.0, 1.0);
  }
}

class _AiStar extends StatefulWidget {
  const _AiStar({required this.color, required this.twinkle});

  final Color color;
  final bool twinkle;

  @override
  State<_AiStar> createState() => _AiStarState();
}

class _AiStarState extends State<_AiStar> with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.twinkle) _loop.repeat();
  }

  @override
  void didUpdateWidget(covariant _AiStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.twinkle && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!widget.twinkle && _loop.isAnimating) {
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final twinkle = widget.twinkle
            ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi))
            : 1.0;
        return Opacity(opacity: twinkle, child: child);
      },
      child: AppAssetImage(
        asset: AppIcons.stars,
        width: 16,
        height: 16,
        color: widget.color,
      ),
    );
  }
}
