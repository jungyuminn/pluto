import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendFavoritePreference {
  FriendFavoritePreference._();

  static final instance = FriendFavoritePreference._();

  static const key = 'friend_favorite_uids';
  static const syncedKeys = [key];

  final listenable = ValueNotifier<List<String>>(const []);

  List<String> get uids => listenable.value;

  bool contains(String uid) => uids.contains(uid);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hydrate(prefs);
  }

  void hydrate(SharedPreferences prefs) {
    final next = _clean(prefs.getStringList(key) ?? const <String>[]);
    if (listEquals(next, listenable.value)) return;
    listenable.value = next;
  }

  Future<void> setFavorite(String uid, bool favorite) async {
    final id = uid.trim();
    if (id.isEmpty) return;
    final next = [for (final item in uids) item];
    final has = next.contains(id);
    if (favorite && !has) {
      next.add(id);
    } else if (!favorite && has) {
      next.remove(id);
    } else {
      return;
    }
    await _write(next);
  }

  int countIn(List<FriendProfile> items) {
    return items.where((item) => contains(item.uid)).length;
  }

  List<FriendProfile> apply(List<FriendProfile> items) {
    if (items.isEmpty || uids.isEmpty) return items;
    final byId = {for (final item in items) item.uid: item};
    final top = <FriendProfile>[];
    for (final id in uids) {
      final item = byId.remove(id);
      if (item != null) top.add(item);
    }
    return [
      ...top,
      for (final item in items)
        if (byId.containsKey(item.uid)) item,
    ];
  }

  Future<void> setOrder(List<String> uids) => _write(uids);

  Future<void> reorder(
    List<FriendProfile> items, {
    required int oldIndex,
    required int newIndex,
  }) {
    final favCount = countIn(items);
    if (oldIndex < 0 || oldIndex >= favCount) return Future.value();
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target > favCount - 1) target = favCount - 1;
    final next = [
      for (final item in items)
        if (contains(item.uid)) item,
    ];
    final moved = next.removeAt(oldIndex);
    next.insert(target, moved);
    return setOrder([for (final item in next) item.uid]);
  }

  Future<void> forget(String uid) {
    final id = uid.trim();
    if (id.isEmpty) return Future.value();
    return _write([for (final item in uids) if (item != id) item]);
  }

  List<String> _clean(List<String> uids) {
    return [
      for (final id in uids)
        if (id.trim().isNotEmpty) id.trim(),
    ];
  }

  Future<void> _write(List<String> uids) async {
    final next = _clean(uids);
    if (listEquals(next, listenable.value)) return;
    listenable.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, next);
  }
}
