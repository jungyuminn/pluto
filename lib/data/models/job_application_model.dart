import 'package:pluto/domain/entities/application_round.dart';
import 'package:pluto/domain/entities/job_application.dart';

class JobApplicationModel {
  JobApplicationModel._();

  static JobApplication fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as String,
      companyName: json['companyName'] as String? ?? '',
      applyStatus: json['applyStatus'] as String? ?? '',
      position: json['position'] as String? ?? '',
      appliedDate: _date(json['appliedDate']),
      deadline: _date(json['deadline']),
      rounds: _rounds(json),
      status: json['status'] as String? ?? '',
      coverLetterPath: json['coverLetterPath'] as String?,
      coverLetterFileName: json['coverLetterFileName'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ?? '',
      categoryColor: (json['categoryColor'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> toJson(JobApplication application) {
    final rounds = application.rounds;
    return {
      'id': application.id,
      'companyName': application.companyName,
      'applyStatus': application.applyStatus,
      'position': application.position,
      'appliedDate': application.appliedDate?.toIso8601String(),
      'deadline': application.deadline?.toIso8601String(),
      'rounds': [for (final round in rounds) _roundJson(round)],
      'round1': _roundJson(_at(rounds, 0)),
      'round2': _roundJson(_at(rounds, 1)),
      'round3': _roundJson(_at(rounds, 2)),
      'round4': _roundJson(_at(rounds, 3)),
      'status': application.status,
      'coverLetterPath': application.coverLetterPath,
      'coverLetterFileName': application.coverLetterFileName,
      'sortOrder': application.sortOrder,
      'categoryId': application.categoryId,
      'categoryName': application.categoryName,
      'categoryColor': application.categoryColor,
    };
  }

  static List<ApplicationRound> _rounds(Map<String, dynamic> json) {
    final list = json['rounds'];
    if (list is List && list.isNotEmpty) {
      return [for (final item in list) _round(item)];
    }
    return [
      _round(json['round1']),
      _round(json['round2']),
      _round(json['round3']),
      _round(json['round4']),
    ];
  }

  static ApplicationRound _at(List<ApplicationRound> rounds, int index) {
    if (index < 0 || index >= rounds.length) return const ApplicationRound();
    return rounds[index];
  }

  static ApplicationRound _round(dynamic value) {
    if (value is String) return ApplicationRound(name: value);
    if (value is Map) {
      return ApplicationRound(
        name: value['name'] as String? ?? '',
        date: _date(value['date']),
        note: value['note'] as String? ?? '',
      );
    }
    return const ApplicationRound();
  }

  static Map<String, dynamic> _roundJson(ApplicationRound round) {
    return {
      'name': round.name,
      'date': round.date?.toIso8601String(),
      'note': round.note,
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
