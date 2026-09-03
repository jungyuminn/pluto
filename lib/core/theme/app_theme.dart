import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/data/datasources/theme_preference.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF1D4ED8);

  static ThemeData get light => themed(dark: false);

  static ThemeData get dark => themed(dark: true);

  static ThemeData themed({
    required bool dark,
    AppTypeface typeface = AppTypeface.pretendard,
    AppSkin skin = AppSkin.classic,
    Color? customAccent,
  }) {
    final base = dark ? AppColors.dark : AppColors.light;
    final accent =
        customAccent ?? AppSkinAssets.accentColor(skin, dark, base.accent);
    final accentBright = customAccent == null
        ? AppSkinAssets.accentColor(skin, dark, base.accentBright)
        : Color.lerp(customAccent, Colors.white, dark ? 0.18 : 0.08)!;
    final colors = base.copyWith(
      accent: accent,
      accentBright: accentBright,
      icon: skin == AppSkin.classic && customAccent == null
          ? base.icon
          : accentBright,
      rangeFill: Color.lerp(base.card, accent, dark ? 0.32 : 0.22),
      rangePressed: Color.lerp(base.card, accent, dark ? 0.42 : 0.32),
    );
    return _theme(
      colors,
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
        iconTheme: IconThemeData(color: colors.icon),
      ),
      iconTheme: IconThemeData(color: colors.icon),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.accentBright,
        applyThemeToAll: true,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accentBright,
        selectionColor: colors.accentBright.withValues(alpha: 0.28),
        selectionHandleColor: colors.accentBright,
      ),
      extensions: [colors],
    );
  }
}
