import 'package:flutter/material.dart';

enum TutorialAnchorId {
  navBar,
  navHome,
  navCalendar,
  navStats,
  navJob,
  statsPlanet,
  statsCollected,
  statsCalendar,
  calendarTitle,
  calendarMenu,
  calendarGrid,
  calendarDay,
  homeTools,
  homeSettings,
  homeList,
  homeTomorrow,
  jobTools,
  jobAdd,
}

class TutorialAnchor extends StatelessWidget {
  const TutorialAnchor({
    super.key,
    required this.id,
    required this.child,
  });

  final TutorialAnchorId id;
  final Widget child;

  static final _keys = <TutorialAnchorId, GlobalKey>{
    for (final id in TutorialAnchorId.values) id: GlobalKey(),
  };

  static GlobalKey keyOf(TutorialAnchorId id) => _keys[id]!;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _keys[id],
      child: child,
    );
  }
}
