import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';

class CalendarWeekdayHeader extends StatelessWidget {
  const CalendarWeekdayHeader({super.key});

  static const _labels = AppStrings.weekdays;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          for (final label in _labels)
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
