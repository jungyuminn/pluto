import 'package:job_planner/domain/entities/license.dart';
import 'package:job_planner/domain/repositories/license_repository.dart';

class LicenseMemoryRepository implements LicenseRepository {
  LicenseMemoryRepository([List<License>? seed]) : _items = [...?seed];

  final List<License> _items;

  @override
  Future<List<License>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(License license) async {
    _items.add(license);
  }

  @override
  Future<void> update(License license) async {
    final index = _items.indexWhere((item) => item.id == license.id);
    if (index < 0) {
      _items.add(license);
      return;
    }
    _items[index] = license;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> replaceAll(List<License> licenses) async {
    _items
      ..clear()
      ..addAll(licenses);
  }
}
