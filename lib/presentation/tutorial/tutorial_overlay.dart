import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:pluto/presentation/tutorial/tutorial_demos.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  static const _tabWait = Duration(milliseconds: 380);
  static const _revealDuration = Duration(milliseconds: 280);

  TutorialController? _tutorial;
  TutorialStep? _displayedStep;
  var _displayedIndex = 0;
  var _displayedLast = false;
  var _displayedFirst = true;
  int? _shownTab;
  Rect? _hole;
  Rect? _holeFrom;
  var _generation = 0;
  var _stepIndex = -1;
  var _visible = false;
  late final AnimationController _appear;
  late final AnimationController _holeMotion;
  late final AnimationController _pulse;
  late final Animation<double> _appearFade;
  late final Animation<double> _holeEase;
  final _layerKey = GlobalKey();
  final _cardKey = GlobalKey();
  var _spotlightHidden = false;
  Offset? _cardSlideFrom;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(
      vsync: this,
      duration: _revealDuration,
      reverseDuration: const Duration(milliseconds: 200),
    );
    _holeMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _holeEase = CurvedAnimation(
      parent: _holeMotion,
      curve: Curves.easeOutCubic,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _appearFade = CurvedAnimation(
      parent: _appear,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = TutorialController.maybeOf(context);
    if (identical(next, _tutorial)) return;
    _tutorial?.removeListener(_onTutorial);
    _tutorial = next;
    _tutorial?.addListener(_onTutorial);
    unawaited(_prepareStep());
  }

  @override
  void dispose() {
    _tutorial?.removeListener(_onTutorial);
    _appear.dispose();
    _holeMotion.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onTutorial() => unawaited(_prepareStep());

  void _syncPulse(bool on) {
    if (on) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  Future<void> _prepareStep() async {
    final generation = ++_generation;
    final tutorial = _tutorial;
    if (tutorial == null || !tutorial.active) {
      _syncPulse(false);
      if (!_visible && _appear.value == 0) return;
      await _appear.reverse();
      if (!mounted || generation != _generation) return;
      _holeMotion.value = 0;
      setState(() {
        _visible = false;
        _hole = null;
        _holeFrom = null;
        _shownTab = null;
        _stepIndex = -1;
        _displayedStep = null;
        _spotlightHidden = false;
        _cardSlideFrom = null;
      });
      return;
    }

    final stepIndex = tutorial.index;
    final tabChanged = _shownTab != null && _shownTab != tutorial.step.tab;
    _shownTab = tutorial.step.tab;

    if (!_visible) {
      setState(() {
        _visible = true;
        _displayedStep = tutorial.step;
        _displayedIndex = tutorial.index;
        _displayedLast = tutorial.isLast;
        _displayedFirst = tutorial.isFirst;
      });
    }
    if (_appear.status != AnimationStatus.forward &&
        _appear.status != AnimationStatus.completed) {
      _appear.forward();
    }

    if (tabChanged) {
      setState(() => _spotlightHidden = true);
      _holeMotion.value = 1;
      await Future<void>.delayed(_tabWait);
      if (!mounted || generation != _generation) return;
    }

    final anchor = tutorial.step.anchor;
    if (anchor != null) {
      final target = TutorialAnchor.keyOf(anchor).currentContext;
      final box = target?.findRenderObject();
      if (target != null &&
          target.mounted &&
          box is RenderBox &&
          box.hasSize &&
          box.attached &&
          Scrollable.maybeOf(target) != null) {
        try {
          await Scrollable.ensureVisible(
            target,
            duration: Duration.zero,
            alignment: 0.42,
          );
        } catch (_) {}
      }
    }
    if (!mounted || generation != _generation) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || generation != _generation) return;

    var nextHole = _readHole(tutorial.step.anchor);
    for (var i = 0; i < 6 && nextHole == null && anchor != null; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _generation) return;
      nextHole = _readHole(anchor);
    }
    final stepChanged = stepIndex != _stepIndex;
    if (stepChanged) {
      _cardSlideFrom = _readCardPos();
    }
    setState(() {
      _holeFrom = stepChanged ? _hole : nextHole;
      _hole = nextHole;
      _stepIndex = stepIndex;
      _displayedStep = tutorial.step;
      _displayedIndex = tutorial.index;
      _displayedLast = tutorial.isLast;
      _displayedFirst = tutorial.isFirst;
      _spotlightHidden = false;
    });
    _syncPulse(nextHole != null);
    if (stepChanged && (_holeFrom != null || nextHole != null)) {
      _holeMotion.forward(from: 0);
    } else {
      _holeMotion.value = 1;
    }
  }

  Offset? _readCardPos() {
    final card = _cardKey.currentContext?.findRenderObject();
    final overlay = _layerKey.currentContext?.findRenderObject() ??
        context.findRenderObject();
    if (card is! RenderBox || overlay is! RenderBox) return null;
    if (!card.attached || !overlay.attached) return null;
    if (!card.hasSize || !overlay.hasSize) return null;
    return overlay.globalToLocal(card.localToGlobal(Offset.zero));
  }

  Rect? _readHole(TutorialAnchorId? anchor) {
    if (anchor == null) return null;
    final box = TutorialAnchor.keyOf(anchor).currentContext?.findRenderObject();
    final overlay = _layerKey.currentContext?.findRenderObject() ??
        context.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox) return null;
    if (!box.attached || !overlay.attached) return null;
    if (!box.hasSize || !overlay.hasSize) return null;
    if (box.size.shortestSide < 8 || overlay.size.isEmpty) return null;
    try {
      final rect = MatrixUtils.transformRect(
        box.getTransformTo(overlay),
        Offset.zero & box.size,
      );
      if (!rect.isFinite || rect.width < 8 || rect.height < 8) return null;
      return _visibleHole(rect, overlay.size);
    } catch (_) {
      return null;
    }
  }

  Rect? _visibleHole(Rect hole, Size size) {
    final padding = MediaQuery.paddingOf(context);
    final view = Rect.fromLTRB(
      8,
      padding.top + 8,
      size.width - 8,
      size.height - padding.bottom - 8,
    );
    final visible = hole.intersect(view);
    if (!visible.overlaps(view) || visible.width < 12 || visible.height < 12) {
      return null;
    }
    return visible;
  }

  Rect? get _paintedHole {
    if (_spotlightHidden) return null;
    final to = _hole;
    if (to == null) return null;
    final from = _holeFrom;
    if (from == null || _holeMotion.isCompleted) return to;
    return Rect.lerp(from, to, _holeEase.value);
  }

  @override
  Widget build(BuildContext context) {
    final step = _displayedStep;
    if (!_visible || step == null) return const SizedBox.shrink();
    final padding = MediaQuery.paddingOf(context);
    final tutorial = _tutorial;
    final canAct = tutorial != null && tutorial.active;
    final card = _TutorialCard(
      step: step,
      isFirst: _displayedFirst,
      isLast: _displayedLast,
      index: _displayedIndex,
      total: tutorial?.stepCount ?? TutorialController.steps.length,
      onNext: canAct ? tutorial.next : () {},
      onPrev: canAct ? tutorial.previous : () {},
      onSkip: canAct ? tutorial.skip : () {},
    );

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          key: _layerKey,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_appear, _holeMotion]),
                  builder: (context, _) {
                    final dim = 0.52 * _appearFade.value;
                    return _BlockingScrim(
                      hole: _paintedHole,
                      color: Colors.black.withValues(alpha: dim),
                      passHole: false,
                      pulse: _pulse.value,
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _appearFade,
                  child: CustomPaint(
                    painter: _HolePulsePainter(
                      hole: _paintedHole,
                      pulse: _pulse.value,
                      visible: _paintedHole != null,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: _appearFade,
                child: AnimatedBuilder(
                  animation: _holeMotion,
                  builder: (context, child) {
                    return CustomSingleChildLayout(
                      delegate: _CardDelegate(
                        fromPos: _cardSlideFrom,
                        toHole: _hole,
                        t: _holeEase.value,
                        safe: padding,
                      ),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  child: KeyedSubtree(
                    key: _cardKey,
                    child: card,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockingScrim extends LeafRenderObjectWidget {
  const _BlockingScrim({
    required this.hole,
    required this.color,
    required this.passHole,
    required this.pulse,
  });

  final Rect? hole;
  final Color color;
  final bool passHole;
  final double pulse;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _BlockingScrimRender(
      hole: hole,
      color: color,
      passHole: passHole,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _BlockingScrimRender renderObject,
  ) {
    renderObject
      ..hole = hole
      ..color = color
      ..passHole = passHole;
  }
}

class _BlockingScrimRender extends RenderBox {
  _BlockingScrimRender({
    required Rect? hole,
    required Color color,
    required bool passHole,
  })  : _hole = hole,
        _color = color,
        _passHole = passHole;

  Rect? _hole;
  Color _color;
  bool _passHole;

  set hole(Rect? value) {
    if (_hole == value) return;
    _hole = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  set passHole(bool value) {
    if (_passHole == value) return;
    _passHole = value;
    markNeedsPaint();
  }

  RRect? get _cut {
    final hole = _hole;
    if (hole == null) return null;
    return RRect.fromRectAndRadius(hole.inflate(8), const Radius.circular(16));
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hasSize || size.isEmpty) return false;
    if (_passHole) {
      final cut = _cut;
      if (cut != null && cut.contains(position)) return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!hasSize || size.isEmpty) return;
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final path = Path()..addRect(Offset.zero & size);
    final cut = _cut;
    if (cut != null) {
      path
        ..addRRect(cut)
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = _color);
    canvas.restore();
  }
}

class _HolePulsePainter extends CustomPainter {
  const _HolePulsePainter({
    required this.hole,
    required this.pulse,
    required this.visible,
  });

  final Rect? hole;
  final double pulse;
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || hole == null) return;
    final t = Curves.easeOut.transform(pulse);
    final rect = hole!.inflate(8 + 10 * t);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.45 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_HolePulsePainter oldDelegate) {
    return hole != oldDelegate.hole ||
        pulse != oldDelegate.pulse ||
        visible != oldDelegate.visible;
  }
}

class _CardDelegate extends SingleChildLayoutDelegate {
  const _CardDelegate({
    required this.fromPos,
    required this.toHole,
    required this.t,
    required this.safe,
  });

  final Offset? fromPos;
  final Rect? toHole;
  final double t;
  final EdgeInsets safe;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth = (constraints.maxWidth - 40).clamp(0.0, 360.0);
    final maxHeight = (constraints.maxHeight - safe.vertical - 24).clamp(
      0.0,
      constraints.maxHeight,
    );
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  Offset _posFor(Rect? hole, Size size, Size childSize) {
    final left = (size.width - childSize.width) / 2;
    const gap = 16.0;
    const margin = 12.0;
    final minTop = safe.top + margin;
    final maxTop = size.height - safe.bottom - childSize.height - margin;
    final high = maxTop < minTop ? minTop : maxTop;

    double top;
    final target = hole;
    if (target == null) {
      top = (size.height - childSize.height) / 2;
    } else {
      final below = target.bottom + gap;
      final above = target.top - gap - childSize.height;
      if (below <= high) {
        top = below < minTop ? minTop : below;
      } else if (above >= minTop) {
        top = above;
      } else {
        final roomAbove = target.top - safe.top;
        final roomBelow = size.height - safe.bottom - target.bottom;
        top = roomAbove >= roomBelow ? minTop : high;
      }
    }
    return Offset(left, top.clamp(minTop, high));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final to = _posFor(toHole, size, childSize);
    final from = fromPos ?? to;
    return Offset.lerp(from, to, t) ?? to;
  }

  @override
  bool shouldRelayout(_CardDelegate oldDelegate) {
    return fromPos != oldDelegate.fromPos ||
        toHole != oldDelegate.toHole ||
        t != oldDelegate.t ||
        safe != oldDelegate.safe;
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
  });

  final TutorialStep step;
  final bool isFirst;
  final bool isLast;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (index + 1) / total,
                  minHeight: 4,
                  backgroundColor: colors.border,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (step.badge.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          step.badge,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${index + 1} / $total',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previous,
                      if (current != null) current,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: Column(
                  key: ValueKey(index),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.body,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: colors.secondary,
                      ),
                    ),
                    if (step.demo != TutorialDemo.none) ...[
                      const SizedBox(height: 12),
                      TutorialDemoView(demo: step.demo),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!isLast)
                    PressBounce(
                      onPressed: onSkip,
                      pressedColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Text(
                          AppStrings.tutorialSkip,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!isFirst) ...[
                    PressBounce(
                      onPressed: onPrev,
                      color: colors.accent.withValues(alpha: 0.14),
                      pressedColor: colors.accent.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
                        child: Text(
                          AppStrings.tutorialPrev,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PressBounce(
                    onPressed: onNext,
                    color: colors.accent,
                    pressedColor:
                        Color.lerp(colors.accent, Colors.black, 0.12)!,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      child: Text(
                        isLast
                            ? AppStrings.tutorialDone
                            : index == 0
                                ? AppStrings.tutorialStart
                                : AppStrings.tutorialNext,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
