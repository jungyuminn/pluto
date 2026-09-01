import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/core/utils/swipe_to_delete.dart';
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/add_company_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_repeat_event_dialog.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar_sheet.dart';

class HomeAllEventsCard extends StatelessWidget {
  const HomeAllEventsCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: Color.lerp(colors.card, Colors.black, 0.08)!,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.allEventsCard,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: colors.accentBright,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: colors.accentBright,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final _search = PlainTextEditingController();
  final _searchFocus = FocusNode();
  var _events = <CalendarEvent>[];
  var _rawEvents = <CalendarEvent>[];
  var _applications = <JobApplication>[];
  var _categories = <EventCategory>[];
  var _loading = true;
  var _typeFilter = _TypeFilter.all;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final applications = await scope.getJobApplications();
    final categories = await scope.getEventCategories();
    final companyCategories =
        await scope.fetchCategories(CategoryKind.company);
    if (!mounted) return;
    final todos = _uniqueTodos(events);
    final jobs = [
      for (final application in applications)
        _jobItem(application, companyCategories),
    ];
    setState(() {
      _rawEvents = events;
      _applications = applications;
      _events = [...jobs, ...todos]..sort((a, b) {
          if (a.someday != b.someday) return a.someday ? 1 : -1;
          final byDay = a.day.compareTo(b.day);
          if (byDay != 0) return byDay;
          return (a.startMinutes ?? 24 * 60)
              .compareTo(b.startMinutes ?? 24 * 60);
        });
      _categories = [...companyCategories, ...categories];
      _loading = false;
    });
  }

  List<CalendarEvent> _uniqueTodos(List<CalendarEvent> events) {
    final seen = <String>{};
    final items = <CalendarEvent>[];
    final sorted = [...events]..sort((a, b) {
        final byDay = a.day.compareTo(b.day);
        if (byDay != 0) return byDay;
        return (a.startMinutes ?? 24 * 60).compareTo(b.startMinutes ?? 24 * 60);
      });
    for (final event in sorted) {
      if (event.isJob) continue;
      final groupId = event.groupId;
      if (groupId != null && !seen.add(groupId)) continue;
      items.add(event);
    }
    return items;
  }

  CalendarEvent _jobItem(
    JobApplication application,
    List<EventCategory> companyCategories,
  ) {
    DateTime? date;
    for (final round in application.rounds) {
      final roundDate = round.date;
      if (roundDate == null) continue;
      final day = DateTime(roundDate.year, roundDate.month, roundDate.day);
      if (date == null || day.isBefore(date)) date = day;
    }
    final applied = application.appliedDate;
    date ??= applied == null
        ? null
        : DateTime(applied.year, applied.month, applied.day);
    return CalendarEvent(
      id: 'job:${application.id}',
      title: application.companyName,
      date: date ?? DateTime.now(),
      memo: application.position.trim(),
      categoryId: application.categoryId,
      categoryName: application.hasCategory
          ? application.categoryName
          : (application.applyStatus.isNotEmpty
              ? application.applyStatus
              : AppStrings.monthlyStatsJobSection),
      categoryColor: jobCategoryColor(application, companyCategories),
      isJob: true,
      jobApplicationId: application.id,
      someday: date == null,
    );
  }

  JobApplication? _applicationOf(CalendarEvent event) {
    final id = event.jobApplicationId;
    if (id == null) return null;
    for (final application in _applications) {
      if (application.id == id) return application;
    }
    return null;
  }

  bool _matches(CalendarEvent event) {
    if (event.isJob) {
      if (_typeFilter == _TypeFilter.todos) return false;
    } else if (_typeFilter == _TypeFilter.jobs) {
      return false;
    }
    if (!_inDateRange(event)) return false;
    final query = _search.text;
    if (KoreanSearch.compact(query).isEmpty) return true;
    return KoreanSearch.matchesAny(_searchTexts(event), query);
  }

  bool _inDateRange(CalendarEvent event) {
    final start = _rangeStart;
    final end = _rangeEnd;
    if (start == null || end == null) return true;
    if (event.isJob) {
      final application = _applicationOf(event);
      if (application == null) {
        return !event.someday && _dayInRange(event.day, start, end);
      }
      var hasDate = false;
      for (final round in application.rounds) {
        final date = round.date;
        if (date == null) continue;
        hasDate = true;
        if (_dayInRange(date, start, end)) return true;
      }
      final applied = application.appliedDate;
      if (!hasDate && applied != null) {
        return _dayInRange(applied, start, end);
      }
      return false;
    }
    if (event.someday) return false;
    final groupId = event.groupId;
    if (groupId != null) {
      for (final item in _rawEvents) {
        if (item.groupId != groupId) continue;
        if (_dayInRange(item.day, start, end)) return true;
      }
      return false;
    }
    return _dayInRange(event.day, start, end);
  }

  bool _dayInRange(DateTime date, DateTime start, DateTime end) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  String get _rangeChipLabel {
    final start = _rangeStart;
    final end = _rangeEnd;
    if (start == null || end == null) return AppStrings.calendarModeRange;
    if (start == end) return _rangeDayLabel(start);
    return '${_rangeDayLabel(start)} - ${_rangeDayLabel(end)}';
  }

  String _rangeDayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year != now.year) {
      return '${date.year}. ${date.month}. ${date.day}.';
    }
    return '${date.month}. ${date.day}.';
  }

  Future<void> _pickRange() async {
    _searchFocus.unfocus();
    final start = _rangeStart;
    final end = _rangeEnd;
    final picked = await showAppCalendarSheet(
      context,
      date: start,
      dates: start == null || end == null ? null : [start, end],
      mode: AppCalendarMode.range,
      showModes: false,
      modes: const [AppCalendarMode.range],
    );
    if (!mounted) return;
    _keepSearchUnfocused();
    if (picked == null || picked.dates.isEmpty) return;
    final days = [...picked.dates]..sort();
    setState(() {
      _rangeStart = DateTime(days.first.year, days.first.month, days.first.day);
      _rangeEnd = DateTime(days.last.year, days.last.month, days.last.day);
    });
  }

  void _clearRange() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _toggleType(_TypeFilter type) {
    setState(() {
      _typeFilter = _typeFilter == type ? _TypeFilter.all : type;
    });
  }

  bool get _hasActiveFilter {
    return _typeFilter != _TypeFilter.all ||
        _rangeStart != null ||
        KoreanSearch.compact(_search.text).isNotEmpty;
  }

  List<String> _searchTexts(CalendarEvent event) {
    final texts = [
      event.title,
      event.categoryName,
      event.memo,
      _eventDateLabel(event),
    ];
    final application = _applicationOf(event);
    if (application == null) return texts;
    return [
      ...texts,
      application.position,
      application.applyStatus,
      application.status,
      for (final round in application.rounds) round.name,
    ];
  }

  String _eventDateLabel(CalendarEvent event) {
    if (event.isJob && event.someday) return AppStrings.monthlyStatsJobSection;
    if (event.someday) return AppStrings.somedayTitle;
    return _dateLabel(event.day);
  }

  String _dateLabel(DateTime date) {
    final weekday = AppStrings.weekdays[date.weekday % 7];
    final now = DateTime.now();
    if (date.year == now.year) {
      return '${date.month}. ${date.day}. ($weekday)';
    }
    return '${date.year}. ${date.month}. ${date.day}. ($weekday)';
  }

  List<_Section> _sections(List<CalendarEvent> events) {
    final groups = <String, List<CalendarEvent>>{};
    for (final event in events) {
      final key = event.categoryId ?? event.categoryName;
      groups.putIfAbsent(key, () => []).add(event);
    }
    final totals = <String, int>{};
    for (final event in _events) {
      final key = event.categoryId ?? event.categoryName;
      totals[key] = (totals[key] ?? 0) + 1;
    }
    final used = <String>{};
    final sections = <_Section>[];
    for (final category in _categories) {
      final grouped = groups[category.id];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(category.id);
      sections.add(
        _Section(
          key: category.id,
          name: category.name,
          color: category.tint,
          events: grouped,
          total: totals[category.id] ?? grouped.length,
        ),
      );
    }
    for (final event in events) {
      final key = event.categoryId ?? event.categoryName;
      if (used.contains(key)) continue;
      final grouped = groups[key];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(key);
      sections.add(
        _Section(
          key: key,
          name: event.categoryName,
          color: event.color,
          events: grouped,
          total: totals[key] ?? grouped.length,
        ),
      );
    }
    return sections;
  }

  void _keepSearchUnfocused() {
    _searchFocus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.unfocus();
    });
  }

  Future<void> _edit(CalendarEvent event) async {
    _searchFocus.unfocus();
    if (event.isJob) {
      final application = _applicationOf(event);
      if (application == null) return;
      final saved = await showAddCompanySheet(
        context,
        application: application,
      );
      if (!mounted) return;
      _keepSearchUnfocused();
      if (saved) await _reload();
      return;
    }
    final saved = await showAddEventSheet(
      context,
      date: event.date,
      event: event,
      someday: event.someday,
    );
    if (!mounted) return;
    _keepSearchUnfocused();
    if (saved) await _reload();
  }

  Future<void> _toggleComplete(CalendarEvent event) async {
    if (event.isJob) return;
    final updater = AppScope.of(context).updateCalendarEvent;
    final next = event.copyWith(completed: !event.completed);
    if (event.isRepeat) {
      await updater.instance(next);
    } else {
      await updater(next);
    }
    if (mounted) await _reload();
  }

  Future<bool> _delete(CalendarEvent event) async {
    if (event.isJob) return false;
    _searchFocus.unfocus();
    if (event.isRepeat) {
      final scope = await showDeleteRepeatEventDialog(context);
      if (!mounted) return false;
      _keepSearchUnfocused();
      if (scope == null) return false;
      final deleter = AppScope.of(context).deleteCalendarEvent;
      switch (scope) {
        case RepeatDeleteScope.thisOnly:
          await deleter.thisOnly(event);
        case RepeatDeleteScope.thisAndAfter:
          await deleter.thisAndAfter(event);
        case RepeatDeleteScope.all:
          await deleter.allRepeats(event.repeatId!);
      }
      AppBackupService.revision.value++;
      if (mounted) await _reload();
      return true;
    }
    final confirmed = await showDeleteEventDialog(
      context,
      title: event.title,
    );
    if (!mounted) return false;
    _keepSearchUnfocused();
    if (!confirmed) return false;
    await AppScope.of(context).deleteCalendarEvent(event);
    AppBackupService.revision.value++;
    if (mounted) await _reload();
    return true;
  }

  List<CalendarEvent> _todosInCategory(String key) {
    return [
      for (final event in _events)
        if (!event.isJob &&
            (event.categoryId ?? event.categoryName) == key &&
            _matches(event))
          event,
    ];
  }

  Future<void> _deleteCategory(String key, String name) async {
    final events = _todosInCategory(key);
    if (events.isEmpty) return;
    _searchFocus.unfocus();
    final confirmed = await showDeleteEventDialog(
      context,
      title: name,
      body: AppStrings.allEventsDeleteBody(events.length),
    );
    if (!mounted) return;
    _keepSearchUnfocused();
    if (!confirmed) return;
    await AppScope.of(context).deleteCalendarEvent.many(
      events.map((event) => event.id),
    );
    AppBackupService.revision.value++;
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final sections = _sections(_events);
    final anyVisible = _events.any(_matches);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 8),
            child: Row(
              children: [
                _BackButton(onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 10),
                Expanded(
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
                      hintText: AppStrings.allEventsSearchHint,
                      hintStyle: TextStyle(
                        fontFamily: AppFonts.of(context),
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: colors.card,
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: _rangeChipLabel,
                    selected: _rangeStart != null,
                    onPressed: _pickRange,
                    onClear: _rangeStart == null ? null : _clearRange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.monthlyStatsTodoSection,
                    selected: _typeFilter == _TypeFilter.todos,
                    onPressed: () => _toggleType(_TypeFilter.todos),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.monthlyStatsJobSection,
                    selected: _typeFilter == _TypeFilter.jobs,
                    onPressed: () => _toggleType(_TypeFilter.jobs),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          return _FilterSlot(
                            visible: section.events.any(_matches),
                            child: Padding(
                              padding: EdgeInsets.only(top: index == 0 ? 0 : 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: section.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(text: section.name),
                                                TextSpan(
                                                  text:
                                                      ' ${section.events.where(_matches).length}',
                                                  style: TextStyle(
                                                    color: colors.muted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            style: TextStyle(
                                              fontFamily: AppFonts.of(context),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colors.text,
                                            ),
                                          ),
                                        ),
                                        if (section.events.any(
                                          (event) =>
                                              !event.isJob && _matches(event),
                                        ))
                                          PressBounce(
                                            onPressed: () => _deleteCategory(
                                              section.key,
                                              section.name,
                                            ),
                                            pressedColor: colors.pressed,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Text(
                                                AppStrings.allEventsDeleteAll,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppFonts.of(context),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.danger,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  for (final event in section.events)
                                    _FilterSlot(
                                      visible: _matches(event),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: event.isJob
                                            ? DayEventLabel(
                                                title: event.title,
                                                categoryName:
                                                    _eventDateLabel(event),
                                                color: event.color,
                                                completed: event.completed,
                                                isRepeat: event.isRepeat,
                                                isRange: event.isRange,
                                                isJob: true,
                                                memo: event.memo,
                                                timeText: event.someday
                                                    ? null
                                                    : event.timeLabel,
                                                onPressed: () => _edit(event),
                                              )
                                            : SwipeToDelete(
                                                onSwipeLeft: () =>
                                                    _delete(event),
                                                child: DayEventLabel(
                                                  title: event.title,
                                                  categoryName:
                                                      _eventDateLabel(event),
                                                  color: event.color,
                                                  completed: event.completed,
                                                  isRepeat: event.isRepeat,
                                                  isRange: event.isRange,
                                                  memo: event.memo,
                                                  timeText: event.someday
                                                      ? null
                                                      : event.timeLabel,
                                                  onPressed: () =>
                                                      _edit(event),
                                                  onCompletePressed: () =>
                                                      _toggleComplete(event),
                                                ),
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: anyVisible ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Center(
                            child: Text(
                              _hasActiveFilter
                                  ? AppStrings.allEventsSearchEmpty
                                  : AppStrings.allEventsEmpty,
                              style: TextStyle(
                                fontFamily: AppFonts.of(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.key,
    required this.name,
    required this.color,
    required this.events,
    required this.total,
  });

  final String key;
  final String name;
  final Color color;
  final List<CalendarEvent> events;
  final int total;
}

enum _TypeFilter { all, todos, jobs }

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fill = selected ? colors.accent : colors.card;
    final pressed = selected ? colors.accent : colors.pressed;
    final radius = BorderRadius.circular(999);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PressBounce(
            onPressed: onPressed,
            color: fill,
            pressedColor: pressed,
            borderRadius: onClear == null
                ? radius
                : const BorderRadius.horizontal(left: Radius.circular(999)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 8, onClear == null ? 14 : 8, 8),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.text,
                ),
              ),
            ),
          ),
          if (onClear != null)
            PressBounce(
              onPressed: onClear,
              color: fill,
              pressedColor: pressed,
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(999)),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(2, 8, 10, 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterSlot extends StatelessWidget {
  const _FilterSlot({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          heightFactor: visible ? 1 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            opacity: visible ? 1 : 0,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}
