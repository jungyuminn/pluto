import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/data/datasources/calendar_preference.dart';
import 'package:job_planner/data/datasources/day_events_view_preference.dart';
import 'package:job_planner/data/datasources/home_view_preference.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/long_goal.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/home/leftover_todos_screen.dart';
import 'package:job_planner/presentation/screens/home/monthly_stats_screen.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_day_card.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_leftover_card.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_long_goal_card.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_monthly_stats_card.dart';
import 'package:job_planner/presentation/screens/settings/settings_screen.dart';
import 'package:job_planner/presentation/widgets/app_bar_icon_group.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.visible = true});

  final bool visible;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _search = PlainTextEditingController();
  final _searchFocus = FocusNode();
  late final AnimationController _searchAnimation;
  late final CurvedAnimation _searchFade;
  var _todayEvents = <CalendarEvent>[];
  var _tomorrowEvents = <CalendarEvent>[];
  var _weekEvents = <CalendarEvent>[];
  var _monthEvents = <CalendarEvent>[];
  var _leftoverEvents = <CalendarEvent>[];
  var _categories = <EventCategory>[];
  var _longGoals = <LongGoal>[];
  var _loading = true;
  var _initialized = false;
  var _compact = false;
  var _searchOpen = false;
  var _startMonday = false;
  CalendarPreference? _calendarPrefs;
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

  List<CalendarEvent> _filter(List<CalendarEvent> events) {
    final query = _search.text;
    if (KoreanSearch.compact(query).isEmpty) return events;
    return events.where((event) {
      return KoreanSearch.matchesAny(
        [event.title, event.categoryName],
        query,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _searchFade = CurvedAnimation(
      parent: _searchAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
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
    if (_initialized) return;
    _initialized = true;
    _compact = AppScope.of(context).homeViewPreference.isCompact;
    _startMonday = calendarPrefs.startMonday;
    _reload();
  }

  void _onCalendarPrefs() {
    final startMonday = _calendarPrefs?.startMonday ?? false;
    if (!mounted || _startMonday == startMonday) return;
    _startMonday = startMonday;
    _reload();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _reload();
    if (!widget.visible && oldWidget.visible) _searchFocus.unfocus();
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

  @override
  void dispose() {
    _calendarPrefs?.removeListener(_onCalendarPrefs);
    WidgetsBinding.instance.removeObserver(this);
    _searchFade.dispose();
    _searchAnimation.dispose();
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final applications = await scope.getJobApplications();
    final categories = await scope.getEventCategories();
    final homePrefs = scope.homeViewPreference;
    if (!mounted) return;
    final weekEnd = _weekEnd;
    final monthEnd = DateTime(_today.year, _today.month + 1, 0);
    setState(() {
      _todayEvents = calendarEventsOn(
        date: _today,
        events: events,
        applications: applications,
      );
      _tomorrowEvents = calendarEventsOn(
        date: _tomorrow,
        events: events,
        applications: applications,
      );
      _weekEvents = homePrefs.showWeek
          ? calendarEventsInRange(
              start: _today,
              end: weekEnd,
              events: events,
              applications: applications,
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
            )
          : const <CalendarEvent>[];
      _monthLabel = homePrefs.showMonth
          ? calendarRangeLabel(_today, monthEnd)
          : null;
      _leftoverEvents = leftoverTodosBefore(_today, events);
      _categories = categories;
      _longGoals = List.of(scope.longGoalStore.goals);
      _loading = false;
    });
  }

  Future<void> _toggleCompact() async {
    final next = !_compact;
    setState(() => _compact = next);
    await AppScope.of(context).homeViewPreference.setCompact(next);
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

  Future<void> _toggleSearch() async {
    if (_searchOpen) {
      _searchFocus.unfocus();
      await _searchAnimation.reverse();
      if (!mounted) return;
      setState(() {
        _searchOpen = false;
        _search.clear();
      });
      return;
    }

    setState(() => _searchOpen = true);
    await _searchAnimation.forward();
    if (mounted) _searchFocus.requestFocus();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsScreen(),
      ),
    );
    if (!mounted) return;
    _compact = AppScope.of(context).homeViewPreference.isCompact;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottomGap = 88 + MediaQuery.paddingOf(context).bottom;
    final leftover = _filter(_leftoverEvents);
    final sortPrefs = AppScope.of(context).dayEventsViewPreference;
    final homePrefs = AppScope.of(context).homeViewPreference;

    return AppSkinBackground(
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: ThemedAsset(
          asset: AppIcons.logo,
          height: 120,
          semanticLabel: AppStrings.appName,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AppBarIconGroup(
                actions: [
                  AppBarIconAction(
                    asset: AppIcons.search,
                    label: AppStrings.homeSearchHint,
                    selected: _searchOpen,
                    onPressed: _toggleSearch,
                  ),
                  AppBarIconAction(
                    asset: _compact
                        ? AppIcons.detailView
                        : AppIcons.quickView,
                    label: _compact
                        ? AppStrings.detailedView
                        : AppStrings.compactView,
                    onPressed: _toggleCompact,
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
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeIn(
              child: Column(
                children: [
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _searchFade,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _searchFade,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: TextField(
                            controller: _search,
                            focusNode: _searchFocus,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.homeSearchHint,
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.of(context),
                                color: AppColors.of(context).muted,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: AppColors.of(context).card,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _homeList(
                      leftover: leftover,
                      homePrefs: homePrefs,
                      sortPrefs: sortPrefs,
                      bottomGap: bottomGap,
                    ),
                  ),
                ],
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

    Widget? header;
    if (stats.isNotEmpty) {
      header = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              stats[i],
            ],
          ],
        ),
      );
    }

    return ReorderableListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
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
  }

  bool _showsCard(
    HomeCardKind kind, {
    required List<CalendarEvent> leftover,
    required HomeViewPreference homePrefs,
  }) {
    return switch (kind) {
      HomeCardKind.leftover => homePrefs.showLeftover && leftover.isNotEmpty,
      HomeCardKind.today => homePrefs.showToday,
      HomeCardKind.tomorrow => homePrefs.showTomorrow,
      HomeCardKind.week => homePrefs.showWeek,
      HomeCardKind.month => homePrefs.showMonth,
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
      HomeCardKind.today => HomeDayCard(
          title: AppStrings.todayTitle,
          date: _today,
          events: _filter(_todayEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          onEventsChanged: _reload,
        ),
      HomeCardKind.tomorrow => HomeDayCard(
          title: AppStrings.tomorrowTitle,
          date: _tomorrow,
          events: _filter(_tomorrowEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          onEventsChanged: _reload,
        ),
      HomeCardKind.week => HomeDayCard(
          title: AppStrings.weekTitle,
          events: _filter(_weekEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          showAddButton: false,
          dateLabel: _weekLabel,
          groupDates: calendarDaysInRange(_today, _weekEnd),
          onEventsChanged: _reload,
        ),
      HomeCardKind.month => HomeDayCard(
          title: AppStrings.monthTitle,
          events: _filter(_monthEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          showAddButton: false,
          dateLabel: _monthLabel,
          groupDates: calendarDaysInRange(
            _today,
            DateTime(_today.year, _today.month + 1, 0),
          ),
          onEventsChanged: _reload,
        ),
      HomeCardKind.longGoal => HomeLongGoalCard(
          goals: _longGoals,
          categories: _categories,
          today: _today,
          compact: _compact,
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
