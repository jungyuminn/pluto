import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pluto/core/constants/oauth_config.dart';
import 'package:pluto/data/datasources/kakao_web_auth.dart';
import 'package:pluto/firebase_options.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppAuthException implements Exception {
  const AppAuthException(this.code, [this.detail]);

  final String code;
  final String? detail;
}

class AppAuthService {
  AppAuthService._();

  static final instance = AppAuthService._();

  static const googleServerClientId =
      '246357426149-hfck4ic0e2f0krfkot5hvb3vtm36ko58.apps.googleusercontent.com';

  var _googleReady = false;
  var _kakaoProfileTried = false;
  String? _sessionProvider;

  bool get isReady => Firebase.apps.isNotEmpty;

  Stream<User?> get authState {
    if (!isReady) return Stream.value(null);
    return FirebaseAuth.instance.userChanges().asyncMap((user) async {
      if (user != null &&
          !_kakaoProfileTried &&
          user.providerData.any((info) => info.providerId == 'oidc.kakao')) {
        await _applyKakaoProfile();
        return FirebaseAuth.instance.currentUser ?? user;
      }
      return user;
    });
  }

  User? get user => isReady ? FirebaseAuth.instance.currentUser : null;

  String? get signInProvider => _sessionProvider ?? providerOf(user);

  static String? providerOf(User? user) {
    if (user == null) return null;
    final ids = {for (final info in user.providerData) info.providerId};
    if (ids.length == 1) {
      if (ids.contains('oidc.kakao')) return 'kakao';
      if (ids.contains('google.com')) return 'google';
      if (ids.contains('apple.com')) return 'apple';
    }
    if (ids.contains('oidc.kakao')) return 'kakao';
    if (ids.contains('google.com')) return 'google';
    if (ids.contains('apple.com')) return 'apple';
    if (user.uid.startsWith('kakao_')) return 'kakao';
    return null;
  }

  static String? socialDisplayName(User user) {
    final candidates = [
      user.displayName,
      ...user.providerData.map((info) => info.displayName),
    ];
    for (final raw in candidates) {
      final name = raw?.trim() ?? '';
      if (_isSocialName(name)) return name;
    }
    return null;
  }

  static bool _isSocialName(String name) {
    if (name.isEmpty) return false;
    if (name.contains('@')) return false;
    if (RegExp(r'^\d+$').hasMatch(name)) return false;
    return true;
  }

  Future<void> applySocialProfile() async {
    final user = this.user;
    if (user == null) return;
    if (user.providerData.any((info) => info.providerId == 'oidc.kakao') ||
        user.uid.startsWith('kakao_')) {
      await _applyKakaoProfile(force: true);
    }
  }

  static String? _kakaoNicknameOf(kakao.User me) {
    final fromAccount = me.kakaoAccount?.profile?.nickname?.trim();
    if (fromAccount != null && fromAccount.isNotEmpty) return fromAccount;
    final fromProps = me.properties?['nickname']?.trim();
    if (fromProps != null && fromProps.isNotEmpty) return fromProps;
    return null;
  }

  static String accountHandle(User user) {
    final emails = [
      user.email,
      ...user.providerData.map((info) => info.email),
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    if (emails.isNotEmpty) return emails.first;
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return accountId(user);
  }

  static String accountId(User user) {
    final emails = [
      user.email,
      ...user.providerData.map((info) => info.email),
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    if (emails.isNotEmpty) return emails.first;
    final ids = user.providerData
        .map((info) => info.uid)
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    if (ids.isNotEmpty) return ids.first;
    return user.uid;
  }

  static String socialLabel(User user) {
    final providers = {
      for (final info in user.providerData) info.providerId,
    };
    if (providers.contains('oidc.kakao')) return '카카오';
    if (providers.contains('google.com')) return '구글';
    if (providers.contains('apple.com')) return '애플';
    return '소셜';
  }

  static bool isUserCanceled(Object error) {
    if (error is AppAuthException) return error.code == 'canceled';
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled;
    }
    if (error is SignInWithAppleAuthorizationException) {
      return error.code == AuthorizationErrorCode.canceled ||
          error.code == AuthorizationErrorCode.unknown;
    }
    if (error is FirebaseAuthException) {
      return _isCancelCode(error.code) || _isCancelText(error.message);
    }
    if (error is PlatformException) {
      return _isCancelCode(error.code) || _isCancelText(error.message);
    }
    return _isCancelText(error.toString());
  }

  static bool _isCancelCode(String code) {
    final normalized = code
        .toLowerCase()
        .replaceAll('_', '-')
        .replaceFirst(RegExp(r'^error-'), '');
    return normalized == 'canceled' ||
        normalized == 'cancelled' ||
        normalized == 'web-context-canceled' ||
        normalized == 'aborted-by-user' ||
        normalized == 'user-canceled' ||
        normalized == 'user-cancelled';
  }

  static bool _isCancelText(String? text) {
    if (text == null) return false;
    final lower = text.toLowerCase();
    return lower.contains('cancel') || lower.contains('cancelled');
  }

  Future<void> signInWithGoogle() async {
    _requireReady();
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        _sessionProvider = 'google';
        return;
      }
      await _ensureGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppAuthException('canceled');
      }
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      _sessionProvider = 'google';
    } catch (error) {
      if (isUserCanceled(error)) {
        throw const AppAuthException('canceled');
      }
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    _requireReady();
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
        await _signInWithAppleProvider();
        _sessionProvider = 'apple';
        return;
      }
      final rawNonce = _randomNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final idToken = apple.identityToken;
      if (idToken == null) {
        throw const AppAuthException('canceled');
      }
      await FirebaseAuth.instance.signInWithCredential(
        AppleAuthProvider.credentialWithIDToken(
          idToken,
          rawNonce,
          AppleFullPersonName(
            givenName: apple.givenName,
            familyName: apple.familyName,
          ),
        ),
      );
      _sessionProvider = 'apple';
    } catch (error) {
      if (isUserCanceled(error)) {
        throw const AppAuthException('canceled');
      }
      rethrow;
    }
  }

  Future<void> signInWithKakao() async {
    _requireReady();
    if (!OauthConfig.kakaoEnabled) {
      throw const AppAuthException('kakao_key');
    }
    if (kIsWeb) {
      await _signInWithKakaoWeb();
      return;
    }
    final rawNonce = _randomNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
    kakao.OAuthToken token;
    try {
      token = await _kakaoLogin(nonce);
      if (token.idToken == null || token.idToken!.isEmpty) {
        token = await kakao.UserApi.instance.loginWithNewScopes(
          ['openid', 'profile_nickname'],
          nonce: nonce,
        );
      }
    } on kakao.KakaoAuthException catch (error) {
      if (error.error == kakao.AuthErrorCause.accessDenied) {
        throw const AppAuthException('canceled');
      }
      if (error.error == kakao.AuthErrorCause.misconfigured) {
        throw AppAuthException(
          'kakao_misconfigured',
          error.errorDescription ?? error.error.toString(),
        );
      }
      throw AppAuthException(
        'kakao_oidc',
        error.errorDescription ?? error.error.toString(),
      );
    } on kakao.KakaoClientException catch (error) {
      if (error.reason == kakao.ClientErrorCause.cancelled) {
        throw const AppAuthException('canceled');
      }
      throw AppAuthException('kakao_oidc', error.reason.toString());
    }
    final idToken = token.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AppAuthException('kakao_oidc', 'id-token-missing');
    }
    final payload = _decodeJwtPayload(idToken);
    final aud = payload['aud'];
    final hasNonce = payload.containsKey('nonce');
    debugPrint(
      'Kakao ID token iss=${payload['iss']} aud=$aud hasNonce=$hasNonce',
    );
    try {
      await _signInKakaoWithFirebase(
        idToken,
        token.accessToken,
        hasNonce ? rawNonce : null,
      );
      _sessionProvider = 'kakao';
      final jwtName = '${payload['nickname'] ?? payload['name'] ?? ''}'.trim();
      if (jwtName.isNotEmpty && _isSocialName(jwtName)) {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null && current.displayName != jwtName) {
          await current.updateDisplayName(jwtName);
          await current.reload();
        }
      }
      await _applyKakaoProfile(force: true);
    } catch (error) {
      debugPrint('Kakao Firebase auth failed: $error');
      throw AppAuthException(
        'kakao_oidc',
        '${_authErrorCode(error)} aud=$aud nonce=$hasNonce',
      );
    }
  }

  Future<void> _signInWithKakaoWeb() async {
    if (!OauthConfig.kakaoWebEnabled) {
      throw const AppAuthException('kakao_web_key');
    }
    KakaoWebTokens tokens;
    try {
      tokens = await loginWithKakaoOnWeb(
        appKey: OauthConfig.kakaoJavaScriptAppKey,
      );
    } on KakaoWebLoginException catch (error) {
      if (error.code == 'canceled') {
        throw const AppAuthException('canceled');
      }
      if (error.code == 'misconfigured') {
        throw AppAuthException('kakao_web_misconfigured', error.detail);
      }
      throw AppAuthException('kakao_oidc', error.detail);
    } catch (error) {
      if (isUserCanceled(error)) {
        throw const AppAuthException('canceled');
      }
      throw AppAuthException('kakao_oidc', _authErrorCode(error));
    }
    if (tokens.accessToken.isEmpty) {
      throw const AppAuthException('kakao_oidc', 'access-token-missing');
    }
    try {
      final customToken = await _exchangeKakaoWebToken(tokens.accessToken);
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      _sessionProvider = 'kakao';
    } catch (error) {
      if (error is AppAuthException) rethrow;
      debugPrint('Kakao web Firebase auth failed: $error');
      throw AppAuthException('kakao_oidc', _authErrorCode(error));
    }
  }

  Future<String> _exchangeKakaoWebToken(String accessToken) async {
    final response = await http.post(
      Uri.parse(
        'https://asia-northeast3-jopb-65c0f.cloudfunctions.net/kakaoWebSignIn',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'data': {'accessToken': accessToken},
      }),
    );
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    if (response.statusCode != 200) {
      final error = payload['error'];
      final code = error is Map ? error['status']?.toString() : null;
      final message = error is Map ? error['message']?.toString() : null;
      debugPrint(
        'Kakao web function failed: ${response.statusCode} $code $message',
      );
      throw AppAuthException(
        'kakao_oidc',
        '${code ?? response.statusCode} ${message ?? ''}'.trim(),
      );
    }
    final result = payload['result'];
    final customToken = result is Map ? result['token']?.toString() : null;
    if (customToken == null || customToken.isEmpty) {
      throw const AppAuthException('kakao_oidc', 'custom-token-missing');
    }
    return customToken;
  }

  Future<kakao.OAuthToken> _kakaoLogin(String nonce) async {
    if (await kakao.isKakaoTalkInstalled()) {
      try {
        return await kakao.UserApi.instance.loginWithKakaoTalk(nonce: nonce);
      } on kakao.KakaoClientException catch (error) {
        if (error.reason == kakao.ClientErrorCause.cancelled) rethrow;
      } on kakao.KakaoAuthException catch (error) {
        if (error.error == kakao.AuthErrorCause.accessDenied) rethrow;
      }
    }
    return kakao.UserApi.instance.loginWithKakaoAccount(nonce: nonce);
  }

  Future<void> _signInKakaoWithFirebase(
    String idToken,
    String accessToken,
    String? rawNonce,
  ) async {
    final provider = OAuthProvider('oidc.kakao');
    Object? lastError;
    final credentials = <OAuthCredential>[
      if (rawNonce != null)
        provider.credential(idToken: idToken, rawNonce: rawNonce),
      provider.credential(idToken: idToken),
      provider.credential(idToken: idToken, accessToken: accessToken),
      if (rawNonce != null)
        provider.credential(
          idToken: idToken,
          accessToken: accessToken,
          rawNonce: rawNonce,
        ),
    ];
    for (final credential in credentials) {
      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
        return;
      } catch (error) {
        lastError = error;
        debugPrint('Kakao Firebase attempt failed: $error');
      }
    }
    throw lastError ?? const AppAuthException('kakao_oidc');
  }

  Future<void> _applyKakaoProfile({bool force = false}) async {
    if (_kakaoProfileTried && !force) return;
    _kakaoProfileTried = true;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    try {
      var me = await kakao.UserApi.instance.me();
      var nickname = _kakaoNicknameOf(me);
      if ((nickname == null || nickname.isEmpty) &&
          me.kakaoAccount?.profileNicknameNeedsAgreement == true &&
          !kIsWeb) {
        await kakao.UserApi.instance.loginWithNewScopes(['profile_nickname']);
        me = await kakao.UserApi.instance.me();
        nickname = _kakaoNicknameOf(me);
      }
      if (nickname == null || nickname.isEmpty) return;
      if (firebaseUser.displayName == nickname) return;
      await firebaseUser.updateDisplayName(nickname);
      await firebaseUser.reload();
    } catch (error) {
      debugPrint('Kakao profile apply failed: $error');
    }
  }

  static String _authErrorCode(Object error) {
    if (error is FirebaseAuthException) return error.code;
    if (error is PlatformException) return error.code;
    return error.runtimeType.toString();
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
      case 3:
        payload += '=';
    }
    final decoded = utf8.decode(base64Decode(payload));
    final json = jsonDecode(decoded);
    return json is Map<String, dynamic> ? json : {};
  }

  Future<void> signOut() async {
    if (!isReady) return;
    final providers = {
      for (final info
          in FirebaseAuth.instance.currentUser?.providerData ?? const [])
        info.providerId,
    };
    const timeout = Duration(milliseconds: 800);
    final tasks = <Future<void>>[];
    if (providers.contains('google.com')) {
      tasks.add(() async {
        try {
          await GoogleSignIn.instance.signOut().timeout(timeout);
        } catch (_) {}
      }());
    }
    if (providers.contains('oidc.kakao') && OauthConfig.kakaoEnabled) {
      tasks.add(() async {
        try {
          await kakao.UserApi.instance.logout().timeout(timeout);
        } catch (_) {}
      }());
    }
    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
    _kakaoProfileTried = false;
    _sessionProvider = null;
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAccount() async {
    _requireReady();
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      try {
        await user.delete();
      } on FirebaseAuthException catch (error) {
        if (error.code != 'requires-recent-login') rethrow;
        await _reauthenticate();
        user = FirebaseAuth.instance.currentUser;
        if (user == null) throw const AppAuthException('unavailable');
        await user.delete();
      }
    } catch (error) {
      if (isUserCanceled(error)) {
        throw const AppAuthException('canceled');
      }
      if (error is AppAuthException) rethrow;
      throw AppAuthException(
        'account_delete',
        _authErrorCode(error),
      );
    }
    try {
      if (OauthConfig.kakaoEnabled) {
        await kakao.UserApi.instance.unlink();
      }
    } catch (_) {}
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    _kakaoProfileTried = false;
    _sessionProvider = null;
  }

  Future<void> _reauthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final providers = user.providerData.map((info) => info.providerId).toSet();
    if (providers.contains('google.com')) {
      await _ensureGoogle();
      GoogleSignInAccount? account;
      try {
        final lightweight =
            GoogleSignIn.instance.attemptLightweightAuthentication();
        if (lightweight != null) {
          account = await lightweight;
        }
      } catch (_) {}
      account ??= await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AppAuthException('canceled');
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return;
    }
    if (providers.contains('apple.com')) {
      await signInWithApple();
      return;
    }
    if (providers.contains('oidc.kakao')) {
      try {
        final existing =
            await kakao.TokenManagerProvider.instance.manager.getToken();
        final idToken = existing?.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          await user.reauthenticateWithCredential(
            OAuthProvider('oidc.kakao').credential(
              idToken: idToken,
              accessToken: existing?.accessToken,
            ),
          );
          return;
        }
      } catch (_) {}
      await signInWithKakao();
    }
  }

  Future<void> _signInWithAppleProvider() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(provider);
      return;
    }
    await FirebaseAuth.instance.signInWithProvider(provider);
  }

  void _requireReady() {
    if (!isReady) throw const AppAuthException('unavailable');
  }

  Future<void> ensureGoogleInitialized() => _ensureGoogle();

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      serverClientId: googleServerClientId,
    );
    _googleReady = true;
  }

  String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
