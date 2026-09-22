import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendCategoryPreference {
  FriendCategoryPreference._();

  static final instance = FriendCategoryPreference._();

  static const key = 'friend_private_category_ids';
  static const jobsKey = 'friend_share_jobs';
  static const companyKey = 'friend_private_company_category_ids';
  static const syncedKeys = [key, jobsKey, companyKey];
  static const defaultBools = {jobsKey: true};

  final listenable = ValueNotifier<Set<String>>(<String>{});
  final companyListenable = ValueNotifier<Set<String>>(<String>{});
  final shareJobsListenable = ValueNotifier<bool>(true);

  Listenable get allListenable => Listenable.merge([
        listenable,
        companyListenable,
        shareJobsListenable,
      ]);

  Set<String> get privateIds => listenable.value;
  Set<String> get companyPrivateIds => companyListenable.value;
  bool get shareJobs => shareJobsListenable.value;

  bool isPublic(String? categoryId) {
    return !privateIds.contains(_idOf(categoryId));
  }

  bool isCompanyPublic(String? categoryId) {
    final id = categoryId?.trim() ?? '';
    if (id.isEmpty) return true;
    return !companyPrivateIds.contains(id);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hydrate(prefs);
  }

  void hydrate(SharedPreferences prefs) {
    listenable.value = {...prefs.getStringList(key) ?? const <String>[]};
    companyListenable.value = {
      ...prefs.getStringList(companyKey) ?? const <String>[],
    };
    shareJobsListenable.value = prefs.getBool(jobsKey) ?? true;
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

  Future<void> setShareJobs(bool value) async {
    if (shareJobs == value) return;
    shareJobsListenable.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(jobsKey, value);
  }

  Future<void> setCompanyPublic(String categoryId, bool public) async {
    final id = categoryId.trim();
    if (id.isEmpty) return;
    final next = {...companyPrivateIds};
    if (public) {
      next.remove(id);
    } else {
      next.add(id);
    }
    if (setEquals(next, companyPrivateIds)) return;
    companyListenable.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(companyKey, next.toList());
  }

  static String _idOf(String? categoryId) {
    final id = categoryId?.trim() ?? '';
    return id.isEmpty ? EventCategory.defaultId : id;
  }
}
