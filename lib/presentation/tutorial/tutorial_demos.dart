import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:pluto/presentation/screens/stats/widgets/planet_fill.dart';
import 'package:pluto/presentation/screens/shell/widgets/pill_bottom_nav.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class TutorialDemoView extends StatelessWidget {
  const TutorialDemoView({super.key, required this.demo});

  final TutorialDemo demo;

  @override
  Widget build(BuildContext context) {
    final jobOn = AppScope.maybeOf(context)?.navPreference.jobMode ?? false;
    final statsOn =
        AppScope.maybeOf(context)?.navPreference.showStatsTab ?? true;
    return switch (demo) {
      TutorialDemo.none => const SizedBox.shrink(),
      TutorialDemo.navTabs => _NavDemo(jobMode: jobOn, showStats: statsOn),
      TutorialDemo.calendarTitle => const _TitleDemo(),
      TutorialDemo.calendarTap => const _TapDemo(),
      TutorialDemo.calendarRange => const _RangeDemo(),
      TutorialDemo.todoComplete => const _CompleteDemo(),
      TutorialDemo.todoMove => const _MoveDemo(),
      TutorialDemo.calendarMenu => _MenuDemo(jobMode: jobOn),
      TutorialDemo.homeSearch => _SearchDemo(jobMode: jobOn),
      TutorialDemo.homeSettings => const _SettingsDemo(),
      TutorialDemo.homeReorder => const _ReorderDemo(),
      TutorialDemo.statsPlanetFill => const _PlanetFillDemo(),
      TutorialDemo.statsCollection => const _PlanetCollectionDemo(),
      TutorialDemo.statsDays => const _StatsDaysDemo(),
      TutorialDemo.jobSwipe => const _SwipeDemo(),
    };
  }
}

class _DemoLoop extends StatefulWidget {
  const _DemoLoop({
    required this.builder,
    this.duration = const Duration(milliseconds: 2600),
    this.height = 108,
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;
  final double height;

  @override
  State<_DemoLoop> createState() => _DemoLoopState();
}

class _DemoLoopState extends State<_DemoLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: colors.groupedBackground,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, child) => widget.builder(context, _loop.value),
            ),
          ),
        ),
      ),
    );
  }
}

double _gate(double t, double a, double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return ((t - a) / (b - a)).clamp(0.0, 1.0);
}

double _pulse(double t, double a, double b, double c) {
  if (t < a) return 0;
  if (t < b) return _gate(t, a, b);
  if (t < c) return 1;
  return (1 - _gate(t, c, math.min(1, c + 0.12))).clamp(0.0, 1.0);
}

class _NavDemo extends StatelessWidget {
  const _NavDemo({this.jobMode = false, this.showStats = true});

  final bool jobMode;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    return _DemoLoop(
      builder: (context, t) {
        final tap = _pulse(t, 0.28, 0.4, 0.86);
        final selected = t < 0.42 ? 1 : 0;
        final showJob = jobMode;
        final n = 2 + (showStats ? 1 : 0) + (showJob ? 1 : 0);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PillBottomNav(
                currentIndex: selected,
                showStats: showStats,
                showJob: showJob,
                tutorial: false,
                embedded: true,
                onChanged: (_) {},
              ),
              if (tap > 0)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      (selected - (n - 1) / 2) * (2 / n),
                      0,
                    ),
                    child: _Finger(pressed: tap),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TitleDemo extends StatelessWidget {
  const _TitleDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return _DemoLoop(
      builder: (context, t) {
        final tap = _pulse(t, 0.22, 0.34, 0.82);
        final zoomed = t >= 0.34 && t < 0.82;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: zoomed ? 1 : 0,
                    child: Text(
                      '2026년',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                  ),
                  Text(
                    zoomed ? '연도 고르기' : '8월',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: zoomed ? 22 : 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 36,
                top: 48,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

class _TapDemo extends StatelessWidget {
  const _TapDemo();

  @override
  Widget build(BuildContext context) {
    return _DemoLoop(
      height: 118,
      builder: (context, t) {
        final tap = _pulse(t, 0.18, 0.3, 0.86);
        final label = Curves.easeOutCubic.transform(_gate(t, 0.34, 0.52));
        return _WeekStrip(
          highlight: tap > 0.4 ? 2 : -1,
          fingerDay: 2,
          finger: tap,
          labels: {
            2: _LabelAppear(
              progress: label,
              title: '자소서',
              color: const Color(0xFF3B82F6),
            ),
          },
        );
      },
    );
  }
}

class _RangeDemo extends StatelessWidget {
  const _RangeDemo();

  @override
  Widget build(BuildContext context) {
    return _DemoLoop(
      height: 118,
      builder: (context, t) {
        final press = _pulse(t, 0.12, 0.24, 0.84);
        final drag = t < 0.26
            ? 0.0
            : t < 0.58
                ? Curves.easeInOutCubic.transform(_gate(t, 0.26, 0.58))
                : t < 0.84
                    ? 1.0
                    : 0.0;
        final start = 1;
        final end = start + (drag * 3).round();
        final label = Curves.easeOutCubic.transform(_gate(t, 0.30, 0.48));
        return _WeekStrip(
          rangeStart: press > 0.2 ? start : -1,
          rangeEnd: press > 0.2 ? end : -1,
          fingerDay: start + drag * 3,
          finger: press,
          spans: [
            if (press > 0.2)
              _SpanAppear(
                start: start,
                end: end,
                progress: label.clamp(0.35, 1.0),
                title: '여행',
                color: const Color(0xFF8B5CF6),
              ),
          ],
        );
      },
    );
  }
}

class _CompleteDemo extends StatelessWidget {
  const _CompleteDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    const accent = Color(0xFF3B82F6);
    return _DemoLoop(
      builder: (context, t) {
        final press = _pulse(t, 0.32, 0.44, 0.86);
        final done = t < 0.44
            ? 0.0
            : t < 0.64
                ? Curves.easeOutCubic.transform(_gate(t, 0.44, 0.64))
                : t < 0.86
                    ? 1.0
                    : 0.0;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tint(accent, done > 0.5 ? 0.11 : 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: done > 0.55 ? 0 : 4,
                        height: 52,
                        color: accent,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '자기소개서 제출',
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color.lerp(
                                    colors.text,
                                    colors.muted,
                                    done * 0.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '서류',
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.hint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CustomPaint(
                            painter: _CheckPainter(
                              progress: done,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (press > 0)
              Positioned(
                right: 18,
                top: 46,
                child: _Finger(pressed: press),
              ),
          ],
        );
      },
    );
  }
}

class _MoveDemo extends StatelessWidget {
  const _MoveDemo();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3B82F6);
    return _DemoLoop(
      height: 156,
      duration: const Duration(milliseconds: 3000),
      builder: (context, t) {
        final press = _pulse(t, 0.12, 0.24, 0.88);
        final drag = t < 0.26
            ? 0.0
            : t < 0.62
                ? Curves.easeInOutCubic.transform(_gate(t, 0.26, 0.62))
                : t < 0.88
                    ? 1.0
                    : 0.0;
        final land = Curves.easeOutCubic.transform(_gate(t, 0.58, 0.72));
        return LayoutBuilder(
          builder: (context, constraints) {
            const pad = 12.0;
            const gap = 5.0;
            final cell = (constraints.maxWidth - pad * 2 - gap * 6) / 7;
            final startX = pad + 18;
            final startY = 18.0;
            final endX = pad + 4 * (cell + gap) + cell / 2 - 40;
            final endY = 78.0;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Opacity(
                    opacity: (1 - drag * 0.85).clamp(0.2, 1),
                    child: const _MiniCard(
                      title: '자기소개서 제출',
                      top: 0,
                      full: true,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 92,
                  child: _WeekStrip(
                    highlight: land > 0.5 ? 4 : -1,
                    finger: 0,
                    labels: {
                      if (land > 0)
                        4: _LabelAppear(
                          progress: land,
                          title: '자기소개서',
                          color: accent,
                        ),
                    },
                  ),
                ),
                if (drag > 0 && land < 1)
                  Positioned(
                    left: startX + (endX - startX) * drag,
                    top: startY + (endY - startY) * drag,
                    width: 88,
                    child: Opacity(
                      opacity: (press * (1 - land)).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: -0.08 * drag,
                        child: CalendarEventLabel(
                          title: '자기소개서',
                          color: accent,
                          height: 18,
                          fontSize: 10,
                          applyCalendarScale: false,
                        ),
                      ),
                    ),
                  ),
                if (press > 0)
                  Positioned(
                    left: startX + (endX - startX) * drag + 28,
                    top: startY + (endY - startY) * drag + 4,
                    child: _Finger(pressed: press),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SearchDemo extends StatelessWidget {
  const _SearchDemo({this.jobMode = false});

  final bool jobMode;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return _DemoLoop(
      height: 148,
      duration: const Duration(milliseconds: 3000),
      builder: (context, t) {
        final press = _pulse(t, 0.28, 0.40, 0.88);
        final onlyTodos = jobMode && t >= 0.40 && t < 0.88;
        final jobs = !jobMode
            ? 0.0
            : onlyTodos
                ? 1 - Curves.easeOutCubic.transform(_gate(t, 0.40, 0.56))
                : 1.0;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          ThemedAsset(
                            asset: AppIcons.search,
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              jobMode
                                  ? AppStrings.allEventsSearchHint
                                  : AppStrings.allEventsSearchHintDaily,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _FilterPill(
                        label: AppStrings.calendarModeRange,
                        selected: false,
                      ),
                      if (jobMode) ...[
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: AppStrings.monthlyStatsTodoSection,
                          selected: onlyTodos,
                        ),
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: AppStrings.monthlyStatsJobSection,
                          selected: false,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  CalendarEventLabel(
                    title: '자기소개서 제출',
                    color: const Color(0xFF3B82F6),
                    height: 18,
                    fontSize: 10,
                    applyCalendarScale: false,
                  ),
                  if (jobs > 0) ...[
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: jobs,
                      child: CalendarEventLabel(
                        title: '플루토',
                        color: const Color(0xFF8B5CF6),
                        isJob: true,
                        height: 18,
                        fontSize: 10,
                        applyCalendarScale: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (press > 0)
              Positioned(
                left: 108,
                top: 52,
                child: _Finger(pressed: press),
              ),
          ],
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? colors.accent : colors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? colors.accent : colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: font,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : colors.text,
        ),
      ),
    );
  }
}

class _SettingsDemo extends StatelessWidget {
  const _SettingsDemo();

  static const _items = [
    AppStrings.settingsHomeLayoutSection,
    AppStrings.settingsThemeSection,
    AppStrings.settingsNotificationSection,
    AppStrings.settingsNavSection,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _DemoLoop(
      height: 168,
      duration: const Duration(milliseconds: 3600),
      builder: (context, t) {
        final selected = (t * 3.99).floor().clamp(0, 3);
        final local = (t * 4) % 1;
        final press = _pulse(local, 0.18, 0.32, 0.78);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        _MenuLine(
                          label: _items[i],
                          highlighted: selected == i,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (press > 0)
              Positioned(
                right: 28,
                top: 22 + selected * 32.0,
                child: _Finger(pressed: press),
              ),
          ],
        );
      },
    );
  }
}

class _MenuDemo extends StatelessWidget {
  const _MenuDemo({this.jobMode = false});

  final bool jobMode;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return _DemoLoop(
      height: 176,
      duration: const Duration(milliseconds: 3400),
      builder: (context, t) {
        final press = _pulse(t, 0.10, 0.22, 0.90);
        final open = Curves.easeOutCubic.transform(_gate(t, 0.22, 0.34));
        final toItem = Curves.easeInOutCubic.transform(_gate(t, 0.34, 0.46));
        final filter = t >= 0.54 && t < 0.90;
        final toCompany = Curves.easeInOutCubic.transform(_gate(t, 0.56, 0.68));
        final companyOn = 1 - _gate(t, 0.70, 0.80);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          '8월',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                        const Spacer(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: ThemedAsset(
                                asset: AppIcons.more,
                                width: 18,
                                height: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _WeekStrip(
                            labels: const {
                              0: _LabelAppear(
                                progress: 1,
                                title: '자소서',
                                color: Color(0xFF3B82F6),
                              ),
                              1: _LabelAppear(
                                progress: 1,
                                title: '면접',
                                color: Color(0xFFF97316),
                              ),
                              3: _LabelAppear(
                                progress: 1,
                                title: '서류',
                                color: Color(0xFF3B82F6),
                              ),
                            },
                            jobLabels: const {
                              1: _LabelAppear(
                                progress: 1,
                                title: '네이버',
                                color: Color(0xFF22C55E),
                                isJob: true,
                              ),
                              2: _LabelAppear(
                                progress: 1,
                                title: '카카오',
                                color: Color(0xFFEAB308),
                                isJob: true,
                              ),
                              4: _LabelAppear(
                                progress: 1,
                                title: '플루토',
                                color: Color(0xFF8B5CF6),
                                isJob: true,
                              ),
                            },
                            jobOpacity: jobMode ? companyOn : 0,
                          ),
                        ),
                        if (open > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Opacity(
                              opacity: open * (t < 0.90 ? 1 : 0),
                              child: Transform.scale(
                                alignment: Alignment.topRight,
                                scale: 0.88 + 0.12 * open,
                                child: SizedBox(
                                  width: 148,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colors.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: colors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.shadow,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 4,
                                      ),
                                      child: filter
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _MenuLine(
                                                  label: '표시할 항목',
                                                  leading:
                                                      Icons.chevron_left_rounded,
                                                ),
                                                _MenuLine(
                                                  label: '할일 보기',
                                                  trailing:
                                                      const _MiniSwitch(on: 1),
                                                ),
                                                if (jobMode)
                                                  _MenuLine(
                                                    label: '지원서 보기',
                                                    trailing: _MiniSwitch(
                                                      on: companyOn,
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _MenuLine(
                                                  label: '표시할 항목',
                                                  highlighted:
                                                      toItem > 0.7 && t < 0.54,
                                                ),
                                                const _MenuLine(
                                                  label: '일기 전환',
                                                  trailing: _MiniSwitch(on: 0),
                                                ),
                                                const _MenuLine(
                                                  label: '가계부 전환',
                                                  trailing: _MiniSwitch(on: 0),
                                                ),
                                              ],
                                            ),
                                    ),
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
            ),
            if (press > 0)
              Positioned(
                right: 14 + 20 * toItem - 8 * toCompany,
                top: 14 + 52 * toItem + 36 * toCompany,
                child: _Finger(pressed: press),
              ),
          ],
        );
      },
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine({
    required this.label,
    this.leading,
    this.trailing,
    this.highlighted = false,
  });

  final String label;
  final IconData? leading;
  final Widget? trailing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? colors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, size: 16, color: colors.icon),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.on});

  final double on;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 32,
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(colors.border, colors.accent, on),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Align(
            alignment: Alignment.lerp(
              Alignment.centerLeft,
              Alignment.centerRight,
              on,
            )!,
            child: const SizedBox(
              width: 14,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReorderDemo extends StatelessWidget {
  const _ReorderDemo();

  @override
  Widget build(BuildContext context) {
    return _DemoLoop(
      duration: const Duration(milliseconds: 2800),
      builder: (context, t) {
        final press = _pulse(t, 0.16, 0.3, 0.86);
        final move = t < 0.34
            ? 0.0
            : t < 0.58
                ? Curves.easeInOutCubic.transform(_gate(t, 0.34, 0.58))
                : t < 0.86
                    ? 1.0
                    : 0.0;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Stack(
                children: [
                  _MiniCard(
                    title: '오늘',
                    top: 8 + 36 * move,
                    lifted: false,
                  ),
                  _MiniCard(
                    title: '내일',
                    top: 44 - 36 * move,
                    lifted: move > 0 && move < 1,
                  ),
                ],
              ),
            ),
            if (press > 0)
              Positioned(
                left: 140,
                top: 58 - 36 * move,
                child: _Finger(pressed: press),
              ),
          ],
        );
      },
    );
  }
}

class _PlanetFillDemo extends StatelessWidget {
  const _PlanetFillDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    const names = [
      AppStrings.statsRank1,
      AppStrings.statsRank2,
      AppStrings.statsRank3,
      AppStrings.statsRank4,
      AppStrings.statsRank5,
      AppStrings.statsRank6,
      AppStrings.statsRank7,
      AppStrings.statsRank8,
      AppStrings.statsRank9,
      AppStrings.statsRank10,
    ];
    return _DemoLoop(
      height: 148,
      duration: const Duration(milliseconds: 14000),
      builder: (context, t) {
        final level = 1 + (t * 9.999).floor().clamp(0, 9);
        return Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              width: 92,
              height: 92,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 640),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                layoutBuilder: (current, previous) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ...previous,
                      if (current != null) current,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.88, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: PlanetFill(
                  key: ValueKey(level),
                  level: level,
                  wave: 0.16,
                  outline: colors.icon,
                  empty: colors.card,
                  pokeable: false,
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              child: Text(
                names[level - 1],
                key: ValueKey(level),
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanetCollectionDemo extends StatelessWidget {
  const _PlanetCollectionDemo();

  static const _levels = [3, 5, 8, 10];
  static const _months = ['3월', '5월', '8월', '12월'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return _DemoLoop(
      height: 140,
      duration: const Duration(milliseconds: 3200),
      builder: (context, t) {
        final tap = _pulse(t, 0.22, 0.34, 0.78);
        final selected = t >= 0.34 && t < 0.78 ? 2 : -1;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.statsCollectedTitle,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < _levels.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: selected == i
                                    ? colors.accent.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 56,
                                    child: PlanetFill(
                                      level: _levels[i],
                                      wave: 0.12,
                                      outline: colors.icon,
                                      empty: colors.card,
                                      pokeable: false,
                                    ),
                                  ),
                                  Text(
                                    _months[i],
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 168,
                top: 58,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

class _StatsDaysDemo extends StatelessWidget {
  const _StatsDaysDemo();

  static const _filled = {1, 4, 7, 8, 11, 15, 17};

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _DemoLoop(
      height: 128,
      duration: const Duration(milliseconds: 2800),
      builder: (context, t) {
        final tap = _pulse(t, 0.2, 0.32, 0.82);
        final picked = t >= 0.32 && t < 0.82 ? 8 : -1;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++) ...[
                    if (row > 0) const SizedBox(height: 6),
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < 7; col++) ...[
                            if (col > 0) const SizedBox(width: 6),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: () {
                                    final i = row * 7 + col;
                                    if (i == picked) return colors.accent;
                                    if (_filled.contains(i)) {
                                      return colors.accent.withValues(
                                        alpha: 0.35,
                                      );
                                    }
                                    return colors.border.withValues(alpha: 0.7);
                                  }(),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 148,
                top: 52,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

class _SwipeDemo extends StatelessWidget {
  const _SwipeDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _DemoLoop(
      builder: (context, t) {
        final press = _pulse(t, 0.16, 0.28, 0.84);
        final swipe = t < 0.3
            ? 0.0
            : t < 0.55
                ? Curves.easeInOutCubic.transform(_gate(t, 0.3, 0.55))
                : t < 0.84
                    ? 1.0
                    : 0.0;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 52,
                  child: Stack(
                    children: [
                      ColoredBox(
                        color: colors.danger.withValues(alpha: 0.16),
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(-72 * swipe, 0),
                        child: const _MiniCard(
                          title: '플루토',
                          top: 0,
                          full: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (press > 0)
              Positioned(
                left: 168 - 72 * swipe,
                top: 46,
                child: _Finger(pressed: press),
              ),
          ],
        );
      },
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.title,
    required this.top,
    this.lifted = false,
    this.full = false,
  });

  final String title;
  final double top;
  final bool lifted;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: lifted
            ? [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: full ? 52 : 32,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: font,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
    if (full) return card;
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: card,
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    this.highlight = -1,
    this.rangeStart = -1,
    this.rangeEnd = -1,
    this.fingerDay = 0,
    this.finger = 0,
    this.labels = const {},
    this.jobLabels = const {},
    this.spans = const [],
    this.jobOpacity = 1,
  });

  final int highlight;
  final int rangeStart;
  final int rangeEnd;
  final double fingerDay;
  final double finger;
  final Map<int, _LabelAppear> labels;
  final Map<int, _LabelAppear> jobLabels;
  final List<_SpanAppear> spans;
  final double jobOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final hasJobs = jobLabels.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 12.0;
        const gap = 5.0;
        const dateH = 10.0;
        const cellH = 28.0;
        const labelH = 16.0;
        final cell = (constraints.maxWidth - pad * 2 - gap * 6) / 7;
        final fingerX = pad + fingerDay * (cell + gap) + cell / 2;
        const labelTop = 10 + dateH + 6 + cellH + 4;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(pad, 10, pad, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: cell,
                      child: Column(
                        children: [
                          Text(
                            '${13 + i}',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.muted,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _DayCell(
                            size: cell,
                            selected: i == highlight ||
                                (rangeStart >= 0 &&
                                    i >= rangeStart &&
                                    i <= rangeEnd),
                            first: i == rangeStart || i == highlight,
                            last: i == rangeEnd || i == highlight,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: hasJobs ? labelH * 2 + 4 : labelH,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: labelH,
                                  child: labels[i] == null
                                      ? const SizedBox.shrink()
                                      : _DayLabel(item: labels[i]!),
                                ),
                                if (hasJobs) ...[
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: labelH,
                                    child: jobLabels[i] == null
                                        ? const SizedBox.shrink()
                                        : _DayLabel(
                                            item: jobLabels[i]!,
                                            opacity: jobOpacity,
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (final span in spans)
              Positioned(
                left: pad + span.start * (cell + gap),
                top: labelTop,
                width: (span.end - span.start + 1) * cell +
                    (span.end - span.start) * gap,
                height: labelH,
                child: _DayLabel(item: span.asLabel),
              ),
            if (finger > 0)
              Positioned(
                left: fingerX - 14,
                top: 28,
                child: _Finger(pressed: finger),
              ),
          ],
        );
      },
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.item, this.opacity = 1});

  final _LabelAppear item;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final visible = (item.progress * opacity).clamp(0.0, 1.0);
    return Opacity(
      opacity: visible,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - item.progress)),
        child: Transform.scale(
          alignment: Alignment.topCenter,
          scale: 0.86 + 0.14 * item.progress,
          child: CalendarEventLabel(
            title: item.title,
            color: item.color,
            isJob: item.isJob,
            height: 16,
            fontSize: 9,
            applyCalendarScale: false,
          ),
        ),
      ),
    );
  }
}

class _LabelAppear {
  const _LabelAppear({
    required this.progress,
    required this.title,
    required this.color,
    this.isJob = false,
  });

  final double progress;
  final String title;
  final Color color;
  final bool isJob;
}

class _SpanAppear {
  const _SpanAppear({
    required this.start,
    required this.end,
    required this.progress,
    required this.title,
    required this.color,
  });

  final int start;
  final int end;
  final double progress;
  final String title;
  final Color color;

  _LabelAppear get asLabel => _LabelAppear(
        progress: progress,
        title: title,
        color: color,
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.size,
    required this.selected,
    required this.first,
    required this.last,
  });

  final double size;
  final bool selected;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.horizontal(
      left: first ? const Radius.circular(8) : Radius.zero,
      right: last ? const Radius.circular(8) : Radius.zero,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? colors.accent.withValues(alpha: 0.22) : colors.card,
        borderRadius: selected ? radius : BorderRadius.circular(8),
        border: Border.all(color: selected ? colors.accent : colors.border),
      ),
    );
  }
}

class _Finger extends StatelessWidget {
  const _Finger({required this.pressed});

  final double pressed;

  @override
  Widget build(BuildContext context) {
    final scale = 1 - pressed * 0.12;
    return Opacity(
      opacity: pressed.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final circleProgress = (1 - progress * 1.15).clamp(0.0, 1.0);
    if (circleProgress > 0) {
      final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width * 0.36,
      );
      final circle = Path()..addArc(rect, -math.pi / 2, 2 * math.pi);
      final metric = circle.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * circleProgress),
        paint,
      );
    }
    if (progress > 0) {
      final check = Path()
        ..moveTo(size.width * 0.18, size.height * 0.52)
        ..lineTo(size.width * 0.40, size.height * 0.74)
        ..lineTo(size.width * 0.84, size.height * 0.26);
      final metric = check.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
