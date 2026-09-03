import 'package:pluto/domain/repositories/license_repository.dart';

class DeleteLicense {
  const DeleteLicense(this._repository);

  final LicenseRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
