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

Future<void> prepareKakaoWebSdk(String appKey) async {}

Future<KakaoWebTokens> loginWithKakaoOnWeb({
  required String appKey,
  String? nonce,
}) {
  throw const KakaoWebLoginException('failed', 'not-web');
}
