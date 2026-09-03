import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/repositories/job_application_repository.dart';

class UpdateJobApplication {
  const UpdateJobApplication(this._repository);

  final JobApplicationRepository _repository;

  Future<void> call(JobApplication application) async {
    if (application.sortOrder != 0) {
      await _repository.update(application);
      return;
    }
    final current = await _repository.getAll();
    JobApplication? existing;
    for (final item in current) {
      if (item.id != application.id) continue;
      existing = item;
      break;
    }
    if (existing == null || existing.sortOrder == 0) {
      await _repository.update(application);
      return;
    }
    await _repository.update(
      application.copyWith(sortOrder: existing.sortOrder),
    );
  }
}
