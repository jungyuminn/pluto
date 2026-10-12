import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/event_category.dart';

abstract final class CategoryAiClient {
  static const _region = 'asia-northeast3';

  static Future<EventCategory?> pick({
    required String title,
    required List<EventCategory> categories,
    CategoryKind kind = CategoryKind.event,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    if (Firebase.apps.isEmpty) return null;
    if (FirebaseAuth.instance.currentUser == null) return null;

    final usable = [
      for (final category in categories.take(40))
        if (category.name.trim().isNotEmpty) category,
    ];
    final names = [for (final category in usable) category.name.trim()];
    final prompt = trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
    try {
      final result = await FirebaseFunctions.instanceFor(region: _region)
          .httpsCallable('classifyCategory')
          .call({
            'title': prompt,
            'names': names,
            'kind': kind.name,
          })
          .timeout(const Duration(seconds: 12));
      final data = result.data;
      if (data is! Map) return null;
      return _parse(
        '${data['mode'] ?? ''}'.trim(),
        '${data['name'] ?? ''}'.trim(),
        names,
        usable,
      );
    } catch (error) {
      debugPrint('Category AI failed: $error');
      return null;
    }
  }

  static EventCategory? _parse(
    String mode,
    String text,
    List<String> names,
    List<EventCategory> categories,
  ) {
    text = text.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
    if (text.isEmpty) return null;
    final exact = _match(text, names, categories, contains: false);
    if (exact != null) return exact;
    if (mode != 'new') {
      return _match(text, names, categories, contains: true);
    }
    final created = _cleanNewName(text);
    if (created == null) return null;
    return EventCategory.draft(
      name: created,
      color: EventCategory.unusedColor([
        for (final category in categories) category.color,
      ]),
    );
  }

  static EventCategory? _match(
    String text,
    List<String> names,
    List<EventCategory> categories, {
    required bool contains,
  }) {
    if (text.isEmpty || names.isEmpty) return null;
    String? picked;
    for (final name in names) {
      if (name == text) {
        picked = name;
        break;
      }
    }
    if (picked == null && contains) {
      for (final name in names) {
        if (text.contains(name)) {
          picked = name;
          break;
        }
      }
    }
    if (picked == null) return null;
    for (final category in categories) {
      if (category.name.trim() == picked) return category;
    }
    return null;
  }

  static String? _cleanNewName(String raw) {
    var text = raw.split(RegExp(r'[\n,，]')).first.trim();
    text = text.replaceAll(RegExp(r'\s+'), '');
    if (text.length > 8) text = text.substring(0, 8);
    if (text.length < 2) return null;
    return text;
  }
}
