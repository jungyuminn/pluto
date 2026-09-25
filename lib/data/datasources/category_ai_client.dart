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
      final model = FirebaseAI.agentPlatform(
        useLimitedUseAppCheckTokens: !kIsWeb,
      ).generativeModel(
        model: 'gemini-3.5-flash-lite',
        generationConfig: GenerationConfig(
          temperature: 0,
          maxOutputTokens: 48,
          thinkingConfig: ThinkingConfig.withThinkingBudget(0),
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'mode': Schema.enumString(enumValues: const ['existing', 'new']),
              'name': Schema.string(),
            },
          ),
        ),
      );
      final list = names.isEmpty ? '없음' : names.join(', ');
      final response = await model
          .generateContent([
            Content.text(
              '${_briefOf(kind)}\n'
              '- 분명히 같은 종류일 때만 기존 칸. mode는 existing.\n'
              '- 일상, 기타, 일반, 할일처럼 넓은 칸은 그 일이 그 칸의 이름 그대로일 때만 쓰세요. 나머지를 거기에 넣지 마세요.\n'
              '- 기존 칸에 딱 안 맞으면 더 구체적인 새 칸. mode는 new.\n'
              '- 새 이름은 2~8글자 명사. 제목을 그대로 쓰지 마세요.\n'
              '제목: $prompt\n'
              '기존 칸: $list',
            ),
          ])
          .timeout(const Duration(seconds: 12));
      return _parse(response.text, names, usable);
    } catch (error) {
      debugPrint('Category AI failed: $error');
      return null;
    }
  }

  static String _briefOf(CategoryKind kind) {
    return switch (kind) {
      CategoryKind.event =>
        '할 일·일기 칸입니다. 하는 일의 종류를 고르세요. 예: 축구가기→운동.\n'
            '식비·교통처럼 돈 쓰는 곳 이름은 쓰지 마세요.',
      CategoryKind.ledger =>
        '가계부 칸입니다. 돈이 오간 곳을 고르세요. 예: 점심값→식비, 버스비→교통.\n'
            '운동·여행처럼 할 일 이름은 쓰지 마세요.',
      CategoryKind.license =>
        '자격증 칸입니다. 시험·자격의 종류를 고르세요. 예: 토익→어학, 정보처리기사→기사.',
      CategoryKind.company =>
        '지원서 칸입니다. 회사·기관의 종류를 고르세요. 예: 삼성전자→대기업.',
    };
  }

  static EventCategory? _parse(
    String? raw,
    List<String> names,
    List<EventCategory> categories,
  ) {
    var mode = '';
    var text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        mode = '${decoded['mode'] ?? ''}'.trim();
        if (decoded['name'] != null) {
          text = '${decoded['name']}'.trim();
        }
      }
    } catch (_) {}
    text = text.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
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
