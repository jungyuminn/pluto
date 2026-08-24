import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';

class DiaryEntryModel {
  DiaryEntryModel._();

  static DiaryEntry fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      date: _parseDate(json['date'] as String),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      photoFileName: json['photoFileName'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ??
          CalendarEvent.defaultCategoryName,
      categoryColor:
          json['categoryColor'] as int? ?? CalendarEvent.defaultCategoryColor,
      groupId: json['groupId'] as String?,
    );
  }

  static Map<String, dynamic> toJson(DiaryEntry entry) {
    return {
      'id': entry.id,
      'date': _formatDate(entry.day),
      'title': entry.title,
      'body': entry.body,
      'photoPath': entry.photoPath,
      'photoFileName': entry.photoFileName,
      'categoryId': entry.categoryId,
      'categoryName': entry.categoryName,
      'categoryColor': entry.categoryColor,
      'groupId': entry.groupId,
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
