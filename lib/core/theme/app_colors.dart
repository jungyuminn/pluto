import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.groupedBackground,
    required this.card,
    required this.text,
    required this.muted,
    required this.secondary,
    required this.border,
    required this.pressed,
    required this.selected,
    required this.accent,
    required this.accentBright,
    required this.danger,
    required this.shadow,
    required this.navBar,
    required this.icon,
    required this.rangeFill,
    required this.rangePressed,
    required this.outside,
    required this.hint,
  });

  final Color background;
  final Color groupedBackground;
  final Color card;
  final Color text;
  final Color muted;
  final Color secondary;
  final Color border;
  final Color pressed;
  final Color selected;
  final Color accent;
  final Color accentBright;
  final Color danger;
  final Color shadow;
  final Color navBar;
  final Color icon;
  final Color rangeFill;
  final Color rangePressed;
  final Color outside;
  final Color hint;

  static const light = AppColors(
    background: Color(0xFFF8FAFC),
    groupedBackground: Color(0xFFF4F5F7),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF0F172A),
    muted: Color(0xFF94A3B8),
    secondary: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    pressed: Color(0xFFF1F5F9),
    selected: Color(0xFFF1F5F9),
    accent: Color(0xFF3B82F6),
    accentBright: Color(0xFF40A6FF),
    danger: Color(0xFFEF4444),
    shadow: Color(0x14000000),
    navBar: Color(0xFFFFFFFF),
    icon: Color(0xFF0F172A),
    rangeFill: Color(0xFFDBEAFE),
    rangePressed: Color(0xFFBFDBFE),
    outside: Color(0xFFD1D5DB),
    hint: Color(0xFF666666),
  );

  static const dark = AppColors(
    background: Color(0xFF0B1220),
    groupedBackground: Color(0xFF080C14),
    card: Color(0xFF162032),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    secondary: Color(0xFF94A3B8),
    border: Color(0xFF2A3A52),
    pressed: Color(0xFF1E2D44),
    selected: Color(0xFF1E2D44),
    accent: Color(0xFF60A5FA),
    accentBright: Color(0xFF60A5FA),
    danger: Color(0xFFF87171),
    shadow: Color(0x66000000),
    navBar: Color(0xFF162032),
    icon: Color(0xFFF1F5F9),
    rangeFill: Color(0xFF1E3A5F),
    rangePressed: Color(0xFF254A75),
    outside: Color(0xFF475569),
    hint: Color(0xFF94A3B8),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.light;
  }

  bool get isDark => background.computeLuminance() < 0.5;

  Color tint(Color accent, [double amount = 0.28]) {
    return Color.lerp(card, accent, amount)!;
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? groupedBackground,
    Color? card,
    Color? text,
    Color? muted,
    Color? secondary,
    Color? border,
    Color? pressed,
    Color? selected,
    Color? accent,
    Color? accentBright,
    Color? danger,
    Color? shadow,
    Color? navBar,
    Color? icon,
    Color? rangeFill,
    Color? rangePressed,
    Color? outside,
    Color? hint,
  }) {
    return AppColors(
      background: background ?? this.background,
      groupedBackground: groupedBackground ?? this.groupedBackground,
      card: card ?? this.card,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      secondary: secondary ?? this.secondary,
      border: border ?? this.border,
      pressed: pressed ?? this.pressed,
      selected: selected ?? this.selected,
      accent: accent ?? this.accent,
      accentBright: accentBright ?? this.accentBright,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      navBar: navBar ?? this.navBar,
      icon: icon ?? this.icon,
      rangeFill: rangeFill ?? this.rangeFill,
      rangePressed: rangePressed ?? this.rangePressed,
      outside: outside ?? this.outside,
      hint: hint ?? this.hint,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      groupedBackground:
          Color.lerp(groupedBackground, other.groupedBackground, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      rangeFill: Color.lerp(rangeFill, other.rangeFill, t)!,
      rangePressed: Color.lerp(rangePressed, other.rangePressed, t)!,
      outside: Color.lerp(outside, other.outside, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
    );
  }
}
