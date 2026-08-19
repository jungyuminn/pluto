import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/data/datasources/font_preference.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF1D4ED8);

  static ThemeData get light => themed(dark: false);

  static ThemeData get dark => themed(dark: true);

  static ThemeData themed({
    required bool dark,
    AppTypeface typeface = AppTypeface.pretendard,
  }) {
    return _theme(
      dark ? AppColors.dark : AppColors.light,
      dark ? Brightness.dark : Brightness.light,
      typeface.fontFamily,
    );
  }

  static ThemeData _theme(
    AppColors colors,
    Brightness brightness,
    String? fontFamily,
  ) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(
      surface: colors.card,
      onSurface: colors.text,
      primary: colors.accent,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.card,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: [colors],
    );
  }
}
