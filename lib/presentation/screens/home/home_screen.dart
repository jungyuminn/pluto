import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/notifications/todo_reminder_service.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/core/utils/fade_in.dart';
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/data/datasources/calendar_preference.dart';
import 'package:pluto/data/datasources/day_events_view_preference.dart';
import 'package:pluto/data/datasources/home_view_preference.dart';
import 'package:pluto/data/datasources/nav_preference.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/entities/home_memo.dart';
import 'package:pluto/domain/entities/long_goal.dart';
import 'package:pluto/presentation/screens/calendar/calendar_day_events.dart';
import 'package:pluto/presentation/screens/home/all_events_screen.dart';
import 'package:pluto/presentation/screens/home/leftover_todos_screen.dart';
import 'package:pluto/presentation/screens/home/monthly_stats_screen.dart';
import 'package:pluto/presentation/screens/home/widgets/home_day_card.dart';
import 'package:pluto/presentation/screens/home/widgets/home_friends_row.dart';
import 'package:pluto/presentation/screens/home/widgets/home_leftover_card.dart';
import 'package:pluto/presentation/screens/home/widgets/home_long_goal_card.dart';
import 'package:pluto/presentation/screens/home/widgets/home_memo_card.dart';
import 'package:pluto/presentation/screens/home/widgets/home_monthly_stats_card.dart';
import 'package:pluto/presentation/screens/settings/settings_screen.dart';
import 'package:pluto/presentation/widgets/app_bar_icon_group.dart';
import 'package:pluto/presentation/widgets/app_bar_wordmark.dart';
import 'package:pluto/presentation/widgets/overlay_app_bar.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.visible = true});

  final bool visible;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  var _todayEvents = <CalendarEvent>[];
  var _tomorrowEvents = <CalendarEvent>[];
  var _weekEvents = <CalendarEvent>[];
  var _monthEvents = <CalendarEvent>[];
  var _leftoverEvents = <CalendarEvent>[];
  var _somedayEvents = <CalendarEvent>[];
  var _categories = <EventCategory>[];
  var _longGoals = <LongGoal>[];
  var _memos = <HomeMemo>[];
  var _loading = true;
  var _initialized = false;
  var _startMonday = false;
  final _scroll = ScrollController();
  CalendarPreference? _calendarPrefs;
  NavPreference? _navPrefs;
  String? _weekLabel;
  String? _monthLabel;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _tomorrow => _today.add(const Duration(days: 1));

  DateTime get _weekEnd {
    return calendarWeekEnd(
      _today,
      startMonday: AppScope.of(context).calendarPreference.startMonday,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppBackupService.revision.addListener(_onBackupRestored);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calendarPrefs = AppScope.of(context).calendarPreference;
    if (_calendarPrefs != calendarPrefs) {
      _calendarPrefs?.removeListener(_onCalendarPrefs);
      _calendarPrefs = calendarPrefs;
      _calendarPrefs!.addListener(_onCalendarPrefs);
    }
    final navPrefs = AppScope.of(context).navPreference;
    if (_navPrefs != navPrefs) {
      _navPrefs?.removeListener(_onNavPrefs);
      _navPrefs = navPrefs;
      _navPrefs!.addListener(_onNavPrefs);
    }
    if (_initialized) return;
    _initialized = true;
    _startMonday = calendarPrefs.startMonday;
    _reload();
  }

  void _onCalendarPrefs() {
    final startMonday = _calendarPrefs?.startMonday ?? false;
    if (!mounted || _startMonday == startMonday) return;
    _startMonday = startMonday;
    _reload();
  }

  void _onNavPrefs() {
    if (!mounted) return;
    _reload();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !widget.visible) return;
    _reloadFromDisk();
  }

  Future<void> _reloadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await TodoReminderService.instance.sync();
    if (mounted) await _reload();
  }

  void _onBackupRestored() {
    if (!mounted) return;
    _startMonday = AppScope.of(context).calendarPreference.startMonday;
    _reload();
  }

  void scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    AppBackupService.revision.removeListener(_onBackupRestored);
    _calendarPrefs?.removeListener(_onCalendarPrefs);
    _navPrefs?.removeListener(_onNavPrefs);
    _scroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final showJobs = scope.navPreference.showJobTab;
    final applications = showJobs
        ? await scope.getJobApplications()
        : const <JobApplication>[];
    final categories = await scope.getEventCategories();
    final companyCategories = showJobs
        ? await scope.fetchCategories(CategoryKind.company)
        : const <EventCategory>[];
    final homePrefs = scope.homeViewPreference;
    if (!mounted) return;
    final weekEnd = _weekEnd;
    final monthEnd = DateTime(_today.year, _today.month + 1, 0);
    final includeRejected = scope.jobViewPreference.showRejected;
    setState(() {
      _todayEvents = calendarEventsOn(
        date: _today,
        events: events,
        applications: applications,
        companyCategories: companyCategories,
        includeRejected: includeRejected,
      );
      _tomorrowEvents = calendarEventsOn(
        date: _tomorrow,
        events: events,
        applications: applications,
        companyCategories: companyCategories,
        includeRejected: includeRejected,
      );
      _weekEvents = homePrefs.showWeek
          ? calendarEventsInRange(
              start: _today,
              end: weekEnd,
              events: events,
              applications: applications,
              companyCategories: companyCategories,
              includeRejected: includeRejected,
            )
          : const <CalendarEvent>[];
      _weekLabel = homePrefs.showWeek
          ? calendarRangeLabel(_today, weekEnd)
          : null;
      _monthEvents = homePrefs.showMonth
          ? calendarEventsInRange(
              start: _today,
              end: monthEnd,
              events: events,
              applications: applications,
              companyCategories: companyCategories,
              includeRejected: includeRejected,
            )
          : const <CalendarEvent>[];
      _monthLabel = homePrefs.showMonth
          ? calendarRangeLabel(_today, monthEnd)
          : null;
      _leftoverEvents = leftoverTodosBefore(_today, events);
      _somedayEvents = [
        for (final event in events)
          if (event.someday && !event.isJob) event,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _categories = categories;
      _longGoals = List.of(scope.longGoalStore.goals);
      _memos = List.of(scope.memoStore.memos);
      _loading = false;
    });
  }

  Future<void> _openMonthlyStats() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const MonthlyStatsScreen(),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openWeeklyStats() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const MonthlyStatsScreen(weekly: true),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openLeftover() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LeftoverTodosScreen(),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AllEventsScreen(),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsScreen(),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottomGap = 88 +
        (PcLayout.isPc ? PcLayout.navLift : 0) +
        MediaQuery.paddingOf(context).bottom;
    final leftover = _leftoverEvents;
    final sortPrefs = AppScope.of(context).dayEventsViewPreference;
    final homePrefs = AppScope.of(context).homeViewPreference;

    return AppSkinBackground(
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: OverlayAppBar(
        title: const AppBarWordmark(slot: WordmarkSlot.home),
        actions: TutorialAnchor(
          id: TutorialAnchorId.homeTools,
          child: AppBarIconGroup(
            actions: [
              AppBarIconAction(
                asset: AppIcons.search,
                label: AppScope.of(context).navPreference.showJobTab
                    ? AppStrings.homeSearchHint
                    : AppStrings.homeSearchHintDaily,
                onPressed: _openSearch,
              ),
              AppBarIconAction(
                asset: AppIcons.setting,
                label: AppStrings.settingsTitle,
                onPressed: _openSettings,
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeIn(
              child: TutorialAnchor(
                id: TutorialAnchorId.homeList,
                child: _homeList(
                  leftover: leftover,
                  homePrefs: homePrefs,
                  sortPrefs: sortPrefs,
                  bottomGap: bottomGap,
                ),
              ),
            ),
    ),
    );
  }

  Widget _homeList({
    required List<CalendarEvent> leftover,
    required HomeViewPreference homePrefs,
    required DayEventsViewPreference sortPrefs,
    required double bottomGap,
  }) {
    final stats = <Widget>[];
    if (homePrefs.shouldShowWeeklyStats(_today)) {
      stats.add(
        HomeMonthlyStatsCard(
          title: AppStrings.weeklyStatsCardTitle,
          onPressed: _openWeeklyStats,
        ),
      );
    }
    if (homePrefs.shouldShowMonthlyStats(_today)) {
      stats.add(
        HomeMonthlyStatsCard(
          title: AppStrings.monthlyStatsCardTitle(
            DateTime(_today.year, _today.month - 1).month,
          ),
          onPressed: _openMonthlyStats,
        ),
      );
    }
    if (homePrefs.showLeftover && leftover.isNotEmpty) {
      stats.add(
        HomeLeftoverCard(
          count: leftover.length,
          onPressed: _openLeftover,
        ),
      );
    }

    final kinds = [
      for (final kind in homePrefs.cardOrder)
        if (kind != HomeCardKind.leftover &&
            _showsCard(kind, leftover: leftover, homePrefs: homePrefs))
          kind,
    ];

    final header = Column(
      children: [
        if (homePrefs.showFriends) const HomeFriendsRow(),
        if (stats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  stats[i],
                ],
              ],
            ),
          ),
      ],
    );

    final list = ReorderableListView(
      scrollController: _scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        OverlayAppBar.overlapOf(context) + 8,
        16,
        bottomGap,
      ),
      buildDefaultDragHandles: false,
      header: header,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(animation.value);
            return Transform.translate(
              offset: Offset(0, -8 * t),
              child: Transform.scale(
                scale: 1 + 0.04 * t,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorder: (oldIndex, newIndex) => _reorderCards(
        kinds,
        oldIndex: oldIndex,
        newIndex: newIndex,
        homePrefs: homePrefs,
      ),
      children: [
        for (var i = 0; i < kinds.length; i++)
          ReorderableDelayedDragStartListener(
            key: ValueKey(kinds[i].name),
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _layoutCard(
                kinds[i],
                leftover: leftover,
                homePrefs: homePrefs,
                sortPrefs: sortPrefs,
              ),
            ),
          ),
      ],
    );
    if (!PcLayout.isPc) return list;
    return PcLayout.constrainWidth(list);
  }

  bool _showsCard(
    HomeCardKind kind, {
    required List<CalendarEvent> leftover,
    required HomeViewPreference homePrefs,
  }) {
    return switch (kind) {
      HomeCardKind.leftover => homePrefs.showLeftover && leftover.isNotEmpty,
      HomeCardKind.memo => homePrefs.showMemo,
      HomeCardKind.today => homePrefs.showToday,
      HomeCardKind.tomorrow => homePrefs.showTomorrow,
      HomeCardKind.week => homePrefs.showWeek,
      HomeCardKind.month => homePrefs.showMonth,
      HomeCardKind.someday => homePrefs.showSomeday,
      HomeCardKind.longGoal => homePrefs.showLongGoal,
    };
  }

  Widget _layoutCard(
    HomeCardKind kind, {
    required List<CalendarEvent> leftover,
    required HomeViewPreference homePrefs,
    required DayEventsViewPreference sortPrefs,
  }) {
    return switch (kind) {
      HomeCardKind.leftover => HomeLeftoverCard(
          count: leftover.length,
          onPressed: _openLeftover,
        ),
      HomeCardKind.memo => HomeMemoCard(
          memos: _memos,
          onChanged: _reload,
        ),
      HomeCardKind.today => HomeDayCard(
          title: AppStrings.todayTitle,
          date: _today,
          events: _todayEvents,
          categories: _categories,
          categoryView: sortPrefs.categoryView,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          hour24: sortPrefs.hour24,
          onEventsChanged: _reload,
        ),
      HomeCardKind.tomorrow => HomeDayCard(
          title: AppStrings.tomorrowTitle,
          date: _tomorrow,
          events: _tomorrowEvents,
          categories: _categories,
          categoryView: sortPrefs.categoryView,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          hour24: sortPrefs.hour24,
          onEventsChanged: _reload,
        ),
      HomeCardKind.week => HomeDayCard(
          title: AppStrings.weekTitle,
          events: _weekEvents,
          categories: _categories,
          categoryView: sortPrefs.categoryView,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          hour24: sortPrefs.hour24,
          showAddButton: false,
          dateLabel: _weekLabel,
          groupDates: calendarDaysInRange(_today, _weekEnd),
          onEventsChanged: _reload,
        ),
      HomeCardKind.month => HomeDayCard(
          title: AppStrings.monthTitle,
          events: _monthEvents,
          categories: _categories,
          categoryView: sortPrefs.categoryView,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          hour24: sortPrefs.hour24,
          showAddButton: false,
          dateLabel: _monthLabel,
          groupDates: calendarDaysInRange(
            _today,
            DateTime(_today.year, _today.month + 1, 0),
          ),
          onEventsChanged: _reload,
        ),
      HomeCardKind.someday => HomeDayCard(
          title: AppStrings.somedayTitle,
          date: null,
          events: _somedayEvents,
          categories: _categories,
          categoryView: sortPrefs.categoryView,
          sortByTime: sortPrefs.sortByTime,
          showTime: false,
          someday: true,
          onEventsChanged: _reload,
        ),
      HomeCardKind.longGoal => HomeLongGoalCard(
          goals: _longGoals,
          categories: _categories,
          today: _today,
          compact: false,
          onChanged: _reload,
        ),
    };
  }

  void _reorderCards(
    List<HomeCardKind> visible, {
    required int oldIndex,
    required int newIndex,
    required HomeViewPreference homePrefs,
  }) {
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    if (to == oldIndex) return;
    if (visible[oldIndex] == HomeCardKind.leftover) return;
    final nextVisible = List<HomeCardKind>.of(visible);
    final moved = nextVisible.removeAt(oldIndex);
    nextVisible.insert(to, moved);
    final queue = List<HomeCardKind>.of(nextVisible);
    final rest = <HomeCardKind>[
      for (final kind in homePrefs.cardOrder)
        if (kind != HomeCardKind.leftover)
          if (visible.contains(kind)) queue.removeAt(0) else kind,
    ];
    homePrefs.setCardOrder([HomeCardKind.leftover, ...rest]);
    setState(() {});
  }
}
