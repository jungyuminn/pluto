import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DayStickerLayer {
  event,
  ledger,
  diary;

  static DayStickerLayer current({
    required bool showDiary,
    required bool showLedger,
  }) {
    if (showLedger) return ledger;
    if (showDiary) return diary;
    return event;
  }
}

class DayEmojiStore extends ChangeNotifier {
  DayEmojiStore({SharedPreferences? prefs}) : _prefs = prefs {
    _load();
  }

  static void Function(Map<String, String> stickers)? syncEventLayer;

  static const key = 'day_emojis';
  static const packOrderKey = 'sticker_pack_order';

  final SharedPreferences? _prefs;
  final _layers = {
    for (final layer in DayStickerLayer.values) layer: <String, String>{},
  };
  var _packOrder = <String>[];

  String? on(
    DateTime date, {
    DayStickerLayer layer = DayStickerLayer.event,
  }) {
    final value = _layers[layer]?[stampOf(date)]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  List<String> get packOrder => List.unmodifiable(_packOrder);

  Future<void> setPackOrder(List<String> ids) async {
    if (listEquals(_packOrder, ids)) return;
    _packOrder = List.of(ids);
    await _prefs?.setStringList(packOrderKey, _packOrder);
    notifyListeners();
  }

  Future<void> set(
    DateTime date,
    String? emoji, {
    DayStickerLayer layer = DayStickerLayer.event,
  }) async {
    final stamp = stampOf(date);
    final next = emoji?.trim() ?? '';
    final current = Map<String, String>.of(_layers[layer] ?? {});
    if (next.isEmpty) {
      if (!current.containsKey(stamp)) return;
      current.remove(stamp);
    } else {
      current[stamp] = next;
    }
    _layers[layer] = current;
    await _persist();
    notifyListeners();
    if (layer == DayStickerLayer.event) {
      syncEventLayer?.call(current);
    }
  }

  void reload() {
    _load();
    notifyListeners();
  }

  static String stampOf(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Map<String, String> eventStampsFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      if (_looksLayered(decoded)) {
        return _stampMap(decoded[DayStickerLayer.event.name]);
      }
      return _stampMap(decoded);
    } catch (_) {
      return {};
    }
  }

  void _load() {
    for (final layer in DayStickerLayer.values) {
      _layers[layer] = {};
    }
    var migrated = false;
    final raw = _prefs?.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          if (_looksLayered(decoded)) {
            for (final layer in DayStickerLayer.values) {
              _layers[layer] = _stampMap(decoded[layer.name]);
            }
          } else {
            final stamps = _stampMap(decoded);
            for (final layer in DayStickerLayer.values) {
              _layers[layer] = Map<String, String>.of(stamps);
            }
            migrated = stamps.isNotEmpty;
          }
        }
      } catch (_) {}
    }
    _packOrder = _prefs?.getStringList(packOrderKey) ?? const [];
    if (migrated) _persist();
  }

  Future<void> _persist() async {
    await _prefs?.setString(
      key,
      jsonEncode({
        for (final layer in DayStickerLayer.values) layer.name: _layers[layer],
      }),
    );
  }

  static bool _looksLayered(Map decoded) {
    for (final layer in DayStickerLayer.values) {
      if (decoded[layer.name] is Map) return true;
    }
    return false;
  }

  static Map<String, String> _stampMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.key is String &&
            entry.value is String &&
            (entry.value as String).trim().isNotEmpty)
          entry.key as String: entry.value as String,
    };
  }
}
