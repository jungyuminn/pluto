import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:job_planner/presentation/tutorial/tutorial_controller.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class TutorialDemoView extends StatelessWidget {
  const TutorialDemoView({super.key, required this.demo});

  final TutorialDemo demo;

  @override
  Widget build(BuildContext context) {
    return switch (demo) {
      TutorialDemo.none => const SizedBox.shrink(),
      TutorialDemo.navTabs => const _NavDemo(),
      TutorialDemo.calendarTitle => const _TitleDemo(),
      TutorialDemo.calendarTap => const _TapDemo(),
      TutorialDemo.calendarRange => const _RangeDemo(),
      TutorialDemo.todoComplete => const _CompleteDemo(),
      TutorialDemo.calendarMenu => const _MenuDemo(),
      TutorialDemo.homeReorder => const _ReorderDemo(),
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
  const _NavDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    const labels = ['홈', '캘린더', '취업'];
    return _DemoLoop(
      builder: (context, t) {
        final tap = _pulse(t, 0.28, 0.4, 0.86);
        final selected = t < 0.42 ? 1 : 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? colors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: selected == i
                                  ? Colors.white
                                  : colors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 78,
                top: 44,
                child: _Finger(pressed: tap),
              ),
          ],
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
                  color: colors.tint(accent, done > 0.5 ? 0.12 : 0.22),
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

class _MenuDemo extends StatelessWidget {
  const _MenuDemo();

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
                                title: '잡플래너',
                                color: Color(0xFF8B5CF6),
                                isJob: true,
                              ),
                            },
                            jobOpacity: companyOn,
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
                                                _MenuLine(
                                                  label: '기업 보기',
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
                          title: '잡플래너',
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
