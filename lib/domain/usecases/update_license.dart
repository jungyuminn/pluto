import 'package:job_planner/domain/entities/license.dart';
import 'package:job_planner/domain/repositories/license_repository.dart';

class UpdateLicense {
  const UpdateLicense(this._repository);

  final LicenseRepository _repository;

  Future<void> call(License license) async {
    if (license.sortOrder != 0) {
      await _repository.update(license);
      return;
    }
    final current = await _repository.getAll();
    License? existing;
    for (final item in current) {
      if (item.id != license.id) continue;
      existing = item;
      break;
    }
    if (existing == null || existing.sortOrder == 0) {
      await _repository.update(license);
      return;
    }
    await _repository.update(license.copyWith(sortOrder: existing.sortOrder));
  }
}
