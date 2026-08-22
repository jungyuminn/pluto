import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    this.title = '',
    this.body = '',
    this.photoPath,
    this.photoFileName,
    this.categoryId,
    this.categoryName = CalendarEvent.defaultCategoryName,
    this.categoryColor = CalendarEvent.defaultCategoryColor,
  });

  final String id;
  final DateTime date;
  final String title;
  final String body;
  final String? photoPath;
  final String? photoFileName;
  final String? categoryId;
  final String categoryName;
  final int categoryColor;

  Color get color => Color(categoryColor);

  DateTime get day => DateTime(date.year, date.month, date.day);

  bool get hasPhoto {
    final path = photoPath;
    return path != null && path.isNotEmpty;
  }

  bool get isBlank =>
      title.trim().isEmpty && body.trim().isEmpty && !hasPhoto;

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? body,
    String? photoPath,
    String? photoFileName,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    bool clearPhoto = false,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      body: body ?? this.body,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
      photoFileName: clearPhoto ? null : photoFileName ?? this.photoFileName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }
}
