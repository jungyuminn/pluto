import 'package:pluto/data/datasources/cover_letter_storage.dart';
import 'package:pluto/data/datasources/license_local_datasource.dart';
import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/domain/repositories/license_repository.dart';

class LicenseRepositoryImpl implements LicenseRepository {
  const LicenseRepositoryImpl(
    this._localDataSource, {
    this.fileStorage = const CoverLetterStorage(
      folderName: CoverLetterStorage.licenseFilesFolder,
    ),
  });

  final LicenseLocalDataSource _localDataSource;
  final CoverLetterStorage fileStorage;

  @override
  Future<List<License>> getAll() async {
    return _localDataSource.fetchAll();
  }

  @override
  Future<void> add(License license) async {
    final saved = await _withStoredFile(license);
    final current = _localDataSource.fetchAll();
    await _localDataSource.saveAll([...current, saved]);
  }

  @override
  Future<void> update(License license) async {
    final current = _localDataSource.fetchAll();
    final index = current.indexWhere((item) => item.id == license.id);
    final existingPath = index < 0 ? null : current[index].filePath;
    final saved = await _withStoredFile(
      license,
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
  Future<void> replaceAll(List<License> licenses) {
    return _localDataSource.saveAll(licenses);
  }

  Future<License> _withStoredFile(
    License license, {
    String? existingPath,
  }) async {
    final sourcePath = license.filePath;
    final fileName = license.fileName;
    if (sourcePath == null || fileName == null) return license;
    if (existingPath != null && sourcePath == existingPath) {
      return license;
    }

    final storedPath = await fileStorage.save(
      id: license.id,
      sourcePath: sourcePath,
      fileName: fileName,
    );
    return license.copyWith(filePath: storedPath);
  }
}
