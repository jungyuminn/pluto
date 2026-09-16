import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/core/utils/swipe_to_delete.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_event_label.dart';

class LeftoverTodoCard extends StatelessWidget {
  const LeftoverTodoCard({
    super.key,
    required this.event,
    required this.today,
    required this.onEdit,
    required this.onPostpone,
    required this.onComplete,
    required this.onDelete,
  });

  final CalendarEvent event;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onPostpone;
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
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dDay,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: colors.danger,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                PressBounce(
                  onPressed: onPostpone,
                  pressedColor: colors.pressed,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      AppStrings.postpone,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.muted,
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
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EventCategory.labelOf(event.color),
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
                memo: event.memo,
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
