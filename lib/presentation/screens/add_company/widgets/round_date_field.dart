import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_action_icon.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar.dart';

class RoundDateField extends StatelessWidget {
  const RoundDateField({
    super.key,
    required this.date,
    required this.onPicked,
    this.color = const Color(0xFF3B82F6),
  });

  final DateTime? date;
  final ValueChanged<DateTime> onPicked;
  final Color color;

  String get _label {
    final value = date!;
    return '${value.year}년 ${value.month}월 ${value.day}일';
  }

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
      return RoundActionIcon(
        asset: AppIcons.calendarOutlined,
        onPressed: () => _pick(context),
      );
    }

    return GestureDetector(
      onTap: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Text(
        _label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: AppFonts.pretendard,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).secondary,
          fontSize: 16,
        ),
      ),
    );
  }
}
