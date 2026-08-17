import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';

class EventCategory {
  const EventCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  static const defaultId = 'default';

  static const presets = [
    EventCategory(id: 'travel', name: '여행', color: 0xFF0EA5E9),
    EventCategory(id: 'exercise', name: '운동', color: 0xFF22C55E),
    EventCategory(id: 'hobby', name: '취미', color: 0xFF8B5CF6),
  ];

  static const fallback = EventCategory(
    id: defaultId,
    name: CalendarEvent.defaultCategoryName,
    color: CalendarEvent.defaultCategoryColor,
  );

  final String id;
  final String name;
  final int color;

  Color get tint => Color(color);

  bool get isDefault => id == defaultId;

  EventCategory copyWith({
    String? name,
    int? color,
  }) {
    return EventCategory(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
