import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';

class PlanetStage {
  const PlanetStage({
    required this.level,
    required this.progress,
    required this.name,
    required this.need,
  });

  static const maxLevel = 10;
  static const maxNeed = 50;

  final int level;
  final double progress;
  final String name;
  final int need;

  static const all = [
    PlanetStage(level: 1, progress: 0.00, name: AppStrings.statsRank1, need: 0),
    PlanetStage(level: 2, progress: 0.11, name: AppStrings.statsRank2, need: 5),
    PlanetStage(level: 3, progress: 0.22, name: AppStrings.statsRank3, need: 10),
    PlanetStage(level: 4, progress: 0.33, name: AppStrings.statsRank4, need: 15),
    PlanetStage(level: 5, progress: 0.44, name: AppStrings.statsRank5, need: 20),
    PlanetStage(level: 6, progress: 0.56, name: AppStrings.statsRank6, need: 25),
    PlanetStage(level: 7, progress: 0.67, name: AppStrings.statsRank7, need: 30),
    PlanetStage(level: 8, progress: 0.78, name: AppStrings.statsRank8, need: 35),
    PlanetStage(level: 9, progress: 0.89, name: AppStrings.statsRank9, need: 40),
    PlanetStage(level: 10, progress: 1.00, name: AppStrings.statsRank10, need: 50),
  ];

  static int levelOf({required int done}) {
    if (done <= 0) return 1;
    var level = 1;
    for (final stage in all) {
      if (done >= stage.need) level = stage.level;
    }
    return level;
  }

  static int needOf(int level) {
    return all[(level - 1).clamp(0, maxLevel - 1)].need;
  }

  static int threshold(int level) => needOf(level);

  static String nameOf(int level, {required bool empty}) {
    if (empty) return AppStrings.statsRank1;
    return all[(level - 1).clamp(0, maxLevel - 1)].name;
  }
}

class CollectedPlanet {
  const CollectedPlanet({
    required this.month,
    required this.level,
    required this.name,
    required this.isMax,
  });

  final DateTime month;
  final int level;
  final String name;
  final bool isMax;

  PlanetStage get stage =>
      PlanetStage.all[(level - 1).clamp(0, PlanetStage.maxLevel - 1)];

  static List<CollectedPlanet> fromEvents(
    List<CalendarEvent> events, {
    required DateTime nowMonth,
  }) {
    final months = <DateTime, ({int done, int total})>{};
    for (final event in events) {
      if (event.isJob || event.someday) continue;
      final month = DateTime(event.day.year, event.day.month);
      if (month.isAfter(nowMonth)) continue;
      final prev = months[month];
      months[month] = (
        done: (prev?.done ?? 0) + (event.completed ? 1 : 0),
        total: (prev?.total ?? 0) + 1,
      );
    }
    final keys = months.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final collected = <CollectedPlanet>[];
    for (final month in keys) {
      final stat = months[month]!;
      if (stat.total <= 0) continue;
      final level = PlanetStage.levelOf(done: stat.done);
      collected.add(
        CollectedPlanet(
          month: month,
          level: level,
          name: PlanetStage.nameOf(level, empty: stat.done <= 0),
          isMax: stat.done >= PlanetStage.maxNeed,
        ),
      );
    }
    return collected;
  }
}
