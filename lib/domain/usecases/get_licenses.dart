import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/domain/repositories/license_repository.dart';

class GetLicenses {
  const GetLicenses(this._repository);

  final LicenseRepository _repository;

  Future<List<License>> call() async {
    final items = List<License>.from(await _repository.getAll());
    items.sort(License.compareListOrder);
    return items;
  }
}
