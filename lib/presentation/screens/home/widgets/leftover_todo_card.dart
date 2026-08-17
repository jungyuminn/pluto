import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/core/utils/swipe_to_delete.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';

class LeftoverTodoCard extends StatelessWidget {
  const LeftoverTodoCard({
    super.key,
    required this.event,
    required this.today,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
  });

  final CalendarEvent event;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final Future<bool> Function() onDelete;

  String get _dDay {
    final days = today.difference(event.day).inDays;
    return 'D + $days';
  }

  String get _dateLabel {
    final date = event.day;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.month}. ${date.day}. ($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dDay,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateLabel,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                PressBounce(
                  onPressed: onEdit,
                  pressedColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF94A3B8),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        AppIcons.memo,
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: event.color,
              ),
            ),
            const SizedBox(height: 8),
            SwipeToDelete(
              onSwipeLeft: onDelete,
              child: DayEventLabel(
                title: event.title,
                categoryName: event.categoryName,
                color: event.color,
                completed: event.completed,
                isRepeat: event.isRepeat,
                isRange: event.isRange,
                showCategory: false,
                onPressed: onEdit,
                onLongPressed: () {
                  onDelete();
                },
                onCompletePressed: onComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
