import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/data/datasources/day_events_view_preference.dart';
import 'package:job_planner/data/datasources/home_view_preference.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/home/leftover_todos_screen.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_day_card.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_leftover_card.dart';
import 'package:job_planner/presentation/screens/settings/settings_screen.dart';
import 'package:job_planner/presentation/widgets/app_bar_icon_group.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.visible = true});

  final bool visible;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
  var _loading = true;
  var _initialized = false;
  var _compact = false;
  var _searchOpen = false;
  String? _weekLabel;
  String? _monthLabel;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _tomorrow => _today.add(const Duration(days: 1));

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
    if (_initialized) return;
    _initialized = true;
    _compact = AppScope.of(context).homeViewPreference.isCompact;
    _reload();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _reload();
  }

  @override
  void dispose() {
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
    final weekEnd = _today.add(const Duration(days: 6));
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
      _loading = false;
    });
  }

  Future<void> _toggleCompact() async {
    final next = !_compact;
    setState(() => _compact = next);
    await AppScope.of(context).homeViewPreference.setCompact(next);
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).background,
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
                            style: const TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.homeSearchHint,
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.pretendard,
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
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
                      children: [
                        ..._homeCards(
                          leftover: leftover,
                          homePrefs: homePrefs,
                          sortPrefs: sortPrefs,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _homeCards({
    required List<CalendarEvent> leftover,
    required HomeViewPreference homePrefs,
    required DayEventsViewPreference sortPrefs,
  }) {
    final cards = <Widget>[];

    void add(Widget card) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 12));
      cards.add(card);
    }

    if (homePrefs.showLeftover && leftover.isNotEmpty) {
      add(
        HomeLeftoverCard(
          count: leftover.length,
          onPressed: _openLeftover,
        ),
      );
    }
    if (homePrefs.showToday) {
      add(
        HomeDayCard(
          key: const ValueKey('today'),
          title: AppStrings.todayTitle,
          date: _today,
          events: _filter(_todayEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          onEventsChanged: _reload,
        ),
      );
    }
    if (homePrefs.showTomorrow) {
      add(
        HomeDayCard(
          key: const ValueKey('tomorrow'),
          title: AppStrings.tomorrowTitle,
          date: _tomorrow,
          events: _filter(_tomorrowEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          onEventsChanged: _reload,
        ),
      );
    }
    if (homePrefs.showWeek) {
      add(
        HomeDayCard(
          key: const ValueKey('week'),
          title: AppStrings.weekTitle,
          events: _filter(_weekEvents),
          categories: _categories,
          compact: _compact,
          sortByTime: sortPrefs.sortByTime,
          showTime: sortPrefs.showTime,
          showAddButton: false,
          dateLabel: _weekLabel,
          groupDates: calendarDaysInRange(
            _today,
            _today.add(const Duration(days: 6)),
          ),
          onEventsChanged: _reload,
        ),
      );
    }
    if (homePrefs.showMonth) {
      add(
        HomeDayCard(
          key: const ValueKey('month'),
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
      );
    }
    return cards;
  }
}
