import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/repositories/job_application_repository.dart';

class GetJobApplications {
  const GetJobApplications(this._repository);

  final JobApplicationRepository _repository;

  Future<List<JobApplication>> call() async {
    final items = List<JobApplication>.from(await _repository.getAll());
    items.sort(JobApplication.compareListOrder);
    return items;
  }
}
