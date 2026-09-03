abstract final class OauthConfig {
  /// 카카오 디벨로퍼스 > 앱 > 플랫폼 키 > 네이티브 앱 키.
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '6aede049b89802a11282dd82c57ef8c6',
  );

  static bool get kakaoEnabled => kakaoNativeAppKey.isNotEmpty;
}
