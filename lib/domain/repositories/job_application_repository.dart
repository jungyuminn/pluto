import 'package:job_planner/domain/entities/job_application.dart';

abstract class JobApplicationRepository {
  Future<List<JobApplication>> getAll();
  Future<void> add(JobApplication application);
  Future<void> update(JobApplication application);
  Future<void> delete(String id);
  Future<void> replaceAll(List<JobApplication> applications);
}
