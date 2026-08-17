import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/month_grid.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    this.onPressed,
    this.inRange = false,
  });

  final CalendarDay day;
  final ValueChanged<Rect>? onPressed;
  final bool inRange;

  static const dateTop = 10.0;
  static const dateSize = 20.0;
  static const holidayGap = 3.0;
  static const holidayHeight = 12.0;
  static const eventsTopGap = 2.0;
  static const labelHeight = 18.0;
  static const labelGap = 2.0;
  static const sideInset = 2.0;

  static double get eventsTop => eventsTopFor(hasHoliday: false);

  static double eventsTopFor({required bool hasHoliday}) {
    var top = dateTop + dateSize + eventsTopGap;
    if (hasHoliday) top += holidayGap + holidayHeight;
    return top;
  }

  static const _sunday = Color(0xFFEF4444);
  static const _saturday = Color(0xFF60A5FA);
  static const _weekday = Color(0xFF0F172A);
  static const _outside = Color(0xFFD1D5DB);
  static const _outsideHoliday = Color(0xFFF0A0A0);
  static const _today = Color(0xFF0088FF);

  Color get _color {
    if (!day.inMonth) {
      return day.isHoliday ? _outsideHoliday : _outside;
    }
    if (day.isHoliday || day.isSunday) return _sunday;
    if (day.isSaturday) return _saturday;
    return _weekday;
  }

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
    final color = _color;
    final holiday = day.holidayName;
    final today = day.isToday;

    return PressBounce(
      onPressed: onPressed == null ? () {} : () => onPressed!(_originOf(context)),
      pressedScale: 0.96,
      color: inRange ? const Color(0xFFDBEAFE) : Colors.transparent,
      pressedColor: inRange
          ? const Color(0xFFBFDBFE)
          : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(top: dateTop),
        child: Column(
          children: [
            Container(
              width: dateSize,
              height: dateSize,
              alignment: Alignment.center,
              decoration: today
                  ? const BoxDecoration(
                      color: _today,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${day.date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: today ? FontWeight.w800 : FontWeight.w600,
                  height: 1,
                  color: today ? Colors.white : color,
                ),
              ),
            ),
            if (holiday != null) ...[
              const SizedBox(height: holidayGap),
              SizedBox(
                height: holidayHeight,
                child: Text(
                  holiday,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
