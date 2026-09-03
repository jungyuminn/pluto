import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

class KakaoWebTokens {
  const KakaoWebTokens({required this.accessToken, this.idToken});

  final String accessToken;
  final String? idToken;
}

class KakaoWebLoginException implements Exception {
  const KakaoWebLoginException(this.code, [this.detail]);

  final String code;
  final String? detail;
}

const _kakaoSdkSrc =
    'https://t1.kakaocdn.net/kakao_js_sdk/2.7.5/kakao.min.js';
const _kakaoRedirectUri = 'JS-SDK';

const _helperJs = r'''
window.__jpKakaoLogin = function(opts) {
  if (!window.Kakao || !Kakao.Auth || typeof Kakao.Auth.authorize !== 'function') {
    return Promise.reject({error: 'sdk-missing'});
  }
  return Promise.resolve(Kakao.Auth.authorize(opts)).then(function(res) {
    if (typeof res === 'string') {
      return JSON.stringify({code: res});
    }
    try {
      return JSON.stringify(res || {});
    } catch (e) {
      return JSON.stringify({error: 'stringify-failed', error_description: String(e)});
    }
  });
};
window.__jpKakaoToken = function(body) {
  return fetch('https://kauth.kakao.com/oauth/token', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: body
  }).then(function(res) {
    return res.text().then(function(text) {
      return JSON.stringify({status: res.status, ok: res.ok, text: text});
    });
  });
};
''';

@JS('Kakao')
external KakaoSDK? get _kakao;

@JS('__jpKakaoLogin')
external JSPromise<JSString> _jsKakaoLogin(JSObject options);

@JS('__jpKakaoToken')
external JSPromise<JSString> _jsKakaoToken(String body);

extension type KakaoSDK._(JSObject _) implements JSObject {
  external void init(String appKey);
  external bool isInitialized();
  external void cleanup();
}

Future<void> prepareKakaoWebSdk(String appKey) async {
  await _ensureSdkLoaded();
  _initSdk(appKey);
  _installHelpers();
}

Future<KakaoWebTokens> loginWithKakaoOnWeb({
  required String appKey,
  String? nonce,
}) async {
  final kakao = _kakao;
  if (kakao == null) {
    await prepareKakaoWebSdk(appKey);
  } else {
    _initSdk(appKey);
    _installHelpers();
  }

  final settings = JSObject();
  settings['isPopup'] = true.toJS;
  settings['scope'] = 'openid'.toJS;
  settings['throughTalk'] = true.toJS;
  if (nonce != null && nonce.isNotEmpty) {
    settings['nonce'] = nonce.toJS;
  }

  final raw = await _awaitJsString(() => _jsKakaoLogin(settings));
  final result = _decodeMap(raw, 'auth-code-missing');
  final errorCode = result['error']?.toString() ?? '';
  if (errorCode.isNotEmpty) {
    throw _authError(errorCode, result['error_description']?.toString() ?? '');
  }
  final code = result['code']?.toString() ?? '';
  if (code.isEmpty) {
    throw KakaoWebLoginException('failed', 'auth-code-missing $raw');
  }

  return _exchangeCodeForTokens(
    appKey: appKey,
    code: code,
  );
}

void _initSdk(String appKey) {
  final kakao = _kakao;
  if (kakao == null) {
    throw const KakaoWebLoginException('failed', 'sdk-missing');
  }
  if (kakao.isInitialized()) kakao.cleanup();
  kakao.init(appKey);
}

void _installHelpers() {
  if (globalContext.getProperty('__jpKakaoLogin'.toJS) != null) return;
  final script = HTMLScriptElement()..text = _helperJs;
  document.head?.append(script);
}

Future<void> _ensureSdkLoaded() async {
  if (_kakao != null) return;
  final existing = document.querySelector(
    'script[src*="kakao_js_sdk"], script[data-kakao-js-sdk]',
  );
  if (existing != null) {
    await _waitUntilSdkReady();
    return;
  }

  final completer = Completer<void>();
  final script = HTMLScriptElement()
    ..src = _kakaoSdkSrc
    ..async = true
    ..crossOrigin = 'anonymous';
  script.setAttribute('data-kakao-js-sdk', 'true');
  script.addEventListener(
    'load',
    (Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS,
  );
  script.addEventListener(
    'error',
    (Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const KakaoWebLoginException('failed', 'sdk-load-failed'),
        );
      }
    }.toJS,
  );
  document.head?.append(script);
  await completer.future;
  if (_kakao == null) {
    throw const KakaoWebLoginException('failed', 'sdk-missing');
  }
}

Future<void> _waitUntilSdkReady() async {
  for (var i = 0; i < 50; i++) {
    if (_kakao != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw const KakaoWebLoginException('failed', 'sdk-missing');
}

Future<KakaoWebTokens> _exchangeCodeForTokens({
  required String appKey,
  required String code,
}) async {
  final origin = window.location.origin;
  final body = {
    'grant_type': 'authorization_code',
    'client_id': appKey,
    'redirect_uri': _kakaoRedirectUri,
    'code': code,
    'client_origin': origin,
    'ka': _kaHeader(origin),
  }.entries
      .map(
        (entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      )
      .join('&');

  final raw = await _awaitJsString(() => _jsKakaoToken(body));
  final envelope = _decodeMap(raw, 'token-request-failed');
  final status = envelope['status'];
  final text = envelope['text']?.toString() ?? '';
  Map<String, dynamic> payload;
  try {
    payload = _decodeMap(text, 'token-invalid');
  } catch (_) {
    throw KakaoWebLoginException(
      'failed',
      'token-invalid status=$status body=$text',
    );
  }
  final error = payload['error']?.toString() ?? '';
  if (error.isNotEmpty) {
    throw _authError(
      error,
      payload['error_description']?.toString() ?? 'status=$status',
    );
  }
  if (envelope['ok'] == false) {
    throw KakaoWebLoginException('failed', 'token-http status=$status body=$text');
  }
  final accessToken = payload['access_token']?.toString() ?? '';
  if (accessToken.isEmpty) {
    throw KakaoWebLoginException('failed', 'access-token-missing $text');
  }
  final idToken = payload['id_token']?.toString();
  return KakaoWebTokens(
    accessToken: accessToken,
    idToken: (idToken == null || idToken.isEmpty) ? null : idToken,
  );
}

Future<String> _awaitJsString(JSPromise<JSString> Function() run) async {
  try {
    return (await run().toDart).toDart;
  } catch (error) {
    throw _fromJsAuthError(error);
  }
}

Map<String, dynamic> _decodeMap(String raw, String fallback) {
  if (raw.isEmpty) {
    throw KakaoWebLoginException('failed', fallback);
  }
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw KakaoWebLoginException('failed', '$fallback $raw');
}

String _kaHeader(String origin) {
  final language = window.navigator.language;
  final device = window.navigator.platform.replaceAll(' ', '_');
  return [
    'sdk/2.7.5',
    'os/javascript',
    'sdk_type/javascript',
    'lang/$language',
    'device/$device',
    'origin/${Uri.encodeComponent(origin)}',
  ].join(' ');
}

KakaoWebLoginException _fromJsAuthError(Object error) {
  if (error is KakaoWebLoginException) return error;
  final text = error.toString();
  if (text.toLowerCase().contains('access_denied')) {
    return const KakaoWebLoginException('canceled');
  }
  return _authError('', text);
}

KakaoWebLoginException _authError(String code, String description) {
  if (code == 'access_denied') {
    return const KakaoWebLoginException('canceled');
  }
  return KakaoWebLoginException(
    _isMisconfigured(code, description) ? 'misconfigured' : 'failed',
    description.isEmpty ? code : description,
  );
}

bool _isMisconfigured(String code, String description) {
  final text = '$code $description'.toLowerCase();
  return text.contains('koe101') ||
      text.contains('koe006') ||
      text.contains('invalid android_key') ||
      text.contains('invalid origin') ||
      text.contains('not registered') ||
      text.contains('site domain') ||
      text.contains('unregistered');
}
