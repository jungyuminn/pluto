import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/domain/repositories/job_application_repository.dart';

class AddJobApplication {
  const AddJobApplication(this._repository);

  final JobApplicationRepository _repository;

  Future<void> call(JobApplication application) async {
    if (application.sortOrder != 0) {
      await _repository.add(application);
      return;
    }
    final current = await _repository.getAll();
    var maxOrder = 0;
    for (final item in current) {
      if (item.sortOrder > maxOrder) maxOrder = item.sortOrder;
    }
    await _repository.add(application.copyWith(sortOrder: maxOrder + 1));
  }
}
