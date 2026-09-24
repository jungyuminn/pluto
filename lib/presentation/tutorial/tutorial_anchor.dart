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

class TutorialAnchor extends StatefulWidget {
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

  static final _owners = <TutorialAnchorId, State>{};

  static GlobalKey keyOf(TutorialAnchorId id) => _keys[id]!;

  @override
  State<TutorialAnchor> createState() => _TutorialAnchorState();
}

class _TutorialAnchorState extends State<TutorialAnchor> {
  var _ownsKey = false;

  @override
  void initState() {
    super.initState();
    if (!TutorialAnchor._owners.containsKey(widget.id)) {
      TutorialAnchor._owners[widget.id] = this;
      _ownsKey = true;
    }
  }

  @override
  void dispose() {
    if (_ownsKey && TutorialAnchor._owners[widget.id] == this) {
      TutorialAnchor._owners.remove(widget.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ownsKey) return widget.child;
    return KeyedSubtree(
      key: TutorialAnchor._keys[widget.id],
      child: widget.child,
    );
  }
}
