import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRowOrderPreference {
  HomeRowOrderPreference._();

  static final instance = HomeRowOrderPreference._();

  static const key = 'home_row_order';
  static const syncedKeys = [key];
  static const calendarPrefix = 'c:';
  static const friendPrefix = 'u:';

  final listenable = ValueNotifier<List<String>>(const []);

  List<String> get keys => listenable.value;

  static String calendarKey(String id) => '$calendarPrefix$id';

  static String friendKey(String uid) => '$friendPrefix$uid';

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

  Future<void> setOrder(List<String> keys) async {
    final next = [
      for (final id in keys)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (listEquals(next, listenable.value)) return;
    listenable.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, next);
  }

  Future<void> reorder(
    List<String> visible, {
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= visible.length) return Future.value();
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    if (to < 0) to = 0;
    if (to > visible.length - 1) to = visible.length - 1;
    if (to == oldIndex) return Future.value();
    final next = [...visible];
    final moved = next.removeAt(oldIndex);
    next.insert(to, moved);
    return setOrder(next);
  }

  List<String> apply({
    required List<String> calendarIds,
    required List<String> friendUids,
  }) {
    if (keys.isEmpty) {
      return [
        for (final id in calendarIds) calendarKey(id),
        for (final id in friendUids) friendKey(id),
      ];
    }
    final calSet = {for (final id in calendarIds) id};
    final friendSet = {for (final id in friendUids) id};
    final usedCal = <String>{};
    final usedFriend = <String>{};
    final middle = <String>[];
    for (final key in keys) {
      if (key.startsWith(calendarPrefix)) {
        final id = key.substring(calendarPrefix.length);
        if (calSet.contains(id) && usedCal.add(id)) {
          middle.add(calendarKey(id));
        }
      } else if (key.startsWith(friendPrefix)) {
        final id = key.substring(friendPrefix.length);
        if (friendSet.contains(id) && usedFriend.add(id)) {
          middle.add(friendKey(id));
        }
      }
    }
    return [
      for (final id in calendarIds)
        if (!usedCal.contains(id)) calendarKey(id),
      ...middle,
      for (final id in friendUids)
        if (!usedFriend.contains(id)) friendKey(id),
    ];
  }
}
