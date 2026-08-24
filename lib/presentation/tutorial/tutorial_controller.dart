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
  calendarMenu,
  homeReorder,
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
      anchor: TutorialAnchorId.homeList,
      title: AppStrings.tutorialHomeListTitle,
      body: AppStrings.tutorialHomeListBody,
      demo: TutorialDemo.homeReorder,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeJob,
      anchor: TutorialAnchorId.navJob,
      title: AppStrings.tutorialNavJobTitle,
      body: AppStrings.tutorialNavJobBody,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeJob,
      anchor: TutorialAnchorId.jobTools,
      title: AppStrings.tutorialJobToolsTitle,
      body: AppStrings.tutorialJobToolsBody,
    ),
    TutorialStep(
      tab: 2,
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
  bool get isLast => _index >= steps.length - 1;
  TutorialStep get step => steps[_index];
  bool get shouldAutoStart => _preference.shouldAutoStart;

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
