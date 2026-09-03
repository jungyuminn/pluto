import 'package:flutter/material.dart';
import 'package:pluto/core/calendar/lunar_date.dart';
import 'package:pluto/core/calendar/month_grid.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    this.onPressed,
    this.onLongPressed,
    this.inRange = false,
    this.highlighted = false,
    this.showLunar = false,
  });

  final CalendarDay day;
  final ValueChanged<Rect>? onPressed;
  final VoidCallback? onLongPressed;
  final bool inRange;
  final bool highlighted;
  final bool showLunar;

  static const dateTop = 10.0;
  static const dateSize = 20.0;
  static const holidayGap = 3.0;
  static const holidayHeight = 12.0;
  static const lunarGap = 1.0;
  static const lunarHeight = 11.0;
  static const lunarAnim = Duration(milliseconds: 280);
  static const eventsTopGap = 2.0;
  static const labelHeight = 18.0;
  static const labelGap = 2.0;
  static const emojiHeight = 56.0;

  static double emojiHeightFor(double scale) => emojiHeight * scale;
  static const sideInset = 2.0;

  static double dateSizeFor(double scale) => dateSize * scale;

  static double holidayHeightFor(double scale) => holidayHeight * scale;

  static double labelHeightFor(double scale) =>
      (PcLayout.isPc ? 22.0 : labelHeight) * scale;

  static double lunarHeightFor(double scale) => lunarHeight * scale;

  static double eventsTopFor({
    required bool hasHoliday,
    double scale = 1,
    bool showLunar = false,
  }) {
    var top = dateTop + dateSizeFor(scale) + eventsTopGap;
    if (showLunar) top += lunarGap + lunarHeightFor(scale);
    if (hasHoliday) top += holidayGap + holidayHeightFor(scale);
    return top;
  }

  static const _sunday = Color(0xFFEF4444);
  static const _saturday = Color(0xFF60A5FA);
  static const _outsideHoliday = Color(0xFFF0A0A0);
  static const _today = Color(0xFF4AA3FF);

  Color _colorOf(AppColors colors) {
    if (!day.inMonth) {
      return day.isHoliday ? _outsideHoliday : colors.outside;
    }
    if (day.isHoliday || day.isSunday) return _sunday;
    if (day.isSaturday) return _saturday;
    return colors.text;
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
    final colors = AppColors.of(context);
    final color = _colorOf(colors);
    final holiday = day.holidayName;
    final today = day.isToday;
    final scale = AppFonts.calendarScaleOf(context);
    final dateBox = dateSizeFor(scale);

    return PressBounce(
      onPressed: onPressed == null ? () {} : () => onPressed!(_originOf(context)),
      onLongPressed: onLongPressed,
      pressedScale: 0.96,
      color: inRange || highlighted ? colors.rangeFill : Colors.transparent,
      pressedColor: inRange || highlighted ? colors.rangePressed : colors.pressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(top: dateTop),
        child: Column(
          children: [
            Container(
              width: dateBox,
              height: dateBox,
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
                  fontFamily: AppFonts.of(context),
                  fontSize: 12 * scale,
                  fontWeight: today ? FontWeight.w800 : FontWeight.w600,
                  height: 1,
                  color: today ? Colors.white : color,
                ),
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: lunarAnim,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: showLunar
                    ? Padding(
                        padding: const EdgeInsets.only(top: lunarGap),
                        child: SizedBox(
                          height: lunarHeightFor(scale),
                          child: Text(
                            LunarDate.labelOf(day.date) ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 9 * scale,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                              color: day.inMonth ? colors.muted : colors.outside,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
            if (holiday != null) ...[
              const SizedBox(height: holidayGap),
              SizedBox(
                height: holidayHeightFor(scale),
                child: Text(
                  holiday,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 10 * scale,
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
