import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendOrderPreference {
  FriendOrderPreference._();

  static final instance = FriendOrderPreference._();

  static const key = 'friend_order_uids';
  static const syncedKeys = [key];

  final listenable = ValueNotifier<List<String>>(const []);

  List<String> get uids => listenable.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hydrate(prefs);
  }

  void hydrate(SharedPreferences prefs) {
    final next = [
      for (final id in prefs.getStringList(key) ?? const <String>[])
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (listEquals(next, listenable.value)) return;
    listenable.value = next;
  }

  Future<void> setOrder(List<String> uids) async {
    final next = [
      for (final id in uids)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (listEquals(next, listenable.value)) return;
    listenable.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, next);
  }

  Future<void> replaceSubsequence(List<String> visible) {
    final moved = [
      for (final id in visible)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (uids.isEmpty) return setOrder(moved);
    final ids = {for (final id in moved) id};
    final iter = moved.iterator;
    final next = <String>[];
    for (final id in uids) {
      if (ids.contains(id)) {
        if (iter.moveNext()) next.add(iter.current);
      } else {
        next.add(id);
      }
    }
    for (final id in moved) {
      if (!next.contains(id)) next.add(id);
    }
    return setOrder(next);
  }

  List<FriendProfile> apply(List<FriendProfile> items) {
    if (items.length <= 1) return items;
    final order = listenable.value;
    if (order.isEmpty) return items;
    final byId = {for (final item in items) item.uid: item};
    final out = <FriendProfile>[];
    for (final id in order) {
      final item = byId.remove(id);
      if (item != null) out.add(item);
    }
    out.addAll([
      for (final item in items)
        if (byId.containsKey(item.uid)) item,
    ]);
    return out;
  }
}
