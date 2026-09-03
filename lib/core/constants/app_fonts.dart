import 'package:flutter/widgets.dart';
import 'package:pluto/data/datasources/font_preference.dart';

class FontScope extends InheritedWidget {
  const FontScope({
    super.key,
    required this.typeface,
    required this.todoScale,
    required this.labelScale,
    required this.calendarScale,
    required this.calendarLabelScale,
    required super.child,
  });

  final AppTypeface typeface;
  final double todoScale;
  final double labelScale;
  final double calendarScale;
  final double calendarLabelScale;

  static FontScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FontScope>();
  }

  @override
  bool updateShouldNotify(FontScope oldWidget) {
    return typeface != oldWidget.typeface ||
        todoScale != oldWidget.todoScale ||
        labelScale != oldWidget.labelScale ||
        calendarScale != oldWidget.calendarScale ||
        calendarLabelScale != oldWidget.calendarLabelScale;
  }
}

class AppFonts {
  AppFonts._();

  static const pretendard = 'Pretendard';
  static const jalnan = 'Jalnan2';
  static const wordmarkSize = 24.0;
  static const wordmarkColor = Color(0xFF8F9095);
  static const wordmarkLeftInset = 12.0;

  static String? of(BuildContext context) {
    final scope = FontScope.maybeOf(context);
    if (scope == null) return pretendard;
    return scope.typeface.fontFamily;
  }

  static double todoScaleOf(BuildContext context) {
    return FontScope.maybeOf(context)?.todoScale ?? 1;
  }

  static double labelScaleOf(BuildContext context) {
    return FontScope.maybeOf(context)?.labelScale ?? 1;
  }

  static double calendarScaleOf(BuildContext context) {
    return FontScope.maybeOf(context)?.calendarScale ?? 1;
  }

  static double calendarLabelScaleOf(BuildContext context) {
    return FontScope.maybeOf(context)?.calendarLabelScale ?? 1;
  }
}
