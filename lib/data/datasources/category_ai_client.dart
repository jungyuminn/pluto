import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/core/utils/category_history.dart';
import 'package:pluto/domain/entities/event_category.dart';

abstract final class CategoryAiClient {
  static const _region = 'asia-northeast3';
  static const _batchSize = 60;

  static Future<EventCategory?> pick({
    required String title,
    required List<EventCategory> categories,
    CategoryKind kind = CategoryKind.event,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    if (!_ready) return null;

    final usable = _usableOf(categories);
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

  /// 같은 제목은 한 번만 고른다. 키는 [CategoryHistory.normalize].
  static Future<Map<String, EventCategory>> pickMany({
    required Iterable<String> titles,
    required List<EventCategory> categories,
    CategoryKind kind = CategoryKind.event,
  }) async {
    if (!_ready) return {};
    final unique = <String, String>{};
    for (final raw in titles) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final key = CategoryHistory.normalize(trimmed);
      if (key.isEmpty) continue;
      unique.putIfAbsent(
        key,
        () => trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed,
      );
    }
    if (unique.isEmpty) return {};

    var pool = _usableOf(categories);
    final picked = <String, EventCategory>{};
    final entries = unique.entries.toList();
    for (var i = 0; i < entries.length; i += _batchSize) {
      final end = i + _batchSize > entries.length
          ? entries.length
          : i + _batchSize;
      final chunk = entries.sublist(i, end);
      final items = await _callBatch(
        titles: [for (final entry in chunk) entry.value],
        names: [for (final category in pool) category.name.trim()],
        kind: kind,
      );
      for (var n = 0; n < chunk.length; n++) {
        if (n >= items.length) break;
        final next = _parse(
          items[n].$1,
          items[n].$2,
          [for (final category in pool) category.name.trim()],
          pool,
        );
        if (next == null) continue;
        picked[chunk[n].key] = next;
        if (EventCategory.isDraftId(next.id) &&
            pool.every((category) => category.name.trim() != next.name.trim())) {
          pool = [...pool, next];
        }
      }
    }
    return picked;
  }

  static bool get _ready {
    if (Firebase.apps.isEmpty) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  static List<EventCategory> _usableOf(List<EventCategory> categories) {
    return [
      for (final category in categories.take(80))
        if (category.name.trim().isNotEmpty) category,
    ];
  }

  static Future<List<(String, String)>> _callBatch({
    required List<String> titles,
    required List<String> names,
    required CategoryKind kind,
  }) async {
    try {
      final result = await FirebaseFunctions.instanceFor(region: _region)
          .httpsCallable('classifyCategories')
          .call({
            'titles': titles,
            'names': names,
            'kind': kind.name,
          })
          .timeout(const Duration(seconds: 45));
      final data = result.data;
      if (data is! Map) return const [];
      final items = data['items'];
      if (items is! List) return const [];
      return [
        for (final item in items)
          if (item is Map)
            ('${item['mode'] ?? ''}'.trim(), '${item['name'] ?? ''}'.trim()),
      ];
    } catch (error) {
      debugPrint('Category AI batch failed: $error');
      return const [];
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
