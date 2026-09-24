import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:pluto/presentation/tutorial/tutorial_demos.dart';

class TutorialSheetHint extends StatelessWidget {
  const TutorialSheetHint({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tutorial = TutorialController.maybeOf(context);
    if (tutorial == null ||
        !tutorial.active ||
        !tutorial.step.hideOverlay ||
        tutorial.step.action == TutorialAction.handleEvent) {
      return const SizedBox.shrink();
    }
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final step = tutorial.step;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.body,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colors.secondary,
                ),
              ),
              if (step.demo != TutorialDemo.none) ...[
                const SizedBox(height: 8),
                TutorialDemoView(demo: step.demo, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialHandleCard extends StatelessWidget {
  const TutorialHandleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorial = TutorialController.maybeOf(context);
    if (tutorial == null ||
        !tutorial.active ||
        tutorial.step.action != TutorialAction.handleEvent) {
      return const SizedBox.shrink();
    }
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final step = tutorial.step;
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: colors.text,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.body,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: colors.secondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TutorialDemoView(demo: step.demo),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PressBounce(
                      onPressed: () {
                        tutorial.next();
                        Navigator.of(context).maybePop();
                      },
                      color: colors.accent,
                      pressedColor:
                          Color.lerp(colors.accent, Colors.black, 0.12)!,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
                        child: Text(
                          AppStrings.tutorialNext,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
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

class TutorialPulse extends StatefulWidget {
  const TutorialPulse({
    super.key,
    required this.child,
    this.active = true,
    this.radius = 999,
    this.color,
  });

  final Widget child;
  final bool active;
  final double radius;
  final Color? color;

  @override
  State<TutorialPulse> createState() => _TutorialPulseState();
}

class _TutorialPulseState extends State<TutorialPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TutorialPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final accent = widget.color ?? AppColors.of(context).accent;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Padding(
          padding: const EdgeInsets.all(5),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.16 + 0.2 * t),
                        blurRadius: 8 + 5 * t,
                        spreadRadius: 0.5,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
