enum LongGoalKind {
  measure,
  sum,
  daily,
  streak;

  bool get isCheckIn =>
      this == LongGoalKind.daily || this == LongGoalKind.streak;

  String get defaultUnit => switch (this) {
        LongGoalKind.daily || LongGoalKind.streak => '일',
        _ => '',
      };

  static LongGoalKind fromName(String? raw) {
    return switch (raw) {
      'measure' => LongGoalKind.measure,
      'daily' || 'abstain' || 'count' || 'check' => LongGoalKind.daily,
      'streak' => LongGoalKind.streak,
      _ => LongGoalKind.sum,
    };
  }
}

class LongGoal {
  const LongGoal({
    required this.id,
    required this.title,
    required this.color,
    required this.kind,
    required this.target,
    this.unit = '',
    this.memo = '',
    this.categoryId,
    this.sortOrder = 0,
    this.startedAt = '',
  });

  final String id;
  final String title;
  final int color;
  final LongGoalKind kind;
  final double target;
  final String unit;
  final String memo;
  final String? categoryId;
  final int sortOrder;
  final String startedAt;

  String format(double value) {
    final text = formatNumber(value);
    if (unit.isEmpty) return text;
    return '$text$unit';
  }

  LongGoalProgress progress(Iterable<LongGoalLog> logs) {
    return LongGoalProgress.from(this, logs);
  }

  bool streakBroken(Iterable<LongGoalLog> logs, DateTime today) {
    if (kind != LongGoalKind.streak) return false;
    final day = DateTime(today.year, today.month, today.day);
    if (!startedDay(day).isBefore(day)) return false;
    return progress(logs).done <= 0;
  }

  LongGoal copyWith({
    String? title,
    int? color,
    LongGoalKind? kind,
    double? target,
    String? unit,
    String? memo,
    String? categoryId,
    int? sortOrder,
    String? startedAt,
  }) {
    return LongGoal(
      id: id,
      title: title ?? this.title,
      color: color ?? this.color,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      memo: memo ?? this.memo,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'kind': kind.name,
      'target': target,
      'unit': unit,
      'memo': memo,
      'categoryId': categoryId,
      'sortOrder': sortOrder,
      'startedAt': startedAt,
    };
  }

  factory LongGoal.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as List<dynamic>?;
    Map<String, dynamic>? firstStat;
    if (stats != null && stats.isNotEmpty) {
      firstStat = stats.first as Map<String, dynamic>;
    }
    return LongGoal(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF22C55E,
      kind: LongGoalKind.fromName(json['kind'] as String?),
      target: (json['target'] as num?)?.toDouble() ??
          (firstStat?['target'] as num?)?.toDouble() ??
          0,
      unit: json['unit'] as String? ?? firstStat?['unit'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      startedAt: json['startedAt'] as String? ?? '',
    );
  }

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static String dateStamp(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  static DateTime? parseStamp(String stamp) {
    if (stamp.isEmpty) return null;
    final parts = stamp.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  DateTime startedDay(DateTime fallback) {
    final parsed = parseStamp(startedAt);
    if (parsed != null) return parsed;
    if (sortOrder > 1000000000000) {
      final time = DateTime.fromMillisecondsSinceEpoch(sortOrder);
      return DateTime(time.year, time.month, time.day);
    }
    return DateTime(fallback.year, fallback.month, fallback.day);
  }
}

class LongGoalProgress {
  const LongGoalProgress({
    required this.done,
    required this.target,
    required this.ratio,
    required this.summary,
    this.start = 0,
  });

  factory LongGoalProgress.from(LongGoal goal, Iterable<LongGoalLog> logs) {
    final mine = [
      for (final log in logs)
        if (log.goalId == goal.id && log.value != null) log,
    ]..sort((a, b) => a.date.compareTo(b.date));

    if (goal.kind == LongGoalKind.measure) {
      if (mine.isEmpty) {
        return LongGoalProgress(
          done: 0,
          target: goal.target,
          ratio: 0,
          summary: '',
        );
      }
      final start = mine.first.value!;
      final current = mine.last.value!;
      final span = goal.target - start;
      final ratio = span.abs() < 0.000001
          ? (current == goal.target ? 1.0 : 0.0)
          : ((current - start) / span).clamp(0.0, 1.0);
      return LongGoalProgress(
        done: current,
        target: goal.target,
        ratio: ratio,
        summary: '${goal.format(current)} / ${goal.format(goal.target)}',
        start: start,
      );
    }

    if (goal.kind == LongGoalKind.streak) {
      final days = <DateTime>[];
      for (final log in mine) {
        if ((log.value ?? 0) <= 0) continue;
        final day = LongGoal.parseStamp(log.date);
        if (day == null) continue;
        final stamp = DateTime(day.year, day.month, day.day);
        if (days.isEmpty || days.last != stamp) days.add(stamp);
      }
      final done = _streakLength(days).toDouble();
      final ratio = goal.target <= 0 ? 0.0 : done / goal.target;
      return LongGoalProgress(
        done: done,
        target: goal.target,
        ratio: ratio,
        summary: '${LongGoal.formatNumber(done)} / ${goal.format(goal.target)}',
      );
    }

    var done = 0.0;
    for (final log in mine) {
      done += log.value ?? 0;
    }
    final ratio = goal.target <= 0 ? 0.0 : done / goal.target;
    return LongGoalProgress(
      done: done,
      target: goal.target,
      ratio: ratio,
      summary: '${LongGoal.formatNumber(done)} / ${goal.format(goal.target)}',
    );
  }

  final double done;
  final double target;
  final double ratio;
  final String summary;
  final double start;

  double get barValue => ratio.clamp(0.0, 1.0);

  double get span => (target - start).abs();

  int get barSegments {
    final range = span;
    if (range < 2) return 10;
    final n = range.round();
    if ((range - n).abs() < 0.000001 && n >= 2 && n <= 12) return n;
    return 10;
  }

  int get percent => (ratio * 100).round();

  static int _streakLength(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.difference(days.last).inDays > 1) return 0;
    var count = 1;
    for (var i = days.length - 1; i > 0; i--) {
      if (days[i].difference(days[i - 1]).inDays != 1) break;
      count++;
    }
    return count;
  }
}

class LongGoalLog {
  const LongGoalLog({
    required this.goalId,
    required this.date,
    this.value,
  });

  final String goalId;
  final String date;
  final double? value;

  bool get isEmpty => value == null;

  LongGoalLog copyWith({
    double? value,
  }) {
    return LongGoalLog(
      goalId: goalId,
      date: date,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'date': date,
      'value': value,
    };
  }

  factory LongGoalLog.fromJson(Map<String, dynamic> json) {
    final mapped = json['values'] as Map<String, dynamic>?;
    double? value = (json['value'] as num?)?.toDouble();
    if (value == null && mapped != null && mapped.isNotEmpty) {
      value = (mapped.values.first as num?)?.toDouble();
    }
    return LongGoalLog(
      goalId: json['goalId'] as String,
      date: json['date'] as String,
      value: value,
    );
  }
}
