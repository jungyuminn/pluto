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
    this.showJob = true,
    this.tutorial = true,
    this.embedded = false,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool showJob;
  final bool tutorial;
  final bool embedded;

  static const itemWidth = 80.0;
  static const barHeight = 56.0;
  static const animDuration = Duration(milliseconds: 340);
  static const animCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = embedded ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final theme = AppScope.of(context).themePreference;

    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final items = AppSkinAssets.navIcons(theme.skin);
        Widget nav = Padding(
          padding: EdgeInsets.only(bottom: embedded ? 0 : 4 + bottomInset),
          child: TweenAnimationBuilder<double>(
            duration: animDuration,
            curve: animCurve,
            tween: Tween(end: showJob ? 1.0 : 0.0),
            builder: (context, t, child) {
              final jobHit = t > 0.55;
              return Material(
                color: colors.navBar,
                elevation: embedded ? 0 : 8,
                shadowColor: colors.shadow,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: itemWidth * 2 + itemWidth * t,
                  height: barHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: SlidingNavIndicator(
                            index: currentIndex.clamp(0, showJob ? 2 : 1),
                            itemCount: showJob ? 3 : 2,
                            itemExtent: itemWidth,
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _maybeAnchor(
                                TutorialAnchorId.navHome,
                                PillNavItem(
                                  selected: currentIndex == 0,
                                  onTap: () => onChanged(0),
                                  filledAsset: items[0].filled,
                                  outlinedAsset: items[0].outlined,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _maybeAnchor(
                                TutorialAnchorId.navCalendar,
                                PillNavItem(
                                  selected: currentIndex == 1,
                                  onTap: () => onChanged(1),
                                  filledAsset: items[1].filled,
                                  outlinedAsset: items[1].outlined,
                                ),
                              ),
                            ),
                            ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: t,
                                child: SizedBox(
                                  width: itemWidth,
                                  child: IgnorePointer(
                                    ignoring: !jobHit,
                                    child: Opacity(
                                      opacity: t,
                                      child: _maybeAnchor(
                                        TutorialAnchorId.navJob,
                                        PillNavItem(
                                          selected: currentIndex == 2,
                                          onTap: () => onChanged(2),
                                          filledAsset: items[2].filled,
                                          outlinedAsset: items[2].outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
