import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 화면에 글자 크기 항목을 다시 보이게 하려면 true로 바꾸세요.
const showFontSizeSettings = false;

enum AppTypeface {
  pretendard,
  paperlogy,
  system,
  gothic,
  serif,
  ownglyph,
  meetme,
  leeSeoyoon,
  bandal,
  mona,
  omyu,
  bazzi,
  mabinogi,
  babyShark,
  cookieRun,
  suit,
  theJamsil;

  static AppTypeface fromId(
    String? id, {
    AppTypeface fallback = AppTypeface.pretendard,
  }) {
    for (final value in AppTypeface.values) {
      if (value.name == id) return value;
    }
    return fallback;
  }

  String? get fontFamily {
    switch (this) {
      case AppTypeface.pretendard:
        return 'Pretendard';
      case AppTypeface.paperlogy:
        return 'Paperlogy';
      case AppTypeface.system:
        return null;
      case AppTypeface.gothic:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? 'Apple SD Gothic Neo'
            : 'sans-serif';
      case AppTypeface.serif:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? 'AppleMyungjo'
            : 'serif';
      case AppTypeface.ownglyph:
        return 'Ownglyph';
      case AppTypeface.meetme:
        return 'Meetme';
      case AppTypeface.leeSeoyoon:
        return 'LeeSeoyoon';
      case AppTypeface.bandal:
        return 'Bandal';
      case AppTypeface.mona:
        return 'MonaS';
      case AppTypeface.omyu:
        return 'Omyu';
      case AppTypeface.bazzi:
        return 'Bazzi';
      case AppTypeface.mabinogi:
        return 'Mabinogi';
      case AppTypeface.babyShark:
        return 'BabyShark';
      case AppTypeface.cookieRun:
        return 'CookieRun';
      case AppTypeface.suit:
        return 'SUIT';
      case AppTypeface.theJamsil:
        return 'TheJamsil';
    }
  }

  bool get isSelectable =>
      this == AppTypeface.pretendard ||
      this == AppTypeface.paperlogy ||
      this == AppTypeface.suit ||
      this == AppTypeface.theJamsil ||
      this == AppTypeface.ownglyph ||
      this == AppTypeface.meetme ||
      this == AppTypeface.leeSeoyoon ||
      this == AppTypeface.bandal ||
      this == AppTypeface.mona ||
      this == AppTypeface.omyu ||
      this == AppTypeface.bazzi ||
      this == AppTypeface.mabinogi ||
      this == AppTypeface.babyShark ||
      this == AppTypeface.cookieRun;

  String? get widgetRegularAsset => switch (this) {
        AppTypeface.pretendard => 'assets/fonts/Pretendard-Regular.otf',
        AppTypeface.paperlogy => 'assets/fonts/Paperlogy-4Regular.ttf',
        AppTypeface.suit => 'assets/fonts/SUIT-Regular.otf',
        AppTypeface.theJamsil => 'assets/fonts/The Jamsil OTF 3 Regular.otf',
        AppTypeface.ownglyph => 'assets/fonts/park_dahyun.ttf',
        AppTypeface.meetme => 'assets/fonts/meetme.ttf',
        AppTypeface.leeSeoyoon => 'assets/fonts/lee_seoyoon.ttf',
        AppTypeface.bandal => 'assets/fonts/bandal.otf',
        AppTypeface.mona => 'assets/fonts/MonaS12.otf',
        AppTypeface.omyu => 'assets/fonts/omyu.ttf',
        AppTypeface.bazzi => 'assets/fonts/Bazzi.ttf',
        AppTypeface.mabinogi => 'assets/fonts/Mabinogi_Classic_TTF.ttf',
        AppTypeface.babyShark =>
          'assets/fonts/Pinkfong Baby Shark Font_ Regular.ttf',
        AppTypeface.cookieRun => 'assets/fonts/CookieRun Regular.otf',
        AppTypeface.system ||
        AppTypeface.gothic ||
        AppTypeface.serif => null,
      };

  String? get widgetBoldAsset => switch (this) {
        AppTypeface.pretendard => 'assets/fonts/Pretendard-ExtraBold.otf',
        AppTypeface.paperlogy => 'assets/fonts/Paperlogy-8ExtraBold.ttf',
        AppTypeface.suit => 'assets/fonts/SUIT-ExtraBold.otf',
        AppTypeface.theJamsil => 'assets/fonts/The Jamsil OTF 6 ExtraBold.otf',
        AppTypeface.mona => 'assets/fonts/MonaS12-Bold.otf',
        AppTypeface.babyShark =>
          'assets/fonts/Pinkfong Baby Shark Font_ Bold.ttf',
        AppTypeface.cookieRun => 'assets/fonts/CookieRun Black.otf',
        _ => widgetRegularAsset,
      };

  static const selectable = [
    AppTypeface.pretendard,
    AppTypeface.theJamsil,
    AppTypeface.suit,
    AppTypeface.paperlogy,
    AppTypeface.mona,
    AppTypeface.meetme,
    AppTypeface.ownglyph,
    AppTypeface.bandal,
    AppTypeface.omyu,
    AppTypeface.leeSeoyoon,
    AppTypeface.mabinogi,
    AppTypeface.bazzi,
    AppTypeface.babyShark,
    AppTypeface.cookieRun,
  ];
}

enum FontSizeLevel {
  small,
  medium,
  large,
  extraLarge;

  static FontSizeLevel fromId(
    String? id, {
    FontSizeLevel fallback = FontSizeLevel.medium,
  }) {
    for (final value in FontSizeLevel.values) {
      if (value.name == id) return value;
    }
    return fallback;
  }

  double get scale => switch (this) {
        FontSizeLevel.small => 0.88,
        FontSizeLevel.medium => 1,
        FontSizeLevel.large => 1.14,
        FontSizeLevel.extraLarge => 1.28,
      };
}

class FontPreference extends ChangeNotifier {
  FontPreference({
    SharedPreferences? prefs,
    AppTypeface typeface = AppTypeface.pretendard,
    FontSizeLevel todoSize = FontSizeLevel.medium,
    FontSizeLevel calendarSize = FontSizeLevel.medium,
    FontSizeLevel calendarLabelSize = FontSizeLevel.medium,
  })  : _prefs = prefs,
        _typeface = AppTypeface.fromId(
          prefs?.getString(_familyKey),
          fallback: typeface,
        ),
        _todoSize = FontSizeLevel.fromId(
          prefs?.getString(_todoKey),
          fallback: todoSize,
        ),
        _calendarSize = FontSizeLevel.fromId(
          prefs?.getString(_calendarKey),
          fallback: calendarSize,
        ),
        _calendarLabelSize = FontSizeLevel.fromId(
          prefs?.getString(_calendarLabelKey),
          fallback: calendarLabelSize,
        ) {
    if (!_typeface.isSelectable) {
      _typeface = AppTypeface.pretendard;
      _prefs?.setString(_familyKey, _typeface.name);
    }
    _labelScale = clampScale(
      prefs?.getDouble(_labelScaleKey) ?? _todoSize.scale,
    );
    _calendarChipScale = clampScale(
      prefs?.getDouble(_calendarChipKey) ?? _calendarLabelSize.scale,
    );
    _calendarDateScale = clampScale(
      prefs?.getDouble(_calendarDateKey) ?? _calendarSize.scale,
    );
  }

  static const scaleSteps = [
    0.76,
    0.84,
    0.92,
    1.00,
    1.08,
    1.16,
    1.24,
  ];
  static const minScale = 0.76;
  static const maxScale = 1.24;

  static const _familyKey = 'font_family';
  static const syncedKeys = [_familyKey];
  static const defaultFamily = 'pretendard';
  static const _todoKey = 'font_todo_size';
  static const _calendarKey = 'font_calendar_size';
  static const _calendarLabelKey = 'font_calendar_label_size';
  static const _labelScaleKey = 'font_label_scale';
  static const _calendarChipKey = 'font_calendar_chip_scale';
  static const _calendarDateKey = 'font_calendar_date_scale';

  final SharedPreferences? _prefs;
  final ChangeNotifier _appearance = ChangeNotifier();
  AppTypeface _typeface;
  FontSizeLevel _todoSize;
  FontSizeLevel _calendarSize;
  FontSizeLevel _calendarLabelSize;
  late double _labelScale;
  late double _calendarChipScale;
  late double _calendarDateScale;

  Listenable get appearanceListenable => _appearance;

  AppTypeface get typeface => _typeface;
  FontSizeLevel get todoSize => _todoSize;
  FontSizeLevel get calendarSize => _calendarSize;
  FontSizeLevel get calendarLabelSize => _calendarLabelSize;
  double get labelScale => _labelScale;
  double get calendarChipScale => _calendarChipScale;
  double get calendarDateScale => _calendarDateScale;

  double get todoScale => _todoSize.scale;
  double get calendarScale => _calendarSize.scale;
  double get calendarLabelScale => _calendarChipScale;

  static double clampScale(double value) {
    var best = scaleSteps.first;
    var bestDist = (value - best).abs();
    for (final step in scaleSteps) {
      final dist = (value - step).abs();
      if (dist < bestDist) {
        best = step;
        bestDist = dist;
      }
    }
    return best;
  }

  static int stepIndexOf(double value) {
    return scaleSteps.indexOf(clampScale(value));
  }

  Future<void> setTypeface(AppTypeface value) async {
    if (_typeface == value) return;
    _typeface = value;
    _appearance.notifyListeners();
    notifyListeners();
    await _prefs?.setString(_familyKey, value.name);
  }

  Future<void> setTodoSize(FontSizeLevel value) async {
    if (_todoSize == value) return;
    _todoSize = value;
    notifyListeners();
    await _prefs?.setString(_todoKey, value.name);
  }

  Future<void> setCalendarSize(FontSizeLevel value) async {
    if (_calendarSize == value) return;
    _calendarSize = value;
    notifyListeners();
    await _prefs?.setString(_calendarKey, value.name);
  }

  Future<void> setCalendarLabelSize(FontSizeLevel value) async {
    if (_calendarLabelSize == value) return;
    _calendarLabelSize = value;
    notifyListeners();
    await _prefs?.setString(_calendarLabelKey, value.name);
  }

  Future<void> setLabelScale(double value, {bool persist = false}) async {
    final next = clampScale(value);
    if ((_labelScale - next).abs() < 0.0001) {
      if (persist) await _prefs?.setDouble(_labelScaleKey, next);
      return;
    }
    _labelScale = next;
    notifyListeners();
    if (persist) await _prefs?.setDouble(_labelScaleKey, next);
  }

  Future<void> setCalendarChipScale(double value, {bool persist = false}) async {
    final next = clampScale(value);
    if ((_calendarChipScale - next).abs() < 0.0001) {
      if (persist) await _prefs?.setDouble(_calendarChipKey, next);
      return;
    }
    _calendarChipScale = next;
    notifyListeners();
    if (persist) await _prefs?.setDouble(_calendarChipKey, next);
  }

  Future<void> setCalendarDateScale(double value, {bool persist = false}) async {
    final next = clampScale(value);
    if ((_calendarDateScale - next).abs() < 0.0001) {
      if (persist) await _prefs?.setDouble(_calendarDateKey, next);
      return;
    }
    _calendarDateScale = next;
    notifyListeners();
    if (persist) await _prefs?.setDouble(_calendarDateKey, next);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _typeface = AppTypeface.fromId(
      prefs.getString(_familyKey),
      fallback: _typeface,
    );
    if (!_typeface.isSelectable) {
      _typeface = AppTypeface.pretendard;
    }
    _todoSize = FontSizeLevel.fromId(
      prefs.getString(_todoKey),
      fallback: _todoSize,
    );
    _calendarSize = FontSizeLevel.fromId(
      prefs.getString(_calendarKey),
      fallback: _calendarSize,
    );
    _calendarLabelSize = FontSizeLevel.fromId(
      prefs.getString(_calendarLabelKey),
      fallback: _calendarLabelSize,
    );
    _labelScale = clampScale(
      prefs.getDouble(_labelScaleKey) ?? _todoSize.scale,
    );
    _calendarChipScale = clampScale(
      prefs.getDouble(_calendarChipKey) ?? _calendarLabelSize.scale,
    );
    _calendarDateScale = clampScale(
      prefs.getDouble(_calendarDateKey) ?? _calendarSize.scale,
    );
    notifyListeners();
    _appearance.notifyListeners();
  }
}
