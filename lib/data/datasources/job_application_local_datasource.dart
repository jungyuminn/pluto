import 'dart:async';
import 'dart:convert';

import 'package:pluto/core/home_widget/home_screen_widget_service.dart';
import 'package:pluto/core/notifications/todo_reminder_service.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/models/job_application_model.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobApplicationLocalDataSource {
  JobApplicationLocalDataSource(this._prefs);

  static const key = 'job_applications';

  final SharedPreferences _prefs;

  List<JobApplication> fetchAll() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => JobApplicationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<JobApplication> applications) async {
    final payload = jsonEncode(
      applications.map(JobApplicationModel.toJson).toList(),
    );
    await _prefs.setString(key, payload);
    unawaited(_syncSideEffects());
  }

  Future<void> _syncSideEffects() async {
    await TodoReminderService.instance.sync();
    await HomeScreenWidgetService.instance.sync();
    unawaited(FriendService.instance.syncFromLocal());
  }
}
