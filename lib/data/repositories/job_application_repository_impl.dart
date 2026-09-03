import 'package:pluto/data/datasources/cover_letter_storage.dart';
import 'package:pluto/data/datasources/job_application_local_datasource.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/repositories/job_application_repository.dart';

class JobApplicationRepositoryImpl implements JobApplicationRepository {
  const JobApplicationRepositoryImpl(
    this._localDataSource, {
    this.coverLetterStorage = const CoverLetterStorage(),
  });

  final JobApplicationLocalDataSource _localDataSource;
  final CoverLetterStorage coverLetterStorage;

  @override
  Future<List<JobApplication>> getAll() async {
    return _localDataSource.fetchAll();
  }

  @override
  Future<void> add(JobApplication application) async {
    final saved = await _withStoredCoverLetter(application);
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([...current, saved]);
  }

  @override
  Future<void> update(JobApplication application) async {
    final current = _localDataSource.fetchAll();
    final index = current.indexWhere((item) => item.id == application.id);
    final existingPath = index < 0 ? null : current[index].coverLetterPath;
    final saved = await _withStoredCoverLetter(
      application,
      existingPath: existingPath,
    );

    if (index < 0) {
      await _localDataSource.saveAll([...current, saved]);
      return;
    }

    final next = [...current];
    next[index] = saved;
    await _localDataSource.saveAll(next);
  }

  @override
  Future<void> delete(String id) async {
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll(
      current.where((item) => item.id != id).toList(),
    );
  }

  @override
  Future<void> replaceAll(List<JobApplication> applications) {
    return _localDataSource.saveAll(applications);
  }

  Future<JobApplication> _withStoredCoverLetter(
    JobApplication application, {
    String? existingPath,
  }) async {
    final sourcePath = application.coverLetterPath;
    final fileName = application.coverLetterFileName;
    if (sourcePath == null || fileName == null) return application;
    if (existingPath != null && sourcePath == existingPath) {
      return application;
    }

    final storedPath = await coverLetterStorage.save(
      id: application.id,
      sourcePath: sourcePath,
      fileName: fileName,
    );
    return application.copyWith(coverLetterPath: storedPath);
  }
}
