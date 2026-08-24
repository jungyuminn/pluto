import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class AppBarIconAction {
  const AppBarIconAction({
    required this.asset,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String asset;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
}

class AppBarIconGroup extends StatelessWidget {
  const AppBarIconGroup({
    super.key,
    this.actions = const [],
    this.trailing = const [],
  });

  final List<AppBarIconAction> actions;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions) AppBarIconSlot(
              selected: action.selected,
              onPressed: action.onPressed,
              child: ThemedAsset(
                asset: action.asset,
                width: 18,
                height: 18,
                semanticLabel: action.label,
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
  }
}

class AppBarIconSlot extends StatelessWidget {
  const AppBarIconSlot({
    super.key,
    required this.onPressed,
    required this.child,
    this.selected = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: selected ? colors.selected : Colors.transparent,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: child,
      ),
    );
  }
}
