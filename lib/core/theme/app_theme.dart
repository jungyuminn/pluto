import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF1D4ED8);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: AppFonts.pretendard,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
