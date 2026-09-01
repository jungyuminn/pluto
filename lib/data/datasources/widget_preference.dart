import 'dart:async';

import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetPreference {
  WidgetPreference({
    SharedPreferences? prefs,
    bool followTheme = true,
    bool followFont = true,
    double fontScale = 1,
  })  : _prefs = prefs,
        _followTheme = prefs?.getBool(_themeKey) ?? followTheme,
        _followFont = prefs?.getBool(_fontKey) ?? followFont,
        _fontScale = FontPreference.clampScale(
          prefs?.getDouble(_scaleKey) ?? fontScale,
        );

  static const _themeKey = 'widget_follow_theme';
  static const _fontKey = 'widget_follow_font';
  static const _scaleKey = 'widget_font_scale';

  final SharedPreferences? _prefs;
  bool _followTheme;
  bool _followFont;
  double _fontScale;

  bool get followTheme => _followTheme;
  bool get followFont => _followFont;
  double get fontScale => _fontScale;

  Future<void> setFollowTheme(bool value) async {
    if (_followTheme == value) return;
    _followTheme = value;
    await _prefs?.setBool(_themeKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  Future<void> setFollowFont(bool value) async {
    if (_followFont == value) return;
    _followFont = value;
    await _prefs?.setBool(_fontKey, value);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  Future<void> setFontScale(double value) async {
    final next = FontPreference.clampScale(value);
    if ((next - _fontScale).abs() < 0.0001) return;
    _fontScale = next;
    await _prefs?.setDouble(_scaleKey, next);
    unawaited(HomeScreenWidgetService.instance.sync());
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _followTheme = prefs.getBool(_themeKey) ?? _followTheme;
    _followFont = prefs.getBool(_fontKey) ?? _followFont;
    _fontScale = FontPreference.clampScale(
      prefs.getDouble(_scaleKey) ?? _fontScale,
    );
  }
}
