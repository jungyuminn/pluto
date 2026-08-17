import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/apply_status.dart';

class ApplyStatusColors {
  ApplyStatusColors._();

  static const rejected = Color(0xFF94A3B8);

  static const _colors = {
    ApplyStatus.documentSubmitted: Color(0xFF3B82F6),
    ApplyStatus.documentPassed: Color(0xFFB8D63C),
    ApplyStatus.documentRejected: rejected,
    ApplyStatus.writtenPassed: Color(0xFF7CBC1C),
    ApplyStatus.writtenRejected: rejected,
    ApplyStatus.interviewPassed: Color(0xFF4A8A10),
    ApplyStatus.interviewRejected: rejected,
    ApplyStatus.finalPassed: Color(0xFF1F4D08),
  };

  static Color? of(String status) => _colors[status];

  static Color sheetOf(String status, {Color? base}) {
    final accent = of(status) ?? const Color(0xFF3B82F6);
    return Color.lerp(base ?? const Color(0xFFFFFFFF), accent, 0.28)!;
  }
}
