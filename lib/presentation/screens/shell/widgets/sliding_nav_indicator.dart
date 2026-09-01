import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class SlidingNavIndicator extends StatelessWidget {
  const SlidingNavIndicator({
    super.key,
    required this.index,
    required this.itemCount,
    this.itemExtent,
    this.left,
    this.dragging = false,
  });

  final int index;
  final int itemCount;
  final double? itemExtent;
  final double? left;
  final bool dragging;

  static const width = 60.0;
  static const height = 40.0;
  static const duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = itemExtent ?? constraints.maxWidth / itemCount;
          final snapped = cellWidth * index + (cellWidth - width) / 2;
          final top = (constraints.maxHeight - height) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: dragging ? Duration.zero : duration,
                curve: Curves.easeOutCubic,
                left: left ?? snapped,
                top: top,
                width: width,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.of(context).pressed,
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
