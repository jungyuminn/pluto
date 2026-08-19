import 'dart:async';
import 'dart:convert';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/data/models/job_application_model.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobApplicationLocalDataSource {
  JobApplicationLocalDataSource(this._prefs);

  static const _key = 'job_applications';

  final SharedPreferences _prefs;

  List<JobApplication> fetchAll() {
    final raw = _prefs.getString(_key);
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
    await _prefs.setString(_key, payload);
    unawaited(_syncSideEffects());
  }

  Future<void> _syncSideEffects() async {
    await TodoReminderService.instance.sync();
    await HomeScreenWidgetService.instance.sync();
  }
}
