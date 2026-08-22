import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/data/datasources/diary_photo_storage.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_week_diaries.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_header.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_time_machine_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/diary_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.visible = true});

  final bool visible;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  static const _initialPage = 12000;

  late DateTime _baseMonth;
  late final PageController _pages;
  late DateTime _visibleMonth;
  var _events = <CalendarEvent>[];
  var _diaries = <DiaryEntry>[];
  var _applications = <JobApplication>[];
  var _companyCategories = <EventCategory>[];
  var _initialized = false;
  var _rangeDragging = false;
  var _showTodos = true;
  var _showCompanies = true;
  var _showDiary = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showCurrentMonth();
    _pages = PageController(initialPage: _initialPage, keepPage: false);
    AppBackupService.revision.addListener(_onBackupRestored);
  }

  void _onBackupRestored() {
    if (mounted) _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _reload();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _reload();
  }

  @override
  void dispose() {
    AppBackupService.revision.removeListener(_onBackupRestored);
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _showCurrentMonth(jump: true);
  }

  Future<void> _openTimeMachine() async {
    final picked = await showCalendarTimeMachineSheet(
      context,
      month: _visibleMonth,
    );
    if (picked == null || !mounted) return;
    await _goToMonth(picked);
  }

  void _showCurrentMonth({bool jump = false}) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    _baseMonth = current;
    _visibleMonth = current;
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
    final applications = await scope.getJobApplications();
    final companyCategories =
        await scope.fetchCategories(CategoryKind.company);
    if (!mounted) return;
    setState(() {
      _events = events;
      _diaries = diaries;
      _applications = applications;
      _companyCategories = companyCategories;
    });
  }

  List<CalendarEvent> _eventsOn(DateTime date) {
    final events = calendarEventsOn(
      date: date,
      events: _showTodos ? _events : const [],
      applications: _showCompanies ? _applications : const [],
      companyCategories: _companyCategories,
    );
    if (!AppScope.of(context).dayEventsViewPreference.sortByTime) {
      return events;
    }
    return CalendarEvent.withLockedThenStartTime(events);
  }

  DiaryEntry? _diaryOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    for (final diary in _diaries) {
      if (diary.day == day) return diary;
    }
    return null;
  }

  Future<void> _openDay(DateTime date, Rect origin) async {
    if (_showDiary) {
      await showDiarySheet(
        context,
        date: date,
        initial: _diaryOn(date),
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

  Future<void> _deleteDiaryOn(DateTime date) async {
    if (!_showDiary) return;
    final diary = _diaryOn(date);
    if (diary == null) return;
    HapticFeedback.mediumImpact();
    final title = diary.title.trim().isEmpty
        ? AppStrings.diaryFallback
        : diary.title.trim();
    final confirmed = await showDeleteEventDialog(
      context,
      title: title,
      body: AppStrings.deleteDiaryBody,
    );
    if (!confirmed || !mounted) return;
    final photoPath = diary.photoPath;
    await AppScope.of(context).deleteDiary(diary.id);
    if (mounted) await _reload();
    await Future<void>.delayed(CalendarWeekDiaries.fadeDuration);
    await const DiaryPhotoStorage().delete(photoPath);
  }

  Future<void> _openRange(DateTime start, DateTime end) async {
    await showAddEventSheet(
      context,
      date: start,
      rangeEnd: end,
    );
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
                    final startMonday =
                        AppScope.of(context).calendarPreference.startMonday;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      CalendarMonthHeader(
                        month: _visibleMonth,
                        onTitlePressed: _openTimeMachine,
                        showTodos: _showTodos,
                        showCompanies: _showCompanies,
                        showDiary: _showDiary,
                        onShowTodosChanged: (value) {
                          setState(() => _showTodos = value);
                        },
                        onShowCompaniesChanged: (value) {
                          setState(() => _showCompanies = value);
                        },
                        onShowDiaryChanged: (value) {
                          setState(() => _showDiary = value);
                        },
                        onSortPrefsChanged: () => setState(() {}),
                      ),
                      CalendarWeekdayHeader(startMonday: startMonday),
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          physics: _rangeDragging
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          onPageChanged: (page) {
                            setState(() => _visibleMonth = _monthAt(page));
                          },
                          itemBuilder: (context, page) {
                            return CalendarMonthGrid(
                              month: _monthAt(page),
                              startMonday: startMonday,
                              eventsOf: _eventsOn,
                              diaryOf: _diaryOn,
                              showDiary: _showDiary,
                              onDayPressed: _openDay,
                              onDayLongPressed:
                                  _showDiary ? _deleteDiaryOn : null,
                              onRangeDragChanged: _showDiary
                                  ? null
                                  : (dragging) {
                                      setState(() => _rangeDragging = dragging);
                                    },
                              onRangeSelected: _showDiary ? null : _openRange,
                            );
                          },
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
