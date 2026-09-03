import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class EventDateChip extends StatelessWidget {
  const EventDateChip({
    super.key,
    required this.date,
    required this.color,
    required this.onPressed,
    this.label,
    this.iconSize = 20,
  });

  final DateTime date;
  final Color color;
  final VoidCallback onPressed;
  final String? label;
  final double iconSize;

  String get _label {
    if (label != null) return label!;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.month}. ${date.day}. ($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      color: AppColors.of(context).card,
      pressedColor: AppColors.of(context).pressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(
                AppIcons.calendar,
                width: iconSize,
                height: iconSize,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
