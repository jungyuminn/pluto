import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/layout/pc_layout.dart';
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
    this.showStats = true,
    this.showJob = true,
    this.tutorial = true,
    this.embedded = false,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool showStats;
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

  double _slotStart(int logical, double jobT) {
    const cell = PillBottomNav.itemWidth;
    switch (logical) {
      case 0:
        return 0;
      case 1:
        return cell;
      case 3:
        return cell * 2;
      default:
        return cell * 2 + cell * jobT;
    }
  }

  double _slotWidth(int logical, double statsT, double jobT) {
    const cell = PillBottomNav.itemWidth;
    switch (logical) {
      case 0:
      case 1:
        return cell;
      case 3:
        return cell * jobT;
      default:
        return cell * statsT;
    }
  }

  double _indicatorLeftFor(int logical, double statsT, double jobT) {
    const indicator = SlidingNavIndicator.width;
    var target = logical;
    if (logical == 3 && jobT < 0.5) target = 1;
    if (logical == 2 && statsT < 0.5) {
      target = jobT >= 0.5 ? 3 : 1;
    }
    final width = _slotWidth(target, statsT, jobT);
    return _slotStart(target, jobT) + (width - indicator) / 2;
  }

  int _lastLogical({required bool statsHit, required bool jobHit}) {
    if (statsHit) return 2;
    if (jobHit) return 3;
    return 1;
  }

  int _logicalAt(
    double dx, {
    required bool statsHit,
    required bool jobHit,
    required double jobT,
  }) {
    const cell = PillBottomNav.itemWidth;
    if (dx < cell) return 0;
    if (dx < cell * 2) return 1;
    final jobEnd = cell * 2 + cell * jobT;
    if (jobHit && dx < jobEnd) return 3;
    if (statsHit) return 2;
    if (jobHit) return 3;
    return 1;
  }

  void _select(int logical) {
    if (logical == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onChanged(logical);
  }

  void _moveTo(
    double dx,
    double statsT,
    double jobT, {
    required bool statsHit,
    required bool jobHit,
  }) {
    const indicator = SlidingNavIndicator.width;
    final last = _lastLogical(statsHit: statsHit, jobHit: jobHit);
    final minLeft = _indicatorLeftFor(0, statsT, jobT);
    final maxLeft = _indicatorLeftFor(last, statsT, jobT);
    final left = (dx - indicator / 2).clamp(minLeft, maxLeft);
    final logical = _logicalAt(
      dx,
      statsHit: statsHit,
      jobHit: jobHit,
      jobT: jobT,
    );
    setState(() => _dragLeft = left);
    _select(logical);
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
            bottom: widget.embedded
                ? 0
                : 4 + (PcLayout.isPc ? PcLayout.navLift : 0) + bottomInset,
          ),
          child: TweenAnimationBuilder<double>(
            duration: PillBottomNav.animDuration,
            curve: PillBottomNav.animCurve,
            tween: Tween(end: widget.showStats ? 1.0 : 0.0),
            builder: (context, statsT, child) {
              return TweenAnimationBuilder<double>(
                duration: PillBottomNav.animDuration,
                curve: PillBottomNav.animCurve,
                tween: Tween(end: widget.showJob ? 1.0 : 0.0),
                builder: (context, jobT, child) {
                  final statsHit = statsT > 0.55;
                  final jobHit = jobT > 0.55;
                  final barWidth = PillBottomNav.itemWidth * (2 + statsT + jobT);
                  final collapsing =
                      (statsT > 0 && statsT < 1) || (jobT > 0 && jobT < 1);
                  final indicatorLeft = _dragging
                      ? _dragLeft
                      : _indicatorLeftFor(widget.currentIndex, statsT, jobT);
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
                              _dragLeft = _indicatorLeftFor(
                                widget.currentIndex,
                                statsT,
                                jobT,
                              );
                            });
                            _moveTo(
                              details.localPosition.dx,
                              statsT,
                              jobT,
                              statsHit: statsHit,
                              jobHit: jobHit,
                            );
                          },
                          onHorizontalDragUpdate: (details) {
                            _moveTo(
                              details.localPosition.dx,
                              statsT,
                              jobT,
                              statsHit: statsHit,
                              jobHit: jobHit,
                            );
                          },
                          onHorizontalDragEnd: (_) => _endDrag(),
                          onHorizontalDragCancel: _endDrag,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SlidingNavIndicator(
                                  index: widget.currentIndex,
                                  itemCount: 4,
                                  itemExtent: PillBottomNav.itemWidth,
                                  left: indicatorLeft,
                                  dragging: _dragging || collapsing,
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
                                      widthFactor: jobT,
                                      child: SizedBox(
                                        width: PillBottomNav.itemWidth,
                                        child: IgnorePointer(
                                          ignoring: !jobHit,
                                          child: Opacity(
                                            opacity: jobT,
                                            child: _maybeAnchor(
                                              TutorialAnchorId.navJob,
                                              PillNavItem(
                                                selected:
                                                    widget.currentIndex == 3,
                                                onTap: () =>
                                                    widget.onChanged(3),
                                                filledAsset: items[3].filled,
                                                outlinedAsset:
                                                    items[3].outlined,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: statsT,
                                      child: SizedBox(
                                        width: PillBottomNav.itemWidth,
                                        child: IgnorePointer(
                                          ignoring: !statsHit,
                                          child: Opacity(
                                            opacity: statsT,
                                            child: _maybeAnchor(
                                              TutorialAnchorId.navStats,
                                              PillNavItem(
                                                selected:
                                                    widget.currentIndex == 2,
                                                onTap: () =>
                                                    widget.onChanged(2),
                                                filledAsset: items[2].filled,
                                                outlinedAsset:
                                                    items[2].outlined,
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
