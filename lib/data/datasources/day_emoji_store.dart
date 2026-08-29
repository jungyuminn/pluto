import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayEmojiStore extends ChangeNotifier {
  DayEmojiStore({SharedPreferences? prefs}) : _prefs = prefs {
    _load();
  }

  static const key = 'day_emojis';
  static const packOrderKey = 'sticker_pack_order';

  final SharedPreferences? _prefs;
  var _emojis = <String, String>{};
  var _packOrder = <String>[];

  String? on(DateTime date) {
    final value = _emojis[stampOf(date)]?.trim();
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

  Future<void> set(DateTime date, String? emoji) async {
    final stamp = stampOf(date);
    final next = emoji?.trim() ?? '';
    if (next.isEmpty) {
      if (!_emojis.containsKey(stamp)) return;
      _emojis = {for (final entry in _emojis.entries) if (entry.key != stamp) entry.key: entry.value};
    } else {
      _emojis = {..._emojis, stamp: next};
    }
    await _persist();
    notifyListeners();
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

  void _load() {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) {
      _emojis = {};
    } else {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          _emojis = {};
        } else {
          _emojis = {
            for (final entry in decoded.entries)
              if (entry.key is String &&
                  entry.value is String &&
                  (entry.value as String).trim().isNotEmpty)
                entry.key as String: entry.value as String,
          };
        }
      } catch (_) {
        _emojis = {};
      }
    }
    _packOrder = _prefs?.getStringList(packOrderKey) ?? const [];
  }

  Future<void> _persist() async {
    await _prefs?.setString(key, jsonEncode(_emojis));
  }
}
