import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class EventTimeChip extends StatelessWidget {
  const EventTimeChip({
    super.key,
    required this.color,
    this.onPressed,
    this.startMinutes,
    this.endMinutes,
    this.emptyLabel,
  });

  final Color color;
  final VoidCallback? onPressed;
  final int? startMinutes;
  final int? endMinutes;
  final String? emptyLabel;

  String get _label {
    final start = startMinutes;
    final end = endMinutes;
    if (start == null || end == null) {
      return emptyLabel ?? AppStrings.allDayLabel;
    }
    return '${CalendarEvent.formatMinutes(start)}–${CalendarEvent.formatMinutes(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ink = EventCategory.labelOf(color);
    return PressBounce(
      onPressed: onPressed,
      color: colors.card,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
              child: AppAssetImage(
                asset: AppIcons.clock,
                width: 20,
                height: 20,
                semanticLabel: AppStrings.timeAction,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
