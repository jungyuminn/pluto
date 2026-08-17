import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/domain/repositories/job_application_repository.dart';

class ReorderJobApplications {
  const ReorderJobApplications(this._repository);

  final JobApplicationRepository _repository;

  Future<void> call(List<JobApplication> ordered) async {
    final orders = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    if (orders.isEmpty) return;
    final current = await _repository.getAll();
    await _repository.replaceAll([
      for (final application in current)
        if (orders.containsKey(application.id))
          application.copyWith(sortOrder: orders[application.id])
        else
          application,
    ]);
  }
}
