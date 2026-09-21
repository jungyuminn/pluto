import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/animated_accent.dart';
import 'package:pluto/domain/entities/event_category.dart';

class CalendarEventLabel extends StatelessWidget {
  const CalendarEventLabel({
    super.key,
    required this.title,
    required this.color,
    this.completed = false,
    this.showAccent = true,
    this.isJob = false,
    this.height = 18,
    this.fontSize = 11,
    this.fontWeight = FontWeight.w700,
    this.applyCalendarScale = true,
  });

  final String title;
  final Color color;
  final bool completed;
  final bool showAccent;
  final bool isJob;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final bool applyCalendarScale;

  static bool _isAmount(String text) {
    return text.startsWith('+') || text.startsWith('-');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = 3.0;
    final scale = applyCalendarScale
        ? AppFonts.calendarLabelScaleOf(context)
        : 1.0;
    final baseHeight = PcLayout.isPc ? 22.0 : height;
    final baseFont = PcLayout.isPc ? 12.0 : fontSize;
    final labelHeight = baseHeight * scale;

    return AnimatedAccent(
      color: color,
      builder: (context, accent) {
        final background = colors.tint(accent, 0.14);
        final style = TextStyle(
          fontFamily: AppFonts.of(context),
          fontSize: baseFont * scale,
          fontWeight: fontWeight,
          height: 1,
          color: EventCategory.labelOf(accent),
        );

        return SizedBox(
          height: labelHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: (showAccent && !completed) ? 3 : 0,
                    height: labelHeight,
                    child: ColoredBox(color: accent),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) {
                          return Stack(
                            alignment: Alignment.center,
                            fit: StackFit.expand,
                            clipBehavior: Clip.hardEdge,
                            children: [
                              ...previous,
                              if (current != null) current,
                            ],
                          );
                        },
                        transitionBuilder: (child, animation) {
                          final fromRight = child.key is ValueKey<String> &&
                              _isAmount(
                                (child.key! as ValueKey<String>).value,
                              );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(fromRight ? 0.35 : -0.35, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Align(
                          key: ValueKey(title),
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: style,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
