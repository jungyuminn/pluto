import 'package:job_planner/domain/repositories/job_application_repository.dart';

class DeleteJobApplication {
  const DeleteJobApplication(this._repository);

  final JobApplicationRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
