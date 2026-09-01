import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar.dart';

class RoundDateField extends StatelessWidget {
  const RoundDateField({
    super.key,
    required this.date,
    required this.onPicked,
    this.color = const Color(0xFF3B82F6),
    this.emptyLabel,
    this.label,
    this.filledIcon = false,
  });

  final DateTime? date;
  final ValueChanged<DateTime> onPicked;
  final Color color;
  final String? emptyLabel;
  final String? label;
  final bool filledIcon;

  Future<void> _pick(BuildContext context) async {
    final picked = await showAppCalendarSheet(
      context,
      date: date,
      color: color,
      showModes: false,
    );
    if (picked != null) onPicked(picked.date);
  }

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return EventActionIcon(
        label: emptyLabel ?? AppStrings.dateAction,
        text: emptyLabel,
        color: color,
        onPressed: () => _pick(context),
        child: Image.asset(
          filledIcon ? AppIcons.calendar : AppIcons.calendarOutlined,
          width: 20,
          height: 20,
        ),
      );
    }

    return EventDateChip(
      date: date!,
      color: color,
      label: label,
      onPressed: () => _pick(context),
    );
  }
}
