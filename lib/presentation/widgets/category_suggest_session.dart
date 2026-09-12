import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/utils/category_history.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/category_ai_client.dart';
import 'package:pluto/domain/entities/event_category.dart';

typedef CategorySuggestUpdate = void Function(
  EventCategory? category, {
  required bool loading,
});

class CategorySuggestSession {
  static bool isOn(BuildContext context, {required bool editing}) {
    if (editing) return false;
    if (AppAuthService.instance.user == null) return false;
    return AppScope.of(context).categorySuggestPreference.enabled;
  }

  CategorySuggestSession({
    required this.categories,
    required this.records,
    required this.fallback,
    required this.onUpdate,
  });

  final List<EventCategory> categories;
  final List<CategoryHistoryRecord> records;
  final EventCategory fallback;
  final CategorySuggestUpdate onUpdate;

  var _locked = false;
  var _gen = 0;
  Timer? _debounce;

  void onTitle(String raw) {
    if (_locked) return;
    _debounce?.cancel();
    final title = raw.trim();
    if (title.isEmpty) {
      _gen++;
      onUpdate(null, loading: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 520), () {
      unawaited(_run(title));
    });
  }

  void userPicked() {
    _locked = true;
    _debounce?.cancel();
    _gen++;
    onUpdate(null, loading: false);
  }

  Future<void> _run(String title) async {
    if (_locked) return;
    final hit = CategoryHistory.match(
      title: title,
      categories: categories,
      records: records,
    );
    if (hit != null) {
      onUpdate(hit, loading: false);
      return;
    }

    final gen = ++_gen;
    final spinner = Timer(const Duration(milliseconds: 120), () {
      if (_locked || gen != _gen) return;
      onUpdate(null, loading: true);
    });
    final picked = await CategoryAiClient.pick(
      title: title,
      categories: categories,
    );
    spinner.cancel();
    if (_locked || gen != _gen) return;
    onUpdate(picked ?? fallback, loading: false);
  }

  void dispose() {
    _locked = true;
    _debounce?.cancel();
    _gen++;
  }
}
