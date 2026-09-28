import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/live_category.dart';
import 'package:pluto/domain/repositories/event_category_repository.dart';
import 'package:pluto/domain/repositories/job_application_repository.dart';

class GetJobApplications {
  const GetJobApplications(this._repository, [this._categories]);

  final JobApplicationRepository _repository;
  final EventCategoryRepository? _categories;

  Future<List<JobApplication>> call() async {
    final items = List<JobApplication>.from(await _repository.getAll());
    items.sort(JobApplication.compareListOrder);
    final categories = await _categories?.getAll();
    if (categories == null || categories.isEmpty) return items;
    return LiveCategory.jobs(items, categories);
  }
}
