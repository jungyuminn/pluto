import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:pluto/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class RoundDateField extends StatelessWidget {
  const RoundDateField({
    super.key,
    required this.date,
    required this.onPicked,
    this.endDate,
    this.allowRange = false,
    this.color = const Color(0xFF3B82F6),
    this.emptyLabel,
    this.label,
    this.filledIcon = false,
  });

  final DateTime? date;
  final DateTime? endDate;
  final void Function(DateTime start, DateTime? end) onPicked;
  final bool allowRange;
  final Color color;
  final String? emptyLabel;
  final String? label;
  final bool filledIcon;

  bool get _range {
    if (!allowRange || date == null || endDate == null) return false;
    final start = DateTime(date!.year, date!.month, date!.day);
    final last = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return last.isAfter(start);
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showAppCalendarSheet(
      context,
      date: date,
      dates: date == null
          ? null
          : [
              date!,
              if (_range) endDate!,
            ],
      mode: _range ? AppCalendarMode.range : AppCalendarMode.single,
      color: color,
      showModes: allowRange,
      modes: allowRange
          ? const [AppCalendarMode.single, AppCalendarMode.range]
          : null,
    );
    if (picked == null) return;
    if (picked.mode == AppCalendarMode.range && picked.dates.length >= 2) {
      final days = [...picked.dates]..sort();
      onPicked(days.first, days.last);
      return;
    }
    onPicked(picked.date, null);
  }

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return EventActionIcon(
        label: emptyLabel ?? AppStrings.dateAction,
        text: emptyLabel,
        color: color,
        onPressed: () => _pick(context),
        child: AppAssetImage(
          asset: filledIcon ? AppIcons.calendar : AppIcons.calendarOutlined,
          width: 20,
          height: 20,
        ),
      );
    }

    return EventDateChip(
      date: date!,
      color: color,
      label: label ??
          (_range ? AppStrings.rangeEventLabel : null),
      onPressed: () => _pick(context),
    );
  }
}
