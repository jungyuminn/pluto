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
import 'package:pluto/data/datasources/friend_category_preference.dart';
import 'package:pluto/data/datasources/friend_order_preference.dart';
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
    try {
      if (!kIsWeb) {
        await AppAuthService.instance
            .applySocialProfile()
            .timeout(const Duration(seconds: 3));
        hydrateSession();
      }
      await ensureProfile();
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
    try {
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
    } catch (error) {
      final fallback = await _readRemoteProfile();
      if (fallback != null) {
        profile.value = fallback;
        await _writeCachedProfile();
        return fallback;
      }
      rethrow;
    }
  }

  Future<FriendProfile?> _readRemoteProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final snap = await _db.collection('profiles').doc(uid).get();
      if (!snap.exists) return null;
      return FriendProfile.fromMap(snap.data() ?? {}, uid: uid);
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

  Future<FriendProfile> setFriendCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user == null ? null : AppAuthService.socialDisplayName(user);
    final data = await _call('claimFriendCode', {
      'code': code,
      'displayName': ?name,
    });
    final next = FriendProfile.fromMap(data);
    profile.value = next;
    _sessionUid = _uid;
    _sessionProfile = next;
    await _writeCachedProfile();
    return next;
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

  Stream<int> incomingCount() {
    return incomingRequests().map((items) => items.length);
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
        controller.add(FriendOrderPreference.instance.apply(items));
      }

      final order = FriendOrderPreference.instance.listenable;
      order.addListener(emit);
      final sub = remote.listen(
        (snap) {
          items = [
            for (final doc in snap.docs)
              FriendProfile.fromMap(doc.data(), uid: doc.id),
          ];
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

  Future<void> reorderFriends(
    List<FriendProfile> friends, {
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= friends.length) return Future.value();
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target > friends.length - 1) target = friends.length - 1;
    final next = [...friends];
    final moved = next.removeAt(oldIndex);
    next.insert(target, moved);
    return FriendOrderPreference.instance.setOrder([
      for (final friend in next) friend.uid,
    ]);
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

  Future<FriendProfile?> _lookupViaStore(String handle) async {
    if (handle.isEmpty || !_ready) return null;
    final codeSnap = await _db.collection('friend_codes').doc(handle).get();
    final uid = '${codeSnap.data()?['uid'] ?? ''}';
    if (uid.isEmpty) return null;
    final profileSnap = await _db.collection('profiles').doc(uid).get();
    if (!profileSnap.exists) return null;
    final next = FriendProfile.fromMap(profileSnap.data() ?? {}, uid: uid);
    if (next.friendCode.isEmpty) return null;
    return next;
  }

  Future<({String status, String requestId})> _sendViaStore(String code) async {
    final cached = profile.value;
    final uid = (cached?.uid.isNotEmpty == true ? cached!.uid : _uid) ?? '';
    if (cached == null || cached.friendCode.isEmpty || uid.isEmpty) {
      throw const FriendException('needs-code');
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
      'self' => AppStrings.friendsSelf,
      'already-friends' => AppStrings.friendsAlready,
      'already-sent' => AppStrings.friendsAlreadySent,
      'taken' => AppStrings.friendsCodeTaken,
      'bad-code' => AppStrings.friendsCodeBad,
      'bad-name' => AppStrings.friendsNameBad,
      'bad-photo' => AppStrings.friendsPhotoTooBig,
      'needs-code' => AppStrings.friendsCodeNeed,
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

  String _normalize(String raw) {
    return raw.replaceAll('＃', '#').replaceAll(RegExp(r'\s+'), '').trim();
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
