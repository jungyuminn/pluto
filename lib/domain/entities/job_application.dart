import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/domain/entities/apply_status.dart';

class JobApplication {
  JobApplication({
    required this.id,
    required this.companyName,
    this.applyStatus = '',
    this.position = '',
    this.appliedDate,
    this.deadline,
    List<ApplicationRound>? rounds,
    this.status = '',
    this.coverLetterPath,
    this.coverLetterFileName,
    this.sortOrder = 0,
    this.categoryId,
    this.categoryName = '',
    this.categoryColor,
  }) : rounds = normalizeRounds(rounds);

  static const minRoundCount = 1;
  static const defaultRoundCount = 4;
  static const maxRoundCount = 12;
  static const firstRowRoundCount = 5;

  final String id;
  final String companyName;
  final String applyStatus;
  final String position;
  final DateTime? appliedDate;
  final DateTime? deadline;
  final List<ApplicationRound> rounds;
  final String status;
  final String? coverLetterPath;
  final String? coverLetterFileName;
  final int sortOrder;
  final String? categoryId;
  final String categoryName;
  final int? categoryColor;

  bool get hasCategory =>
      (categoryId?.isNotEmpty ?? false) && categoryName.trim().isNotEmpty;

  bool get isRejected => ApplyStatus.isRejected(applyStatus);

  static List<ApplicationRound> normalizeRounds(List<ApplicationRound>? rounds) {
    if (rounds == null || rounds.isEmpty) {
      return List.unmodifiable(
        List<ApplicationRound>.filled(defaultRoundCount, const ApplicationRound()),
      );
    }
    final next = [...rounds];
    while (next.length < minRoundCount) {
      next.add(const ApplicationRound());
    }
    if (next.length > maxRoundCount) {
      return List.unmodifiable(next.take(maxRoundCount));
    }
    return List.unmodifiable(next);
  }

  /// 오늘부터 5일 안에 있는 가장 가까운 전형까지 남은 일수. 없으면 null.
  int? upcomingDDay([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    int? nearest;
    for (final round in rounds) {
      final date = round.date;
      if (date == null) continue;
      final target = DateTime(date.year, date.month, date.day);
      final days = target.difference(today).inDays;
      if (days < 0 || days > 5) continue;
      if (nearest == null || days < nearest) nearest = days;
    }
    return nearest;
  }

  /// 오늘 포함, 아직 지나지 않은 전형 중 가장 가까운 날짜.
  DateTime? nearestUpcomingRoundDate([DateTime? now]) {
    DateTime? nearest;
    for (final round in rounds) {
      final date = round.date;
      if (date == null || round.isPast(now)) continue;
      final target = DateTime(date.year, date.month, date.day);
      if (nearest == null || target.isBefore(nearest)) nearest = target;
    }
    return nearest;
  }

  /// 오늘 이후(오늘 포함)에서 가장 가까운 날짜까지 남은 일수.
  int? nearestRoundDays([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final nearest = nearestUpcomingRoundDate(now);
    if (nearest == null) return null;
    return nearest.difference(today).inDays;
  }

  static int compareDateOrder(JobApplication a, JobApplication b) {
    final aDate = a.nearestUpcomingRoundDate();
    final bDate = b.nearestUpcomingRoundDate();
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  static int _compareRejected(JobApplication a, JobApplication b) {
    if (a.isRejected != b.isRejected) return a.isRejected ? 1 : -1;
    return 0;
  }

  /// 탈락은 맨 아래, 그다음 남은 전형 중 가까운 날짜 순.
  static int compareHomeOrder(JobApplication a, JobApplication b) {
    final rejected = _compareRejected(a, b);
    if (rejected != 0) return rejected;
    return compareDateOrder(a, b);
  }

  /// 저장된 사용자 순서. 탈락은 항상 맨 아래.
  static int compareListOrder(JobApplication a, JobApplication b) {
    final rejected = _compareRejected(a, b);
    if (rejected != 0) return rejected;
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    if (byOrder != 0) return byOrder;
    return compareDateOrder(a, b);
  }

  JobApplication copyWith({
    String? companyName,
    String? applyStatus,
    String? position,
    DateTime? appliedDate,
    DateTime? deadline,
    List<ApplicationRound>? rounds,
    String? status,
    String? coverLetterPath,
    String? coverLetterFileName,
    int? sortOrder,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    bool clearCategory = false,
  }) {
    return JobApplication(
      id: id,
      companyName: companyName ?? this.companyName,
      applyStatus: applyStatus ?? this.applyStatus,
      position: position ?? this.position,
      appliedDate: appliedDate ?? this.appliedDate,
      deadline: deadline ?? this.deadline,
      rounds: rounds ?? this.rounds,
      status: status ?? this.status,
      coverLetterPath: coverLetterPath ?? this.coverLetterPath,
      coverLetterFileName: coverLetterFileName ?? this.coverLetterFileName,
      sortOrder: sortOrder ?? this.sortOrder,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? '' : (categoryName ?? this.categoryName),
      categoryColor: clearCategory ? null : (categoryColor ?? this.categoryColor),
    );
  }
}
