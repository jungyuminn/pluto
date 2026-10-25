import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class SlidingKindBar<T> extends StatefulWidget {
  const SlidingKindBar({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.accent,
    required this.onChanged,
    this.onReselected,
    this.barColor,
    this.height = 42,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final Color accent;
  final ValueChanged<T> onChanged;
  final VoidCallback? onReselected;
  final Color? barColor;
  final double height;

  @override
  State<SlidingKindBar<T>> createState() => _SlidingKindBarState<T>();
}

class _SlidingKindBarState<T> extends State<SlidingKindBar<T>> {
  void _selectIndex(int index, {bool fromTap = false}) {
    if (index < 0 || index >= widget.values.length) return;
    final next = widget.values[index];
    if (next == widget.selected) {
      if (fromTap) widget.onReselected?.call();
      return;
    }
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: widget.barColor ?? colors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _selectIndex(
              _indexAt(details.localPosition.dx, width),
              fromTap: true,
            ),
            onHorizontalDragUpdate: (details) {
              _selectIndex(_indexAt(details.localPosition.dx, width));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final value in widget.values)
                  Expanded(
                    child: PressBounce(
                      passthrough: true,
                      pressedScale: 0.92,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: value == widget.selected
                                ? colors.text
                                : colors.muted,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(widget.labelOf(value)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _indexAt(double dx, double width) {
    if (width <= 0 || widget.values.isEmpty) return 0;
    final cell = width / widget.values.length;
    return (dx / cell).floor().clamp(0, widget.values.length - 1);
  }

}
