import 'package:job_planner/domain/entities/license.dart';
import 'package:job_planner/domain/repositories/license_repository.dart';

class ReorderLicenses {
  const ReorderLicenses(this._repository);

  final LicenseRepository _repository;

  Future<void> call(List<License> ordered) async {
    if (ordered.isEmpty) return;
    final orders = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    final current = await _repository.getAll();
    final rest = [
      for (final license in current)
        if (!orders.containsKey(license.id)) license,
    ];
    await _repository.replaceAll([
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(sortOrder: i),
      for (var i = 0; i < rest.length; i++)
        rest[i].copyWith(sortOrder: ordered.length + i),
    ]);
  }
}
