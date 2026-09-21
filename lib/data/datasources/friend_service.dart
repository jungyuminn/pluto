import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/calendar_event_local_datasource.dart';
import 'package:pluto/data/datasources/event_category_local_datasource.dart';
import 'package:pluto/data/datasources/last_event_category_preference.dart';
import 'package:pluto/data/datasources/friend_category_preference.dart';
import 'package:pluto/data/datasources/friend_favorite_preference.dart';
import 'package:pluto/data/datasources/friend_home_preference.dart';
import 'package:pluto/data/datasources/friend_order_preference.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/models/calendar_event_model.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/todo_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendService {
  FriendService._();

  static final instance = FriendService._();

  static const _region = 'asia-northeast3';
  static const _profileKeyPrefix = 'friend_profile_';
  static const _pendingNameKeyPrefix = 'friend_pending_name_';

  final profile = ValueNotifier<FriendProfile?>(null);
  final avatarTick = ValueNotifier(0);
  final _avatarMem = <String, Uint8List>{};
  final _avatarGen = <String, int>{};
  FriendProfile? _sessionProfile;
  String? _sessionUid;
  Future<void>? _bootstrapWork;
  String? _bootstrapUid;

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
  String? _requestStreamUid;
  StreamController<List<FriendRequestItem>>? _incomingCtrl;
  StreamController<List<FriendRequestItem>>? _outgoingCtrl;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _outgoingSub;
  var _lastIncoming = const <FriendRequestItem>[];
  var _lastOutgoing = const <FriendRequestItem>[];
  String? _todoStreamUid;
  StreamController<List<TodoRequestItem>>? _incomingTodoCtrl;
  StreamController<List<TodoRequestItem>>? _outgoingTodoCtrl;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingTodoSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _outgoingTodoSub;
  var _lastIncomingTodos = const <TodoRequestItem>[];
  var _lastOutgoingTodos = const <TodoRequestItem>[];
  var _incomingTodoAll = const <TodoRequestItem>[];
  var _outgoingTodoAll = const <TodoRequestItem>[];
  Future<List<CalendarEvent>> Function()? _readCalendar;
  Future<void> Function(CalendarEvent event)? _addCalendar;
  Future<void> Function(CalendarEvent event)? _updateCalendar;
  Future<void> Function(List<CalendarEvent> events)? _writeCalendar;
  VoidCallback? _onCalendarChanged;
  Future<void> _materializeWork = Future.value();

  bool get _ready =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  String? get _uid =>
      _ready ? FirebaseAuth.instance.currentUser?.uid : null;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: _region);

  Uint8List? avatarBytes(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    return _avatarMem[uid];
  }

  void hydrateSession() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final current = profile.value;
    if (current?.uid == user.uid && current!.photoURL.isNotEmpty) return;
    if (_sessionUid == user.uid && _sessionProfile != null) {
      profile.value = _sessionProfile;
      return;
    }
    if (current?.uid == user.uid) return;
    final photo = AppAuthService.socialPhotoURL(user) ?? '';
    final name = AppAuthService.socialDisplayName(user) ?? '';
    if (photo.isEmpty && name.isEmpty) return;
    profile.value = FriendProfile(
      uid: user.uid,
      displayName: name,
      friendCode: current?.friendCode ?? '',
      photoURL: photo,
    );
  }

  void reset() {
    final current = profile.value;
    if (current != null && current.uid.isNotEmpty) {
      _sessionUid = current.uid;
      _sessionProfile = current;
    }
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
    _bootstrapUid = null;
    _bootstrapWork = null;
    _disposeRequestStreams();
    _disposeTodoStreams();
    profile.value = null;
  }

  Future<void> bootstrap() async {
    DayEmojiStore.syncEventLayer = scheduleStickerSync;
    hydrateSession();
    unawaited(_warmAvatar(profile.value));
    final uid = _uid;
    if (uid == null) {
      await FriendCategoryPreference.instance.load();
      await FriendOrderPreference.instance.load();
      await FriendHomePreference.instance.load();
      await FriendFavoritePreference.instance.load();
      return;
    }
    if (_bootstrapUid == uid && _bootstrapWork != null) {
      return _bootstrapWork;
    }
    _bootstrapUid = uid;
    final work = _runBootstrap();
    _bootstrapWork = work;
    try {
      await work;
    } finally {
      if (identical(_bootstrapWork, work)) _bootstrapWork = null;
    }
  }

  Future<void> _runBootstrap() async {
    await _restoreLocal();
    unawaited(_warmAvatar(profile.value));
    unawaited(FriendCategoryPreference.instance.load());
    unawaited(FriendOrderPreference.instance.load());
    unawaited(FriendHomePreference.instance.load());
    unawaited(FriendFavoritePreference.instance.load());
    try {
      if (!kIsWeb) {
        await AppAuthService.instance
            .applySocialProfile()
            .timeout(const Duration(seconds: 3));
        hydrateSession();
      }
      await ensureProfile();
      _bindTodoStreams();
      unawaited(_warmAvatar(profile.value));
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
    if (!kIsWeb) {
      try {
        await AppAuthService.instance
            .applySocialProfile()
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    final user = FirebaseAuth.instance.currentUser;
    final name = user == null ? null : AppAuthService.socialDisplayName(user);
    Future<FriendProfile> finish(FriendProfile next) async {
      var resolved = next;
      final pending = await _readPendingName();
      if (pending != null && pending.isNotEmpty) {
        resolved = resolved.copyWith(displayName: pending);
      }
      profile.value = resolved;
      await _writeCachedProfile();
      return resolved;
    }

    if (!kIsWeb) {
      try {
        final data = await _call('ensureFriendProfile', {
          'displayName': ?name,
        });
        return finish(FriendProfile.fromMap(data));
      } catch (error) {
        debugPrint('Friend ensure function failed: $error');
        final fallback = await _readRemoteProfile();
        if (fallback != null) return finish(fallback);
      }
    }
    return finish(await _ensureViaStore(hint: name));
  }

  Future<FriendProfile?> _readRemoteProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final snap = await _db.collection('profiles').doc(uid).get();
      if (!snap.exists) return null;
      return _profileFromStore(uid, snap.data() ?? {});
    } catch (_) {
      return null;
    }
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
      final next = kIsWeb
          ? await _renameViaStore(name)
          : FriendProfile.fromMap(
              await _call('updateFriendDisplayName', {
                'displayName': name,
              }),
            );
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
    _avatarMem.remove(uid);
    avatarTick.value++;
    if (_sessionUid == uid) {
      _sessionUid = null;
      _sessionProfile = null;
    }
    try {
      final file = await _avatarFile(uid);
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
  }

  void _rememberAvatar(String uid, Uint8List bytes) {
    if (uid.isEmpty || bytes.isEmpty) return;
    _avatarMem[uid] = bytes;
    _avatarGen[uid] = (_avatarGen[uid] ?? 0) + 1;
    avatarTick.value++;
    unawaited(_writeAvatarFile(uid, bytes));
  }

  Future<void> _warmAvatar(FriendProfile? next) async {
    final uid = next?.uid ?? '';
    final url = next?.photoURL ?? '';
    if (uid.isEmpty || url.isEmpty) return;
    if (_avatarMem.containsKey(uid)) return;
    final gen = _avatarGen[uid] ?? 0;
    try {
      final file = await _avatarFile(uid);
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty && (_avatarGen[uid] ?? 0) == gen) {
          _avatarMem[uid] = bytes;
          avatarTick.value++;
          return;
        }
      }
    } catch (_) {}
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;
      if ((_avatarGen[uid] ?? 0) != gen) return;
      final current = profile.value;
      if (current?.uid == uid &&
          current!.photoURL.isNotEmpty &&
          current.photoURL != url) {
        return;
      }
      _rememberAvatar(uid, response.bodyBytes);
    } catch (_) {}
  }

  Future<File?> _avatarFile(String uid) async {
    if (kIsWeb || uid.isEmpty) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/friend_avatar_$uid');
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeAvatarFile(String uid, Uint8List bytes) async {
    try {
      final file = await _avatarFile(uid);
      if (file == null) return;
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  Future<FriendProfile> setPhoto(Uint8List bytes, String contentType) async {
    final uid = _uid;
    if (uid == null) {
      throw const FriendException('login-required');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FriendException('bad-photo');
    }
    _rememberAvatar(uid, bytes);
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
      final next = current.copyWith(photoURL: url);
      profile.value = next;
      _sessionUid = uid;
      _sessionProfile = next;
      await _writeCachedProfile();
    }
    final data = await _call('updateFriendPhoto', {'photoURL': url});
    final saved = FriendProfile.fromMap(data);
    profile.value = saved;
    _sessionUid = uid;
    _sessionProfile = saved;
    await _writeCachedProfile();
    return saved;
  }

  Future<FriendProfile> clearPhoto() async {
    final uid = _uid;
    if (uid == null) {
      throw const FriendException('login-required');
    }
    _avatarMem.remove(uid);
    _avatarGen[uid] = (_avatarGen[uid] ?? 0) + 1;
    avatarTick.value++;
    try {
      final file = await _avatarFile(uid);
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
    final current = profile.value;
    if (current != null) {
      final next = current.copyWith(photoURL: '');
      profile.value = next;
      _sessionUid = uid;
      _sessionProfile = next;
      await _writeCachedProfile();
    }
    for (final ext in const ['jpg', 'png', 'webp']) {
      try {
        await FirebaseStorage.instance
            .ref('users/$uid/profile/avatar.$ext')
            .delete();
      } catch (_) {}
    }
    try {
      final data = await _call('updateFriendPhoto', {'photoURL': ''});
      final saved = FriendProfile.fromMap(data);
      profile.value = saved;
      _sessionUid = uid;
      _sessionProfile = saved;
      await _writeCachedProfile();
      return saved;
    } on FriendException catch (error) {
      if (error.code != 'bad-photo') rethrow;
      return _clearPhotoViaStore();
    }
  }

  Future<FriendProfile> _clearPhotoViaStore() async {
    final uid = _uid;
    if (uid == null) throw const FriendException('login-required');
    final ref = _db.collection('profiles').doc(uid);
    await ref.set({
      'photoURL': '',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    final saved = await ref.get();
    final next = _profileFromStore(uid, saved.data() ?? {});
    profile.value = next;
    _sessionUid = uid;
    _sessionProfile = next;
    await _writeCachedProfile();
    return next;
  }

  Future<FriendProfile> setFriendCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user == null ? null : AppAuthService.socialDisplayName(user);
    Future<FriendProfile> apply(FriendProfile next) async {
      profile.value = next;
      _sessionUid = _uid;
      _sessionProfile = next;
      await _writeCachedProfile();
      return next;
    }

    if (kIsWeb) {
      return apply(await _claimViaStore(code, hint: name));
    }
    try {
      final data = await _call('claimFriendCode', {
        'code': code,
        'displayName': ?name,
      });
      return apply(FriendProfile.fromMap(data));
    } catch (error) {
      if (error is FriendException && !_retryClaim(error)) rethrow;
      debugPrint('Friend claim function failed: $error');
      return apply(await _claimViaStore(code, hint: name));
    }
  }

  bool _retryClaim(FriendException error) {
    return switch (error.code) {
      'taken' ||
      'bad-code' ||
      'code-cooldown' ||
      'unauthenticated' ||
      'login-required' =>
        false,
      _ => true,
    };
  }

  List<FriendRequestItem> get lastIncoming => _lastIncoming;

  List<FriendRequestItem> get lastOutgoing => _lastOutgoing;

  Stream<List<FriendRequestItem>> incomingRequests() {
    _bindRequestStreams();
    return _incomingCtrl?.stream ?? Stream.value(_lastIncoming);
  }

  Stream<List<FriendRequestItem>> outgoingRequests() {
    _bindRequestStreams();
    return _outgoingCtrl?.stream ?? Stream.value(_lastOutgoing);
  }

  Stream<int> incomingRequestCount() {
    _bindRequestStreams();
    return incomingRequests().map((items) => items.length);
  }

  Stream<int> incomingTodoCount() {
    _bindTodoStreams();
    return incomingTodos().map((items) => items.length);
  }

  void bindCalendar({
    required Future<List<CalendarEvent>> Function() read,
    required Future<void> Function(CalendarEvent event) add,
    Future<void> Function(CalendarEvent event)? update,
    Future<void> Function(List<CalendarEvent> events)? write,
    VoidCallback? onChanged,
  }) {
    _readCalendar = read;
    _addCalendar = add;
    _updateCalendar = update;
    _writeCalendar = write;
    _onCalendarChanged = onChanged;
    unawaited(_syncSharedTodos());
  }

  List<TodoRequestItem> get lastIncomingTodos => _lastIncomingTodos;

  List<TodoRequestItem> get lastOutgoingTodos => _lastOutgoingTodos;

  Future<void> resyncSharedTodos() => _syncSharedTodos();

  Stream<List<TodoRequestItem>> incomingTodos() {
    _bindTodoStreams();
    return _incomingTodoCtrl?.stream ?? Stream.value(_lastIncomingTodos);
  }

  Stream<List<TodoRequestItem>> outgoingTodos() {
    _bindTodoStreams();
    return _outgoingTodoCtrl?.stream ?? Stream.value(_lastOutgoingTodos);
  }

  void _disposeRequestStreams() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _incomingSub = null;
    _outgoingSub = null;
    _incomingCtrl?.close();
    _outgoingCtrl?.close();
    _incomingCtrl = null;
    _outgoingCtrl = null;
    _requestStreamUid = null;
    _lastIncoming = const [];
    _lastOutgoing = const [];
  }

  void _bindRequestStreams() {
    final uid = _uid;
    if (uid == null) {
      _disposeRequestStreams();
      return;
    }
    if (_requestStreamUid == uid &&
        _incomingCtrl != null &&
        _outgoingCtrl != null) {
      return;
    }
    _disposeRequestStreams();
    _requestStreamUid = uid;
    _incomingCtrl = StreamController<List<FriendRequestItem>>.broadcast(
      onListen: () => _replayRequests(_incomingCtrl, _lastIncoming),
    );
    _outgoingCtrl = StreamController<List<FriendRequestItem>>.broadcast(
      onListen: () => _replayRequests(_outgoingCtrl, _lastOutgoing),
    );
    _incomingSub = _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .listen(
          (snap) {
            _lastIncoming = _pendingOf(snap);
            _incomingCtrl?.add(_lastIncoming);
          },
          onError: (Object error) {
            debugPrint('Friend incoming stream failed: $error');
          },
        );
    _outgoingSub = _db
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .listen(
          (snap) {
            _lastOutgoing = _pendingOf(snap);
            _outgoingCtrl?.add(_lastOutgoing);
          },
          onError: (Object error) {
            debugPrint('Friend outgoing stream failed: $error');
          },
        );
  }

  void _replayRequests(
    StreamController<List<FriendRequestItem>>? controller,
    List<FriendRequestItem> last,
  ) {
    scheduleMicrotask(() {
      if (controller == null || controller.isClosed) return;
      controller.add(last);
    });
  }

  void _disposeTodoStreams() {
    _incomingTodoSub?.cancel();
    _outgoingTodoSub?.cancel();
    _incomingTodoSub = null;
    _outgoingTodoSub = null;
    _incomingTodoCtrl?.close();
    _outgoingTodoCtrl?.close();
    _incomingTodoCtrl = null;
    _outgoingTodoCtrl = null;
    _todoStreamUid = null;
    _lastIncomingTodos = const [];
    _lastOutgoingTodos = const [];
    _incomingTodoAll = const [];
    _outgoingTodoAll = const [];
  }

  void _bindTodoStreams() {
    final uid = _uid;
    if (uid == null) {
      _disposeTodoStreams();
      return;
    }
    if (_todoStreamUid == uid &&
        _incomingTodoCtrl != null &&
        _outgoingTodoCtrl != null) {
      unawaited(_syncSharedTodos());
      return;
    }
    _disposeTodoStreams();
    _todoStreamUid = uid;
    _incomingTodoCtrl = StreamController<List<TodoRequestItem>>.broadcast(
      onListen: () => _replayTodos(_incomingTodoCtrl, _lastIncomingTodos),
    );
    _outgoingTodoCtrl = StreamController<List<TodoRequestItem>>.broadcast(
      onListen: () => _replayTodos(_outgoingTodoCtrl, _lastOutgoingTodos),
    );
    _incomingTodoSub = _db
        .collection('todo_requests')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .listen(
          (snap) {
            final items = _todosOf(snap);
            _incomingTodoAll = items;
            _lastIncomingTodos = [
              for (final item in items)
                if (item.isPending) item,
            ];
            _incomingTodoCtrl?.add(_lastIncomingTodos);
            unawaited(_syncSharedTodos());
          },
          onError: (Object error) {
            debugPrint('Shared todo incoming stream failed: $error');
          },
        );
    _outgoingTodoSub = _db
        .collection('todo_requests')
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .listen(
          (snap) {
            final previousIds = {
              for (final item in _outgoingTodoAll) item.id,
            };
            final items = _todosOf(snap);
            _outgoingTodoAll = items;
            _lastOutgoingTodos = [
              for (final item in items)
                if (item.isPending) item,
            ];
            _outgoingTodoCtrl?.add(_lastOutgoingTodos);
            unawaited(_recoverOutgoing(previousIds, items));
            unawaited(_syncSharedTodos());
          },
          onError: (Object error) {
            debugPrint('Shared todo outgoing stream failed: $error');
          },
        );
  }

  void _replayTodos(
    StreamController<List<TodoRequestItem>>? controller,
    List<TodoRequestItem> last,
  ) {
    scheduleMicrotask(() {
      if (controller == null || controller.isClosed) return;
      controller.add(last);
    });
  }

  List<TodoRequestItem> _todosOf(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final items = [
      for (final doc in snap.docs) TodoRequestItem.fromMap(doc.id, doc.data()),
    ];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> _materializeAccepted(List<TodoRequestItem> items) {
    return _syncSharedTodos(extra: items);
  }

  Future<void> _materializeById(String requestId) async {
    try {
      final snap = await _db.collection('todo_requests').doc(requestId).get();
      if (!snap.exists) return;
      await _materializeAccepted([
        TodoRequestItem.fromMap(snap.id, snap.data() ?? {}),
      ]);
    } catch (error) {
      debugPrint('Shared todo load failed: $error');
    }
  }

  Future<void> _recoverOutgoing(
    Set<String> previousIds,
    List<TodoRequestItem> current,
  ) async {
    final have = {for (final item in current) item.id};
    final missing = previousIds.difference(have);
    if (missing.isEmpty) return;
    final extras = <TodoRequestItem>[];
    for (final id in missing) {
      try {
        final snap = await _db.collection('todo_requests').doc(id).get();
        if (!snap.exists) continue;
        extras.add(TodoRequestItem.fromMap(snap.id, snap.data() ?? {}));
      } catch (error) {
        debugPrint('Shared todo recover failed: $error');
      }
    }
    if (extras.isEmpty) return;
    final known = {for (final item in _outgoingTodoAll) item.id};
    _outgoingTodoAll = [
      ..._outgoingTodoAll,
      for (final item in extras)
        if (!known.contains(item.id)) item,
    ];
    await _syncSharedTodos();
  }

  Future<void> _syncSharedTodos({List<TodoRequestItem>? extra}) {
    final seen = <String>{};
    final accepted = <TodoRequestItem>[];
    final gone = <String>{};
    for (final item in [
      ..._incomingTodoAll,
      ..._outgoingTodoAll,
      ...?extra,
    ]) {
      if (!seen.add(item.id)) continue;
      if (item.isAccepted) {
        accepted.add(item);
      } else if (item.isGone) {
        gone.add(item.id);
      }
    }
    if (accepted.isEmpty && gone.isEmpty) return Future.value();
    final previous = _materializeWork;
    final work = () async {
      try {
        await previous;
      } catch (_) {}
      final read = _readCalendar;
      final write = _writeCalendar;
      if (read == null) return;
      try {
        final uid = _uid;
        final current = await read();
        final byShared = <String, List<CalendarEvent>>{};
        for (final event in current) {
          final sharedId = event.sharedId ?? '';
          if (sharedId.isEmpty) continue;
          (byShared[sharedId] ??= []).add(event);
        }
        var next = [
          for (final event in current)
            if ((event.sharedId ?? '').isEmpty ||
                !gone.contains(event.sharedId))
              event,
        ];
        var changed = next.length != current.length;
        for (final item in accepted) {
          final existing = byShared[item.id] ?? const <CalendarEvent>[];
          final desired = item.toEvents(
            uid: uid,
            category: existing.isEmpty
                ? await _categoryFor(item, uid)
                : null,
            existing: existing,
          );
          if (_sameSharedEvents(existing, desired)) continue;
          next = [
            for (final event in next)
              if ((event.sharedId ?? '') != item.id) event,
            ...desired,
          ];
          changed = true;
        }
        if (!changed) return;
        if (write != null) {
          await write(next);
        } else {
          await _applySharedFallback(current, next);
        }
        _onCalendarChanged?.call();
      } catch (error) {
        debugPrint('Shared todo calendar sync failed: $error');
      }
    }();
    _materializeWork = work;
    return work;
  }

  bool _sameSharedEvents(List<CalendarEvent> a, List<CalendarEvent> b) {
    if (a.length != b.length) return false;
    final byId = {for (final event in a) event.id: event};
    for (final event in b) {
      final other = byId[event.id];
      if (other == null || !_sameSharedEvent(other, event)) return false;
    }
    return true;
  }

  bool _sameSharedEvent(CalendarEvent a, CalendarEvent b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.memo.trim() == b.memo.trim() &&
        a.day.year == b.day.year &&
        a.day.month == b.day.month &&
        a.day.day == b.day.day &&
        a.startMinutes == b.startMinutes &&
        a.endMinutes == b.endMinutes &&
        a.groupId == b.groupId &&
        a.repeatId == b.repeatId &&
        a.sharedMine == b.sharedMine &&
        a.sharedPeer == b.sharedPeer &&
        a.completed == b.completed &&
        a.categoryId == b.categoryId &&
        a.categoryName == b.categoryName &&
        a.categoryColor == b.categoryColor;
  }

  Future<void> _applySharedFallback(
    List<CalendarEvent> current,
    List<CalendarEvent> next,
  ) async {
    final add = _addCalendar;
    final update = _updateCalendar;
    if (add == null && update == null) return;
    final have = {for (final event in current) event.id: event};
    for (final event in next) {
      final before = have[event.id];
      if (before == null) {
        await add?.call(event);
      } else if (!_sameSharedEvent(before, event)) {
        await update?.call(event);
      }
    }
  }

  Future<EventCategory> _categoryFor(TodoRequestItem item, String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = EventCategoryLocalDataSource(prefs).fetchAll();
    if (uid != null && uid == item.fromUid) {
      for (final category in categories) {
        if (category.name == item.categoryName) return category;
      }
      return EventCategory(
        id: '',
        name: item.categoryName,
        color: item.categoryColor,
      );
    }
    final events = await _readCalendar?.call() ?? const <CalendarEvent>[];
    return LastEventCategoryPreference.resolve(
          events: events,
          categories: categories,
          storedId: LastEventCategoryPreference(prefs: prefs).id,
        ) ??
        EventCategory.fallback;
  }

  Future<CalendarEvent> toggleComplete(CalendarEvent event) async {
    if (!event.isShared) {
      return event.copyWith(completed: !event.completed);
    }
    final uid = _uid;
    final sharedId = event.sharedId!.trim();
    final nextMine = !event.sharedMine;
    var peerDone = event.sharedPeer || (event.completed && event.sharedMine);
    if (uid != null && sharedId.isNotEmpty) {
      peerDone = await _setTodoMineCompleted(
        sharedId,
        uid,
        nextMine,
        day: event.day,
        fallback: peerDone,
      );
    }
    return event.copyWith(
      sharedMine: nextMine,
      sharedPeer: peerDone,
      completed: nextMine && peerDone,
    );
  }

  Future<bool> _setTodoMineCompleted(
    String requestId,
    String uid,
    bool mine, {
    DateTime? day,
    bool fallback = false,
  }) async {
    try {
      final ref = _db.collection('todo_requests').doc(requestId);
      final snap = await ref.get();
      if (!snap.exists) return fallback;
      final item = TodoRequestItem.fromMap(snap.id, snap.data() ?? {});
      if (!item.isAccepted) return fallback;
      if (uid != item.fromUid && uid != item.toUid) return fallback;
      final useDates = item.days.length > 1 ||
          item.fromCompletedDates != null ||
          item.toCompletedDates != null;
      if (!useDates || day == null) {
        final field = uid == item.fromUid ? 'fromCompleted' : 'toCompleted';
        await ref.update({
          field: mine,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        return uid == item.fromUid ? item.toCompleted : item.fromCompleted;
      }
      final key = TodoRequestItem.dateKey(day);
      final mineField =
          uid == item.fromUid ? 'fromCompletedDates' : 'toCompletedDates';
      final boolField = uid == item.fromUid ? 'fromCompleted' : 'toCompleted';
      final mineKeys = item.completedKeys(uid, mine: true);
      final peerKeys = item.completedKeys(uid, mine: false);
      if (mine) {
        if (!mineKeys.contains(key)) mineKeys.add(key);
      } else {
        mineKeys.remove(key);
      }
      await ref.update({
        mineField: mineKeys,
        boolField: mineKeys.length >= item.days.length && item.days.isNotEmpty,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return peerKeys.contains(key);
    } catch (error) {
      debugPrint('Shared todo complete failed: $error');
      return fallback;
    }
  }

  Stream<List<FriendProfile>> friends() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    final remote = _db
        .collection('friendships')
        .doc(uid)
        .collection('friends')
        .snapshots();
    return Stream<List<FriendProfile>>.multi((controller) {
      var items = const <FriendProfile>[];
      var ready = false;
      void emit() {
        if (!ready || controller.isClosed) return;
        final ordered = FriendOrderPreference.instance.apply(items);
        unawaited(
          FriendHomePreference.instance.seedIfNeeded([
            for (final friend in ordered) friend.uid,
          ]),
        );
        controller.add(ordered);
      }

      final order = FriendOrderPreference.instance.listenable;
      order.addListener(emit);
      final sub = remote.listen(
        (snap) {
          final rows = [
            for (final doc in snap.docs)
              (
                profile: FriendProfile.fromMap(doc.data(), uid: doc.id),
                createdAt: (doc.data()['createdAt'] as num?)?.toInt() ?? 0,
              ),
          ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          items = [for (final row in rows) row.profile];
          ready = true;
          emit();
        },
        onError: controller.addError,
      );
      controller.onCancel = () {
        order.removeListener(emit);
        unawaited(sub.cancel());
      };
    });
  }

  Future<void> reorderFavorites(
    List<FriendProfile> favorites, {
    required int oldIndex,
    required int newIndex,
  }) {
    return FriendFavoritePreference.instance.reorder(
      favorites,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  Future<void> reorderRegulars(
    List<FriendProfile> regulars, {
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= regulars.length) return Future.value();
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target > regulars.length - 1) target = regulars.length - 1;
    final next = [...regulars];
    final moved = next.removeAt(oldIndex);
    next.insert(target, moved);
    return FriendOrderPreference.instance.replaceSubsequence([
      for (final friend in next) friend.uid,
    ]);
  }

  Future<void> reorderFriends(
    List<FriendProfile> friends, {
    required int oldIndex,
    required int newIndex,
  }) {
    final favCount = FriendFavoritePreference.instance.countIn(friends);
    if (oldIndex < favCount) {
      return reorderFavorites(
        friends,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
    }
    return reorderRegulars(
      [
        for (final friend in friends)
          if (!FriendFavoritePreference.instance.contains(friend.uid)) friend,
      ],
      oldIndex: oldIndex - favCount,
      newIndex: newIndex - favCount,
    );
  }

  Future<void> reorderHomeFriends(
    List<FriendProfile> friends, {
    required int oldIndex,
    required int newIndex,
  }) {
    return reorderFriends(
      friends,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  Future<FriendProfile?> lookupByCode(String code) async {
    final handle = _normalize(code);
    try {
      return await _lookupViaStore(handle);
    } catch (error) {
      debugPrint('Friend lookup store failed: $error');
    }
    try {
      final data = await _call('lookupFriendCode', {'code': handle});
      final next = FriendProfile.fromMap(data);
      if (next.uid.isEmpty || next.friendCode.isEmpty) return null;
      return next;
    } on FriendException catch (error) {
      if (error.code == 'no-user' || error.code == 'not-found') return null;
      rethrow;
    }
  }

  Future<bool> isFriend(String uid) async {
    final me = _uid;
    if (me == null || uid.isEmpty) return false;
    try {
      final snap = await _db
          .collection('friendships')
          .doc(me)
          .collection('friends')
          .doc(uid)
          .get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<({String status, String requestId})> sendRequest(String code) async {
    final me = profile.value;
    if (me == null || !me.hasIdentity) {
      throw const FriendException('needs-profile');
    }
    if (kIsWeb) {
      return _sendViaStore(code);
    }
    try {
      final result = await _call('sendFriendRequest', {'code': _normalize(code)});
      return (
        status: '${result['status'] ?? 'pending'}',
        requestId: '${result['requestId'] ?? ''}',
      );
    } catch (error) {
      if (error is FriendException && !_retrySend(error)) rethrow;
      debugPrint('Friend send function failed: $error');
      return _sendViaStore(code);
    }
  }

  bool _retrySend(FriendException error) {
    return switch (error.code) {
      'self' ||
      'already-friends' ||
      'already-sent' ||
      'needs-code' ||
      'needs-profile' ||
      'no-user' ||
      'not-found' ||
      'bad-code' =>
        false,
      _ => true,
    };
  }

  Future<void> accept(String requestId) async {
    try {
      await _call('acceptFriendRequest', {'requestId': requestId});
    } catch (error) {
      debugPrint('Friend accept function failed: $error');
      await _respondViaStore(requestId, accept: true);
    }
  }

  Future<void> decline(String requestId) async {
    try {
      await _call('declineFriendRequest', {'requestId': requestId});
    } catch (error) {
      debugPrint('Friend decline function failed: $error');
      await _respondViaStore(requestId, accept: false);
    }
  }

  Future<void> cancel(String requestId) async {
    try {
      await _call('cancelFriendRequest', {'requestId': requestId});
    } catch (error) {
      debugPrint('Friend cancel function failed: $error');
      await _cancelViaStore(requestId);
    }
  }

  Future<void> remove(String uid) async {
    try {
      await _call('removeFriend', {'uid': uid});
    } catch (error) {
      debugPrint('Friend remove function failed: $error');
      await _removeViaStore(uid);
    }
    await FriendHomePreference.instance.forget(uid);
    await FriendFavoritePreference.instance.forget(uid);
  }

  Future<({String status, String requestId})> sendTodo({
    required FriendProfile to,
    required String title,
    required DateTime date,
    String memo = '',
    String categoryName = CalendarEvent.defaultCategoryName,
    int categoryColor = CalendarEvent.defaultCategoryColor,
    int? startMinutes,
    int? endMinutes,
    List<DateTime>? days,
    String dateMode = 'single',
  }) async {
    final clean = title.trim();
    if (clean.isEmpty || clean.length > 80) {
      throw const FriendException('bad-todo');
    }
    final allDays = _sharedDays(days ?? [date]);
    final mode = _sharedMode(dateMode, allDays);
    return _sendTodoViaStore(
      to: to,
      title: clean,
      date: allDays.first,
      memo: memo,
      categoryName: categoryName,
      categoryColor: categoryColor,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      days: allDays,
      dateMode: mode,
    );
  }

  Future<void> acceptTodo(String requestId) async {
    try {
      await _call('acceptSharedTodo', {'requestId': requestId});
    } catch (error) {
      debugPrint('Shared todo accept function failed: $error');
      await _respondTodoViaStore(requestId, 'accepted');
      return;
    }
    await _materializeById(requestId);
  }

  Future<void> declineTodo(String requestId) async {
    try {
      await _call('declineSharedTodo', {'requestId': requestId});
    } catch (error) {
      debugPrint('Shared todo decline function failed: $error');
      await _respondTodoViaStore(requestId, 'declined');
    }
  }

  Future<void> cancelTodo(String requestId) async {
    try {
      await _call('cancelSharedTodo', {'requestId': requestId});
    } catch (error) {
      debugPrint('Shared todo cancel function failed: $error');
      await _respondTodoViaStore(requestId, 'cancelled');
    }
  }

  final _removingShared = <String>{};

  Future<void> editShared(
    CalendarEvent event, {
    List<DateTime>? days,
    String dateMode = 'single',
  }) async {
    final id = event.sharedId?.trim() ?? '';
    if (id.isEmpty) return;
    final allDays = _sharedDays(days ?? [event.day]);
    final mode = _sharedMode(dateMode, allDays);
    await _reshapeSharedLocal(event, allDays, mode);
    final payload = {
      'requestId': id,
      'title': event.title,
      'date': _date(allDays.first),
      'dates': [for (final day in allDays) _date(day)],
      'dateMode': mode,
      'memo': event.memo,
      'startMinutes': ?event.startMinutes,
      'endMinutes': ?event.endMinutes,
    };
    try {
      if (kIsWeb) {
        try {
          await _editTodoViaStore(event, days: allDays, dateMode: mode);
        } catch (error) {
          debugPrint('Shared todo edit store failed: $error');
          await _call('editSharedTodo', payload);
        }
        return;
      }
      try {
        await _call('editSharedTodo', payload);
      } catch (error) {
        debugPrint('Shared todo edit function failed: $error');
        await _editTodoViaStore(event, days: allDays, dateMode: mode);
      }
    } catch (error) {
      debugPrint('Shared todo edit failed: $error');
    }
  }

  List<DateTime> _sharedDays(List<DateTime> days) {
    final seen = <String>{};
    final all = <DateTime>[];
    for (final date in days) {
      final day = DateTime(date.year, date.month, date.day);
      if (!seen.add(TodoRequestItem.dateKey(day))) continue;
      all.add(day);
      if (all.length >= TodoRequestItem.maxDays) break;
    }
    all.sort((a, b) => a.compareTo(b));
    return all.isEmpty ? [DateTime.now()] : all;
  }

  String _sharedMode(String raw, List<DateTime> days) {
    return TodoRequestItem.parseMode(raw, days);
  }

  Future<void> _reshapeSharedLocal(
    CalendarEvent event,
    List<DateTime> days,
    String dateMode,
  ) async {
    final read = _readCalendar;
    final write = _writeCalendar;
    final sharedId = event.sharedId?.trim() ?? '';
    if (read == null || write == null || sharedId.isEmpty) return;
    final current = await read();
    final existing = [
      for (final item in current)
        if ((item.sharedId ?? '') == sharedId) item,
    ];
    final byDay = <String, CalendarEvent>{
      for (final item in existing) TodoRequestItem.dateKey(item.day): item,
    };
    final range = dateMode == 'range' && days.length >= 2;
    final repeat = dateMode == 'repeat';
    final sample = existing.isEmpty ? null : existing.first;
    final groupId = range ? (sample?.groupId ?? 'shared_${sharedId}_g') : null;
    final repeatId = repeat ? (sample?.repeatId ?? 'shared_${sharedId}_r') : null;
    final desired = <CalendarEvent>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final prev = byDay[TodoRequestItem.dateKey(day)];
      desired.add(
        CalendarEvent(
          id: prev?.id ??
              (days.length == 1
                  ? 'shared_$sharedId'
                  : 'shared_${sharedId}_${TodoRequestItem.dateKey(day)}'),
          title: event.title,
          date: day,
          memo: event.memo,
          categoryId: event.categoryId,
          categoryName: event.categoryName,
          categoryColor: event.categoryColor,
          startMinutes: event.startMinutes,
          endMinutes: event.endMinutes,
          sortOrder: prev?.sortOrder ?? event.sortOrder + i,
          groupId: groupId,
          repeatId: repeatId,
          sharedId: sharedId,
          sharedMine: prev?.sharedMine ?? false,
          sharedPeer: prev?.sharedPeer ?? false,
          completed: (prev?.sharedMine ?? false) && (prev?.sharedPeer ?? false),
        ),
      );
    }
    if (_sameSharedEvents(existing, desired)) return;
    await write([
      for (final item in current)
        if ((item.sharedId ?? '') != sharedId) item,
      ...desired,
    ]);
    _onCalendarChanged?.call();
  }

  Future<void> removeShared(String requestId) async {
    final id = requestId.trim();
    if (id.isEmpty || !_removingShared.add(id)) return;
    try {
      try {
        await _call('removeSharedTodo', {'requestId': id});
      } catch (error) {
        debugPrint('Shared todo remove function failed: $error');
        await _removeTodoViaStore(id);
      }
    } finally {
      _removingShared.remove(id);
    }
  }

  Future<({String status, String requestId})> _sendTodoViaStore({
    required FriendProfile to,
    required String title,
    required DateTime date,
    required String memo,
    required String categoryName,
    required int categoryColor,
    int? startMinutes,
    int? endMinutes,
    List<DateTime>? days,
    String dateMode = 'single',
  }) async {
    final me = profile.value;
    final uid = (me?.uid.isNotEmpty == true ? me!.uid : _uid) ?? '';
    if (me == null || !me.hasIdentity || uid.isEmpty) {
      throw const FriendException('needs-profile');
    }
    if (to.uid.isEmpty || to.uid == uid) {
      throw const FriendException('self');
    }
    if (!await isFriend(to.uid)) {
      throw const FriendException('not-friends');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${uid}_${to.uid}_$now';
    await _db.collection('todo_requests').doc(id).set({
      'fromUid': uid,
      'toUid': to.uid,
      'fromName': me.displayName,
      'fromCode': me.friendCode,
      'fromPhotoURL': me.photoURL,
      'toName': to.displayName,
      'toCode': to.friendCode,
      'toPhotoURL': to.photoURL,
      'title': title,
      'date': _date(date),
      'dates': [for (final day in days ?? [date]) _date(day)],
      'dateMode': dateMode,
      'memo': memo.trim(),
      'categoryName': categoryName.trim(),
      'categoryColor': categoryColor,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'status': 'pending',
      'fromCompleted': false,
      'toCompleted': false,
      'createdAt': now,
      'participants': [uid, to.uid],
    });
    return (status: 'pending', requestId: id);
  }

  Future<void> _respondTodoViaStore(String requestId, String status) async {
    final me = _uid;
    if (me == null) throw const FriendException('login-required');
    final ref = _db.collection('todo_requests').doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) throw const FriendException('not-found');
    final item = TodoRequestItem.fromMap(snap.id, snap.data() ?? {});
    if (!item.isPending) throw const FriendException('not-allowed');
    if (status == 'cancelled') {
      if (item.fromUid != me) throw const FriendException('not-allowed');
    } else if (item.toUid != me) {
      throw const FriendException('not-allowed');
    }
    await ref.update({
      'status': status,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (status == 'accepted') {
      await _materializeAccepted([item.copyWithStatus(status)]);
    }
  }

  Future<void> _editTodoViaStore(
    CalendarEvent event, {
    List<DateTime>? days,
    String dateMode = 'single',
  }) async {
    final me = _uid;
    final id = event.sharedId?.trim() ?? '';
    if (me == null) throw const FriendException('login-required');
    if (id.isEmpty) return;
    final title = event.title.trim();
    if (title.isEmpty || title.length > 80) {
      throw const FriendException('bad-todo');
    }
    final allDays = _sharedDays(days ?? [event.day]);
    final mode = _sharedMode(dateMode, allDays);
    final ref = _db.collection('todo_requests').doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    final item = TodoRequestItem.fromMap(snap.id, snap.data() ?? {});
    if (item.fromUid != me && item.toUid != me) {
      throw const FriendException('not-allowed');
    }
    if (!item.isAccepted) return;
    await ref.update({
      'title': title,
      'date': _date(allDays.first),
      'dates': [for (final day in allDays) _date(day)],
      'dateMode': mode,
      'memo': event.memo.trim(),
      'startMinutes': event.startMinutes ?? FieldValue.delete(),
      'endMinutes': event.endMinutes ?? FieldValue.delete(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _removeTodoViaStore(String requestId) async {
    final me = _uid;
    if (me == null) throw const FriendException('login-required');
    final ref = _db.collection('todo_requests').doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final item = TodoRequestItem.fromMap(snap.id, snap.data() ?? {});
    if (item.fromUid != me && item.toUid != me) {
      throw const FriendException('not-allowed');
    }
    if (item.isGone) return;
    await ref.update({
      'status': 'removed',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _requestSnap(
    String id,
  ) async {
    try {
      final snap = await _db.collection('friend_requests').doc(id).get();
      return snap.exists ? snap : null;
    } catch (error) {
      debugPrint('Friend request get failed: $error');
      return null;
    }
  }

  Future<FriendProfile> _ensureViaStore({String? hint}) async {
    final uid = _uid;
    if (uid == null) throw const FriendException('login-required');
    final ref = _db.collection('profiles').doc(uid);
    final snap = await ref.get();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (snap.exists) {
      return _profileFromStore(uid, snap.data() ?? {});
    }
    final displayName = (hint ?? '').trim();
    await ref.set({
      'displayName': displayName,
      'friendCode': '',
      'customName': false,
      'updatedAt': now,
    });
    return _profileFromStore(uid, {
      'displayName': displayName,
      'friendCode': '',
    });
  }

  Future<FriendProfile> _claimViaStore(String raw, {String? hint}) async {
    final uid = _uid;
    if (uid == null) throw const FriendException('login-required');
    final code = _parseCode(raw);
    final profileRef = _db.collection('profiles').doc(uid);
    final codeRef = _db.collection('friend_codes').doc(code);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.runTransaction((tx) async {
      final profileSnap = await tx.get(profileRef);
      final data = Map<String, dynamic>.from(profileSnap.data() ?? {});
      final current = '${data['friendCode'] ?? ''}'.trim();
      final hadUsable = _isUsableCode(current);
      if (hadUsable && current == code) return;
      if (hadUsable) {
        final changedAt = (data['friendCodeChangedAt'] as num?)?.toInt() ?? 0;
        if (changedAt > 0 && now < changedAt + _codeCooldownMs) {
          throw const FriendException('code-cooldown');
        }
      }
      final taken = await tx.get(codeRef);
      if (taken.exists && '${taken.data()?['uid'] ?? ''}' != uid) {
        throw const FriendException('taken');
      }
      if (current.isNotEmpty && current != code) {
        tx.delete(_db.collection('friend_codes').doc(current));
      }
      tx.set(codeRef, {'uid': uid});
      final customName = data['customName'] == true;
      final hinted = (hint ?? '').trim();
      tx.set(
        profileRef,
        {
          if (!customName && hinted.isNotEmpty) 'displayName': hinted,
          'friendCode': code,
          'friendCodeChangedAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
    });
    final saved = await profileRef.get();
    return _profileFromStore(uid, saved.data() ?? {});
  }

  Future<FriendProfile> _renameViaStore(String raw) async {
    final uid = _uid;
    if (uid == null) throw const FriendException('login-required');
    final name = raw
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty || name.length > 16 || RegExp(r'[#＃@＠]').hasMatch(name)) {
      throw const FriendException('bad-name');
    }
    final ref = _db.collection('profiles').doc(uid);
    await ref.set({
      'displayName': name,
      'customName': true,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    final saved = await ref.get();
    return _profileFromStore(uid, saved.data() ?? {});
  }

  FriendProfile _profileFromStore(String uid, Map<String, dynamic> data) {
    final stored = '${data['friendCode'] ?? ''}'.trim();
    final usable = _isUsableCode(stored);
    final changedAt = (data['friendCodeChangedAt'] as num?)?.toInt() ?? 0;
    final name = '${data['displayName'] ?? ''}'.trim();
    return FriendProfile(
      uid: uid,
      displayName: name,
      friendCode: usable ? stored : '',
      suggestedCode: _suggestCode(name),
      needsCode: !usable,
      nextChangeAt: usable && changedAt > 0 ? changedAt + _codeCooldownMs : 0,
      photoURL: '${data['photoURL'] ?? ''}'.trim(),
    );
  }

  Future<FriendProfile?> _lookupViaStore(String handle) async {
    final code = _normalize(handle);
    if (code.isEmpty || !_ready) return null;
    final codeSnap = await _db.collection('friend_codes').doc(code).get();
    if (!codeSnap.exists) return null;
    final uid = '${codeSnap.data()?['uid'] ?? ''}';
    if (uid.isEmpty) return null;
    final profileSnap = await _db.collection('profiles').doc(uid).get();
    if (!profileSnap.exists) return null;
    final next = _profileFromStore(uid, profileSnap.data() ?? {});
    if (next.friendCode.isEmpty) return null;
    return next;
  }

  Future<({String status, String requestId})> _sendViaStore(String code) async {
    final cached = profile.value;
    final uid = (cached?.uid.isNotEmpty == true ? cached!.uid : _uid) ?? '';
    if (cached == null || !cached.hasIdentity || uid.isEmpty) {
      throw const FriendException('needs-profile');
    }
    final me = FriendProfile(
      uid: uid,
      displayName: cached.displayName,
      friendCode: cached.friendCode,
      photoURL: cached.photoURL,
    );
    final other = await _lookupViaStore(_normalize(code));
    if (other == null) throw const FriendException('no-user');
    if (other.uid == me.uid) throw const FriendException('self');
    if (await isFriend(other.uid)) {
      throw const FriendException('already-friends');
    }
    final existing = await _requestSnap('${me.uid}_${other.uid}');
    if (existing != null &&
        FriendRequestItem.fromMap(existing.id, existing.data() ?? {}).isPending) {
      throw const FriendException('already-sent');
    }
    final reverse = await _requestSnap('${other.uid}_${me.uid}');
    if (reverse != null &&
        FriendRequestItem.fromMap(reverse.id, reverse.data() ?? {}).isPending) {
      await _writeFriendship(me, other, reverse.id);
      await reverse.reference.update({
        'status': 'accepted',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return (status: 'accepted', requestId: reverse.id);
    }
    final id = '${me.uid}_${other.uid}';
    await _db.collection('friend_requests').doc(id).set({
      'fromUid': me.uid,
      'toUid': other.uid,
      'fromName': me.displayName,
      'fromCode': me.friendCode,
      'fromPhotoURL': me.photoURL,
      'toName': other.displayName,
      'toCode': other.friendCode,
      'toPhotoURL': other.photoURL,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'participants': [me.uid, other.uid],
    });
    return (status: 'pending', requestId: id);
  }

  Future<void> _respondViaStore(String requestId, {required bool accept}) async {
    final me = profile.value;
    if (me == null) throw const FriendException('login-required');
    final ref = _db.collection('friend_requests').doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) throw const FriendException('not-found');
    final item = FriendRequestItem.fromMap(snap.id, snap.data() ?? {});
    if (item.toUid != me.uid || !item.isPending) {
      throw const FriendException('not-allowed');
    }
    if (accept) {
      final other = FriendProfile(
        uid: item.fromUid,
        displayName: item.fromName,
        friendCode: item.fromCode,
        photoURL: item.fromPhotoURL,
      );
      await _writeFriendship(me, other, requestId);
    }
    await ref.update({
      'status': accept ? 'accepted' : 'declined',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _cancelViaStore(String requestId) async {
    final me = _uid;
    if (me == null) throw const FriendException('login-required');
    final ref = _db.collection('friend_requests').doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) throw const FriendException('not-found');
    final item = FriendRequestItem.fromMap(snap.id, snap.data() ?? {});
    if (item.fromUid != me || !item.isPending) {
      throw const FriendException('not-allowed');
    }
    await ref.update({
      'status': 'cancelled',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _removeViaStore(String uid) async {
    final me = _uid;
    if (me == null || uid.isEmpty) {
      throw const FriendException('login-required');
    }
    final batch = _db.batch();
    batch.delete(
      _db.collection('friendships').doc(me).collection('friends').doc(uid),
    );
    batch.delete(
      _db.collection('friendships').doc(uid).collection('friends').doc(me),
    );
    await batch.commit();
  }

  Future<void> _writeFriendship(
    FriendProfile me,
    FriendProfile other,
    String requestId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _db.batch();
    batch.set(
      _db.collection('friendships').doc(me.uid).collection('friends').doc(other.uid),
      {
        'uid': other.uid,
        'displayName': other.displayName,
        'friendCode': other.friendCode,
        'photoURL': other.photoURL,
        'createdAt': now,
        'requestId': requestId,
      },
    );
    batch.set(
      _db.collection('friendships').doc(other.uid).collection('friends').doc(me.uid),
      {
        'uid': me.uid,
        'displayName': me.displayName,
        'friendCode': me.friendCode,
        'photoURL': me.photoURL,
        'createdAt': now,
        'requestId': requestId,
      },
    );
    await batch.commit();
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

  int _codeCooldownDays(Object error) {
    final fromProfile = profile.value?.cooldownDays ?? 0;
    if (fromProfile > 0) return fromProfile;
    if (error is FirebaseFunctionsException) {
      final details = error.details;
      if (details is Map) {
        final at = (details['nextChangeAt'] as num?)?.toInt() ?? 0;
        final left = at - DateTime.now().millisecondsSinceEpoch;
        if (left > 0) return (left / 86400000).ceil();
      }
    }
    return 30;
  }

  String messageOf(Object error) {
    final code = error is FriendException
        ? error.code
        : error is FirebaseFunctionsException
            ? error.message ?? error.code
            : '';
    return switch (code) {
      'no-user' || 'not-found' => AppStrings.friendsNotFound,
      'not-friends' => AppStrings.friendsNotFriends,
      'bad-todo' => AppStrings.friendsSharedTodoBad,
      'self' => AppStrings.friendsSelf,
      'already-friends' => AppStrings.friendsAlready,
      'already-sent' => AppStrings.friendsAlreadySent,
      'taken' => AppStrings.friendsCodeTaken,
      'bad-code' => AppStrings.friendsCodeBad,
      'bad-name' => AppStrings.friendsNameBad,
      'bad-photo' => AppStrings.friendsPhotoTooBig,
      'needs-code' => AppStrings.friendsCodeNeed,
      'needs-profile' => AppStrings.friendsProfileNeed,
      'code-cooldown' => AppStrings.friendsCodeCooldown(_codeCooldownDays(error)),
      'rate-limited' || 'resource-exhausted' => AppStrings.friendsRateLimited,
      'unauthenticated' || 'login-required' => AppStrings.friendsNeedLogin,
      _ => AppStrings.friendsFailed,
    };
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
    if (!FriendCategoryPreference.instance.isPublic(event.categoryId)) {
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

  static const _codeCooldownMs = 30 * 24 * 60 * 60 * 1000;
  static const _reservedCodes = {
    'pluto',
    '플루토',
    'admin',
    'official',
    'support',
    'help',
  };

  String _normalize(String raw) {
    return raw
        .replaceAll('＃', '#')
        .replaceAll('＠', '@')
        .replaceAll(RegExp(r'\s+'), '')
        .trim()
        .replaceFirst(RegExp(r'^[@#]+'), '')
        .toLowerCase();
  }

  String _parseCode(String raw) {
    final code = _normalize(raw);
    if (!_isUsableCode(code)) {
      throw const FriendException('bad-code');
    }
    return code;
  }

  bool _isUsableCode(String code) {
    if (code.length < 2 || code.length > 32) return false;
    if (_reservedCodes.contains(code)) return false;
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(code)) return false;
    if (code.contains('..')) return false;
    return true;
  }

  String _suggestCode(String name) {
    final code = _normalize(name.replaceAll(RegExp(r'[#＃@＠/\\]'), ''));
    return _isUsableCode(code) ? code : '';
  }

  static const _actions = {
    'ensureFriendProfile': 'ensure',
    'claimFriendCode': 'claim',
    'updateFriendDisplayName': 'rename',
    'updateFriendPhoto': 'photo',
    'lookupFriendCode': 'lookup',
    'sendFriendRequest': 'send',
    'acceptFriendRequest': 'accept',
    'declineFriendRequest': 'decline',
    'cancelFriendRequest': 'cancel',
    'removeFriend': 'remove',
    'sendSharedTodo': 'todo-send',
    'acceptSharedTodo': 'todo-accept',
    'declineSharedTodo': 'todo-decline',
    'cancelSharedTodo': 'todo-cancel',
    'removeSharedTodo': 'todo-remove',
    'editSharedTodo': 'todo-edit',
    'deleteFriendData': 'delete',
  };

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic>? data,
  ]) async {
    if (!_ready) {
      throw const FriendException('login-required');
    }
    final payload = <String, dynamic>{
      'action': _actions[name] ?? name,
      ...?data,
    };
    try {
      final result = await _fn
          .httpsCallable(
            name == 'deleteFriendData' ? name : 'friendAction',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 20),
            ),
          )
          .call(name == 'deleteFriendData' ? (data ?? {}) : payload);
      final body = result.data;
      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }
      return {};
    } on FirebaseFunctionsException catch (error) {
      throw FriendException(error.message ?? error.code);
    } on TimeoutException {
      throw const FriendException('rate-limited');
    }
  }
}
