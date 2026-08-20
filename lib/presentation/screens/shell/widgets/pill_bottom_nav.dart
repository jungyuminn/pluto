import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_nav_item.dart';
import 'package:job_planner/presentation/screens/shell/widgets/sliding_nav_indicator.dart';

class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final theme = AppScope.of(context).themePreference;

    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final items = AppSkinAssets.navIcons(theme.skin);
        return Padding(
          padding: EdgeInsets.only(bottom: 4 + bottomInset),
          child: Material(
            color: colors.navBar,
            elevation: 8,
            shadowColor: colors.shadow,
            shape: const StadiumBorder(),
            child: SizedBox(
              width: 240,
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SlidingNavIndicator(
                        index: currentIndex,
                        itemCount: items.length,
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: PillNavItem(
                              selected: i == currentIndex,
                              onTap: () => onChanged(i),
                              filledAsset: items[i].filled,
                              outlinedAsset: items[i].outlined,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
