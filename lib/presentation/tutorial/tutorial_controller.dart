import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/data/datasources/tutorial_preference.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';

enum TutorialAction {
  none,
  tapDay,
  composeEvent,
  pickDateMode,
  saveEvent,
  handleEvent,
  completeEvent,
  openHome,
  openJob,
}

class TutorialStep {
  const TutorialStep({
    required this.tab,
    required this.title,
    required this.body,
    this.badge = '',
    this.anchor,
    this.demo = TutorialDemo.none,
    this.action = TutorialAction.none,
    this.passHole = false,
    this.hideOverlay = false,
    this.forceTab = false,
    this.jobOnly = false,
    this.statsOnly = false,
  });

  final int tab;
  final TutorialAnchorId? anchor;
  final String badge;
  final String title;
  final String body;
  final TutorialDemo demo;
  final TutorialAction action;
  final bool passHole;
  final bool hideOverlay;
  final bool forceTab;
  final bool jobOnly;
  final bool statsOnly;
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
  settingsHelp,
  statsPlanetFill,
  statsCollection,
  statsDays,
  jobSwipe,
  dateModes,
  saveEvent,
  swipeAndMove,
  composeEvent,
}

class TutorialController extends ChangeNotifier {
  TutorialController(this._preference);

  static const steps = [
    TutorialStep(
      tab: 1,
      title: AppStrings.tutorialWelcomeTitle,
      body: AppStrings.tutorialWelcomeBody,
      forceTab: true,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarDay,
      title: AppStrings.tutorialAddTapTitle,
      body: AppStrings.tutorialAddTapBody,
      demo: TutorialDemo.calendarTap,
      action: TutorialAction.tapDay,
      passHole: true,
      forceTab: true,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      title: AppStrings.tutorialAddComposeTitle,
      body: AppStrings.tutorialAddComposeBody,
      demo: TutorialDemo.composeEvent,
      action: TutorialAction.composeEvent,
      hideOverlay: true,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      title: AppStrings.tutorialAddModeTitle,
      body: AppStrings.tutorialAddModeBody,
      demo: TutorialDemo.dateModes,
      action: TutorialAction.pickDateMode,
      hideOverlay: true,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      title: AppStrings.tutorialAddSaveTitle,
      body: AppStrings.tutorialAddSaveBody,
      demo: TutorialDemo.saveEvent,
      action: TutorialAction.saveEvent,
      hideOverlay: true,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      title: AppStrings.tutorialHandleTitle,
      body: AppStrings.tutorialHandleBody,
      demo: TutorialDemo.swipeAndMove,
      action: TutorialAction.handleEvent,
      hideOverlay: true,
      forceTab: true,
    ),
    TutorialStep(
      tab: 1,
      badge: AppStrings.tutorialBadgeCalendar,
      anchor: TutorialAnchorId.calendarMenu,
      title: AppStrings.tutorialMoreTitle,
      body: AppStrings.tutorialMoreBody,
      demo: TutorialDemo.calendarMenu,
      forceTab: true,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.homeList,
      title: AppStrings.tutorialHomeGoTitle,
      body: AppStrings.tutorialHomeGoBody,
      forceTab: true,
    ),
    TutorialStep(
      tab: 0,
      badge: AppStrings.tutorialBadgeHome,
      anchor: TutorialAnchorId.homeSettings,
      title: AppStrings.tutorialSettingsTitle,
      body: AppStrings.tutorialSettingsBody,
      demo: TutorialDemo.settingsHelp,
      forceTab: true,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStats,
      anchor: TutorialAnchorId.statsPlanet,
      title: AppStrings.tutorialStatsGoTitle,
      body: AppStrings.tutorialStatsGoBody,
      demo: TutorialDemo.statsPlanetFill,
      forceTab: true,
      statsOnly: true,
    ),
    TutorialStep(
      tab: 2,
      badge: AppStrings.tutorialBadgeStats,
      anchor: TutorialAnchorId.statsCalendar,
      title: AppStrings.tutorialStatsDaysTitle,
      body: AppStrings.tutorialStatsDaysBody,
      forceTab: true,
      statsOnly: true,
    ),
    TutorialStep(
      tab: 3,
      badge: AppStrings.tutorialBadgeJob,
      anchor: TutorialAnchorId.navJob,
      title: AppStrings.tutorialJobGoTitle,
      body: AppStrings.tutorialJobGoBody,
      demo: TutorialDemo.jobSwipe,
      action: TutorialAction.openJob,
      passHole: true,
      jobOnly: true,
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
  var _fromSettings = false;
  var _covered = false;
  var _navPhase = 0;
  var _jobPhase = 0;
  var _typedTitle = false;
  var _pickedCategory = false;

  bool get active => _active;
  int get index => _index;
  bool get isFirst => _index <= 0;
  bool get canPrevious {
    if (!_active || isFirst) return false;
    return _previousOverlayIndex() != null;
  }

  int? _previousOverlayIndex() {
    for (var i = _index - 1; i >= 0; i--) {
      if (!visibleSteps[i].hideOverlay) return i;
    }
    return null;
  }
  bool get isLast => _index >= visibleSteps.length - 1;
  bool get overlayVisible => _active && !step.hideOverlay && !_covered;
  bool get awaitAction => step.action != TutorialAction.none;
  TutorialStep get step => _displayStep(visibleSteps[_index]);
  int get stepCount => visibleSteps.length;
  bool get shouldAutoStart => _preference.shouldAutoStart;
  bool get showFeatureIntro => _preference.featureIntroVisible;

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
            tab: step.tab,
            badge: step.badge,
            anchor: step.anchor,
            title: step.title,
            body: _adaptedBody(step),
            demo: step.demo,
            action: step.action,
            passHole: step.passHole,
            hideOverlay: step.hideOverlay,
            forceTab: step.forceTab,
            jobOnly: step.jobOnly,
            statsOnly: step.statsOnly,
          ),
    ];
  }

  TutorialStep _displayStep(TutorialStep step) {
    if (step.action == TutorialAction.openHome && _navPhase == 1) {
      return TutorialStep(
        tab: 2,
        badge: AppStrings.tutorialBadgeStats,
        anchor: TutorialAnchorId.navStats,
        title: AppStrings.tutorialStatsGoTitle,
        body: AppStrings.tutorialStatsGoBody,
        demo: TutorialDemo.statsPlanetFill,
        action: TutorialAction.openHome,
        passHole: true,
      );
    }
    if (step.action == TutorialAction.openJob && _jobPhase == 1) {
      return TutorialStep(
        tab: 3,
        badge: AppStrings.tutorialBadgeJob,
        anchor: TutorialAnchorId.jobAdd,
        title: AppStrings.tutorialJobAddTitle,
        body: AppStrings.tutorialJobAddFollowBody,
        demo: TutorialDemo.jobSwipe,
        action: TutorialAction.openJob,
        passHole: true,
        jobOnly: true,
      );
    }
    return step;
  }

  bool _shouldSkip(TutorialStep step) {
    if (_hideJobTab && step.jobOnly) return true;
    if (_hideStatsTab && step.statsOnly) return true;
    return false;
  }

  String _adaptedBody(TutorialStep step) {
    if (_hideJobTab && step.body == AppStrings.tutorialWelcomeBody) {
      return AppStrings.tutorialWelcomeBodyDaily;
    }
    return step.body;
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

  static TutorialController? find(BuildContext context) {
    return context.getInheritedWidgetOfExactType<TutorialScope>()?.notifier;
  }

  Future<void> maybeAutoStart({required bool hasExistingData}) async {
    if (!hasExistingData && _preference.shouldAutoStart) {
      start();
      return;
    }
    if (_preference.shouldAutoStart) {
      await _preference.markSkippedForExistingUser();
      await _preference.skipFeatureIntro();
      notifyListeners();
    }
  }

  Future<void> dismissFeatureIntro() async {
    if (!_preference.featureIntroVisible) return;
    await _preference.skipFeatureIntro();
    notifyListeners();
  }

  void start({bool fromSettings = false}) {
    _fromSettings = fromSettings;
    _active = true;
    _index = 0;
    _covered = false;
    _resetFlags();
    notifyListeners();
  }

  void next() {
    if (!_active) return;
    if (isLast) {
      finish();
      return;
    }
    _index += 1;
    _resetFlags();
    notifyListeners();
  }

  void previous() {
    if (!_active || !canPrevious) return;
    if (step.action == TutorialAction.openHome && _navPhase == 1) {
      _navPhase = 0;
      notifyListeners();
      return;
    }
    if (step.action == TutorialAction.openJob && _jobPhase == 1) {
      _jobPhase = 0;
      notifyListeners();
      return;
    }
    final prev = _previousOverlayIndex();
    if (prev == null) return;
    _index = prev;
    _resetFlags();
    notifyListeners();
  }

  Future<void> skip() => finish();

  Future<void> finish() async {
    final replay = _fromSettings;
    _fromSettings = false;
    _active = false;
    _index = 0;
    _covered = false;
    _resetFlags();
    notifyListeners();
    await _preference.markCompleted();
    if (replay) return;
    await Future<void>.delayed(const Duration(milliseconds: 280));
    await _preference.markFeatureIntroEligible();
    notifyListeners();
  }

  void setCovered(bool value) {
    if (!_active || _covered == value) return;
    _covered = value;
    notifyListeners();
  }

  void noteDayClosed() {
    if (!_active) return;
    if (visibleSteps[_index].action == TutorialAction.handleEvent) {
      next();
    }
  }

  void noteAddOpened() {
    if (!_active) return;
    if (visibleSteps[_index].action == TutorialAction.tapDay) {
      next();
    }
  }

  void noteAddClosed({required bool saved}) {
    if (!_active) return;
    _covered = false;
    final action = visibleSteps[_index].action;
    if (saved) {
      while (_active && _isAddFollow(visibleSteps[_index].action)) {
        next();
      }
      return;
    }
    if (_isAddFollow(action)) {
      _goTo(TutorialAction.tapDay);
    } else {
      notifyListeners();
    }
  }

  static bool _isAddFollow(TutorialAction action) {
    return action == TutorialAction.composeEvent ||
        action == TutorialAction.pickDateMode ||
        action == TutorialAction.saveEvent;
  }

  bool get isAddFollow {
    if (!_active) return false;
    return _isAddFollow(visibleSteps[_index].action);
  }

  bool allowsAddInteract(TutorialAction needed) {
    if (!isAddFollow) return true;
    return visibleSteps[_index].action == needed;
  }

  void noteAddTitle(bool hasTitle) {
    if (!_active) return;
    if (visibleSteps[_index].action != TutorialAction.composeEvent) return;
    _typedTitle = hasTitle;
    _tryComposeNext();
  }

  void noteCategoryPicked() {
    if (!_active) return;
    if (visibleSteps[_index].action != TutorialAction.composeEvent) return;
    _pickedCategory = true;
    _tryComposeNext();
  }

  void _tryComposeNext() {
    if (_typedTitle && _pickedCategory) next();
  }

  void noteDateMode() {
    if (!_active) return;
    if (visibleSteps[_index].action == TutorialAction.pickDateMode) {
      next();
    }
  }

  void noteCompleted({required bool completed}) {
    if (!_active || !completed) return;
    if (visibleSteps[_index].action == TutorialAction.completeEvent) {
      next();
    }
  }

  void noteTab(int tab) {
    if (!_active) return;
    final action = visibleSteps[_index].action;
    if (action == TutorialAction.openHome) {
      if (_navPhase == 0 && tab == 0) {
        if (_hideStatsTab) {
          next();
          return;
        }
        _navPhase = 1;
        notifyListeners();
        return;
      }
      if (_navPhase == 1 && tab == 2) {
        next();
      }
      return;
    }
    if (action == TutorialAction.openJob && _jobPhase == 0 && tab == 3) {
      _jobPhase = 1;
      notifyListeners();
    }
  }

  void noteJobOpened() {
    if (!_active) return;
    if (visibleSteps[_index].action == TutorialAction.openJob) {
      next();
    }
  }

  void _goTo(TutorialAction action) {
    final i = visibleSteps.indexWhere((step) => step.action == action);
    if (i < 0) return;
    _index = i;
    _resetFlags();
    notifyListeners();
  }

  void _resetFlags() {
    _navPhase = 0;
    _jobPhase = 0;
    _typedTitle = false;
    _pickedCategory = false;
  }
}

class TutorialScope extends InheritedNotifier<TutorialController> {
  const TutorialScope({
    super.key,
    required TutorialController controller,
    required super.child,
  }) : super(notifier: controller);
}
