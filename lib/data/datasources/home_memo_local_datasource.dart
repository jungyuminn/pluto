import 'dart:convert';

import 'package:pluto/domain/entities/home_memo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeMemoLocalDataSource {
  HomeMemoLocalDataSource({SharedPreferences? prefs}) : _prefs = prefs {
    _load();
  }

  static const key = 'home_memos';

  final SharedPreferences? _prefs;
  var _memos = <HomeMemo>[];

  List<HomeMemo> get memos {
    final next = List<HomeMemo>.of(_memos)
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.id.compareTo(b.id);
      });
    return List.unmodifiable(next);
  }

  Future<void> upsert(HomeMemo memo) async {
    final index = _memos.indexWhere((item) => item.id == memo.id);
    if (index < 0) {
      _memos = [..._memos, memo];
    } else {
      final next = List<HomeMemo>.of(_memos);
      next[index] = memo;
      _memos = next;
    }
    await _persist();
  }

  Future<void> delete(String id) async {
    _memos = [for (final memo in _memos) if (memo.id != id) memo];
    await _persist();
  }

  Future<void> reorder(List<HomeMemo> ordered) async {
    _memos = [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
    ];
    await _persist();
  }

  void reload() {
    _memos = [];
    _load();
  }

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as List<dynamic>;
    _memos = [
      for (final item in decoded)
        HomeMemo.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> _persist() async {
    await _prefs?.setString(
      key,
      jsonEncode(_memos.map((memo) => memo.toJson()).toList()),
    );
  }
}
