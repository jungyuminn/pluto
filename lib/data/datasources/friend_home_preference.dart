import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendHomePreference {
  FriendHomePreference._();

  static final instance = FriendHomePreference._();

  static const uidsKey = 'friend_home_uids';
  static const seenKey = 'friend_home_seen_uids';
  static const seededKey = 'friend_home_seeded';
  static const syncedKeys = [uidsKey, seenKey, seededKey];

  final listenable = ValueNotifier<List<String>>(const []);
  var _seen = const <String>[];
  var _seeded = false;
  var _seeding = false;

  List<String> get uids => listenable.value;

  bool get seeded => _seeded;

  bool contains(String uid) => uids.contains(uid);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hydrate(prefs);
  }

  void hydrate(SharedPreferences prefs) {
    _seeded = prefs.getBool(seededKey) ?? false;
    _seen = _clean(prefs.getStringList(seenKey) ?? const <String>[]);
    final next = _clean(prefs.getStringList(uidsKey) ?? const <String>[]);
    if (listEquals(next, listenable.value)) return;
    listenable.value = next;
  }

  List<FriendProfile> onHome(List<FriendProfile> friends) {
    if (!_seeded) return friends;
    final byId = {for (final friend in friends) friend.uid: friend};
    return [
      for (final id in uids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> seedIfNeeded(List<String> friendUids) async {
    if (_seeding) return;
    _seeding = true;
    try {
      final friends = _clean(friendUids);
      if (!_seeded) {
        await _write(uids: friends, seen: friends, seeded: true);
        return;
      }
      if (_seen.isEmpty && friends.isNotEmpty) {
        await _write(uids: uids, seen: friends, seeded: true);
        return;
      }
      final newcomers = [
        for (final id in friends)
          if (!_seen.contains(id)) id,
      ];
      if (newcomers.isEmpty) return;
      await _write(
        uids: [...uids, ...newcomers],
        seen: [..._seen, ...newcomers],
        seeded: true,
      );
    } finally {
      _seeding = false;
    }
  }

  Future<void> setPinned(String uid, bool pinned) async {
    final id = uid.trim();
    if (id.isEmpty) return;
    final next = [for (final item in uids) item];
    final has = next.contains(id);
    if (pinned && !has) {
      next.add(id);
    } else if (!pinned && has) {
      next.remove(id);
    } else if (_seeded) {
      return;
    }
    final seen = [
      for (final item in _seen) item,
      if (!_seen.contains(id)) id,
    ];
    await _write(uids: next, seen: seen, seeded: true);
  }

  Future<void> forget(String uid) {
    final id = uid.trim();
    if (id.isEmpty) return Future.value();
    return _write(
      uids: [for (final item in uids) if (item != id) item],
      seen: [for (final item in _seen) if (item != id) item],
      seeded: true,
    );
  }

  Future<void> setOrder(List<String> uids) {
    return _write(uids: uids, seen: _seen, seeded: true);
  }

  List<String> _clean(List<String> uids) {
    return [
      for (final id in uids)
        if (id.trim().isNotEmpty) id.trim(),
    ];
  }

  Future<void> _write({
    required List<String> uids,
    required List<String> seen,
    required bool seeded,
  }) async {
    final next = _clean(uids);
    final nextSeen = _clean(seen);
    if (_seeded == seeded &&
        listEquals(next, listenable.value) &&
        listEquals(nextSeen, _seen)) {
      return;
    }
    _seeded = seeded;
    _seen = nextSeen;
    listenable.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(uidsKey, next);
    await prefs.setStringList(seenKey, nextSeen);
    await prefs.setBool(seededKey, seeded);
  }
}
