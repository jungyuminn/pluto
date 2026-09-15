import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendCategoryPreference {
  FriendCategoryPreference._();

  static final instance = FriendCategoryPreference._();

  static const key = 'friend_private_category_ids';
  static const syncedKeys = [key];

  final listenable = ValueNotifier<Set<String>>(<String>{});

  Set<String> get privateIds => listenable.value;

  bool isPublic(String? categoryId) {
    return !privateIds.contains(_idOf(categoryId));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hydrate(prefs);
  }

  void hydrate(SharedPreferences prefs) {
    listenable.value = {...prefs.getStringList(key) ?? const <String>[]};
  }

  Future<void> setPublic(String categoryId, bool public) async {
    final id = _idOf(categoryId);
    final next = {...privateIds};
    if (public) {
      next.remove(id);
    } else {
      next.add(id);
    }
    if (setEquals(next, privateIds)) return;
    listenable.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, next.toList());
  }

  static String _idOf(String? categoryId) {
    final id = categoryId?.trim() ?? '';
    return id.isEmpty ? EventCategory.defaultId : id;
  }
}
