import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/domain/repositories/job_application_repository.dart';

class JobApplicationMemoryRepository implements JobApplicationRepository {
  JobApplicationMemoryRepository([List<JobApplication>? seed])
    : _items = [...?seed];

  final List<JobApplication> _items;

  @override
  Future<List<JobApplication>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(JobApplication application) async {
    _items.add(application);
  }

  @override
  Future<void> update(JobApplication application) async {
    final index = _items.indexWhere((item) => item.id == application.id);
    if (index < 0) {
      _items.add(application);
      return;
    }
    _items[index] = application;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> replaceAll(List<JobApplication> applications) async {
    _items
      ..clear()
      ..addAll(applications);
  }
}
