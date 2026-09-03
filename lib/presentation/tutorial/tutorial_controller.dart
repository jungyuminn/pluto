import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/data/datasources/tutorial_preference.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';

class TutorialStep {
  const TutorialStep({
    required this.tab,
    required this.title,
    required this.body,
    this.badge = '',
    this.anchor,
    this.demo = TutorialDemo.none,
  });

  final int tab;
  final TutorialAnchorId? anchor;
  final String badge;
  final String title;
  final String body;
  final TutorialDemo demo;
}

enum TutorialDemo {
  none,
  navTabs,
  calendarTitle,
  calendarTap,
  calendarRange,
  todoComplete,
  todoMove,
  calendarMenu,
  homeSearch,
  homeSettings,
  homeReorder,
  statsPlanetFill,
  statsCollection,
  statsDays,
  jobSwipe,
}

class TutorialController extends ChangeNotifier {
  TutorialController(this._preference);

  static const steps = [
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeStart,
      title: AppStrings.tutorialWelcomeTitle,
      body: AppStrings.tutorialWelcomeBody,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeNav,
      anchor: TutorialAnchorId.navBar,
      title: AppStrings.tutorialNavBarTitle,
      body: AppStrings.tutorialNavBarBody,
      demo: TutorialDemo.navTabs,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.navCalendar,
      title: AppStrings.tutorialNavCalendarTitle,
      body: AppStrings.tutorialNavCalendarBody,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarTitle,
      title: AppStrings.tutorialCalendarTitleTitle,
      body: AppStrings.tutorialCalendarTitleBody,
      demo: TutorialDemo.calendarTitle,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarGrid,
      title: AppStrings.tutorialCalendarGridTitle,
      body: AppStrings.tutorialCalendarGridBody,
      demo: TutorialDemo.calendarTap,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarGrid,
      title: AppStrings.tutorialCalendarRangeTitle,
      body: AppStrings.tutorialCalendarRangeBody,
      demo: TutorialDemo.calendarRange,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarGrid,
      title: AppStrings.tutorialCalendarCompleteTitle,
      body: AppStrings.tutorialCalendarCompleteBody,
      demo: TutorialDemo.todoComplete,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarGrid,
      title: AppStrings.tutorialCalendarMoveTitle,
      body: AppStrings.tutorialCalendarMoveBody,
      demo: TutorialDemo.todoMove,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarMenu,
      title: AppStrings.tutorialCalendarMenuTitle,
      body: AppStrings.tutorialCalendarMenuBody,
      demo: TutorialDemo.calendarMenu,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.navHome,
      title: AppStrings.tutorialNavHomeTitle,
      body: AppStrings.tutorialNavHomeBody,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.homeTools,
      title: AppStrings.tutorialHomeToolsTitle,
      body: AppStrings.tutorialHomeToolsBody,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.homeTools,
      title: AppStrings.tutorialHomeSearchTitle,
      body: AppStrings.tutorialHomeSearchBody,
      demo: TutorialDemo.homeSearch,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.homeTools,
      title: AppStrings.tutorialHomeSettingsTitle,
      body: AppStrings.tutorialHomeSettingsBody,
      demo: TutorialDemo.homeSettings,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.homeList,
      title: AppStrings.tutorialHomeListTitle,
      body: AppStrings.tutorialHomeListBody,
      demo: TutorialDemo.homeReorder,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStats,
      anchor: TutorialAnchorId.statsPlanet,
      title: AppStrings.tutorialNavStatsTitle,
      body: AppStrings.tutorialNavStatsBody,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStats,
      anchor: TutorialAnchorId.statsPlanet,
      title: AppStrings.tutorialStatsPlanetTitle,
      body: AppStrings.tutorialStatsPlanetBody,
      demo: TutorialDemo.statsPlanetFill,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStats,
      anchor: TutorialAnchorId.statsCollected,
      title: AppStrings.tutorialStatsGuideTitle,
      body: AppStrings.tutorialStatsGuideBody,
      demo: TutorialDemo.statsCollection,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStats,
      anchor: TutorialAnchorId.statsCalendar,
      title: AppStrings.tutorialStatsDaysTitle,
      body: AppStrings.tutorialStatsDaysBody,
      demo: TutorialDemo.statsDays,
    ),
    TutorialStep(
      tab: 3,
      badge: AppStrings.tutorialBadgeJob,
      anchor: TutorialAnchorId.navJob,
      title: AppStrings.tutorialNavJobTitle,
      body: AppStrings.tutorialNavJobBody,
    ),
    TutorialStep(
      tab: 3,
      badge: AppStrings.tutorialBadgeJob,
      anchor: TutorialAnchorId.jobTools,
      title: AppStrings.tutorialJobToolsTitle,
      body: AppStrings.tutorialJobToolsBody,
    ),
    TutorialStep(
      tab: 3,
      badge: AppStrings.tutorialBadgeJob,
      anchor: TutorialAnchorId.jobAdd,
      title: AppStrings.tutorialJobAddTitle,
      body: AppStrings.tutorialJobAddBody,
      demo: TutorialDemo.jobSwipe,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStart,
      title: AppStrings.tutorialDoneTitle,
      body: AppStrings.tutorialDoneBody,
    ),
  ];

  final TutorialPreference _preference;

  var _active = false;
  var _index = 0;

  bool get active => _active;
  int get index => _index;
  bool get isFirst => _index <= 0;
  bool get isLast => _index >= visibleSteps.length - 1;
  TutorialStep get step => visibleSteps[_index];
  int get stepCount => visibleSteps.length;
  bool get shouldAutoStart => _preference.shouldAutoStart;

  var _hideJobTab = false;
  bool get hideJobTab => _hideJobTab;

  var _hideStatsTab = false;
  bool get hideStatsTab => _hideStatsTab;

  List<TutorialStep> get visibleSteps {
    if (!_hideJobTab && !_hideStatsTab) return steps;
    return [
      for (final step in steps)
        if (!_shouldSkip(step))
          TutorialStep(
            tab: _remapTab(step.tab),
            badge: step.badge,
            anchor: step.anchor,
            title: step.title,
            body: _adaptedBody(step),
            demo: step.demo,
          ),
    ];
  }

  bool _shouldSkip(TutorialStep step) {
    if (_hideJobTab && _isJobOnly(step)) return true;
    if (_hideStatsTab && _isStatsOnly(step)) return true;
    return false;
  }

  int _remapTab(int tab) {
    if (_hideStatsTab && tab == 2) return 1;
    return tab;
  }

  String _adaptedBody(TutorialStep step) {
    if (step.body == AppStrings.tutorialNavBarBody) {
      if (_hideStatsTab && _hideJobTab) {
        return AppStrings.tutorialNavBarBodyNoStatsDaily;
      }
      if (_hideStatsTab) return AppStrings.tutorialNavBarBodyNoStats;
      if (_hideJobTab) return AppStrings.tutorialNavBarBodyDaily;
      return step.body;
    }
    if (_hideJobTab) return _dailyBody(step);
    return step.body;
  }

  static String _dailyBody(TutorialStep step) {
    if (step.body == AppStrings.tutorialWelcomeBody) {
      return AppStrings.tutorialWelcomeBodyDaily;
    }
    if (step.body == AppStrings.tutorialNavBarBody) {
      return AppStrings.tutorialNavBarBodyDaily;
    }
    if (step.body == AppStrings.tutorialNavCalendarBody) {
      return AppStrings.tutorialNavCalendarBodyDaily;
    }
    if (step.body == AppStrings.tutorialCalendarMenuBody) {
      return AppStrings.tutorialCalendarMenuBodyDaily;
    }
    if (step.body == AppStrings.tutorialHomeSearchBody) {
      return AppStrings.tutorialHomeSearchBodyDaily;
    }
    return step.body;
  }

  static bool _isJobOnly(TutorialStep step) {
    return step.anchor == TutorialAnchorId.navJob ||
        step.anchor == TutorialAnchorId.jobTools ||
        step.anchor == TutorialAnchorId.jobAdd;
  }

  static bool _isStatsOnly(TutorialStep step) {
    return step.anchor == TutorialAnchorId.statsPlanet ||
        step.anchor == TutorialAnchorId.statsCollected ||
        step.anchor == TutorialAnchorId.statsCalendar;
  }

  void _clampIndex() {
    if (_index >= visibleSteps.length) {
      _index = (visibleSteps.length - 1).clamp(0, visibleSteps.length);
    }
  }

  void setHideJobTab(bool value) {
    if (_hideJobTab == value) return;
    _hideJobTab = value;
    _clampIndex();
    notifyListeners();
  }

  void setHideStatsTab(bool value) {
    if (_hideStatsTab == value) return;
    _hideStatsTab = value;
    _clampIndex();
    notifyListeners();
  }

  static TutorialController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TutorialScope>();
    assert(scope != null, 'TutorialScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }

  static TutorialController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TutorialScope>()
        ?.notifier;
  }

  Future<void> maybeAutoStart({required bool hasExistingData}) async {
    if (!hasExistingData && _preference.shouldAutoStart) {
      start();
      return;
    }
    if (_preference.shouldAutoStart) {
      await _preference.markSkippedForExistingUser();
    }
  }

  void start() {
    _active = true;
    _index = 0;
    notifyListeners();
  }

  void next() {
    if (!_active) return;
    if (isLast) {
      finish();
      return;
    }
    _index += 1;
    notifyListeners();
  }

  void previous() {
    if (!_active || isFirst) return;
    _index -= 1;
    notifyListeners();
  }

  Future<void> skip() => finish();

  Future<void> finish() async {
    _active = false;
    _index = 0;
    notifyListeners();
    await _preference.markCompleted();
  }
}

class TutorialScope extends InheritedNotifier<TutorialController> {
  const TutorialScope({
    super.key,
    required TutorialController controller,
    required super.child,
  }) : super(notifier: controller);
}
