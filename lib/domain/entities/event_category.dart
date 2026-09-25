import 'package:flutter/material.dart';
import 'package:pluto/domain/entities/calendar_event.dart';

enum CategoryKind { event, company, ledger, license }

class CategoryColorPack {
  const CategoryColorPack({required this.id, required this.colors});

  final String id;
  final List<int> colors;
}

class EventCategory {
  const EventCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  static const defaultId = 'default';
  static const draftPrefix = 'draft_';

  static bool isDraftId(String? id) {
    return id != null && id.startsWith(draftPrefix);
  }

  static EventCategory draft({required String name, required int color}) {
    return EventCategory(
      id: '$draftPrefix${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: color,
    );
  }

  static int unusedColor(Iterable<int> used) {
    final taken = {for (final color in used) color};
    for (final color in palette) {
      if (!taken.contains(color)) return color;
    }
    return palette[taken.length % palette.length];
  }

  static const basicPalette = [
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

  static const pastelPalette = [
    0xFFFFAAA0,
    0xFFFFC06A,
    0xFFF5E07A,
    0xFFD4F06A,
    0xFFA8EBB0,
    0xFF7AE8D4,
    0xFF9FDCFF,
    0xFF7A9FFF,
    0xFFB09AFF,
    0xFFE0A8FF,
    0xFFFF9AD8,
    0xFFD2A679,
    0xFFC5C9B8,
    0xFFB4C0CC,
  ];

  static const deepPalette = [
    0xFF6E1B2A,
    0xFF8A3E12,
    0xFF6B4A10,
    0xFF3F4A14,
    0xFF1A3F28,
    0xFF0D3F3C,
    0xFF0A3048,
    0xFF1A2A5C,
    0xFF2A1A58,
    0xFF3A1450,
    0xFF5C1A40,
    0xFF4A3028,
    0xFF2E1C16,
    0xFF1C2836,
  ];

  static const dustyPalette = [
    0xFFB86A6A,
    0xFFC4846A,
    0xFFC4965A,
    0xFFB8A85C,
    0xFF8EAB78,
    0xFF6B8F70,
    0xFF5F8F86,
    0xFF6A9AAA,
    0xFF6E8AAB,
    0xFF8A7A9E,
    0xFFB8889A,
    0xFFA86A82,
    0xFF9A7A68,
    0xFF7E8B98,
  ];

  static const palette = [
    ...basicPalette,
    ...pastelPalette,
    ...dustyPalette,
    ...deepPalette,
  ];

  static const colorPacks = [
    CategoryColorPack(id: 'basic', colors: basicPalette),
    CategoryColorPack(id: 'pastel', colors: pastelPalette),
    CategoryColorPack(id: 'dusty', colors: dustyPalette),
    CategoryColorPack(id: 'deep', colors: deepPalette),
  ];

  static int packIndexOf(int color) {
    for (var i = 0; i < colorPacks.length; i++) {
      if (colorPacks[i].colors.contains(color)) return i;
    }
    return 0;
  }

  /// 파스텔 3~6번은 배경이 연해서 라벨 글씨만 살짝 진하게.
  static Color labelOf(Color color) {
    final value = color.toARGB32();
    if (value != pastelPalette[2] &&
        value != pastelPalette[3] &&
        value != pastelPalette[4] &&
        value != pastelPalette[5]) {
      return color;
    }
    return Color.lerp(color, const Color(0xFF1C1910), 0.2)!;
  }

  static const presets = [
    EventCategory(id: 'travel', name: '여행', color: 0xFF00ACC1),
    EventCategory(id: 'exercise', name: '운동', color: 0xFF7CB342),
    EventCategory(id: 'hobby', name: '취미', color: 0xFFA855F7),
  ];

  static const companyPresets = [
    EventCategory(id: 'company_large', name: '대기업', color: 0xFF3B82F6),
    EventCategory(id: 'company_public', name: '공기업', color: 0xFF00ACC1),
    EventCategory(id: 'company_university', name: '대학교', color: 0xFFA855F7),
  ];

  static const ledgerPresets = [
    EventCategory(id: 'ledger_food', name: '식비', color: 0xFFFF8A65),
    EventCategory(id: 'ledger_transport', name: '교통', color: 0xFF3B82F6),
    EventCategory(id: 'ledger_living', name: '생활', color: 0xFF7CB342),
  ];

  static const licensePresets = [
    EventCategory(id: 'license_language', name: '어학', color: 0xFF3B82F6),
    EventCategory(id: 'license_engineer', name: '기사', color: 0xFF00ACC1),
    EventCategory(id: 'license_craftsman', name: '기능사', color: 0xFF7CB342),
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
