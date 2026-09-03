import 'package:pluto/domain/entities/event_category.dart';

class EventCategoryModel {
  EventCategoryModel._();

  static EventCategory fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as int? ?? EventCategory.fallback.color,
    );
  }

  static Map<String, dynamic> toJson(EventCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'color': category.color,
    };
  }
}
