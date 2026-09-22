import 'dart:convert';

import 'package:pluto/data/datasources/calendar_event_local_datasource.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/datasources/diary_local_datasource.dart';
import 'package:pluto/data/datasources/event_category_local_datasource.dart';
import 'package:pluto/data/datasources/job_application_local_datasource.dart';
import 'package:pluto/data/datasources/ledger_local_datasource.dart';
import 'package:pluto/data/datasources/license_local_datasource.dart';
import 'package:pluto/data/datasources/long_goal_local_datasource.dart';
import 'package:pluto/data/datasources/calendar_preference.dart';
import 'package:pluto/data/datasources/category_suggest_preference.dart';
import 'package:pluto/data/datasources/day_events_view_preference.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/data/datasources/friend_category_preference.dart';
import 'package:pluto/data/datasources/friend_favorite_preference.dart';
import 'package:pluto/data/datasources/friend_home_preference.dart';
import 'package:pluto/data/datasources/friend_order_preference.dart';
import 'package:pluto/data/datasources/home_view_preference.dart';
import 'package:pluto/data/datasources/home_memo_local_datasource.dart';
import 'package:pluto/data/datasources/job_view_preference.dart';
import 'package:pluto/data/datasources/last_category_color_preference.dart';
import 'package:pluto/data/datasources/last_event_category_preference.dart';
import 'package:pluto/data/datasources/license_view_preference.dart';
import 'package:pluto/data/datasources/nav_preference.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/data/datasources/wordmark_preference.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudSyncSnapshot {
  CloudSyncSnapshot._();

  static const schema = 1;
  static const uidKey = 'cloud_sync_uid';
  static const providerKey = 'cloud_sync_provider';
  static const parkedDumpKey = 'cloud_parked_local_dump';

  static const eventsKey = CalendarEventLocalDataSource.key;
  static const jobsKey = JobApplicationLocalDataSource.key;
  static const licensesKey = LicenseLocalDataSource.key;
  static const diariesKey = DiaryLocalDataSource.key;
  static const ledgersKey = LedgerLocalDataSource.key;
  static const emojisKey = DayEmojiStore.key;
  static const stickerOrderKey = DayEmojiStore.packOrderKey;
  static const goalsKey = LongGoalLocalDataSource.goalsKey;
  static const goalLogsKey = LongGoalLocalDataSource.logsKey;
  static const memosKey = HomeMemoLocalDataSource.key;
  static const eventCategoriesKey = EventCategoryLocalDataSource.eventKey;
  static const companyCategoriesKey = EventCategoryLocalDataSource.companyKey;
  static const ledgerCategoriesKey = EventCategoryLocalDataSource.ledgerKey;
  static const licenseCategoriesKey = EventCategoryLocalDataSource.licenseKey;
  static const themesKey = ThemePreference.customThemesKey;
  static const customThemeIdKey = 'app_custom_theme_id';
  static const darkKey = 'app_dark_mode';
  static const skinKey = 'app_skin';
  static const mondayKey = 'calendar_start_monday';
  static const diaryCoverOrderKey = 'diary_cover_order';
  static const wordmarkHomeKey = WordmarkPreference.homeKey;
  static const wordmarkJobKey = WordmarkPreference.jobKey;
  static const wordmarkLicenseKey = WordmarkPreference.licenseKey;

  static const contentKeys = [
    eventsKey,
    jobsKey,
    licensesKey,
    diariesKey,
    ledgersKey,
    emojisKey,
    stickerOrderKey,
    goalsKey,
    goalLogsKey,
    memosKey,
    eventCategoriesKey,
    companyCategoriesKey,
    ledgerCategoriesKey,
    licenseCategoriesKey,
    themesKey,
    customThemeIdKey,
    wordmarkHomeKey,
    wordmarkJobKey,
    wordmarkLicenseKey,
  ];

  static const settingKeys = [
    darkKey,
    skinKey,
    themesKey,
    customThemeIdKey,
    mondayKey,
    diaryCoverOrderKey,
    ...NavPreference.syncedKeys,
    ...FontPreference.syncedKeys,
    ...CalendarPreference.syncedKeys,
    ...HomeViewPreference.syncedKeys,
    ...JobViewPreference.syncedKeys,
    ...LicenseViewPreference.syncedKeys,
    ...DayEventsViewPreference.syncedKeys,
    ...CategorySuggestPreference.syncedKeys,
    ...LastCategoryColorPreference.syncedKeys,
    ...LastEventCategoryPreference.syncedKeys,
    ...FriendCategoryPreference.syncedKeys,
    ...FriendOrderPreference.syncedKeys,
    ...FriendHomePreference.syncedKeys,
    ...FriendFavoritePreference.syncedKeys,
  ];

  static const syncedKeys = [
    ...contentKeys,
    darkKey,
    skinKey,
    ...settingKeys,
  ];

  static const _viewDefaultBools = [
    NavPreference.defaultBools,
    CalendarPreference.defaultBools,
    HomeViewPreference.defaultBools,
    JobViewPreference.defaultBools,
    LicenseViewPreference.defaultBools,
    DayEventsViewPreference.defaultBools,
    CategorySuggestPreference.defaultBools,
    FriendCategoryPreference.defaultBools,
  ];

  static const _listMergeKeys = {
    eventsKey,
    jobsKey,
    licensesKey,
    ledgersKey,
    goalsKey,
    goalLogsKey,
    memosKey,
    eventCategoriesKey,
    companyCategoriesKey,
    ledgerCategoriesKey,
    licenseCategoriesKey,
    themesKey,
  };

  static Map<String, dynamic> dump(SharedPreferences prefs) {
    final out = <String, dynamic>{};
    for (final key in syncedKeys) {
      if (prefs.containsKey(key)) {
        _putPref(out, key, prefs.get(key));
        continue;
      }
      if (contentKeys.contains(key)) continue;
      _putPref(out, key, _settingFallback(key));
    }
    return out;
  }

  static void _putPref(Map<String, dynamic> out, String key, Object? value) {
    if (value is String) {
      out[key] = {'t': 's', 'v': value};
    } else if (value is bool) {
      out[key] = {'t': 'b', 'v': value};
    } else if (value is int) {
      out[key] = {'t': 'i', 'v': value};
    } else if (value is double) {
      out[key] = {'t': 'd', 'v': value};
    } else if (value is List) {
      out[key] = {'t': 'l', 'v': List<String>.from(value)};
    }
  }

  static Object? _settingFallback(String key) {
    if (key == darkKey || key == mondayKey) return false;
    if (key == skinKey) return 'classic';
    if (key == diaryCoverOrderKey) return <String>[];
    if (key == FriendCategoryPreference.key) return <String>[];
    if (key == FriendCategoryPreference.companyKey) return <String>[];
    if (key == FriendOrderPreference.key) return <String>[];
    if (key == FriendFavoritePreference.key) return <String>[];
    if (key == FriendHomePreference.uidsKey) return <String>[];
    if (key == FriendHomePreference.seenKey) return <String>[];
    if (key == FriendHomePreference.seededKey) return false;
    if (key == FontPreference.syncedKeys.single) {
      return FontPreference.defaultFamily;
    }
    if (key == HomeViewPreference.cardOrderKey) {
      return HomeCardKind.defaults.map((kind) => kind.name).join(',');
    }
    for (final defaults in _viewDefaultBools) {
      if (defaults.containsKey(key)) return defaults[key];
    }
    return null;
  }

  static Map<String, dynamic> decodeDump(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is Map) return normalizeDump(decoded);
    return {};
  }

  static Map<String, dynamic> normalizeDump(Map raw) {
    final out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is Map) {
        out['${entry.key}'] = Map<String, dynamic>.from(value);
      }
    }
    return out;
  }

  static Future<void> apply(
    SharedPreferences prefs,
    Map<String, dynamic> dump, {
    Iterable<String>? keys,
  }) async {
    for (final key in keys ?? syncedKeys) {
      final payload = dump[key];
      if (payload is! Map) {
        if (contentKeys.contains(key)) {
          await prefs.remove(key);
        } else if (CategorySuggestPreference.syncedKeys.contains(key)) {
          await prefs.setBool(key, false);
        } else if (LastCategoryColorPreference.syncedKeys.contains(key) ||
            LastEventCategoryPreference.syncedKeys.contains(key)) {
          await prefs.remove(key);
        }
        continue;
      }
      final type = payload['t'] as String?;
      final value = payload['v'];
      switch (type) {
        case 's':
          await prefs.setString(key, value as String);
        case 'b':
          await prefs.setBool(key, value as bool);
        case 'i':
          await prefs.setInt(key, (value as num).toInt());
        case 'd':
          await prefs.setDouble(key, (value as num).toDouble());
        case 'l':
          await prefs.setStringList(key, List<String>.from(value as List));
        default:
          await prefs.remove(key);
      }
    }
  }

  static bool isFoundation(SharedPreferences prefs) => isFoundationDump(dump(prefs));

  static bool hasUserContent(Map<String, dynamic> dump) {
    return !isFoundationDump(dump);
  }

  static bool hasLocalItems(Map<String, dynamic> dump) {
    if (_hasListItems(dump, eventsKey)) return true;
    if (_hasListItems(dump, jobsKey)) return true;
    if (_hasListItems(dump, licensesKey)) return true;
    if (_hasListItems(dump, diariesKey)) return true;
    if (_hasListItems(dump, ledgersKey)) return true;
    if (_hasListItems(dump, goalsKey)) return true;
    if (_hasListItems(dump, goalLogsKey)) return true;
    if (_hasListItems(dump, memosKey)) return true;
    if (_hasEmojiItems(_stringOf(dump, emojisKey))) return true;
    return false;
  }

  static bool isFoundationDump(Map<String, dynamic> dump) {
    if (_hasListItems(dump, jobsKey)) return false;
    if (_hasListItems(dump, licensesKey)) return false;
    if (_hasListItems(dump, diariesKey)) return false;
    if (_hasListItems(dump, ledgersKey)) return false;
    if (_hasListItems(dump, goalsKey)) return false;
    if (_hasListItems(dump, goalLogsKey)) return false;
    if (_hasListItems(dump, memosKey)) return false;
    if (_hasEmojiItems(_stringOf(dump, emojisKey))) return false;
    if (!_eventsAreStarter(_stringOf(dump, eventsKey))) return false;
    if (!_themesAreStarter(_stringOf(dump, themesKey))) return false;
    if (!_categoriesAreDefault(
      _stringOf(dump, eventCategoriesKey),
      EventCategory.presets,
    )) {
      return false;
    }
    if (!_categoriesAreDefault(
      _stringOf(dump, companyCategoriesKey),
      EventCategory.companyPresets,
    )) {
      return false;
    }
    if (!_categoriesAreDefault(
      _stringOf(dump, ledgerCategoriesKey),
      EventCategory.ledgerPresets,
    )) {
      return false;
    }
    if (!_categoriesAreDefault(
      _stringOf(dump, licenseCategoriesKey),
      EventCategory.licensePresets,
    )) {
      return false;
    }
    if (_boolOf(dump, darkKey) == true) return false;
    if (_boolOf(dump, mondayKey) == true) return false;
    if (!_viewPrefsAreDefault(dump)) return false;
    final skin = _stringOf(dump, skinKey);
    if (skin != null && skin.isNotEmpty && skin != 'classic') return false;
    if ((_stringOf(dump, customThemeIdKey) ?? '').isNotEmpty) return false;
    if ((_listOf(dump, stickerOrderKey) ?? const []).isNotEmpty) return false;
    if ((_listOf(dump, diaryCoverOrderKey) ?? const []).isNotEmpty) return false;
    if ((_listOf(dump, FriendOrderPreference.key) ?? const []).isNotEmpty) {
      return false;
    }
    if ((_listOf(dump, FriendFavoritePreference.key) ?? const []).isNotEmpty) {
      return false;
    }
    if (_boolOf(dump, FriendHomePreference.seededKey) == true) return false;
    if ((_listOf(dump, FriendHomePreference.uidsKey) ?? const []).isNotEmpty) {
      return false;
    }
    if ((_listOf(dump, FriendHomePreference.seenKey) ?? const []).isNotEmpty) {
      return false;
    }
    if ((_stringOf(dump, wordmarkHomeKey) ?? '').isNotEmpty) return false;
    if ((_stringOf(dump, wordmarkJobKey) ?? '').isNotEmpty) return false;
    if ((_stringOf(dump, wordmarkLicenseKey) ?? '').isNotEmpty) return false;
    return true;
  }

  static Map<String, dynamic> merge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final out = <String, dynamic>{...remote, ...local};
    for (final key in _listMergeKeys) {
      final merged = _mergeIdLists(
        _stringOf(local, key),
        _stringOf(remote, key),
        dropStarterPrefix: key == eventsKey
            ? CalendarEventLocalDataSource.starterIdPrefix
            : key == themesKey
                ? ThemePreference.starterIdPrefix
                : null,
      );
      if (merged == null) {
        out.remove(key);
      } else {
        out[key] = {'t': 's', 'v': merged};
      }
    }
    final diaries = _mergeDiaries(
      _stringOf(local, diariesKey),
      _stringOf(remote, diariesKey),
    );
    if (diaries == null) {
      out.remove(diariesKey);
    } else {
      out[diariesKey] = {'t': 's', 'v': diaries};
    }
    final emojis = _mergeEmojiMaps(
      _stringOf(local, emojisKey),
      _stringOf(remote, emojisKey),
    );
    if (emojis == null) {
      out.remove(emojisKey);
    } else {
      out[emojisKey] = {'t': 's', 'v': emojis};
    }
    final stickers = _mergeStringLists(
      _listOf(local, stickerOrderKey),
      _listOf(remote, stickerOrderKey),
    );
    if (stickers == null) {
      out.remove(stickerOrderKey);
    } else {
      out[stickerOrderKey] = {'t': 'l', 'v': stickers};
    }
    final covers = _mergeStringLists(
      _listOf(local, diaryCoverOrderKey),
      _listOf(remote, diaryCoverOrderKey),
    );
    if (covers == null) {
      out.remove(diaryCoverOrderKey);
    } else {
      out[diaryCoverOrderKey] = {'t': 'l', 'v': covers};
    }
    final friendOrder = _mergeStringLists(
      _listOf(local, FriendOrderPreference.key),
      _listOf(remote, FriendOrderPreference.key),
    );
    if (friendOrder == null) {
      out.remove(FriendOrderPreference.key);
    } else {
      out[FriendOrderPreference.key] = {'t': 'l', 'v': friendOrder};
    }
    final friendFavorites = _mergeStringLists(
      _listOf(local, FriendFavoritePreference.key),
      _listOf(remote, FriendFavoritePreference.key),
    );
    if (friendFavorites == null) {
      out.remove(FriendFavoritePreference.key);
    } else {
      out[FriendFavoritePreference.key] = {'t': 'l', 'v': friendFavorites};
    }
    final localHomeSeeded = _boolOf(local, FriendHomePreference.seededKey) == true;
    final remoteHomeSeeded =
        _boolOf(remote, FriendHomePreference.seededKey) == true;
    if (localHomeSeeded || remoteHomeSeeded) {
      out[FriendHomePreference.seededKey] = {'t': 'b', 'v': true};
      final homeUids = localHomeSeeded && remoteHomeSeeded
          ? _mergeStringLists(
              _listOf(local, FriendHomePreference.uidsKey),
              _listOf(remote, FriendHomePreference.uidsKey),
            )
          : _listOf(
              localHomeSeeded ? local : remote,
              FriendHomePreference.uidsKey,
            );
      if (homeUids == null) {
        out.remove(FriendHomePreference.uidsKey);
      } else {
        out[FriendHomePreference.uidsKey] = {'t': 'l', 'v': homeUids};
      }
      final homeSeen = localHomeSeeded && remoteHomeSeeded
          ? _mergeStringLists(
              _listOf(local, FriendHomePreference.seenKey),
              _listOf(remote, FriendHomePreference.seenKey),
            )
          : _listOf(
              localHomeSeeded ? local : remote,
              FriendHomePreference.seenKey,
            );
      if (homeSeen == null) {
        out.remove(FriendHomePreference.seenKey);
      } else {
        out[FriendHomePreference.seenKey] = {'t': 'l', 'v': homeSeen};
      }
    }
    return out;
  }

  static String hashOf(Map<String, dynamic> dump) => jsonEncode(dump);

  static bool _viewPrefsAreDefault(Map<String, dynamic> dump) {
    for (final defaults in _viewDefaultBools) {
      for (final entry in defaults.entries) {
        final value = _boolOf(dump, entry.key);
        if (value != null && value != entry.value) return false;
      }
    }
    final font = _stringOf(dump, FontPreference.syncedKeys.first);
    if (font != null &&
        font.isNotEmpty &&
        font != FontPreference.defaultFamily) {
      return false;
    }
    if (!HomeViewPreference.cardOrderIsDefault(
      _stringOf(dump, HomeViewPreference.cardOrderKey),
    )) {
      return false;
    }
    return true;
  }

  static bool? _boolOf(Map<String, dynamic> dump, String key) {
    final payload = dump[key];
    if (payload is! Map) return null;
    if (payload['t'] != 'b') return null;
    final value = payload['v'];
    return value is bool ? value : null;
  }

  static String? _stringOf(Map<String, dynamic> dump, String key) {
    final payload = dump[key];
    if (payload is! Map) return null;
    if (payload['t'] != 's') return null;
    final value = payload['v'];
    return value is String ? value : null;
  }

  static List<String>? _listOf(Map<String, dynamic> dump, String key) {
    final payload = dump[key];
    if (payload is! Map) return null;
    if (payload['t'] != 'l') return null;
    final value = payload['v'];
    if (value is! List) return null;
    return [for (final item in value) '$item'];
  }

  static bool _hasListItems(Map<String, dynamic> dump, String key) {
    return _listItems(_stringOf(dump, key)).isNotEmpty;
  }

  static List<Map<String, dynamic>> _listItems(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[]') return const [];
    try {
      final items = jsonDecode(raw);
      if (items is! List) return const [];
      return [
        for (final item in items)
          if (item is Map<String, dynamic>)
            item
          else if (item is Map)
            Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  static bool _eventsAreStarter(String? raw) {
    final items = _listItems(raw);
    if (items.isEmpty) return true;
    if (items.length != CalendarEventLocalDataSource.starterTitles.length) {
      return false;
    }
    return items.every(CalendarEventLocalDataSource.isUnmodifiedStarter);
  }

  static bool _themesAreStarter(String? raw) {
    final items = _listItems(raw);
    if (items.isEmpty) return true;
    if (items.length != ThemePreference.starterNames.length) return false;
    return items.every(ThemePreference.isUnmodifiedStarter);
  }

  static bool _categoriesAreDefault(String? raw, List<EventCategory> presets) {
    if (raw == null || raw.isEmpty) return true;
    final items = _listItems(raw);
    if (items.isEmpty) return true;
    if (items.length == 1 && items.first['id'] == EventCategory.defaultId) {
      return true;
    }
    if (items.length != presets.length) return false;
    for (var i = 0; i < presets.length; i++) {
      final item = items[i];
      if (item['id'] != presets[i].id) return false;
      if (item['name'] != presets[i].name) return false;
      if ((item['color'] as num?)?.toInt() != presets[i].color) return false;
    }
    return true;
  }

  static bool _hasEmojiItems(String? raw) {
    if (raw == null || raw.isEmpty || raw == '{}') return false;
    try {
      final items = jsonDecode(raw);
      if (items is! Map || items.isEmpty) return false;
      for (final value in items.values) {
        if (value is String && value.trim().isNotEmpty) return true;
        if (value is Map) {
          for (final item in value.values) {
            if (item is String && item.trim().isNotEmpty) return true;
          }
        }
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static String? _mergeIdLists(
    String? localRaw,
    String? remoteRaw, {
    String? dropStarterPrefix,
  }) {
    final local = _listItems(localRaw);
    final remote = _listItems(remoteRaw);
    if (local.isEmpty && remote.isEmpty) return null;
    final seen = <String>{
      for (final item in local) item['id'] as String? ?? '',
    };
    final merged = [
      ...local,
      for (final item in remote)
        if (!seen.contains(item['id'] as String? ?? '')) item,
    ];
    if (dropStarterPrefix != null &&
        merged.any((item) {
          final id = item['id'] as String? ?? '';
          return id.isNotEmpty && !id.startsWith(dropStarterPrefix);
        })) {
      merged.removeWhere((item) {
        final id = item['id'] as String? ?? '';
        return id.startsWith(dropStarterPrefix);
      });
    }
    if (merged.isEmpty) return null;
    return jsonEncode(merged);
  }

  static String? _mergeDiaries(String? localRaw, String? remoteRaw) {
    final local = _listItems(localRaw);
    final remote = _listItems(remoteRaw);
    if (local.isEmpty && remote.isEmpty) return null;
    final merged = [...local];
    final seenIds = {
      for (final item in local) item['id'] as String? ?? '',
    };
    final occupied = {
      for (final item in local) '${item['date'] ?? ''}',
    }..remove('');
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final item in remote) {
      final id = item['id'] as String? ?? '';
      if (seenIds.contains(id)) continue;
      final group = (item['groupId'] as String?) ?? id;
      if (group.isEmpty) continue;
      groups.putIfAbsent(group, () => []).add(item);
    }
    for (final items in groups.values) {
      final days = {
        for (final item in items) '${item['date'] ?? ''}',
      }..remove('');
      if (days.any(occupied.contains)) continue;
      merged.addAll(items);
      occupied.addAll(days);
      for (final item in items) {
        seenIds.add(item['id'] as String? ?? '');
      }
    }
    if (merged.isEmpty) return null;
    return jsonEncode(merged);
  }

  static String? _mergeEmojiMaps(String? localRaw, String? remoteRaw) {
    final remote = _decodeMap(remoteRaw);
    final local = _decodeMap(localRaw);
    if (remote.isEmpty && local.isEmpty) return null;
    final out = _deepCopy(remote);
    _overlay(out, local);
    if (out.isEmpty) return null;
    return jsonEncode(out);
  }

  static List<String>? _mergeStringLists(
    List<String>? local,
    List<String>? remote,
  ) {
    if ((local == null || local.isEmpty) &&
        (remote == null || remote.isEmpty)) {
      return null;
    }
    final seen = <String>{};
    final out = <String>[];
    for (final item in [...?local, ...?remote]) {
      if (seen.add(item)) out.add(item);
    }
    return out;
  }

  static Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty || raw == '{}') return {};
    try {
      final items = jsonDecode(raw);
      if (items is Map<String, dynamic>) return items;
      if (items is Map) return Map<String, dynamic>.from(items);
      return {};
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    final out = <String, dynamic>{};
    for (final entry in source.entries) {
      final value = entry.value;
      if (value is Map) {
        out[entry.key] = _deepCopy(Map<String, dynamic>.from(value));
      } else {
        out[entry.key] = value;
      }
    }
    return out;
  }

  static void _overlay(Map<String, dynamic> target, Map<String, dynamic> source) {
    for (final entry in source.entries) {
      final current = target[entry.key];
      final next = entry.value;
      if (current is Map && next is Map) {
        final nested = Map<String, dynamic>.from(current);
        _overlay(nested, Map<String, dynamic>.from(next));
        target[entry.key] = nested;
      } else {
        target[entry.key] = next;
      }
    }
  }
}
