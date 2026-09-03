import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/repositories/job_application_repository.dart';

class ReorderJobApplications {
  const ReorderJobApplications(this._repository);

  final JobApplicationRepository _repository;

  Future<void> call(List<JobApplication> ordered) async {
    if (ordered.isEmpty) return;
    final orders = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    final current = await _repository.getAll();
    final rest = [
      for (final application in current)
        if (!orders.containsKey(application.id)) application,
    ];
    await _repository.replaceAll([
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
      for (var i = 0; i < rest.length; i++)
        rest[i].copyWith(sortOrder: ordered.length + i),
    ]);
  }
}
