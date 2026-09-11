import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/data/datasources/calendar_event_local_datasource.dart';
import 'package:pluto/data/datasources/cloud_sync_files.dart';
import 'package:pluto/data/datasources/cloud_sync_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CloudOverlapChoice { merge, accountOnly }

enum CloudSwitchChoice { fresh, copy }

class CloudSyncService {
  CloudSyncService._();

  static final instance = CloudSyncService._();

  AppScope? _scope;
  StreamSubscription<dynamic>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteParentSub;
  Timer? _watch;
  var _ready = false;
  var _busy = false;
  var _epoch = 0;
  var _missedRemote = false;
  String? _uploadedHash;
  String? _vaultProvider;
  String? _listenKey;
  Future<void>? _inflight;
  var _writtenAt = 0;
  var _lastRemoteFiles = const <CloudFileEntry>[];

  bool get isReady =>
      Firebase.apps.isNotEmpty && AppAuthService.instance.isReady;

  bool get isBound =>
      _ready && AppAuthService.instance.user != null;

  void attach(AppScope scope) {
    _scope = scope;
    _authSub ??= AppAuthService.instance.authState.listen((user) {
      if (user == null) {
        _stop();
        return;
      }
      if (!_ready) return;
      unawaited(_resumeIfBound());
    });
    unawaited(_resumeIfBound());
  }

  Future<void> ensureBound(BuildContext context) async {
    final user = AppAuthService.instance.user;
    if (user == null) {
      _stop();
      return;
    }
    if (kIsWeb) {
      await reconcileAfterLogin(context);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(CloudSyncSnapshot.uidKey);
    final lastProvider = prefs.getString(CloudSyncSnapshot.providerKey);
    final provider = _currentProvider();
    if (lastUid == user.uid &&
        (lastProvider == null || lastProvider == provider)) {
      _vaultProvider = lastProvider ?? provider;
      _ready = true;
      _startWatch();
      unawaited(onResumed());
      return;
    }
    if (!context.mounted) return;
    await reconcileAfterLogin(context);
  }

  Future<void> reconcileAfterLogin(
    BuildContext context, {
    VoidCallback? onSettingsReady,
  }) async {
    final user = AppAuthService.instance.user;
    if (user == null) return;
    final scope = _scopeFor(context);
    final prefs = await SharedPreferences.getInstance();
    ++_epoch;
    _watch?.cancel();
    _watch = null;
    _ready = false;
    _busy = true;
    var parkedNow = false;
    try {
      final provider = _currentProvider();
      _vaultProvider = provider;
      final remote = await _fetch(user.uid, provider);
      debugPrint(
        'Cloud login uid=${user.uid} provider=$provider '
        'remoteHasContent=${remote.hasContent}',
      );
      if (!kIsWeb &&
          prefs.getString(CloudSyncSnapshot.uidKey) == null &&
          !prefs.containsKey(CloudSyncSnapshot.parkedDumpKey)) {
        await prefs.setString(
          CloudSyncSnapshot.parkedDumpKey,
          jsonEncode(CloudSyncSnapshot.dump(prefs)),
        );
        parkedNow = true;
      }
      if (remote.hasContent) {
        await CloudSyncSnapshot.apply(
          prefs,
          remote.dump,
          keys: CloudSyncSnapshot.settingKeys,
        );
        AppBackupService.hydrateSyncedSettings(scope);
      }
      onSettingsReady?.call();
      if (parkedNow) await CloudSyncFiles.parkLocal();
      if (remote.hasContent) {
        _lastRemoteFiles = remote.files;
        await _applyDump(
          scope,
          prefs,
          remote.dump,
          uid: user.uid,
          files: remote.files,
          replaceFiles: true,
        );
      } else {
        await _resetLocal(scope, prefs);
      }
      await _bind(prefs, user.uid, provider);
      _ready = true;
      _uploadedHash = remote.hasContent
          ? await _hash(prefs, remote.dump, remote.files)
          : await _hash(prefs);
      if (remote.writtenAt > _writtenAt) _writtenAt = remote.writtenAt;
      _startWatch();
      unawaited(_flushIfDirty());
    } catch (error) {
      debugPrint('Cloud sync login failed: $error');
      if (parkedNow) {
        try {
          await _restoreParked(scope, prefs);
        } catch (_) {}
      }
      rethrow;
    } finally {
      _busy = false;
    }
  }

  Future<void> flushAndSignOut() async {
    final bound = _ready;
    _busy = true;
    _watch?.cancel();
    _watch = null;
    final prefs = await SharedPreferences.getInstance();
    try {
      final inflight = _inflight;
      if (inflight != null) {
        try {
          await inflight.timeout(const Duration(seconds: 45));
        } catch (_) {
          await CloudSyncFiles.cancelUploads();
        }
      }
      final user = AppAuthService.instance.user;
      final prefsUid = prefs.getString(CloudSyncSnapshot.uidKey);
      final prefsProvider = prefs.getString(CloudSyncSnapshot.providerKey);
      final canSave = user != null &&
          (bound ||
              prefsUid == user.uid ||
              prefsProvider != null ||
              _vaultProvider != null);
      if (canSave) {
        _vaultProvider = prefs.getString(CloudSyncSnapshot.providerKey) ??
            _vaultProvider ??
            _currentProvider();
        final dump = await _localDump();
        await _upload(
          user.uid,
          dump,
          allowEmpty: true,
          pruneFiles: false,
          waitForFiles: true,
          ignoreEpoch: true,
        );
      }
      await AppAuthService.instance.signOut();
    } catch (error) {
      if (error is AppAuthException) rethrow;
      throw AppAuthException('sync_logout', _code(error));
    } finally {
      await prefs.remove(CloudSyncSnapshot.uidKey);
      await prefs.remove(CloudSyncSnapshot.providerKey);
      _stop();
      final scope = _scope;
      if (scope != null) {
        try {
          await _restoreParked(scope, prefs);
        } catch (error) {
          debugPrint('Cloud parked restore failed: $error');
        }
      }
      _busy = false;
    }
  }

  Future<void> deleteCloudAndAccount({required AppScope scope}) async {
    final user = AppAuthService.instance.user;
    if (user == null) return;
    final uid = user.uid;
    final provider = _currentProvider();
    _vaultProvider = provider;
    _stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CloudSyncSnapshot.uidKey);
    await prefs.remove(CloudSyncSnapshot.providerKey);
    try {
      final known = <CloudFileEntry>[];
      var otherVaults = false;
      try {
        final snap = await _legacyDoc(uid).get();
        final data = snap.data();
        final vaults = data?['vaults'];
        if (vaults is Map) {
          final mine = vaults[provider];
          if (mine is Map) {
            known.addAll(CloudSyncFiles.parseManifest(mine['files']));
          }
          otherVaults = vaults.keys.any((key) => '$key' != provider);
        }
        try {
          final sub = await _legacyDoc(uid).collection('vaults').doc(provider).get();
          known.addAll(CloudSyncFiles.parseManifest(sub.data()?['files']));
        } catch (_) {}
      } catch (error) {
        debugPrint('Cloud delete fetch failed: $error');
      }
      await CloudSyncFiles.deleteRemote(uid, known: known);
      try {
        await _legacyDoc(uid).update({
          FieldPath(['vaults', provider]): FieldValue.delete(),
        });
      } catch (error) {
        debugPrint('Cloud delete vault clear failed: $error');
      }
      try {
        await _legacyDoc(uid).collection('vaults').doc(provider).delete();
      } catch (_) {}
      if (!otherVaults) {
        try {
          await _legacyDoc(uid).delete();
        } on FirebaseException catch (error) {
          if (error.code != 'not-found') rethrow;
        }
      }
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') {
        _startWatch();
        throw AppAuthException('sync', error.code);
      }
    } catch (error) {
      _startWatch();
      throw AppAuthException('sync', _code(error));
    }
    await AppAuthService.instance.deleteAccount();
    await _restoreParked(scope, prefs);
  }

  Future<void> onResumed() async {
    if (!_ready || AppAuthService.instance.user == null) return;
    await _flushIfDirty();
    await _pullIfIdle();
  }

  Future<void> _resumeIfBound() async {
    final user = AppAuthService.instance.user;
    if (user == null) {
      _stop();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) return;
    if (prefs.getString(CloudSyncSnapshot.uidKey) != user.uid) return;
    if (_busy) return;
    final lastProvider = prefs.getString(CloudSyncSnapshot.providerKey);
    final provider = _currentProvider();
    if (lastProvider != null && lastProvider != provider) return;
    _vaultProvider = lastProvider ?? provider;
    _ready = true;
    _startWatch();
    unawaited(onResumed());
  }

  void _startWatch() {
    _watch ??= Timer.periodic(const Duration(milliseconds: 400), (_) {
      unawaited(_flushIfDirty());
    });
    _listenRemote();
  }

  void _listenRemote() {
    final user = AppAuthService.instance.user;
    if (user == null) return;
    final provider = _vaultProvider ?? _currentProvider();
    final key = '${user.uid}::$provider';
    if (_listenKey == key && _remoteSub != null) {
      return;
    }
    unawaited(_remoteSub?.cancel());
    unawaited(_remoteParentSub?.cancel());
    _remoteParentSub = null;
    _listenKey = key;
    final ref = _legacyDoc(user.uid);
    _remoteSub = ref.collection('vaults').doc(provider).snapshots().listen(
      (snap) {
        if (!snap.exists || snap.metadata.hasPendingWrites) return;
        _handleRemoteSnap(_parseVault(snap.data()));
      },
      onError: (error) {
        debugPrint('Cloud sync vault listen failed: $error');
      },
    );
  }

  void _handleRemoteSnap(_RemoteSnapshot remote) {
    if (!_ready || _busy) return;
    if (_inflight != null) {
      _missedRemote = true;
      return;
    }
    unawaited(_onRemoteVault(remote));
  }

  void _stop() {
    _watch?.cancel();
    _watch = null;
    unawaited(_remoteSub?.cancel());
    unawaited(_remoteParentSub?.cancel());
    _remoteSub = null;
    _remoteParentSub = null;
    _listenKey = null;
    _missedRemote = false;
    _ready = false;
    _uploadedHash = null;
    _writtenAt = 0;
    _lastRemoteFiles = const [];
    _vaultProvider = null;
    _epoch++;
  }

  Future<void> _flushIfDirty() async {
    final user = AppAuthService.instance.user;
    final epoch = _epoch;
    if (!_ready || user == null || _busy || _inflight != null) return;
    final dump = await _localDump();
    if (epoch != _epoch || !_ready || _busy || AppAuthService.instance.user?.uid != user.uid) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final hash = await _hash(prefs, dump);
    if (epoch != _epoch || !_ready || _busy) return;
    if (hash == _uploadedHash) return;
    if (CloudSyncSnapshot.isFoundationDump(dump)) return;
    try {
      await _upload(user.uid, dump, waitForFiles: false);
    } catch (error) {
      debugPrint('Cloud sync upload failed: $error');
    }
  }

  Future<void> _pullIfIdle() async {
    final user = AppAuthService.instance.user;
    final scope = _scope;
    final epoch = _epoch;
    if (!_ready || user == null || scope == null || _busy) return;
    final prefs = await SharedPreferences.getInstance();
    final local = CloudSyncSnapshot.dump(prefs);
    if (epoch != _epoch || !_ready || _busy) return;
    if (await _hash(prefs, local) != _uploadedHash) {
      await _flushIfDirty();
      return;
    }
    try {
      final remote = await _fetch(user.uid, _currentProvider());
      await _applyRemoteIfChanged(
        remote,
        prefs: prefs,
        local: local,
        uid: user.uid,
        epoch: epoch,
        scope: scope,
      );
    } catch (error) {
      debugPrint('Cloud sync pull failed: $error');
    }
  }

  Future<void> _onRemoteVault(_RemoteSnapshot remote) async {
    if (!remote.hasContent) return;
    final user = AppAuthService.instance.user;
    final scope = _scope;
    final epoch = _epoch;
    if (!_ready || user == null || scope == null || _busy || _inflight != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (epoch != _epoch || !_ready || _busy) return;
    final local = CloudSyncSnapshot.dump(prefs);
    if (await _hash(prefs, local) != _uploadedHash) {
      unawaited(_flushIfDirty());
      return;
    }
    try {
      await _applyRemoteIfChanged(
        remote,
        prefs: prefs,
        local: local,
        uid: user.uid,
        epoch: epoch,
        scope: scope,
      );
    } catch (error) {
      debugPrint('Cloud sync live apply failed: $error');
    }
  }

  Future<void> _applyRemoteIfChanged(
    _RemoteSnapshot remote, {
    required SharedPreferences prefs,
    required Map<String, dynamic> local,
    required String uid,
    required int epoch,
    required AppScope scope,
  }) async {
    if (epoch != _epoch || !_ready || _busy) return;
    if (!remote.hasContent) return;
    if (remote.writtenAt > 0 &&
        _writtenAt > 0 &&
        remote.writtenAt < _writtenAt) {
      return;
    }
    _lastRemoteFiles = remote.files;
    final localFiles = await CloudSyncFiles.collect(prefs);
    final needed = CloudSyncFiles.merge(
      remote.files,
      CloudSyncFiles.referencedInDump(remote.dump),
    );
    final remoteHash = CloudSyncSnapshot.hashOf(remote.dump);
    final localDumpHash = CloudSyncSnapshot.hashOf(local);
    if (remoteHash == localDumpHash) {
      if (CloudSyncFiles.fingerprint(remote.files) ==
          CloudSyncFiles.fingerprint(localFiles)) {
        _uploadedHash = await _hash(prefs, local, localFiles);
        if (remote.writtenAt > _writtenAt) _writtenAt = remote.writtenAt;
        return;
      }
      await CloudSyncFiles.download(uid, needed);
      final extras = localFiles.any(
        (file) => remote.files.every((remoteFile) => remoteFile.key != file.key),
      );
      if (extras) await _flushIfDirty();
      if (remote.writtenAt > _writtenAt) _writtenAt = remote.writtenAt;
      return;
    }
    await _applyDump(
      scope,
      prefs,
      remote.dump,
      uid: uid,
      files: remote.files,
      replaceFiles: true,
    );
    if (epoch != _epoch) return;
    if (remote.writtenAt > _writtenAt) _writtenAt = remote.writtenAt;
    _uploadedHash = await _hash(prefs);
  }

  Future<void> _upload(
    String uid,
    Map<String, dynamic> dump, {
    bool allowEmpty = false,
    bool pruneFiles = true,
    bool waitForFiles = true,
    bool ignoreEpoch = false,
  }) async {
    if (!allowEmpty && CloudSyncSnapshot.isFoundationDump(dump)) return;
    final epoch = _epoch;
    bool alive() => ignoreEpoch || epoch == _epoch;
    final previous = _inflight ?? Future<void>.value();
    final gate = Completer<void>();
    _inflight = gate.future;
    try {
      await previous;
      if (!alive()) return;
      final prefs = await SharedPreferences.getInstance();
      final collected = await CloudSyncFiles.collect(prefs);
      if (!alive()) return;
      final referenced = CloudSyncFiles.referencedInDump(dump);
      final files = kIsWeb
          ? CloudSyncFiles.merge(
              collected,
              [
                for (final file in _lastRemoteFiles)
                  if (referenced.any((item) => item.key == file.key)) file,
              ],
            )
          : collected;
      final provider = _vaultProvider ?? _currentProvider();
      final writtenAt = DateTime.now().millisecondsSinceEpoch;
      final vault = <String, dynamic>{
        'hasContent': CloudSyncSnapshot.hasUserContent(dump),
        'payload': jsonEncode(dump),
        'files': [for (final file in files) file.toJson()],
        'writtenAt': writtenAt,
      };
      final filesUnchanged = CloudSyncFiles.fingerprint(files) ==
              CloudSyncFiles.fingerprint(_lastRemoteFiles) &&
          (_lastRemoteFiles.isNotEmpty || files.isEmpty);
      if (!filesUnchanged) {
        final fileWork = CloudSyncFiles.upload(
          uid,
          files,
          prune: false,
        );
        if (waitForFiles) {
          try {
            await fileWork;
          } catch (error) {
            debugPrint('Cloud sync file upload failed: $error');
          }
        } else {
          unawaited(fileWork);
        }
      }
      if (!alive()) return;
      await _writeVault(uid, provider, vault);
      if (!alive()) return;
      if (pruneFiles && waitForFiles && !kIsWeb && !filesUnchanged) {
        await CloudSyncFiles.pruneUnused(uid, files);
      }
      if (!alive()) return;
      _writtenAt = writtenAt;
      _lastRemoteFiles = files;
      _uploadedHash = await _hash(prefs, dump, files);
    } finally {
      if (!gate.isCompleted) gate.complete();
      if (identical(_inflight, gate.future)) _inflight = null;
      if (_missedRemote) {
        _missedRemote = false;
        if (_ready && !_busy) unawaited(_pullIfIdle());
      }
    }
  }

  Future<void> _bind(
    SharedPreferences prefs,
    String uid,
    String provider,
  ) async {
    await prefs.setString(CloudSyncSnapshot.uidKey, uid);
    await prefs.setString(CloudSyncSnapshot.providerKey, provider);
    _vaultProvider = provider;
    _ready = true;
  }

  Future<void> _restoreParked(AppScope scope, SharedPreferences prefs) async {
    final raw = prefs.getString(CloudSyncSnapshot.parkedDumpKey);
    if (raw == null || raw.isEmpty) return;
    await prefs.remove(CloudSyncSnapshot.parkedDumpKey);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    await CloudSyncSnapshot.apply(
      prefs,
      CloudSyncSnapshot.normalizeDump(decoded),
    );
    await CloudSyncFiles.restoreParked();
    await CloudSyncFiles.relocate();
    await AppBackupService.applyToApp(scope);
  }

  Future<void> _writeVault(
    String uid,
    String provider,
    Map<String, dynamic> vault,
  ) async {
    final ref = _legacyDoc(uid);
    try {
      await ref.collection('vaults').doc(provider).set(vault);
    } catch (error) {
      debugPrint('Cloud vault doc write skipped: $error');
    }
    await ref.set({
      'schema': CloudSyncSnapshot.schema,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    try {
      await ref.update({
        FieldPath(['vaults', provider]): vault,
      });
    } catch (error) {
      debugPrint('Cloud parent vault write skipped: $error');
    }
  }

  Future<_RemoteSnapshot> _fetch(String uid, String provider) async {
    try {
      final ref = _legacyDoc(uid);
      try {
        final sub = await ref
            .collection('vaults')
            .doc(provider)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 12));
        if (sub.exists) {
          final parsed = _parseVault(sub.data());
          if (parsed.hasContent) return parsed;
        }
      } catch (error) {
        debugPrint('Cloud vault doc fetch skipped: $error');
      }
      final snap = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 12));
      if (!snap.exists) return const _RemoteSnapshot.empty();
      final data = snap.data() ?? const <String, dynamic>{};
      final vaults = data['vaults'];
      if (vaults is Map && vaults[provider] != null) {
        return _parseVault(vaults[provider]);
      }
      if (data['vaults.$provider'] != null) {
        return _parseVault(data['vaults.$provider']);
      }
      debugPrint('Cloud fetch miss uid=$uid provider=$provider');
      return const _RemoteSnapshot.empty();
    } on FirebaseException catch (error) {
      throw AppAuthException('sync', error.code);
    } catch (error) {
      throw AppAuthException('sync', _code(error));
    }
  }

  _RemoteSnapshot _parseVault(Object? raw) {
    if (raw is! Map) return const _RemoteSnapshot.empty();
    final data = Map<String, dynamic>.from(raw);
    final payload = data['payload'];
    var dump = <String, dynamic>{};
    if (payload is String && payload.isNotEmpty) {
      dump = CloudSyncSnapshot.decodeDump(payload);
    } else if (payload is Map) {
      dump = CloudSyncSnapshot.normalizeDump(payload);
    }
    final flagged = data['hasContent'] == true;
    final hasContent = CloudSyncSnapshot.hasUserContent(dump) ||
        (flagged && dump.isNotEmpty && !CloudSyncSnapshot.isFoundationDump(dump));
    return _RemoteSnapshot(
      hasContent: hasContent,
      dump: dump,
      files: CloudSyncFiles.parseManifest(data['files']),
      writtenAt: (data['writtenAt'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _applyDump(
    AppScope scope,
    SharedPreferences prefs,
    Map<String, dynamic> dump, {
    required String uid,
    List<CloudFileEntry> files = const [],
    bool replaceFiles = false,
  }) async {
    await CloudSyncSnapshot.apply(prefs, dump);
    await CloudSyncFiles.relocate();
    try {
      final needed = CloudSyncFiles.merge(
        files,
        CloudSyncFiles.referencedInDump(CloudSyncSnapshot.dump(prefs)),
      );
      final downloaded = await CloudSyncFiles.download(uid, needed);
      if (replaceFiles && downloaded && needed.isNotEmpty) {
        await CloudSyncFiles.clearUnused(needed);
      }
      await CloudSyncFiles.relocate();
    } catch (error) {
      debugPrint('Cloud sync file download failed: $error');
    }
    await AppBackupService.applyToApp(scope);
  }

  Future<void> _resetLocal(AppScope scope, SharedPreferences prefs) async {
    for (final key in CloudSyncSnapshot.contentKeys) {
      await prefs.remove(key);
    }
    await CloudSyncFiles.clearLocal();
    await CalendarEventLocalDataSource(prefs).resetToStarters();
    await scope.themePreference.resetToStarters();
    await AppBackupService.applyToApp(scope);
  }

  Future<Map<String, dynamic>> _localDump() async {
    final prefs = await SharedPreferences.getInstance();
    return CloudSyncSnapshot.dump(prefs);
  }

  Future<String> _hash(
    SharedPreferences prefs, [
    Map<String, dynamic>? dump,
    List<CloudFileEntry>? files,
  ]) async {
    dump ??= CloudSyncSnapshot.dump(prefs);
    files ??= await CloudSyncFiles.collect(prefs);
    return '${CloudSyncSnapshot.hashOf(dump)}::${CloudSyncFiles.fingerprint(files)}';
  }

  AppScope _scopeFor(BuildContext context) {
    return _scope ?? AppScope.of(context);
  }

  String _currentProvider() {
    return AppAuthService.instance.signInProvider ??
        AppAuthService.providerOf(AppAuthService.instance.user) ??
        'default';
  }

  DocumentReference<Map<String, dynamic>> _legacyDoc(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static String _code(Object error) {
    if (error is FirebaseException) return error.code;
    if (error is AppAuthException) return error.code;
    return error.runtimeType.toString();
  }
}

class _RemoteSnapshot {
  const _RemoteSnapshot({
    required this.hasContent,
    required this.dump,
    this.files = const [],
    this.writtenAt = 0,
  });

  const _RemoteSnapshot.empty()
      : hasContent = false,
        dump = const {},
        files = const [],
        writtenAt = 0;

  final bool hasContent;
  final Map<String, dynamic> dump;
  final List<CloudFileEntry> files;
  final int writtenAt;
}
