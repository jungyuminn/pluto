import 'package:flutter/material.dart';

class SlidingNavIndicator extends StatelessWidget {
  const SlidingNavIndicator({
    super.key,
    required this.index,
    required this.itemCount,
  });

  final int index;
  final int itemCount;

  static const width = 60.0;
  static const height = 40.0;
  static const duration = Duration(milliseconds: 30);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / itemCount;
          final left = cellWidth * index + (cellWidth - width) / 2;
          final top = (constraints.maxHeight - height) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutCubic,
                left: left,
                top: top,
                width: width,
                height: height,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
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
