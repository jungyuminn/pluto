import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/core/utils/korean_search.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/datasources/job_view_preference.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/ledger_month_stats.dart';
import 'package:pluto/domain/ledger_salary_repeat.dart';
import 'package:pluto/presentation/screens/calendar/calendar_day_events.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_month_header.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_search_bar.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';
import 'package:pluto/presentation/screens/calendar/widgets/diary_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_day_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_month_stats_sheet.dart';
import 'package:pluto/presentation/widgets/app_calendar/calendar_zoom_picker.dart';

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
  late PageController _pages;
  late DateTime _visibleMonth;
  late DateTime _daysMonth;
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
  var _showDiary = false;
  var _showLedger = false;

  DayStickerLayer get _stickerLayer =>
      DayStickerLayer.current(showDiary: _showDiary, showLedger: _showLedger);

  var _zoom = CalendarZoomLevel.days;
  var _zoomEpoch = 0;
  var _hits = <_SearchHit>[];
  var _hitIndex = 0;
  var _pausedInBackground = false;
  DateTime? _searchDay;
  String? _searchHitKey;
  JobViewPreference? _jobView;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showCurrentMonth();
    _daysMonth = _visibleMonth;
    _pages = PageController(initialPage: _initialPage);
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
      _restoreVisibleMonth();
      _reload();
    }
  }

  void _restoreVisibleMonth() {
    _showDays(_visibleMonth);
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
    if (state == AppLifecycleState.paused) {
      _pausedInBackground = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !_pausedInBackground) return;
    _pausedInBackground = false;
    if (!_pages.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCurrentMonth(jump: true);
      });
      return;
    }
    _showCurrentMonth(jump: true);
  }

  Future<void> _onTitlePressed() async {
    if (_zoom == CalendarZoomLevel.years) {
      await _showDays();
      return;
    }
    if (_zoom == CalendarZoomLevel.days) {
      _daysMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    }
    setState(() => _zoom = CalendarZoom.next(_zoom));
  }

  Future<void> _pickMonth(DateTime month) async {
    await _showDays(month);
  }

  Future<void> _showDays([DateTime? month]) async {
    final target = DateTime(
      (month ?? _visibleMonth).year,
      (month ?? _visibleMonth).month,
    );
    _attachPagesAt(_daysMonth);
    if (!mounted) return;
    setState(() => _zoom = CalendarZoomLevel.days);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!_pages.hasClients) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await _goToMonth(target);
    _daysMonth = target;
  }

  void _attachPagesAt(DateTime month) {
    if (_pages.hasClients) return;
    final page = _pageOf(DateTime(month.year, month.month));
    if (_pages.initialPage == page) return;
    final previous = _pages;
    _pages = PageController(initialPage: page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
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
    _daysMonth = current;
    _zoom = CalendarZoomLevel.days;
    if (!jump) return;
    if (_pages.hasClients) _pages.jumpToPage(_initialPage);
    if (mounted) setState(() {});
  }

  Future<void> _goToMonth(DateTime month) async {
    final target = DateTime(month.year, month.month);
    if (!_pages.hasClients) {
      if (mounted) setState(() => _visibleMonth = target);
      return;
    }
    final page = _pageOf(target);
    final current = _pages.page?.round() ?? _initialPage;
    if (current == page) {
      if (_visibleMonth.year != target.year ||
          _visibleMonth.month != target.month) {
        setState(() => _visibleMonth = target);
      }
      return;
    }
    final distance = (page - current).abs();
    if (distance > 18) {
      _jumpToMonth(target);
      return;
    }
    final ms = (200 + distance * 45).clamp(240, 560);
    await _pages.animateToPage(
      page,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    if (_visibleMonth.year != target.year ||
        _visibleMonth.month != target.month) {
      setState(() => _visibleMonth = target);
    }
  }

  int _pageOf(DateTime month) {
    final delta =
        (month.year - _baseMonth.year) * 12 + (month.month - _baseMonth.month);
    return _initialPage + delta;
  }

  void _jumpToMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    if (_pages.hasClients) {
      final page = _pageOf(target);
      if ((_pages.page?.round() ?? _initialPage) != page) {
        _pages.jumpToPage(page);
      }
    }
    if (_visibleMonth.year == target.year &&
        _visibleMonth.month == target.month) {
      return;
    }
    if (mounted) setState(() => _visibleMonth = target);
  }

  DateTime _monthAt(int page) {
    return DateTime(_baseMonth.year, _baseMonth.month + (page - _initialPage));
  }

  void _stepCalendar(int direction) {
    final next = switch (_zoom) {
      CalendarZoomLevel.days => DateTime(
        _visibleMonth.year,
        _visibleMonth.month + direction,
      ),
      CalendarZoomLevel.months => DateTime(
        _visibleMonth.year + direction,
        _visibleMonth.month,
      ),
      CalendarZoomLevel.years => DateTime(
        _visibleMonth.year + 10 * direction,
        _visibleMonth.month,
      ),
    };
    _goToMonth(next);
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
        consider(diary.groupId ?? diary.id, diary.day, [
          diary.title,
          diary.body,
          diary.categoryName,
        ]);
      }
    } else if (_showLedger) {
      for (final entry in _ledgers) {
        consider(entry.id, LedgerSalaryRepeat.searchDay(entry), [
          entry.title,
          entry.memo,
          entry.signedLabel,
          '${entry.amount}',
          entry.kindLabel,
          entry.displayCategoryName,
        ]);
      }
    } else {
      final calendarPrefs = AppScope.of(context).calendarPreference;
      if (calendarPrefs.showTodos) {
        for (final event in _events) {
          if (event.isJob || event.someday) continue;
          consider(event.groupId ?? event.id, event.day, [
            event.title,
            event.categoryName,
          ]);
        }
      }
      if (calendarPrefs.showCompanies &&
          AppScope.of(context).navPreference.showJobTab) {
        final showRejected = AppScope.of(
          context,
        ).jobViewPreference.showRejected;
        for (final application in _applications) {
          if (!showRejected && application.isRejected) continue;
          for (var i = 0; i < application.rounds.length; i++) {
            final round = application.rounds[i];
            final date = round.date;
            if (date == null) continue;
            consider('job:${application.id}:$i', date, [
              application.companyName,
              application.categoryName,
            ]);
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
    final calendarPrefs = AppScope.of(context).calendarPreference;
    final events = calendarEventsOn(
      date: date,
      events: calendarPrefs.showTodos ? _events : const [],
      applications:
          (calendarPrefs.showCompanies &&
              AppScope.of(context).navPreference.showJobTab)
          ? _applications
          : const [],
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
    final bottomGap =
        72 +
        (PcLayout.isPc ? PcLayout.navLift : 0) +
        MediaQuery.paddingOf(context).bottom;

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
                    listenable: Listenable.merge([
                      AppScope.of(context).calendarPreference,
                      AppScope.of(context).navPreference,
                    ]),
                    builder: (context, _) {
                      final calendarPrefs = AppScope.of(
                        context,
                      ).calendarPreference;
                      final showJobItems = AppScope.of(
                        context,
                      ).navPreference.showJobTab;
                      final startMonday = calendarPrefs.startMonday;
                      final showLunar = calendarPrefs.showLunar;
                      final viewPrefs = AppScope.of(
                        context,
                      ).dayEventsViewPreference;
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
                                onTitlePressed: _onTitlePressed,
                                showTodos: calendarPrefs.showTodos,
                                showCompanies: calendarPrefs.showCompanies,
                                showJobFilter: showJobItems,
                                showDiary: _showDiary,
                                showLedger: _showLedger,
                                searchOpen: searchOpen,
                                onSearchPressed: _toggleSearch,
                                onShowTodosChanged: (value) async {
                                  await AppScope.of(
                                    context,
                                  ).calendarPreference.setShowTodos(value);
                                  if (_searchOpen.value) _refreshHits();
                                },
                                onShowCompaniesChanged: (value) async {
                                  await AppScope.of(
                                    context,
                                  ).calendarPreference.setShowCompanies(value);
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
                                        _zoom == CalendarZoomLevel.days &&
                                        viewPrefs.showLedgerMonthStats
                                    ? LedgerMonthStats.of(
                                        month: _visibleMonth,
                                        entries: _ledgers,
                                      )
                                    : null,
                                onLedgerStatsPressed: () async {
                                  final day = await showLedgerMonthStatsSheet(
                                    context,
                                    month: _visibleMonth,
                                    stats: LedgerMonthStats.of(
                                      month: _visibleMonth,
                                      entries: _ledgers,
                                    ),
                                  );
                                  if (!mounted || day == null) return;
                                  await _openDay(day, Rect.zero);
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
                                      : showJobItems
                                      ? AppStrings.calendarSearchHint
                                      : AppStrings.calendarSearchHintDaily,
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
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned.fill(
                                  child: _SearchStableViewport(
                                  animation: _searchAnimation,
                                  child: TutorialAnchor(
                                    id: TutorialAnchorId.calendarGrid,
                                    child: RepaintBoundary(
                                      child: CalendarZoomTransition(
                                        key: ValueKey(_zoomEpoch),
                                        level: _zoom,
                                        child: switch (_zoom) {
                                          CalendarZoomLevel.days => MouseDragScroll(
                                            controller: _pages,
                                            enabled: !_rangeDragging,
                                            child: Column(
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
                                                      setState(() {
                                                        _visibleMonth =
                                                            _monthAt(page);
                                                        _daysMonth =
                                                            _visibleMonth;
                                                      });
                                                    },
                                                    itemBuilder: (context, page) {
                                                      final emojis =
                                                          AppScope.of(
                                                            context,
                                                          ).dayEmojiStore;
                                                      return ListenableBuilder(
                                                        listenable: emojis,
                                                        builder: (context, _) {
                                                          return CalendarMonthGrid(
                                                            month: _monthAt(
                                                              page,
                                                            ),
                                                            startMonday:
                                                                startMonday,
                                                            showLunar:
                                                                showLunar,
                                                            eventsOf: _eventsOn,
                                                            diariesOf:
                                                                _diariesOn,
                                                            ledgersOf:
                                                                _ledgersOn,
                                                            emojisOf: _showDiary
                                                                ? null
                                                                : (
                                                                    date,
                                                                  ) => emojis.on(
                                                                    date,
                                                                    layer:
                                                                        _stickerLayer,
                                                                  ),
                                                            showDiary:
                                                                _showDiary,
                                                            showLedger:
                                                                _showLedger,
                                                            showLedgerTitle:
                                                                viewPrefs
                                                                    .showLedgerTitle,
                                                            showLedgerAmount:
                                                                viewPrefs
                                                                    .showLedgerAmount,
                                                            ledgerCategoryView:
                                                                viewPrefs
                                                                    .categoryView,
                                                            ledgerKindColor:
                                                                viewPrefs
                                                                    .ledgerKindColor,
                                                            searchDay:
                                                                _searchDay,
                                                            searchHitKey:
                                                                _searchHitKey,
                                                            onDayPressed:
                                                                _openDay,
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
                                if (PcLayout.isPc) ...[
                                  Positioned(
                                    left: 16,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: _WebCalendarArrow(
                                        left: true,
                                        onPressed: () => _stepCalendar(-1),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 16,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: _WebCalendarArrow(
                                        left: false,
                                        onPressed: () => _stepCalendar(1),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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

class _WebCalendarArrow extends StatelessWidget {
  const _WebCalendarArrow({required this.left, required this.onPressed});

  final bool left;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x40000000),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: PressBounce(
        onPressed: onPressed,
        pressedScale: 0.92,
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: SizedBox(
          width: 36,
          height: 72,
          child: Icon(
            left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 30,
            color: const Color(0xFF222222),
          ),
        ),
      ),
    );
  }
}

class _SearchStableViewport extends StatefulWidget {
  const _SearchStableViewport({required this.animation, required this.child});

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
