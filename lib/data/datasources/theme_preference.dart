import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/data/datasources/custom_theme_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSkin {
  classic,
  blossom,
  clover,
  fluffyBear,
  fluffyRabbit,
  pinkHeart,
  summerBeach,
  snowyWinter,
  squishyBear,
  strawberryMilk,
  lovelyBear,
  rainyDay,
  concertDay,
  fluffyCloud,
  catVillage,
  hamsterBakery,
  otterBathhouse,
  rabbitFlowerMarket,
  bearPancakeCafe;

  static const patternSkins = [
    classic,
    blossom,
    clover,
    fluffyBear,
    fluffyRabbit,
    pinkHeart,
  ];

  static const sceneSkins = [
    summerBeach,
    snowyWinter,
    squishyBear,
    strawberryMilk,
    lovelyBear,
    rainyDay,
    concertDay,
    fluffyCloud,
    catVillage,
    hamsterBakery,
    otterBathhouse,
    rabbitFlowerMarket,
    bearPancakeCafe,
  ];

  static const selectable = [
    ...patternSkins,
    ...sceneSkins,
  ];

  static AppSkinGroup groupOf(AppSkin skin, {bool custom = false}) {
    if (custom) return AppSkinGroup.mine;
    if (patternSkins.contains(skin)) return AppSkinGroup.pattern;
    return AppSkinGroup.scene;
  }

  static AppSkin fromId(
    String? id, {
    AppSkin fallback = AppSkin.classic,
  }) {
    for (final value in AppSkin.values) {
      if (value.name != id) continue;
      return value;
    }
    return fallback;
  }
}

enum AppSkinGroup {
  pattern,
  scene,
  mine;

  List<AppSkin> get skins => switch (this) {
        pattern => AppSkin.patternSkins,
        scene => AppSkin.sceneSkins,
        mine => const [],
      };
}

enum UserThemeKind { photo, pattern }

@immutable
class UserTheme {
  const UserTheme({
    required this.id,
    required this.name,
    required this.kind,
    required this.accent,
    this.photoPath = '',
    this.decorationPath = '',
    this.bottomPath = '',
    this.photoWash = defaultPhotoWash,
  });

  static const defaultPhotoWash = 0.28;

  final String id;
  final String name;
  final UserThemeKind kind;
  final int accent;
  final String photoPath;
  final String decorationPath;
  final String bottomPath;
  final double photoWash;

  Color get accentColor => Color(accent);

  Color fillColorFor(bool dark) {
    final tint = accentColor;
    if (!dark) {
      return Color.lerp(const Color(0xFFFFFFFF), tint, 0.14)!;
    }
    return Color.lerp(const Color(0xFF10141C), tint, 0.26)!;
  }

  UserTheme copyWith({
    String? name,
    UserThemeKind? kind,
    int? accent,
    String? photoPath,
    String? decorationPath,
    String? bottomPath,
    double? photoWash,
  }) {
    return UserTheme(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      accent: accent ?? this.accent,
      photoPath: photoPath ?? this.photoPath,
      decorationPath: decorationPath ?? this.decorationPath,
      bottomPath: bottomPath ?? this.bottomPath,
      photoWash: photoWash ?? this.photoWash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'accent': accent,
      'photoPath': photoPath,
      'decorationPath': decorationPath,
      'bottomPath': bottomPath,
      'photoWash': photoWash,
    };
  }

  static UserTheme? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (id == null || name == null) return null;
    final photoPath = json['photoPath'] as String? ?? '';
    final decorationPath = json['decorationPath'] as String? ?? '';
    final bottomPath = json['bottomPath'] as String? ?? '';
    final imagePath = json['imagePath'] as String? ?? '';
    final kind = switch (json['kind'] as String?) {
      'photo' => UserThemeKind.photo,
      'pattern' => UserThemeKind.pattern,
      _ when bottomPath.isNotEmpty || decorationPath.isNotEmpty =>
        UserThemeKind.pattern,
      _ => UserThemeKind.photo,
    };
    return UserTheme(
      id: id,
      name: name,
      kind: kind,
      accent: _colorOf(json['accent'], 0xFF3B82F6),
      photoPath: photoPath.isNotEmpty
          ? photoPath
          : kind == UserThemeKind.photo
              ? imagePath
              : '',
      decorationPath: decorationPath.isNotEmpty
          ? decorationPath
          : kind == UserThemeKind.pattern
              ? imagePath
              : '',
      bottomPath: bottomPath,
      photoWash: _washOf(json['photoWash']),
    );
  }

  static double _washOf(Object? value) {
    final raw = value is num ? value.toDouble() : defaultPhotoWash;
    return raw.clamp(0.0, 1.0);
  }

  static int _colorOf(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}

class ThemePreference extends ChangeNotifier {
  ThemePreference({
    SharedPreferences? prefs,
    bool dark = false,
    AppSkin skin = AppSkin.classic,
  })  : _prefs = prefs,
        _dark = prefs?.getBool(_darkKey) ?? dark,
        _skin = AppSkin.fromId(
          prefs?.getString(_skinKey),
          fallback: skin,
        ),
        _customThemes = _decodeThemes(prefs?.getString(customThemesKey)),
        _customId = prefs?.getString(_customIdKey) {
    if (customTheme == null) _customId = null;
  }

  static const starterIdPrefix = 'starter_theme_';
  static const starterNames = [
    AppStrings.starterThemeReorder,
    AppStrings.starterThemeSwipe,
  ];
  static const starterAccents = [defaultAccent, 0xFFF48FB1];

  static bool isUnmodifiedStarter(Map<String, dynamic> item) {
    final id = item['id'] as String? ?? '';
    if (!id.startsWith(starterIdPrefix)) return false;
    final index = int.tryParse(id.substring(starterIdPrefix.length));
    if (index == null || index < 0 || index >= starterNames.length) {
      return false;
    }
    if ((item['name'] as String? ?? '') != starterNames[index]) return false;
    if ((item['kind'] as String? ?? 'pattern') != 'pattern') return false;
    if ((item['accent'] as num?)?.toInt() != starterAccents[index]) return false;
    if ((item['photoPath'] as String? ?? '').isNotEmpty) return false;
    if ((item['decorationPath'] as String? ?? '').isNotEmpty) return false;
    if ((item['bottomPath'] as String? ?? '').isNotEmpty) return false;
    return true;
  }

  Future<void> seedStartersIfNeeded() async {
    final prefs = _prefs;
    if (prefs == null || prefs.containsKey(customThemesKey)) return;
    _customThemes = _starterThemes();
    notifyListeners();
    await _persistThemes();
  }

  Future<void> resetToStarters() async {
    _customThemes = _starterThemes();
    _customId = null;
    await _prefs?.remove(_customIdKey);
    notifyListeners();
    await _persistThemes();
  }

  static List<UserTheme> _starterThemes() {
    return [
      for (var i = 0; i < starterNames.length; i++)
        UserTheme(
          id: '$starterIdPrefix$i',
          name: starterNames[i],
          kind: UserThemeKind.pattern,
          accent: starterAccents[i],
        ),
    ];
  }

  static const _darkKey = 'app_dark_mode';
  static const _skinKey = 'app_skin';
  static const _customIdKey = 'app_custom_theme_id';
  static const customThemesKey = 'app_custom_themes';
  static const defaultAccent = 0xFF3B82F6;

  final SharedPreferences? _prefs;
  final _storage = const CustomThemeStorage();
  bool _dark;
  AppSkin _skin;
  List<UserTheme> _customThemes;
  String? _customId;

  bool get isDark => _dark;

  AppSkin get skin => _skin;

  List<UserTheme> get customThemes => List.unmodifiable(_customThemes);

  bool get usesCustom => customTheme != null;

  UserTheme? get customTheme {
    final id = _customId;
    if (id == null) return null;
    for (final theme in _customThemes) {
      if (theme.id == id) return theme;
    }
    return null;
  }

  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDark(bool value) async {
    if (_dark == value) return;
    _dark = value;
    notifyListeners();
    await _prefs?.setBool(_darkKey, value);
  }

  Future<void> setSkin(AppSkin value) async {
    if (_skin == value && _customId == null) return;
    _skin = value;
    _customId = null;
    notifyListeners();
    await _prefs?.setString(_skinKey, value.name);
    await _prefs?.remove(_customIdKey);
  }

  Future<void> setCustomTheme(String id) async {
    if (customTheme?.id == id) return;
    var found = false;
    for (final theme in _customThemes) {
      if (theme.id != id) continue;
      found = true;
      break;
    }
    if (!found) return;
    _customId = id;
    notifyListeners();
    await _prefs?.setString(_customIdKey, id);
  }

  Future<UserTheme> saveCustomTheme({
    required String name,
    required UserThemeKind kind,
    required int accent,
    double photoWash = UserTheme.defaultPhotoWash,
    String? photoSource,
    String? photoName,
    String? decorationSource,
    String? decorationName,
    String? bottomSource,
    String? bottomName,
    UserTheme? editing,
  }) async {
    final id = editing?.id ?? '${DateTime.now().microsecondsSinceEpoch}';
    var photoPath = '';
    var decorationPath = '';
    var bottomPath = '';
    if (kind == UserThemeKind.photo) {
      photoPath = await _saveSlot(
        id: id,
        slot: 'photo',
        sourcePath: photoSource,
        fileName: photoName,
      );
    } else {
      decorationPath = await _saveSlot(
        id: id,
        slot: 'deco',
        sourcePath: decorationSource,
        fileName: decorationName,
      );
      bottomPath = await _saveSlot(
        id: id,
        slot: 'bottom',
        sourcePath: bottomSource,
        fileName: bottomName,
      );
    }
    if (editing != null) {
      await _deleteUnused(editing, photoPath, decorationPath, bottomPath);
    }
    final saved = UserTheme(
      id: id,
      name: name,
      kind: kind,
      accent: accent,
      photoPath: photoPath,
      decorationPath: decorationPath,
      bottomPath: bottomPath,
      photoWash: photoWash.clamp(0.0, 1.0),
    );
    final next = [..._customThemes];
    final index = next.indexWhere((theme) => theme.id == id);
    if (index >= 0) {
      next[index] = saved;
    } else {
      next.add(saved);
    }
    _customThemes = next;
    _customId = id;
    notifyListeners();
    await _persistThemes();
    await _prefs?.setString(_customIdKey, id);
    return saved;
  }

  Future<void> reorderCustomThemes(List<UserTheme> next) async {
    if (next.length != _customThemes.length) return;
    final same = next.length == _customThemes.length &&
        [
          for (var i = 0; i < next.length; i++)
            next[i].id == _customThemes[i].id,
        ].every((value) => value);
    if (same) return;
    _customThemes = List.of(next);
    notifyListeners();
    await _persistThemes();
  }

  Future<String> _saveSlot({
    required String id,
    required String slot,
    String? sourcePath,
    String? fileName,
  }) async {
    if (sourcePath == null || sourcePath.isEmpty) return '';
    return _storage.save(
      id: id,
      slot: slot,
      sourcePath: sourcePath,
      fileName: fileName ?? sourcePath,
    );
  }

  Future<void> _deleteUnused(
    UserTheme editing,
    String photoPath,
    String decorationPath,
    String bottomPath,
  ) async {
    for (final path in [
      editing.photoPath,
      editing.decorationPath,
      editing.bottomPath,
    ]) {
      if (path.isEmpty) continue;
      if (path == photoPath || path == decorationPath || path == bottomPath) {
        continue;
      }
      await _storage.delete(path);
    }
  }

  Future<void> deleteCustomTheme(String id) async {
    UserTheme? removed;
    final next = <UserTheme>[];
    for (final theme in _customThemes) {
      if (theme.id == id) {
        removed = theme;
        continue;
      }
      next.add(theme);
    }
    if (removed == null) return;
    _customThemes = next;
    if (_customId == id) {
      _customId = null;
      await _prefs?.remove(_customIdKey);
    }
    notifyListeners();
    await _persistThemes();
    await _storage.delete(removed.photoPath);
    await _storage.delete(removed.decorationPath);
    await _storage.delete(removed.bottomPath);
  }

  void hydrate() {
    final prefs = _prefs;
    if (prefs == null) return;
    _dark = prefs.getBool(_darkKey) ?? _dark;
    _skin = AppSkin.fromId(prefs.getString(_skinKey), fallback: _skin);
    _customThemes = _decodeThemes(prefs.getString(customThemesKey));
    _customId = prefs.getString(_customIdKey);
    if (customTheme == null) _customId = null;
    notifyListeners();
  }

  Future<void> _persistThemes() async {
    await _prefs?.setString(
      customThemesKey,
      jsonEncode([
        for (final theme in _customThemes) theme.toJson(),
      ]),
    );
  }

  static List<UserTheme> _decodeThemes(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final items = jsonDecode(raw);
      if (items is! List) return const [];
      return [
        for (final item in items)
          if (item is Map<String, dynamic>)
            ?UserTheme.fromJson(item)
          else if (item is Map)
            ?UserTheme.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }
}
