import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_nav_item.dart';
import 'package:job_planner/presentation/screens/shell/widgets/sliding_nav_indicator.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';

class PillBottomNav extends StatefulWidget {
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
  State<PillBottomNav> createState() => _PillBottomNavState();
}

class _PillBottomNavState extends State<PillBottomNav> {
  var _dragging = false;
  double? _dragLeft;

  int get _count => widget.showJob ? 3 : 2;

  int get _index => widget.currentIndex.clamp(0, _count - 1);

  double _indicatorLeft(int index) {
    const indicator = SlidingNavIndicator.width;
    const cell = PillBottomNav.itemWidth;
    return cell * index + (cell - indicator) / 2;
  }

  void _select(int index) {
    if (index < 0 || index >= _count) return;
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onChanged(index);
  }

  void _moveTo(double dx, double width, {required bool jobHit}) {
    if (width <= 0) return;
    const indicator = SlidingNavIndicator.width;
    const cell = PillBottomNav.itemWidth;
    final maxIndex = jobHit ? _count - 1 : 1;
    final minLeft = (cell - indicator) / 2;
    final maxLeft = cell * maxIndex + minLeft;
    final left = (dx - indicator / 2).clamp(minLeft, maxLeft);
    final index = (dx / cell).floor().clamp(0, maxIndex);
    setState(() => _dragLeft = left);
    _select(index);
  }

  void _endDrag() {
    if (!_dragging && _dragLeft == null) return;
    setState(() {
      _dragging = false;
      _dragLeft = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = widget.embedded
        ? 0.0
        : MediaQuery.paddingOf(context).bottom;
    final theme = AppScope.of(context).themePreference;

    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final items = AppSkinAssets.navIcons(theme.skin);
        Widget nav = Padding(
          padding: EdgeInsets.only(
            bottom: widget.embedded ? 0 : 4 + bottomInset,
          ),
          child: TweenAnimationBuilder<double>(
            duration: PillBottomNav.animDuration,
            curve: PillBottomNav.animCurve,
            tween: Tween(end: widget.showJob ? 1.0 : 0.0),
            builder: (context, t, child) {
              final jobHit = t > 0.55;
              final barWidth =
                  PillBottomNav.itemWidth * 2 + PillBottomNav.itemWidth * t;
              return Material(
                color: colors.navBar,
                elevation: widget.embedded ? 0 : 8,
                shadowColor: colors.shadow,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: barWidth,
                  height: PillBottomNav.barHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _dragging = true;
                          _dragLeft = _indicatorLeft(_index);
                        });
                        _moveTo(
                          details.localPosition.dx,
                          barWidth,
                          jobHit: jobHit,
                        );
                      },
                      onHorizontalDragUpdate: (details) {
                        _moveTo(
                          details.localPosition.dx,
                          barWidth,
                          jobHit: jobHit,
                        );
                      },
                      onHorizontalDragEnd: (_) => _endDrag(),
                      onHorizontalDragCancel: _endDrag,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SlidingNavIndicator(
                              index: _index,
                              itemCount: widget.showJob ? 3 : 2,
                              itemExtent: PillBottomNav.itemWidth,
                              left: _dragging ? _dragLeft : null,
                              dragging: _dragging,
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: PillBottomNav.itemWidth,
                                child: _maybeAnchor(
                                  TutorialAnchorId.navHome,
                                  PillNavItem(
                                    selected: widget.currentIndex == 0,
                                    onTap: () => widget.onChanged(0),
                                    filledAsset: items[0].filled,
                                    outlinedAsset: items[0].outlined,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: PillBottomNav.itemWidth,
                                child: _maybeAnchor(
                                  TutorialAnchorId.navCalendar,
                                  PillNavItem(
                                    selected: widget.currentIndex == 1,
                                    onTap: () => widget.onChanged(1),
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
                                    width: PillBottomNav.itemWidth,
                                    child: IgnorePointer(
                                      ignoring: !jobHit,
                                      child: Opacity(
                                        opacity: t,
                                        child: _maybeAnchor(
                                          TutorialAnchorId.navJob,
                                          PillNavItem(
                                            selected: widget.currentIndex == 2,
                                            onTap: () => widget.onChanged(2),
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
                ),
              );
            },
          ),
        );
        if (!widget.tutorial) return nav;
        return TutorialAnchor(
          id: TutorialAnchorId.navBar,
          child: nav,
        );
      },
    );
  }

  Widget _maybeAnchor(TutorialAnchorId id, Widget child) {
    if (!widget.tutorial) return child;
    return TutorialAnchor(id: id, child: child);
  }
}
