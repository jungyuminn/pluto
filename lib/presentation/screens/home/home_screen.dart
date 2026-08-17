import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/home/leftover_todos_screen.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_day_card.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_leftover_card.dart';
import 'package:job_planner/presentation/screens/settings/settings_screen.dart';
import 'package:job_planner/presentation/widgets/app_bar_icon_group.dart';

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
  var _leftoverEvents = <CalendarEvent>[];
  var _categories = <EventCategory>[];
  var _loading = true;
  var _initialized = false;
  var _compact = false;
  var _searchOpen = false;

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
    if (!mounted) return;
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
    setState(() {
      _compact = AppScope.of(context).homeViewPreference.isCompact;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomGap = 88 + MediaQuery.paddingOf(context).bottom;
    final leftover = _filter(_leftoverEvents);
    final sortPrefs = AppScope.of(context).dayEventsViewPreference;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: Image.asset(
          AppIcons.logo,
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
                              hintStyle: const TextStyle(
                                fontFamily: AppFonts.pretendard,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                        if (leftover.isNotEmpty) ...[
                          HomeLeftoverCard(
                            count: leftover.length,
                            onPressed: _openLeftover,
                          ),
                          const SizedBox(height: 12),
                        ],
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
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
