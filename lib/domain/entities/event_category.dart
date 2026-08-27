import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';

enum CategoryKind { event, company }

class EventCategory {
  const EventCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  static const defaultId = 'default';

  static const palette = [
    0xFFE53935,
    0xFFFF8A65,
    0xFFFB8C00,
    0xFFF6C000,
    0xFF7CB342,
    0xFF2E7D32,
    0xFF00897B,
    0xFF00ACC1,
    0xFF3B82F6,
    0xFFA855F7,
    0xFFF48FB1,
    0xFFD81B60,
    0xFF8D6E63,
    0xFF64748B,
  ];

  static const presets = [
    EventCategory(id: 'travel', name: '여행', color: 0xFF00ACC1),
    EventCategory(id: 'exercise', name: '운동', color: 0xFF7CB342),
    EventCategory(id: 'hobby', name: '취미', color: 0xFFA855F7),
  ];

  static const companyPresets = [
    EventCategory(id: 'company_public', name: '공기업', color: 0xFF00ACC1),
    EventCategory(id: 'company_private', name: '사기업', color: 0xFF3B82F6),
    EventCategory(id: 'company_startup', name: '스타트업', color: 0xFFA855F7),
    EventCategory(id: 'company_intern', name: '인턴', color: 0xFF7CB342),
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
