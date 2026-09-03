import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/layout/pc_layout.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/domain/monthly_stats.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:job_planner/presentation/screens/stats/planet_stages.dart';
import 'package:job_planner/presentation/screens/stats/widgets/planet_collection_sheet.dart';
import 'package:job_planner/presentation/screens/stats/widgets/planet_fill.dart';
import 'package:job_planner/presentation/screens/stats/widgets/planet_level_sheet.dart';
import 'package:job_planner/presentation/tutorial/tutorial_anchor.dart';
import 'package:job_planner/presentation/widgets/app_calendar/calendar_zoom_picker.dart';
import 'package:job_planner/presentation/widgets/overlay_app_bar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.visible = true});

  final bool visible;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _month;
  late DateTime _zoomFocus;
  var _zoom = CalendarZoomLevel.days;
  MonthlyStats? _stats;
  var _events = const <CalendarEvent>[];
  var _loading = true;
  var _initialized = false;
  late final AnimationController _wave;

  DateTime get _nowMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isCurrentMonth =>
      _month.year == _nowMonth.year && _month.month == _nowMonth.month;

  @override
  void initState() {
    super.initState();
    _month = _nowMonth;
    _zoomFocus = _nowMonth;
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    AppBackupService.revision.addListener(_reload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _reload();
  }

  @override
  void didUpdateWidget(StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _reload();
  }

  @override
  void dispose() {
    AppBackupService.revision.removeListener(_reload);
    _wave.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final events = await AppScope.of(context).getCalendarEvents();
    if (!mounted) return;
    setState(() {
      _events = events;
      _stats = MonthlyStats.of(
        month: _month,
        events: events,
        applications: const [],
      );
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isAfter(_nowMonth)) return;
    HapticFeedback.selectionClick();
    _setMonth(next);
  }

  void _setMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    if (target.isAfter(_nowMonth)) return;
    if (target.year == _month.year && target.month == _month.month) return;
    setState(() {
      _month = target;
      _stats = MonthlyStats.of(
        month: target,
        events: _events,
        applications: const [],
      );
    });
  }

  void _onTitlePressed() {
    HapticFeedback.selectionClick();
    if (_zoom == CalendarZoomLevel.years) {
      setState(() => _zoom = CalendarZoomLevel.days);
      return;
    }
    if (_zoom == CalendarZoomLevel.days) {
      _zoomFocus = _month;
    }
    setState(() => _zoom = CalendarZoom.next(_zoom));
  }

  void _pickZoomMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    if (target.isAfter(_nowMonth)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _zoom = CalendarZoomLevel.days;
      if (target.year == _month.year && target.month == _month.month) return;
      _month = target;
      _stats = MonthlyStats.of(
        month: target,
        events: _events,
        applications: const [],
      );
    });
  }

  void _pickZoomYear(int year) {
    if (year > _nowMonth.year) return;
    HapticFeedback.selectionClick();
    setState(() {
      _zoomFocus = DateTime(year, _zoomFocus.month);
      _zoom = CalendarZoomLevel.months;
    });
  }

  Future<void> _openDayEvents(DateTime date, Rect origin) async {
    HapticFeedback.selectionClick();
    final events = await _eventsOn(date);
    if (!mounted) return;
    await showDayEventsDialog(
      context,
      date: date,
      events: events,
      origin: origin,
      onEventsChanged: _reload,
    );
    if (mounted) await _reload();
  }

  Future<List<CalendarEvent>> _eventsOn(DateTime date) async {
    final scope = AppScope.of(context);
    final calendarPrefs = scope.calendarPreference;
    final applications = (calendarPrefs.showCompanies &&
            scope.navPreference.showJobTab)
        ? await scope.getJobApplications()
        : const <JobApplication>[];
    if (!mounted) return const [];
    final companyCategories = applications.isEmpty
        ? const <EventCategory>[]
        : await scope.fetchCategories(CategoryKind.company);
    if (!mounted) return const [];
    final eventCategories = await scope.fetchCategories(CategoryKind.event);
    if (!mounted) return const [];
    final events = calendarEventsOn(
      date: date,
      events: calendarPrefs.showTodos ? _events : const [],
      applications: applications,
      companyCategories: companyCategories,
      includeRejected: scope.jobViewPreference.showRejected,
    );
    final prefs = scope.dayEventsViewPreference;
    if (prefs.categoryView) {
      return calendarEventsByCategory(
        events,
        categories: eventCategories,
        sortByTime: prefs.sortByTime,
      );
    }
    if (!prefs.sortByTime) return events;
    return CalendarEvent.withLockedThenStartTime(events);
  }

  String _monthLabel() {
    return CalendarZoom.title(
      _zoom,
      _zoom == CalendarZoomLevel.days ? _month : _zoomFocus,
      hideCurrentYear: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final bottomGap = 88 +
        (PcLayout.isPc ? PcLayout.navLift : 0) +
        MediaQuery.paddingOf(context).bottom;
    final play = stats == null
        ? null
        : _MonthPlay.of(
            stats: stats,
            events: _events,
            month: _month,
            today: _today,
          );
    final progress = stats == null || stats.totalTodos == 0
        ? 0.0
        : stats.completedTodos / stats.totalTodos;
    final collected = CollectedPlanet.fromEvents(
      _events,
      nowMonth: _nowMonth,
    );

    return AppSkinBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: OverlayAppBar(
          centerTitle: true,
          leading: _MonthArrow(
            onPressed: _zoom == CalendarZoomLevel.days
                ? () => _shiftMonth(-1)
                : null,
            icon: Icons.chevron_left_rounded,
          ),
          title: PressBounce(
            onPressed: _onTitlePressed,
            pressedScale: 0.97,
            pressedColor: Colors.transparent,
            child: Text(
              _monthLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.jalnan,
                fontSize: AppFonts.wordmarkSize,
                height: 1.1,
                color: AppFonts.wordmarkColor,
              ),
            ),
          ),
          actions: _MonthArrow(
            onPressed: _zoom == CalendarZoomLevel.days && !_isCurrentMonth
                ? () => _shiftMonth(1)
                : null,
            icon: Icons.chevron_right_rounded,
          ),
        ),
        body: _loading || stats == null || play == null
            ? const Center(child: CircularProgressIndicator())
            : FadeIn(
                child: CalendarZoomTransition(
                  level: _zoom,
                  child: switch (_zoom) {
                    CalendarZoomLevel.days => GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity > 240) {
                            _shiftMonth(-1);
                          } else if (velocity < -240) {
                            _shiftMonth(1);
                          }
                        },
                        child: PcLayout.constrainWidth(
                          ListView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              OverlayAppBar.overlapOf(context) - 30,
                              20,
                              bottomGap,
                            ),
                            children: [
                              _PlanetHero(
                                wave: _wave,
                                play: play,
                              ),
                              const SizedBox(height: 12),
                              _LevelBlock(play: play, progress: progress),
                              const SizedBox(height: 16),
                              TutorialAnchor(
                                id: TutorialAnchorId.statsCollected,
                                child: _CollectedCard(
                                  collected: collected,
                                  onSelectMonth: _setMonth,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TutorialAnchor(
                                id: TutorialAnchorId.statsCalendar,
                                child: _StatCard(
                                  play: play,
                                  onDayPressed: _openDayEvents,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    CalendarZoomLevel.months => Padding(
                        padding: EdgeInsets.fromLTRB(
                          8,
                          OverlayAppBar.overlapOf(context) - 16,
                          8,
                          bottomGap,
                        ),
                        child: CalendarMonthZoomView(
                          focused: _zoomFocus,
                          accent: AppColors.of(context).accentBright,
                          isMonthEnabled: (month) => !month.isAfter(_nowMonth),
                          onFocusedChanged: (month) {
                            setState(() => _zoomFocus = month);
                          },
                          onMonthPressed: _pickZoomMonth,
                        ),
                      ),
                    CalendarZoomLevel.years => Padding(
                        padding: EdgeInsets.fromLTRB(
                          8,
                          OverlayAppBar.overlapOf(context) - 16,
                          8,
                          bottomGap,
                        ),
                        child: CalendarYearZoomView(
                          focused: _zoomFocus,
                          accent: AppColors.of(context).accentBright,
                          isYearEnabled: (year) => year <= _nowMonth.year,
                          onFocusedChanged: (month) {
                            setState(() => _zoomFocus = month);
                          },
                          onYearPressed: _pickZoomYear,
                        ),
                      ),
                  },
                ),
              ),
      ),
    );
  }
}

class _MonthPlay {
  const _MonthPlay({
    required this.level,
    required this.exp,
    required this.need,
    required this.rank,
    required this.categoriesUsed,
    required this.done,
    required this.total,
    required this.left,
    required this.isMax,
    required this.hasTodos,
    required this.month,
    required this.today,
    required this.doneDays,
  });

  final int level;
  final int exp;
  final int need;
  final String rank;
  final int categoriesUsed;
  final int done;
  final int total;
  final int left;
  final bool isMax;
  final bool hasTodos;
  final DateTime month;
  final DateTime today;
  final Set<int> doneDays;

  static _MonthPlay of({
    required MonthlyStats stats,
    required List<CalendarEvent> events,
    required DateTime month,
    required DateTime today,
  }) {
    final total = stats.totalTodos;
    final done = stats.completedTodos;
    final isMax = done >= PlanetStage.maxNeed;
    final level = PlanetStage.levelOf(done: done);
    final start = PlanetStage.needOf(level);
    final end = isMax
        ? PlanetStage.maxNeed
        : PlanetStage.needOf(level + 1);
    return _MonthPlay(
      level: level,
      exp: isMax ? PlanetStage.maxNeed : (done - start).clamp(0, 9999),
      need: isMax
          ? PlanetStage.maxNeed
          : math.max(end - start, 1),
      rank: PlanetStage.nameOf(level, empty: total == 0),
      categoriesUsed: stats.categories.length,
      done: done,
      total: total,
      left: stats.incompleteTodos,
      isMax: isMax,
      hasTodos: total > 0,
      month: month,
      today: today,
      doneDays: _doneDays(events, month),
    );
  }

  static Set<int> _doneDays(List<CalendarEvent> events, DateTime month) {
    final days = <int>{};
    for (final event in events) {
      if (event.isJob || event.someday || !event.completed) continue;
      final day = event.day;
      if (day.year != month.year || day.month != month.month) continue;
      days.add(day.day);
    }
    return days;
  }
}

class _PlanetHero extends StatelessWidget {
  const _PlanetHero({
    required this.wave,
    required this.play,
  });

  final Animation<double> wave;
  final _MonthPlay play;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final level = play.isMax ? PlanetStage.maxLevel : play.level;
    return SizedBox(
      height: 248,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 240,
                ),
                child: TutorialAnchor(
                  id: TutorialAnchorId.statsPlanet,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: PlanetFill(
                      key: ValueKey(
                        '${play.month.year}-${play.month.month}-$level',
                      ),
                      level: level,
                      wave: wave.value,
                      outline: colors.icon,
                      empty: colors.card,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 208,
            child: Center(
              child: _RankBadge(
                play: play,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showPlanetLevelSheet(
                    context,
                    level: play.level,
                    isMax: play.isMax,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.play,
    required this.onPressed,
  });

  final _MonthPlay play;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.96,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
            child: Text(
              play.rank,
              key: ValueKey(play.rank),
              style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1,
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBlock extends StatelessWidget {
  const _LevelBlock({
    required this.play,
    required this.progress,
  });

  final _MonthPlay play;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final remain = play.hasTodos && !play.isMax ? play.need - play.exp : null;
    final level = play.isMax ? PlanetStage.maxLevel : play.level;
    final label = !play.hasTodos
        ? AppStrings.statsPlanetEmpty
        : play.isMax
            ? AppStrings.statsPlanetFull
            : AppStrings.statsNextPlanetTodos(remain ?? 0);
    return PressBounce(
      onPressed: () {
        HapticFeedback.selectionClick();
        showPlanetLevelSheet(
          context,
          level: play.level,
          isMax: play.isMax,
        );
      },
      pressedScale: 0.98,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      layoutBuilder: (current, _) =>
                          current ?? const SizedBox.shrink(),
                      child: Text(
                        label,
                        key: ValueKey(label),
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ),
                  if (!play.isMax) ...[
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.statsPlanetStage(level),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              _ExpBar(
                value: play.hasTodos
                    ? (play.isMax ? 1 : play.exp / play.need)
                    : 0,
                progress: progress,
                currentLevel: level,
                nextLevel: play.isMax
                    ? PlanetStage.maxLevel
                    : (play.level + 1).clamp(2, PlanetStage.maxLevel),
                isMax: play.isMax,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpBar extends StatefulWidget {
  const _ExpBar({
    required this.value,
    required this.progress,
    required this.currentLevel,
    required this.nextLevel,
    required this.isMax,
  });

  final double value;
  final double progress;
  final int currentLevel;
  final int nextLevel;
  final bool isMax;

  @override
  State<_ExpBar> createState() => _ExpBarState();
}

class _ExpBarState extends State<_ExpBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isMax) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isMax) return;
        _shine.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ExpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMax && !oldWidget.isMax) {
      _shine.forward(from: 0);
    } else if (!widget.isMax && oldWidget.isMax) {
      _shine.stop();
      _shine.value = 0;
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 820),
      curve: Curves.easeOutCubic,
      tween: Tween(end: widget.value.clamp(0.0, 1.0)),
      builder: (context, bar, _) {
        const planet = 40.0;
        const track = 16.0;
        const inset = planet * 0.42;
        final maxed = widget.isMax;
        return SizedBox(
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 6,
                left: maxed ? 0 : inset,
                right: inset,
                height: track,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 12,
                        width: double.infinity,
                        child: ColoredBox(
                          color: colors.border,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: bar,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: widget.isMax
                                          ? const [
                                              Color(0xFFD9898A),
                                              Color(0xFFFFD36A),
                                              Color(0xFFFFF6DE),
                                            ]
                                          : const [
                                              Color(0xFFD9898A),
                                              Color(0xFFF3C3A0),
                                              Color(0xFFFFE7C2),
                                            ],
                                    ),
                                  ),
                                ),
                                if (widget.isMax)
                                  AnimatedBuilder(
                                    animation: _shine,
                                    builder: (context, _) {
                                      if (_shine.value <= 0 ||
                                          _shine.isCompleted) {
                                        return const SizedBox.shrink();
                                      }
                                      return LayoutBuilder(
                                        builder: (context, constraints) {
                                          final width = constraints.maxWidth;
                                          final x = _shine.value *
                                                  (width + 56) -
                                              28;
                                          return Transform.translate(
                                            offset: Offset(x, 0),
                                            child: SizedBox(
                                              width: 40,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withValues(
                                                        alpha: 0,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0.78,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final mark in const [0.3, 0.6, 0.9])
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _MilestoneDot(
                                reached: widget.progress >= mark,
                              ),
                            ),
                          ),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ],
                ),
              ),
              if (!maxed)
                Positioned(
                  top: 6 + (track - planet) / 2,
                  left: 0,
                  width: planet,
                  height: planet,
                  child: PlanetFill(
                    level: widget.currentLevel,
                    wave: 0.08,
                    outline: colors.icon,
                    empty: colors.card,
                    pokeable: false,
                  ),
                ),
              Positioned(
                top: 6 + (track - planet) / 2,
                right: 0,
                width: planet,
                height: planet,
                child: PlanetFill(
                  level: maxed ? widget.currentLevel : widget.nextLevel,
                  wave: 0.08,
                  outline: colors.icon,
                  empty: colors.card,
                  pokeable: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MilestoneDot extends StatelessWidget {
  const _MilestoneDot({required this.reached});

  final bool reached;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? Colors.white : colors.card,
        border: Border.all(
          color: reached ? const Color(0xFFE3898A) : colors.muted,
          width: 1.6,
        ),
      ),
      child: const SizedBox.square(dimension: 8),
    );
  }
}

double _planetPhase(DateTime month) {
  return ((month.year * 12 + month.month) * 0.17) % 1;
}

class _CollectedCard extends StatelessWidget {
  const _CollectedCard({
    required this.collected,
    required this.onSelectMonth,
  });

  final List<CollectedPlanet> collected;
  final ValueChanged<DateTime> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final nowYear = DateTime.now().year;
    return PressBounce(
      onPressed: () async {
        HapticFeedback.selectionClick();
        final month = await showCollectedPlanetSheet(
          context,
          collected: collected,
        );
        if (month == null || !context.mounted) return;
        onSelectMonth(month);
      },
      pressedScale: 0.98,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.statsCollectedTitle,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.muted,
                  ),
                ],
              ),
              if (collected.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    AppStrings.statsCollectedEmpty,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: collected.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final planet = collected[i];
                        return SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: PlanetFill(
                                  key: ValueKey(planet.month),
                                  level: planet.isMax
                                      ? PlanetStage.maxLevel
                                      : planet.level,
                                  wave: 0.08,
                                  phase: _planetPhase(planet.month),
                                  outline: colors.icon,
                                  empty: colors.card,
                                  pokeable: false,
                                ),
                              ),
                              Text(
                                AppStrings.statsCollectedMonth(
                                  planet.month,
                                  nowYear: nowYear,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.play,
    required this.onDayPressed,
  });

  final _MonthPlay play;
  final void Function(DateTime date, Rect origin) onDayPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final rate = play.total == 0 ? 0.0 : play.done / play.total;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          children: [
            Row(
              children: [
                _RateRing(value: rate),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      _StatLine(
                        label: AppStrings.monthlyStatsCompletedLabel,
                        value: play.done,
                      ),
                      const SizedBox(height: 10),
                      _StatLine(
                        label: AppStrings.monthlyStatsIncompleteLabel,
                        value: play.left,
                      ),
                      const SizedBox(height: 10),
                      _StatLine(
                        label: AppStrings.statsCategoriesUsed,
                        value: play.categoriesUsed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListenableBuilder(
              listenable: AppScope.of(context).calendarPreference,
              builder: (context, _) => _MonthDots(
                play: play,
                onDayPressed: onDayPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.muted,
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          tween: Tween(end: value.toDouble()),
          builder: (context, n, _) {
            return Text(
              '${n.round()}',
              style: TextStyle(
                fontFamily: font,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1,
                color: colors.text,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RateRing extends StatefulWidget {
  const _RateRing({required this.value});

  final double value;

  @override
  State<_RateRing> createState() => _RateRingState();
}

class _RateRingState extends State<_RateRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _check;

  bool get _complete => widget.value >= 0.999;

  @override
  void initState() {
    super.initState();
    _check = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (_complete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _complete) _check.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_RateRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_complete) {
      _check.animateBack(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return SizedBox(
      width: 88,
      height: 88,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 820),
        curve: Curves.easeOutCubic,
        tween: Tween(end: widget.value.clamp(0.0, 1.0)),
        onEnd: () {
          if (_complete) _check.forward();
        },
        builder: (context, ring, _) {
          final percent = (ring * 100).round();
          return AnimatedBuilder(
            animation: _check,
            builder: (context, _) {
              final check = _check.value;
              final showPercent = percent < 100;
              return CustomPaint(
                painter: _RateRingPainter(
                  value: ring,
                  check: check,
                  track: colors.border,
                  fill: colors.accentBright,
                ),
                child: Center(
                  child: Opacity(
                    opacity: showPercent
                        ? (1 - Curves.easeOut.transform(check))
                            .clamp(0.0, 1.0)
                        : 0,
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RateRingPainter extends CustomPainter {
  const _RateRingPainter({
    required this.value,
    required this.check,
    required this.track,
    required this.fill,
  });

  final double value;
  final double check;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    const stroke = 8.0;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        fillPaint,
      );
    }
    if (check <= 0) return;
    final path = Path()
      ..moveTo(center.dx - radius * 0.32, center.dy + radius * 0.04)
      ..lineTo(center.dx - radius * 0.08, center.dy + radius * 0.28)
      ..lineTo(center.dx + radius * 0.38, center.dy - radius * 0.26);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(
      0,
      metric.length * Curves.easeOutCubic.transform(check),
    );
    final checkPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(drawn, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _RateRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.check != check ||
        oldDelegate.track != track ||
        oldDelegate.fill != fill;
  }
}

class _MonthDots extends StatelessWidget {
  const _MonthDots({
    required this.play,
    required this.onDayPressed,
  });

  final _MonthPlay play;
  final void Function(DateTime date, Rect origin) onDayPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final startMonday = AppScope.of(context).calendarPreference.startMonday;
    final first = DateTime(play.month.year, play.month.month, 1);
    final last = DateTime(play.month.year, play.month.month + 1, 0).day;
    final lead = MonthGrid.weekdayIndex(first, startMonday: startMonday);
    final isCurrent = play.today.year == play.month.year &&
        play.today.month == play.month.month;
    final days = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var day = 1; day <= last; day++)
        _DayDot(
          date: DateTime(play.month.year, play.month.month, day),
          done: play.doneDays.contains(day),
          future: isCurrent && day > play.today.day,
          onPressed: onDayPressed,
        ),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < days.length; i += 7) {
      final end = math.min(i + 7, days.length);
      final slice = days.sublist(i, end);
      while (slice.length < 7) {
        slice.add(const SizedBox.shrink());
      }
      rows.add(
        SizedBox(
          height: PcLayout.isPc ? 42 : 28,
          child: Row(
            children: [
              for (final cell in slice) Expanded(child: cell),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            for (final label in AppStrings.weekdayLabels(startMonday: startMonday))
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: PcLayout.isPc ? 12 : 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: colors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        AnimatedSize(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            key: ValueKey('${play.month.year}-${play.month.month}'),
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) SizedBox(height: PcLayout.isPc ? 26 : 20),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.date,
    required this.done,
    required this.future,
    required this.onPressed,
  });

  final DateTime date;
  final bool done;
  final bool future;
  final void Function(DateTime date, Rect origin) onPressed;

  Rect _originOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final accent = colors.accentBright;
    return PressBounce(
      onPressed: () => onPressed(date, _originOf(context)),
      pressedScale: 0.9,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? accent.withValues(alpha: 0.18) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: font,
              fontSize: PcLayout.isPc ? 13 : 11,
              fontWeight: done ? FontWeight.w800 : FontWeight.w600,
              color: done
                  ? accent
                  : future
                      ? colors.muted.withValues(alpha: 0.45)
                      : colors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.9,
      pressedColor: enabled ? colors.pressed : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 40,
        child: Icon(
          icon,
          size: 26,
          color: enabled
              ? AppFonts.wordmarkColor
              : AppFonts.wordmarkColor.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}
