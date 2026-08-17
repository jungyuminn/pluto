import 'package:job_planner/domain/entities/calendar_event.dart';

class CalendarEventModel {
  CalendarEventModel._();

  static CalendarEvent fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      date: _parseDate(json['date'] as String),
      memo: json['memo'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ??
          CalendarEvent.defaultCategoryName,
      categoryColor:
          json['categoryColor'] as int? ?? CalendarEvent.defaultCategoryColor,
      completed: json['completed'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      repeatId: json['repeatId'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      startMinutes: json['startMinutes'] as int?,
      endMinutes: json['endMinutes'] as int?,
    );
  }

  static Map<String, dynamic> toJson(CalendarEvent event) {
    return {
      'id': event.id,
      'title': event.title,
      'date': _formatDate(event.day),
      'memo': event.memo,
      'categoryId': event.categoryId,
      'categoryName': event.categoryName,
      'categoryColor': event.categoryColor,
      'completed': event.completed,
      'groupId': event.groupId,
      'repeatId': event.repeatId,
      'sortOrder': event.sortOrder,
      'startMinutes': event.startMinutes,
      'endMinutes': event.endMinutes,
    };
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime _parseDate(String raw) {
    final parsed = DateTime.parse(raw);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
