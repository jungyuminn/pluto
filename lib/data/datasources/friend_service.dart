import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/calendar_event_local_datasource.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/models/calendar_event_model.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendService {
  FriendService._();

  static final instance = FriendService._();

  static const _region = 'asia-northeast3';
  static const _profileKeyPrefix = 'friend_profile_';
  static const _pendingNameKeyPrefix = 'friend_pending_name_';

  final profile = ValueNotifier<FriendProfile?>(null);

  Timer? _syncTimer;
  Timer? _stickerTimer;
  Timer? _nameRetry;
  List<CalendarEvent> _pending = const [];
  Map<String, String> _pendingStickers = {};
  Set<String> _lastSharedIds = {};
  Set<String> _lastStickerIds = {};
  var _syncing = false;
  var _stickerSyncing = false;
  var _needsResync = false;
  var _needsStickerResync = false;
  var _pushingName = false;

  bool get _ready =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  String? get _uid =>
      _ready ? FirebaseAuth.instance.currentUser?.uid : null;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: _region);

  void reset() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _stickerTimer?.cancel();
    _stickerTimer = null;
    _nameRetry?.cancel();
    _nameRetry = null;
    _pending = const [];
    _pendingStickers = {};
    _lastSharedIds = {};
    _lastStickerIds = {};
    _needsResync = false;
    _needsStickerResync = false;
    profile.value = null;
  }

  Future<void> bootstrap() async {
    DayEmojiStore.syncEventLayer = scheduleStickerSync;
    if (!_ready) return;
    await _restoreLocal();
    try {
      await AppAuthService.instance.applySocialProfile();
      await ensureProfile();
    } catch (error) {
      debugPrint('Friend bootstrap failed: $error');
    }
    try {
      await _flushPendingName();
    } catch (error) {
      debugPrint('Friend name flush failed: $error');
    }
    try {
      await syncFromLocal();
    } catch (error) {
      debugPrint('Friend calendar sync failed: $error');
    }
  }

  Future<FriendProfile> ensureProfile() async {
    await AppAuthService.instance.applySocialProfile();
    final user = FirebaseAuth.instance.currentUser;
    final name = user == null ? null : AppAuthService.socialDisplayName(user);
    final data = await _call('ensureFriendProfile', {
      'displayName': ?name,
    });
    var next = FriendProfile.fromMap(data);
    final pending = await _readPendingName();
    if (pending != null && pending.isNotEmpty) {
      next = next.copyWith(displayName: pending);
    }
    profile.value = next;
    await _writeCachedProfile();
    return next;
  }

  Future<FriendProfile> setDisplayName(String name) async {
    final current = profile.value;
    if (current != null) {
      profile.value = current.copyWith(displayName: name);
    }
    await _writePendingName(name);
    await _writeCachedProfile();
    return _pushDisplayName(name, fallback: current);
  }

  Future<FriendProfile> _pushDisplayName(
    String name, {
    FriendProfile? fallback,
  }) async {
    if (_pushingName) {
      return profile.value ?? fallback ?? FriendProfile(
        uid: _uid ?? '',
        displayName: name,
        friendCode: '',
      );
    }
    _pushingName = true;
    try {
      final data = await _call('updateFriendDisplayName', {
        'displayName': name,
      });
      final next = FriendProfile.fromMap(data);
      profile.value = next;
      await _clearPendingName();
      await _writeCachedProfile();
      return next;
    } catch (error) {
      if (_canRetryName(error)) {
        _scheduleNameRetry();
        return profile.value ?? fallback ?? FriendProfile(
          uid: _uid ?? '',
          displayName: name,
          friendCode: '',
        );
      }
      if (fallback != null) {
        profile.value = fallback;
        await _clearPendingName();
        await _writeCachedProfile();
      }
      rethrow;
    } finally {
      _pushingName = false;
    }
  }

  Future<void> _flushPendingName() async {
    final name = await _readPendingName();
    if (name == null || name.isEmpty) return;
    await _pushDisplayName(name, fallback: profile.value);
  }

  void _scheduleNameRetry() {
    if (_nameRetry?.isActive == true) return;
    _nameRetry = Timer(const Duration(seconds: 12), () {
      unawaited(_flushPendingName());
    });
  }

  bool _canRetryName(Object error) {
    if (error is FriendException) {
      return switch (error.code) {
        'bad-name' ||
        'unauthenticated' ||
        'login-required' =>
          false,
        _ => true,
      };
    }
    return true;
  }

  Future<void> _restoreLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid;
    if (uid == null) return;
    final raw = prefs.getString('$_profileKeyPrefix$uid');
    FriendProfile? cached;
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          cached = FriendProfile.fromMap(data, uid: uid);
        } else if (data is Map) {
          cached = FriendProfile.fromMap(
            Map<String, dynamic>.from(data),
            uid: uid,
          );
        }
      } catch (_) {}
    }
    final pending = prefs.getString('$_pendingNameKeyPrefix$uid')?.trim();
    if (cached == null && (pending == null || pending.isEmpty)) return;
    profile.value = (cached ?? FriendProfile(
      uid: uid,
      displayName: pending ?? '',
      friendCode: '',
    )).copyWith(
      displayName: pending == null || pending.isEmpty
          ? null
          : pending,
    );
  }

  Future<String?> _readPendingName() async {
    final uid = _uid;
    if (uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('$_pendingNameKeyPrefix$uid')?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  Future<void> _writePendingName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_pendingNameKeyPrefix$uid', name);
  }

  Future<void> _clearPendingName() async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pendingNameKeyPrefix$uid');
  }

  Future<void> _writeCachedProfile() async {
    final uid = _uid;
    final current = profile.value;
    if (uid == null || current == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_profileKeyPrefix$uid',
      jsonEncode(current.toMap()),
    );
  }

  Future<void> _clearLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_profileKeyPrefix$uid');
    await prefs.remove('$_pendingNameKeyPrefix$uid');
  }

  Future<FriendProfile> setPhoto(Uint8List bytes, String contentType) async {
    final uid = _uid;
    if (uid == null) {
      throw const FriendException('login-required');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FriendException('bad-photo');
    }
    final type = contentType.startsWith('image/') ? contentType : 'image/jpeg';
    final ext = type == 'image/png'
        ? 'png'
        : type == 'image/webp'
            ? 'webp'
            : 'jpg';
    final ref = FirebaseStorage.instance.ref('users/$uid/profile/avatar.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: type));
    final url = await ref.getDownloadURL();
    final current = profile.value;
    if (current != null) {
      profile.value = current.copyWith(photoURL: url);
      await _writeCachedProfile();
    }
    final data = await _call('updateFriendPhoto', {'photoURL': url});
    final next = FriendProfile.fromMap(data);
    profile.value = next;
    await _writeCachedProfile();
    return next;
  }

  Future<FriendProfile> setFriendCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user == null ? null : AppAuthService.socialDisplayName(user);
    final data = await _call('claimFriendCode', {
      'code': code,
      'displayName': ?name,
    });
    final next = FriendProfile.fromMap(data);
    profile.value = next;
    return next;
  }

  Stream<List<FriendRequestItem>> incomingRequests() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) => _pendingWithPhotos(_pendingOf(snap), outgoing: false));
  }

  Stream<List<FriendRequestItem>> outgoingRequests() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) => _pendingWithPhotos(_pendingOf(snap), outgoing: true));
  }

  Stream<int> incomingCount() {
    return incomingRequests().map((items) => items.length);
  }

  Stream<List<FriendProfile>> friends() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('friendships')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snap) {
      final items = [
        for (final doc in snap.docs)
          FriendProfile.fromMap(doc.data(), uid: doc.id),
      ];
      items.sort((a, b) => a.label.compareTo(b.label));
      return items;
    });
  }

  Future<FriendProfile?> lookupByCode(String code) async {
    if (!_ready) {
      throw const FriendException('login-required');
    }
    final handle = _normalize(code);
    if (handle.isEmpty) return null;
    final codeSnap = await _db.collection('friend_codes').doc(handle).get();
    final uid = '${codeSnap.data()?['uid'] ?? ''}';
    if (uid.isEmpty) return null;
    final profileSnap = await _db.collection('profiles').doc(uid).get();
    if (!profileSnap.exists) return null;
    final next = FriendProfile.fromMap(profileSnap.data() ?? {}, uid: uid);
    if (next.friendCode.isEmpty) return null;
    return next;
  }

  Future<bool> isFriend(String uid) async {
    final me = _uid;
    if (me == null || uid.isEmpty) return false;
    final snap = await _db
        .collection('friendships')
        .doc(me)
        .collection('friends')
        .doc(uid)
        .get();
    return snap.exists;
  }

  Future<({String status, String requestId})> sendRequest(String code) async {
    final result = await _call('sendFriendRequest', {'code': _normalize(code)});
    return (
      status: '${result['status'] ?? 'pending'}',
      requestId: '${result['requestId'] ?? ''}',
    );
  }

  Future<void> accept(String requestId) {
    return _call('acceptFriendRequest', {'requestId': requestId});
  }

  Future<void> decline(String requestId) {
    return _call('declineFriendRequest', {'requestId': requestId});
  }

  Future<void> cancel(String requestId) {
    return _call('cancelFriendRequest', {'requestId': requestId});
  }

  Future<void> remove(String uid) async {
    await _call('removeFriend', {'uid': uid});
  }

  Future<void> deleteAll() async {
    final uid = _uid;
    if (!_ready) return;
    try {
      await _call('deleteFriendData');
    } catch (error) {
      debugPrint('Friend delete failed: $error');
    }
    if (uid != null) await _clearLocal(uid);
    reset();
  }

  void scheduleSync(List<CalendarEvent> events) {
    if (!_ready) return;
    _pending = events;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(_pushShared(_pending));
    });
  }

  Future<void> syncFromLocal() async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(CalendarEventLocalDataSource.key);
    if (raw == null || raw.isEmpty) {
      await _pushShared(const []);
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final events = [
          for (final item in decoded)
            if (item is Map<String, dynamic>)
              CalendarEventModel.fromJson(item),
        ];
        await _pushShared(events);
      } catch (error) {
        debugPrint('Friend calendar parse failed: $error');
      }
    }
    await _pushStickers(
      DayEmojiStore.eventStampsFromRaw(prefs.getString(DayEmojiStore.key)),
    );
  }

  void scheduleStickerSync(Map<String, String> stickers) {
    if (!_ready) return;
    _pendingStickers = Map<String, String>.of(stickers);
    _stickerTimer?.cancel();
    _stickerTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(_pushStickers(_pendingStickers));
    });
  }

  Future<Map<String, String>> stickersInMonth({
    required String friendUid,
    required DateTime month,
  }) async {
    if (!_ready) return const {};
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final snap = await _db
        .collection('shared_calendars')
        .doc(friendUid)
        .collection('stickers')
        .where('date', isGreaterThanOrEqualTo: _date(start))
        .where('date', isLessThanOrEqualTo: _date(end))
        .get();
    return {
      for (final doc in snap.docs)
        if ('${doc.data()['asset'] ?? ''}'.trim().isNotEmpty)
          '${doc.data()['date'] ?? doc.id}': '${doc.data()['asset']}'.trim(),
    };
  }

  Future<List<CalendarEvent>> eventsInMonth({
    required String friendUid,
    required DateTime month,
  }) async {
    if (!_ready) return const [];
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final snap = await _db
        .collection('shared_calendars')
        .doc(friendUid)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: _date(start))
        .where('date', isLessThanOrEqualTo: _date(end))
        .get();
    return [
      for (final doc in snap.docs) _fromShared(doc.id, doc.data()),
    ];
  }

  String messageOf(Object error) {
    final code = error is FriendException
        ? error.code
        : error is FirebaseFunctionsException
            ? error.message ?? error.code
            : '';
    return switch (code) {
      'no-user' || 'not-found' => AppStrings.friendsNotFound,
      'self' => AppStrings.friendsSelf,
      'already-friends' => AppStrings.friendsAlready,
      'already-sent' => AppStrings.friendsAlreadySent,
      'taken' => AppStrings.friendsCodeTaken,
      'bad-code' => AppStrings.friendsCodeBad,
      'bad-name' => AppStrings.friendsNameBad,
      'bad-photo' => AppStrings.friendsPhotoTooBig,
      'needs-code' => AppStrings.friendsCodeNeed,
      'code-cooldown' => AppStrings.friendsCodeCooldown(30),
      'rate-limited' || 'resource-exhausted' => AppStrings.friendsRateLimited,
      'unauthenticated' || 'login-required' => AppStrings.friendsNeedLogin,
      _ => AppStrings.friendsFailed,
    };
  }

  Future<List<FriendRequestItem>> _pendingWithPhotos(
    List<FriendRequestItem> items, {
    required bool outgoing,
  }) async {
    return Future.wait([
      for (final item in items) _fillPhoto(item, outgoing: outgoing),
    ]);
  }

  Future<FriendRequestItem> _fillPhoto(
    FriendRequestItem item, {
    required bool outgoing,
  }) async {
    final hasPhoto = outgoing ? item.toPhotoURL : item.fromPhotoURL;
    final uid = outgoing ? item.toUid : item.fromUid;
    if (hasPhoto.isNotEmpty || uid.isEmpty) return item;
    try {
      final snap = await _db.collection('profiles').doc(uid).get();
      final photo = '${snap.data()?['photoURL'] ?? ''}'.trim();
      if (photo.isEmpty) return item;
      return outgoing
          ? item.copyWith(toPhotoURL: photo)
          : item.copyWith(fromPhotoURL: photo);
    } catch (_) {
      return item;
    }
  }

  List<FriendRequestItem> _pendingOf(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final items = [
      for (final doc in snap.docs)
        FriendRequestItem.fromMap(doc.id, doc.data()),
    ].where((item) => item.isPending).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> _pushShared(List<CalendarEvent> events) async {
    final uid = _uid;
    if (uid == null) return;
    if (_syncing) {
      _pending = events;
      _needsResync = true;
      return;
    }
    _syncing = true;
    _needsResync = false;
    try {
      final shareable = [
        for (final event in events)
          if (_shareable(event)) event,
      ];
      final nextIds = {for (final event in shareable) event.id};
      if (_lastSharedIds.isEmpty) {
        final existing = await _db
            .collection('shared_calendars')
            .doc(uid)
            .collection('events')
            .get();
        _lastSharedIds = {for (final doc in existing.docs) doc.id};
      }
      final removed = _lastSharedIds.difference(nextIds);
      final writes = <Future<void>>[];
      var batch = _db.batch();
      var ops = 0;

      void flushIfNeeded() {
        if (ops < 400) return;
        writes.add(batch.commit());
        batch = _db.batch();
        ops = 0;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      for (final event in shareable) {
        batch.set(
          _db
              .collection('shared_calendars')
              .doc(uid)
              .collection('events')
              .doc(event.id),
          _toShared(event, now),
        );
        ops += 1;
        flushIfNeeded();
      }
      for (final id in removed) {
        batch.delete(
          _db
              .collection('shared_calendars')
              .doc(uid)
              .collection('events')
              .doc(id),
        );
        ops += 1;
        flushIfNeeded();
      }
      if (ops > 0) writes.add(batch.commit());
      await Future.wait(writes);
      _lastSharedIds = nextIds;
    } catch (error) {
      debugPrint('Friend calendar sync failed: $error');
    } finally {
      _syncing = false;
      if (_needsResync) {
        unawaited(_pushShared(_pending));
      }
    }
  }

  Future<void> _pushStickers(Map<String, String> stickers) async {
    final uid = _uid;
    if (uid == null) return;
    if (_stickerSyncing) {
      _pendingStickers = Map<String, String>.of(stickers);
      _needsStickerResync = true;
      return;
    }
    _stickerSyncing = true;
    _needsStickerResync = false;
    try {
      final shareable = {
        for (final entry in stickers.entries)
          if (_shareableSticker(entry.key, entry.value))
            entry.key: entry.value,
      };
      final nextIds = shareable.keys.toSet();
      if (_lastStickerIds.isEmpty) {
        final existing = await _db
            .collection('shared_calendars')
            .doc(uid)
            .collection('stickers')
            .get();
        _lastStickerIds = {for (final doc in existing.docs) doc.id};
      }
      final removed = _lastStickerIds.difference(nextIds);
      final writes = <Future<void>>[];
      var batch = _db.batch();
      var ops = 0;

      void flushIfNeeded() {
        if (ops < 400) return;
        writes.add(batch.commit());
        batch = _db.batch();
        ops = 0;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in shareable.entries) {
        batch.set(
          _db
              .collection('shared_calendars')
              .doc(uid)
              .collection('stickers')
              .doc(entry.key),
          {
            'date': entry.key,
            'asset': entry.value,
            'updatedAt': now,
          },
        );
        ops += 1;
        flushIfNeeded();
      }
      for (final id in removed) {
        batch.delete(
          _db
              .collection('shared_calendars')
              .doc(uid)
              .collection('stickers')
              .doc(id),
        );
        ops += 1;
        flushIfNeeded();
      }
      if (ops > 0) writes.add(batch.commit());
      await Future.wait(writes);
      _lastStickerIds = nextIds;
    } catch (error) {
      debugPrint('Friend sticker sync failed: $error');
    } finally {
      _stickerSyncing = false;
      if (_needsStickerResync) {
        unawaited(_pushStickers(_pendingStickers));
      }
    }
  }

  bool _shareableSticker(String date, String asset) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return false;
    if (!asset.startsWith('assets/stickers/')) return false;
    return asset.length <= 200;
  }

  bool _shareable(CalendarEvent event) {
    if (event.someday || event.isJob) return false;
    if (event.id.startsWith(CalendarEventLocalDataSource.starterIdPrefix)) {
      return false;
    }
    return event.title.trim().isNotEmpty;
  }

  Map<String, Object?> _toShared(CalendarEvent event, int updatedAt) {
    final title = event.title.trim();
    final category = event.categoryName.trim();
    return {
      'title': title.length > 80 ? title.substring(0, 80) : title,
      'date': _date(event.day),
      'color': event.categoryColor,
      'categoryName': category.length > 32 ? category.substring(0, 32) : category,
      'completed': event.completed,
      'groupId': event.groupId,
      'startMinutes': event.startMinutes,
      'endMinutes': event.endMinutes,
      'visibility': 'title',
      'updatedAt': updatedAt,
    };
  }

  CalendarEvent _fromShared(String id, Map<String, dynamic> data) {
    final visibility = '${data['visibility'] ?? 'title'}';
    final rawTitle = '${data['title'] ?? ''}'.trim();
    final title = visibility == 'busy' ? AppStrings.friendsBusyLabel : rawTitle;
    final dateRaw = '${data['date'] ?? ''}';
    final parsed = DateTime.tryParse(dateRaw) ?? DateTime.now();
    final category = '${data['categoryName'] ?? ''}'.trim();
    return CalendarEvent(
      id: id,
      title: title,
      date: DateTime(parsed.year, parsed.month, parsed.day),
      categoryName: category.isEmpty
          ? CalendarEvent.defaultCategoryName
          : category,
      categoryColor: (data['color'] as num?)?.toInt() ??
          CalendarEvent.defaultCategoryColor,
      completed: data['completed'] == true,
      groupId: data['groupId'] as String?,
      startMinutes: (data['startMinutes'] as num?)?.toInt(),
      endMinutes: (data['endMinutes'] as num?)?.toInt(),
    );
  }

  String _date(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _normalize(String raw) {
    return raw.replaceAll('＃', '#').replaceAll(RegExp(r'\s+'), '').trim();
  }

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic>? data,
  ]) async {
    if (!_ready) {
      throw const FriendException('login-required');
    }
    try {
      final result = await _fn.httpsCallable(name).call(data ?? {});
      final payload = result.data;
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      return {};
    } on FirebaseFunctionsException catch (error) {
      throw FriendException(error.message ?? error.code);
    }
  }
}
