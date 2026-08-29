import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/theme/app_colors.dart';

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
  var _dragging = false;
  double? _dragLeft;

  int get _selectedIndex {
    final index = widget.values.indexOf(widget.selected);
    return index < 0 ? 0 : index;
  }

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

  void _moveTo(double dx, double width) {
    if (width <= 0 || widget.values.isEmpty) return;
    final cell = width / widget.values.length;
    final left = (dx - cell / 2).clamp(0.0, width - cell);
    final index = (dx / cell).floor().clamp(0, widget.values.length - 1);
    setState(() => _dragLeft = left);
    _selectIndex(index);
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
          final count = widget.values.length;
          final cell = count == 0 ? 0.0 : width / count;
          final index = _selectedIndex;
          final left = _dragging ? (_dragLeft ?? index * cell) : index * cell;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _selectIndex(
              _indexAt(details.localPosition.dx, width),
              fromTap: true,
            ),
            onHorizontalDragStart: (details) {
              setState(() {
                _dragging = true;
                _dragLeft = index * cell;
              });
              _moveTo(details.localPosition.dx, width);
            },
            onHorizontalDragUpdate: (details) {
              _moveTo(details.localPosition.dx, width);
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragging = false;
                _dragLeft = null;
              });
            },
            onHorizontalDragCancel: () {
              setState(() {
                _dragging = false;
                _dragLeft = null;
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedPositioned(
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: cell,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final value in widget.values)
                      Expanded(
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: value == widget.selected
                                  ? _onAccent(colors)
                                  : colors.text,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(widget.labelOf(value)),
                            ),
                          ),
                        ),
                      ),
                  ],
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

  Color _onAccent(AppColors colors) {
    return widget.accent.computeLuminance() > 0.45
        ? colors.text
        : Colors.white;
  }
}
