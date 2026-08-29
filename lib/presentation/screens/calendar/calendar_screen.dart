import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/data/datasources/job_view_preference.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/domain/ledger_month_stats.dart';
import 'package:job_planner/domain/ledger_salary_repeat.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_header.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_search_bar.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/diary_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_day_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/ledger_month_stats_sheet.dart';
import 'package:job_planner/presentation/widgets/app_calendar/calendar_zoom_picker.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.visible = true});

  final bool visible;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _initialPage = 12000;

  late DateTime _baseMonth;
  late final PageController _pages;
  late DateTime _visibleMonth;
  late final PlainTextEditingController _search;
  late final FocusNode _searchFocus;
  late final AnimationController _searchAnimation;
  late final CurvedAnimation _searchFade;
  late final ValueNotifier<bool> _searchOpen;
  var _events = <CalendarEvent>[];
  var _diaries = <DiaryEntry>[];
  var _ledgers = <LedgerEntry>[];
  var _applications = <JobApplication>[];
  var _companyCategories = <EventCategory>[];
  var _eventCategories = <EventCategory>[];
  var _initialized = false;
  var _rangeDragging = false;
  var _showTodos = true;
  var _showCompanies = true;
  var _showDiary = false;
  var _showLedger = false;
  var _zoom = CalendarZoomLevel.days;
  var _zoomEpoch = 0;
  var _hits = <_SearchHit>[];
  var _hitIndex = 0;
  DateTime? _searchDay;
  String? _searchHitKey;
  JobViewPreference? _jobView;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showCurrentMonth();
    _pages = PageController(initialPage: _initialPage, keepPage: false);
    _search = PlainTextEditingController();
    _searchFocus = FocusNode();
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
    _searchOpen = ValueNotifier(false);
    AppBackupService.revision.addListener(_onBackupRestored);
  }

  void _onBackupRestored() {
    if (mounted) _reload();
  }

  void _onJobView() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppScope.of(context).jobViewPreference;
    if (!identical(next, _jobView)) {
      _jobView?.removeListener(_onJobView);
      _jobView = next;
      _jobView!.addListener(_onJobView);
    }
    if (_initialized) return;
    _initialized = true;
    _reload();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _collapseZoom();
      _reload();
    }
  }

  void _collapseZoom() {
    if (_zoom == CalendarZoomLevel.days) return;
    _zoom = CalendarZoomLevel.days;
    _zoomEpoch++;
  }

  @override
  void dispose() {
    AppBackupService.revision.removeListener(_onBackupRestored);
    _jobView?.removeListener(_onJobView);
    WidgetsBinding.instance.removeObserver(this);
    _searchFade.dispose();
    _searchAnimation.dispose();
    _searchOpen.dispose();
    _searchFocus.dispose();
    _search.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _showCurrentMonth(jump: true);
  }

  Future<void> _onTitlePressed() async {
    if (_zoom == CalendarZoomLevel.years) return;
    setState(() => _zoom = CalendarZoom.next(_zoom));
  }

  Future<void> _pickMonth(DateTime month) async {
    setState(() => _zoom = CalendarZoomLevel.days);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _goToMonth(month);
  }

  void _pickYear(int year) {
    setState(() {
      _visibleMonth = DateTime(year, _visibleMonth.month);
      _zoom = CalendarZoomLevel.months;
    });
  }

  void _showCurrentMonth({bool jump = false}) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    _baseMonth = current;
    _visibleMonth = current;
    _zoom = CalendarZoomLevel.days;
    if (!jump) return;
    if (_pages.hasClients) _pages.jumpToPage(_initialPage);
    if (mounted) setState(() {});
  }

  Future<void> _goToMonth(DateTime month) async {
    final target = DateTime(month.year, month.month);
    if (_visibleMonth.year == target.year &&
        _visibleMonth.month == target.month) {
      return;
    }
    if (!_pages.hasClients) {
      _baseMonth = target;
      _visibleMonth = target;
      if (mounted) setState(() {});
      return;
    }
    final delta =
        (target.year - _baseMonth.year) * 12 +
        (target.month - _baseMonth.month);
    final page = _initialPage + delta;
    final distance = (page - _pages.page!.round()).abs();
    if (distance > 18) {
      _pages.jumpToPage(page);
      setState(() => _visibleMonth = target);
      return;
    }
    final ms = (200 + distance * 45).clamp(240, 560);
    await _pages.animateToPage(
      page,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
  }

  DateTime _monthAt(int page) {
    return DateTime(_baseMonth.year, _baseMonth.month + (page - _initialPage));
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final diaries = await scope.getDiaries();
    final ledgers = await scope.getLedgers();
    final applications = await scope.getJobApplications();
    final companyCategories = await scope.fetchCategories(CategoryKind.company);
    final eventCategories = await scope.fetchCategories(CategoryKind.event);
    if (!mounted) return;
    setState(() {
      _events = events;
      _diaries = diaries;
      _ledgers = ledgers;
      _applications = applications;
      _companyCategories = companyCategories;
      _eventCategories = eventCategories;
    });
    if (_searchOpen.value) _refreshHits(jump: false);
  }

  Future<void> _toggleSearch() async {
    if (_searchOpen.value) {
      _searchFocus.unfocus();
      _searchOpen.value = false;
      await _searchAnimation.reverse();
      if (!mounted) return;
      _search.clear();
      if (_hits.isEmpty && _searchDay == null && _searchHitKey == null) {
        return;
      }
      setState(() {
        _hits = [];
        _hitIndex = 0;
        _searchDay = null;
        _searchHitKey = null;
      });
      return;
    }

    _searchOpen.value = true;
    await _searchAnimation.forward();
    if (mounted) _searchFocus.requestFocus();
  }

  void _onSearchChanged(String _) {
    _refreshHits(resetIndex: true);
  }

  void _refreshHits({bool jump = true, bool resetIndex = false}) {
    final hits = _searchHits(_search.text);
    final index = hits.isEmpty
        ? 0
        : (resetIndex ? 0 : _hitIndex.clamp(0, hits.length - 1));
    setState(() {
      _hits = hits;
      _hitIndex = index;
      _searchDay = hits.isEmpty ? null : hits[index].day;
      _searchHitKey = hits.isEmpty ? null : hits[index].key;
    });
    if (jump && hits.isNotEmpty) _revealHit(hits[index].day);
  }

  List<_SearchHit> _searchHits(String query) {
    if (KoreanSearch.compact(query).isEmpty) return const [];
    final latest = <String, DateTime>{};

    void consider(String key, DateTime date, Iterable<String> texts) {
      if (!KoreanSearch.matchesAny(texts, query)) return;
      final day = DateTime(date.year, date.month, date.day);
      final current = latest[key];
      if (current == null || day.isAfter(current)) latest[key] = day;
    }

    if (_showDiary) {
      for (final diary in _diaries) {
        consider(
          diary.groupId ?? diary.id,
          diary.day,
          [diary.title, diary.body, diary.categoryName],
        );
      }
    } else if (_showLedger) {
      for (final entry in _ledgers) {
        consider(
          entry.id,
          LedgerSalaryRepeat.searchDay(entry),
          [
            entry.title,
            entry.memo,
            entry.signedLabel,
            '${entry.amount}',
            entry.kindLabel,
          ],
        );
      }
    } else {
      if (_showTodos) {
        for (final event in _events) {
          if (event.isJob || event.someday) continue;
          consider(
            event.groupId ?? event.id,
            event.day,
            [event.title, event.categoryName],
          );
        }
      }
      if (_showCompanies) {
        final showRejected =
            AppScope.of(context).jobViewPreference.showRejected;
        for (final application in _applications) {
          if (!showRejected && application.isRejected) continue;
          for (var i = 0; i < application.rounds.length; i++) {
            final round = application.rounds[i];
            final date = round.date;
            if (date == null) continue;
            consider(
              'job:${application.id}:$i',
              date,
              [application.companyName, application.categoryName],
            );
          }
        }
      }
    }

    return [
      for (final entry in latest.entries)
        _SearchHit(key: entry.key, day: entry.value),
    ]..sort((a, b) {
        final byDay = b.day.compareTo(a.day);
        if (byDay != 0) return byDay;
        return a.key.compareTo(b.key);
      });
  }

  Future<void> _revealHit(DateTime day) async {
    if (_zoom != CalendarZoomLevel.days) {
      setState(() => _zoom = CalendarZoomLevel.days);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await _goToMonth(day);
  }

  void _searchStep(int delta) {
    if (_hits.isEmpty) return;
    final next = (_hitIndex + delta) % _hits.length;
    final index = next < 0 ? next + _hits.length : next;
    setState(() {
      _hitIndex = index;
      _searchDay = _hits[index].day;
      _searchHitKey = _hits[index].key;
    });
    _revealHit(_hits[index].day);
  }

  List<CalendarEvent> _eventsOn(DateTime date) {
    final events = calendarEventsOn(
      date: date,
      events: _showTodos ? _events : const [],
      applications: _showCompanies ? _applications : const [],
      companyCategories: _companyCategories,
      includeRejected: AppScope.of(context).jobViewPreference.showRejected,
    );
    final prefs = AppScope.of(context).dayEventsViewPreference;
    if (prefs.categoryView) {
      return calendarEventsByCategory(
        events,
        categories: _eventCategories,
        sortByTime: prefs.sortByTime,
      );
    }
    if (!prefs.sortByTime) return events;
    return CalendarEvent.withLockedThenStartTime(events);
  }

  List<LedgerEntry> _ledgersOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return [
      for (final entry in _ledgers)
        if (LedgerSalaryRepeat.occursOn(entry, day))
          LedgerSalaryRepeat.onDay(entry, day),
    ]..sort(LedgerEntry.compareDisplay);
  }

  List<DiaryEntry> _diariesOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return [
      for (final diary in _diaries)
        if (diary.day == day) diary,
    ];
  }

  ({DateTime start, DateTime end})? _diarySpan(DiaryEntry diary) {
    final groupId = diary.groupId;
    if (groupId == null) return null;
    DateTime? start;
    DateTime? end;
    for (final item in _diaries) {
      if (item.groupId != groupId) continue;
      if (start == null || item.day.isBefore(start)) start = item.day;
      if (end == null || item.day.isAfter(end)) end = item.day;
    }
    if (start == null || end == null || start == end) return null;
    return (start: start, end: end);
  }

  DiaryEntry? _diaryToOpen(DateTime date) {
    final onDay = _diariesOn(date);
    if (onDay.isEmpty) return null;
    final day = DateTime(date.year, date.month, date.day);
    DiaryEntry? startsToday;
    DiaryEntry? single;
    DiaryEntry? earliest;
    DateTime? earliestStart;
    for (final diary in onDay) {
      final span = _diarySpan(diary);
      if (span != null && span.start == day) {
        startsToday ??= diary;
      } else if (span == null) {
        single ??= diary;
      }
      final start = span?.start ?? diary.day;
      if (earliestStart == null || start.isBefore(earliestStart)) {
        earliestStart = start;
        earliest = diary;
      }
    }
    return startsToday ?? single ?? earliest;
  }

  Future<void> _openDay(DateTime date, Rect origin) async {
    if (_showLedger) {
      await showLedgerDaySheet(
        context,
        date: date,
        entries: _ledgersOn(date),
        origin: origin,
      );
      if (mounted) await _reload();
      return;
    }
    if (_showDiary) {
      final diary = _diaryToOpen(date);
      final span = diary == null ? null : _diarySpan(diary);
      await showDiarySheet(
        context,
        date: span?.start ?? date,
        rangeEnd: span?.end,
        initial: diary,
      );
      if (mounted) await _reload();
      return;
    }
    await showDayEventsDialog(
      context,
      date: date,
      events: _eventsOn(date),
      origin: origin,
      onEventsChanged: () {
        _reload();
      },
    );
    if (mounted) await _reload();
  }

  Future<void> _openRange(DateTime start, DateTime end) async {
    if (_showDiary) {
      await showDiarySheet(context, date: start, rangeEnd: end);
    } else {
      await showAddEventSheet(context, date: start, rangeEnd: end);
    }
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottomGap = 72 + MediaQuery.paddingOf(context).bottom;

    return AppSkinBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: AppScope.of(context).calendarPreference,
                    builder: (context, _) {
                      final startMonday = AppScope.of(
                        context,
                      ).calendarPreference.startMonday;
                      final showLunar = AppScope.of(
                        context,
                      ).calendarPreference.showLunar;
                      final viewPrefs =
                          AppScope.of(context).dayEventsViewPreference;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: _searchOpen,
                            builder: (context, searchOpen, _) {
                              return CalendarMonthHeader(
                                month: _visibleMonth,
                                title: CalendarZoom.title(
                                  _zoom,
                                  _visibleMonth,
                                  hideCurrentYear: true,
                                ),
                                onTitlePressed: _zoom == CalendarZoomLevel.years
                                    ? null
                                    : _onTitlePressed,
                                showTodos: _showTodos,
                                showCompanies: _showCompanies,
                                showDiary: _showDiary,
                                showLedger: _showLedger,
                                searchOpen: searchOpen,
                                onSearchPressed: _toggleSearch,
                                onShowTodosChanged: (value) {
                                  setState(() => _showTodos = value);
                                  if (_searchOpen.value) _refreshHits();
                                },
                                onShowCompaniesChanged: (value) {
                                  setState(() => _showCompanies = value);
                                  if (_searchOpen.value) _refreshHits();
                                },
                                onShowDiaryChanged: (value) {
                                  setState(() {
                                    _showDiary = value;
                                    if (value) _showLedger = false;
                                  });
                                  if (_searchOpen.value) _refreshHits();
                                },
                                onShowLedgerChanged: (value) {
                                  setState(() {
                                    _showLedger = value;
                                    if (value) _showDiary = false;
                                  });
                                  if (_searchOpen.value) _refreshHits();
                                },
                                onSortPrefsChanged: () => setState(() {}),
                                onCategoriesChanged: _reload,
                                ledgerMonthStats:
                                    _showLedger &&
                                        _zoom == CalendarZoomLevel.days
                                    ? LedgerMonthStats.of(
                                        month: _visibleMonth,
                                        entries: _ledgers,
                                      )
                                    : null,
                                onLedgerStatsPressed: () {
                                  showLedgerMonthStatsSheet(
                                    context,
                                    month: _visibleMonth,
                                    stats: LedgerMonthStats.of(
                                      month: _visibleMonth,
                                      entries: _ledgers,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          ClipRect(
                            child: SizeTransition(
                              sizeFactor: _searchFade,
                              axisAlignment: -1,
                              child: FadeTransition(
                                opacity: _searchFade,
                                child: CalendarSearchBar(
                                  controller: _search,
                                  focusNode: _searchFocus,
                                  hintText: _showLedger
                                      ? AppStrings.calendarLedgerSearchHint
                                      : _showDiary
                                          ? AppStrings.calendarDiarySearchHint
                                          : AppStrings.calendarSearchHint,
                                  onChanged: _onSearchChanged,
                                  onSubmitted: () => _searchStep(1),
                                  onPrevious: () => _searchStep(-1),
                                  onNext: () => _searchStep(1),
                                  index: _hitIndex,
                                  total: _hits.length,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _SearchStableViewport(
                              animation: _searchAnimation,
                              child: TutorialAnchor(
                                id: TutorialAnchorId.calendarGrid,
                                child: RepaintBoundary(
                                  child: CalendarZoomTransition(
                                    key: ValueKey(_zoomEpoch),
                                    level: _zoom,
                                    child: switch (_zoom) {
                                      CalendarZoomLevel.days => Column(
                                        children: [
                                          CalendarWeekdayHeader(
                                            startMonday: startMonday,
                                          ),
                                          Expanded(
                                            child: PageView.builder(
                                              controller: _pages,
                                              physics: _rangeDragging
                                                  ? const NeverScrollableScrollPhysics()
                                                  : null,
                                              onPageChanged: (page) {
                                                setState(
                                                  () => _visibleMonth =
                                                      _monthAt(page),
                                                );
                                              },
                                              itemBuilder: (context, page) {
                                                final emojis =
                                                    AppScope.of(context)
                                                        .dayEmojiStore;
                                                return ListenableBuilder(
                                                  listenable: emojis,
                                                  builder: (context, _) {
                                                    return CalendarMonthGrid(
                                                      month: _monthAt(page),
                                                      startMonday: startMonday,
                                                      showLunar: showLunar,
                                                      eventsOf: _eventsOn,
                                                      diariesOf: _diariesOn,
                                                      ledgersOf: _ledgersOn,
                                                      emojisOf: emojis.on,
                                                      showDiary: _showDiary,
                                                      showLedger: _showLedger,
                                                      showLedgerTitle:
                                                          viewPrefs
                                                              .showLedgerTitle,
                                                      showLedgerAmount:
                                                          viewPrefs
                                                              .showLedgerAmount,
                                                      ledgerCategoryView:
                                                          viewPrefs
                                                              .categoryView,
                                                      searchDay: _searchDay,
                                                      searchHitKey:
                                                          _searchHitKey,
                                                      onDayPressed: _openDay,
                                                      onRangeDragChanged:
                                                          (dragging) {
                                                        setState(
                                                          () => _rangeDragging =
                                                              dragging,
                                                        );
                                                      },
                                                      onRangeSelected:
                                                          _showLedger
                                                              ? null
                                                              : _openRange,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      CalendarZoomLevel.months =>
                                        CalendarMonthZoomView(
                                          focused: _visibleMonth,
                                          accent: AppColors.of(
                                            context,
                                          ).accentBright,
                                          onFocusedChanged: (month) {
                                            setState(
                                              () => _visibleMonth = month,
                                            );
                                          },
                                          onMonthPressed: _pickMonth,
                                        ),
                                      CalendarZoomLevel.years =>
                                        CalendarYearZoomView(
                                          focused: _visibleMonth,
                                          accent: AppColors.of(
                                            context,
                                          ).accentBright,
                                          onFocusedChanged: (month) {
                                            setState(
                                              () => _visibleMonth = month,
                                            );
                                          },
                                          onYearPressed: _pickYear,
                                        ),
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchHit {
  const _SearchHit({required this.key, required this.day});

  final String key;
  final DateTime day;
}

class _SearchStableViewport extends StatefulWidget {
  const _SearchStableViewport({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<_SearchStableViewport> createState() => _SearchStableViewportState();
}

class _SearchStableViewportState extends State<_SearchStableViewport> {
  double? _restHeight;
  double? _frozenHeight;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(_SearchStableViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) return;
    oldWidget.animation.removeStatusListener(_onStatus);
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted) return;
    setState(() {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _frozenHeight = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;
        final status = widget.animation.status;
        if (status == AnimationStatus.dismissed) {
          _restHeight = available;
          return widget.child;
        }
        if (status == AnimationStatus.completed) {
          return widget.child;
        }
        _frozenHeight ??= _restHeight ?? available;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: _frozenHeight,
            maxHeight: _frozenHeight,
            child: widget.child,
          ),
        );
      },
    );
  }
}
