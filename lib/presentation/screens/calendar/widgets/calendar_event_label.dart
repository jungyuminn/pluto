import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final background =
        AppColors.of(context).tint(color, isJob ? 0.12 : 0.22);
    final radius = isJob ? 6.0 : 3.0;
    final scale =
        applyCalendarScale ? AppFonts.calendarLabelScaleOf(context) : 1.0;
    final labelHeight = height * scale;
    final labelSize = fontSize * scale;

    return SizedBox(
      height: labelHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: isJob ? Border.all(color: color, width: 1) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: (showAccent && !completed && !isJob) ? 3 : 0,
                height: labelHeight,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isJob ? 4 : 3),
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: labelSize,
                        fontWeight: fontWeight,
                        height: 1,
                        color: color,
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
  }
}
