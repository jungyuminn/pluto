import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_nav_item.dart';
import 'package:job_planner/presentation/screens/shell/widgets/sliding_nav_indicator.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';

class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.tutorial = true,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool tutorial;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final theme = AppScope.of(context).themePreference;

    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final items = AppSkinAssets.navIcons(theme.skin);
        Widget nav = Padding(
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
                            child: _maybeAnchor(
                              switch (i) {
                                0 => TutorialAnchorId.navHome,
                                1 => TutorialAnchorId.navCalendar,
                                _ => TutorialAnchorId.navJob,
                              },
                              PillNavItem(
                                selected: i == currentIndex,
                                onTap: () => onChanged(i),
                                filledAsset: items[i].filled,
                                outlinedAsset: items[i].outlined,
                              ),
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
        if (!tutorial) return nav;
        return TutorialAnchor(
          id: TutorialAnchorId.navBar,
          child: nav,
        );
      },
    );
  }

  Widget _maybeAnchor(TutorialAnchorId id, Widget child) {
    if (!tutorial) return child;
    return TutorialAnchor(id: id, child: child);
  }
}
