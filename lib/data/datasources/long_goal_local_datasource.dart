import 'dart:convert';

import 'package:job_planner/domain/entities/long_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LongGoalLocalDataSource {
  LongGoalLocalDataSource({SharedPreferences? prefs}) : _prefs = prefs {
    _load();
  }

  static const _goalsKey = 'long_goals';
  static const _logsKey = 'long_goal_logs';

  final SharedPreferences? _prefs;
  var _goals = <LongGoal>[];
  var _logs = <LongGoalLog>[];

  List<LongGoal> get goals {
    final next = List<LongGoal>.of(_goals)
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.id.compareTo(b.id);
      });
    return List.unmodifiable(next);
  }

  List<LongGoalLog> get logs => List.unmodifiable(_logs);

  LongGoalLog? logOn(String goalId, DateTime day) {
    final stamp = dateStamp(day);
    for (final log in _logs) {
      if (log.goalId == goalId && log.date == stamp) return log;
    }
    return null;
  }

  List<LongGoalLog> recentLogs(String goalId, {int days = 14}) {
    final found = [
      for (final log in _logs)
        if (log.goalId == goalId) log,
    ];
    found.sort((a, b) => b.date.compareTo(a.date));
    if (found.length <= days) return found;
    return found.sublist(0, days);
  }

  Future<void> upsertGoal(LongGoal goal) async {
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index < 0) {
      _goals = [..._goals, goal];
    } else {
      final next = List<LongGoal>.of(_goals);
      next[index] = goal;
      _goals = next;
    }
    await _persistGoals();
  }

  Future<void> deleteGoal(String id) async {
    _goals = [for (final goal in _goals) if (goal.id != id) goal];
    _logs = [for (final log in _logs) if (log.goalId != id) log];
    await _persistGoals();
    await _persistLogs();
  }

  Future<void> reorderGoals(List<LongGoal> ordered) async {
    _goals = [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
    ];
    await _persistGoals();
  }

  Future<void> upsertLog(LongGoalLog log) async {
    if (log.isEmpty) {
      await deleteLog(log.goalId, log.date);
      return;
    }
    final index = _logs.indexWhere(
      (item) => item.goalId == log.goalId && item.date == log.date,
    );
    if (index < 0) {
      _logs = [..._logs, log];
    } else {
      final next = List<LongGoalLog>.of(_logs);
      next[index] = log;
      _logs = next;
    }
    await _persistLogs();
  }

  Future<void> deleteLog(String goalId, String date) async {
    _logs = [
      for (final log in _logs)
        if (log.goalId != goalId || log.date != date) log,
    ];
    await _persistLogs();
  }

  static String dateStamp(DateTime day) => LongGoal.dateStamp(day);

  void reload() {
    _goals = [];
    _logs = [];
    _load();
  }

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final goalsRaw = prefs.getString(_goalsKey);
    if (goalsRaw != null && goalsRaw.isNotEmpty) {
      final decoded = jsonDecode(goalsRaw) as List<dynamic>;
      _goals = [
        for (final item in decoded)
          LongGoal.fromJson(item as Map<String, dynamic>),
      ];
      final migrate = decoded.any((item) {
        final kind = (item as Map<String, dynamic>)['kind'] as String?;
        return kind == 'abstain' || kind == 'count' || kind == 'check';
      });
      if (migrate) {
        _persistGoals();
      }
    }
    final logsRaw = prefs.getString(_logsKey);
    if (logsRaw != null && logsRaw.isNotEmpty) {
      final decoded = jsonDecode(logsRaw) as List<dynamic>;
      _logs = [
        for (final item in decoded)
          LongGoalLog.fromJson(item as Map<String, dynamic>),
      ];
    }
  }

  Future<void> _persistGoals() async {
    await _prefs?.setString(
      _goalsKey,
      jsonEncode(_goals.map((goal) => goal.toJson()).toList()),
    );
  }

  Future<void> _persistLogs() async {
    await _prefs?.setString(
      _logsKey,
      jsonEncode(_logs.map((log) => log.toJson()).toList()),
    );
  }
}
