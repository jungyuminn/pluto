import 'package:pluto/domain/entities/license.dart';

class LicenseModel {
  LicenseModel._();

  static License fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      number: json['number'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      acquiredAt: _date(json['acquiredAt']),
      expiresAt: _date(json['expiresAt']),
      memo: json['memo'] as String? ?? '',
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ?? '',
      categoryColor: (json['categoryColor'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> toJson(License license) {
    return {
      'id': license.id,
      'name': license.name,
      'issuer': license.issuer,
      'number': license.number,
      'grade': license.grade,
      'acquiredAt': license.acquiredAt?.toIso8601String(),
      'expiresAt': license.expiresAt?.toIso8601String(),
      'memo': license.memo,
      'filePath': license.filePath,
      'fileName': license.fileName,
      'sortOrder': license.sortOrder,
      'categoryId': license.categoryId,
      'categoryName': license.categoryName,
      'categoryColor': license.categoryColor,
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
