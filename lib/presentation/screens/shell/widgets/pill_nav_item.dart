import 'package:flutter/material.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class PillNavItem extends StatelessWidget {
  const PillNavItem({
    super.key,
    required this.selected,
    required this.onTap,
    required this.filledAsset,
    required this.outlinedAsset,
  });

  final bool selected;
  final VoidCallback onTap;
  final String filledAsset;
  final String outlinedAsset;

  static const _iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onTap,
      pressedColor: Colors.transparent,
      child: Center(
        child: Image.asset(
          selected ? filledAsset : outlinedAsset,
          width: _iconSize,
          height: _iconSize,
        ),
      ),
    );
  }
}
