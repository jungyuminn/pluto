import 'package:job_planner/domain/entities/license.dart';

abstract class LicenseRepository {
  Future<List<License>> getAll();
  Future<void> add(License license);
  Future<void> update(License license);
  Future<void> delete(String id);
  Future<void> replaceAll(List<License> licenses);
}
