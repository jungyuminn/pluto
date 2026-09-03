import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/domain/repositories/license_repository.dart';

class AddLicense {
  const AddLicense(this._repository);

  final LicenseRepository _repository;

  Future<void> call(License license) async {
    if (license.sortOrder != 0) {
      await _repository.add(license);
      return;
    }
    final current = await _repository.getAll();
    var maxOrder = 0;
    for (final item in current) {
      if (item.sortOrder > maxOrder) maxOrder = item.sortOrder;
    }
    await _repository.add(license.copyWith(sortOrder: maxOrder + 1));
  }
}
