import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class AppBarPill extends StatelessWidget {
  const AppBarPill({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String asset;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PressBounce(
          onPressed: onPressed,
          color: selected ? colors.selected : colors.card,
          pressedColor: colors.pressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ThemedAsset(
              asset: asset,
              width: 18,
              height: 18,
              semanticLabel: label,
            ),
          ),
        ),
      ),
    );
  }
}
