import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/event_category.dart';

abstract final class CategoryAiClient {
  static Future<EventCategory?> pick({
    required String title,
    required List<EventCategory> categories,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || categories.isEmpty) return null;
    if (Firebase.apps.isEmpty) return null;
    if (FirebaseAuth.instance.currentUser == null) return null;

    final usable = [
      for (final category in categories.take(40))
        if (category.name.trim().isNotEmpty) category,
    ];
    final names = [for (final category in usable) category.name.trim()];
    if (names.isEmpty) return null;

    final prompt = trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
    try {
      final model = FirebaseAI.agentPlatform(
        useLimitedUseAppCheckTokens: true,
      ).generativeModel(
        model: 'gemini-3.5-flash-lite',
        generationConfig: GenerationConfig(
          temperature: 0,
          maxOutputTokens: 32,
          thinkingConfig: ThinkingConfig.withThinkingBudget(0),
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'name': Schema.enumString(enumValues: names),
            },
          ),
        ),
      );
      final response = await model
          .generateContent([
            Content.text(
              '제목의 뜻에 맞는 칸 하나만 고르세요. 목록 순서와 현재 선택은 무시하세요.\n'
              '제목: $prompt\n'
              '칸: ${names.join(', ')}',
            ),
          ])
          .timeout(const Duration(seconds: 12));
      return _match(response.text, names, usable);
    } catch (error) {
      debugPrint('Category AI failed: $error');
      return null;
    }
  }

  static EventCategory? _match(
    String? raw,
    List<String> names,
    List<EventCategory> categories,
  ) {
    var text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['name'] != null) {
        text = '${decoded['name']}'.trim();
      }
    } catch (_) {}
    text = text.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
    String? picked;
    for (final name in names) {
      if (name == text) {
        picked = name;
        break;
      }
    }
    if (picked == null) {
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
}
