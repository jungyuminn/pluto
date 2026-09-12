abstract final class OauthConfig {
  /// 카카오 디벨로퍼스 > 앱 > 앱 키 > 네이티브 앱 키.
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '6aede049b89802a11282dd82c57ef8c6',
  );

  /// 카카오 디벨로퍼스 > 앱 > 앱 키 > JavaScript 키.
  /// 웹 카카오 로그인에 필요합니다.
  static const kakaoJavaScriptAppKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_APP_KEY',
    defaultValue: '97649502c9b3b8c6b90b2254bffe4ad8',
  );

  static bool get kakaoEnabled => kakaoNativeAppKey.isNotEmpty;

  static bool get kakaoWebEnabled => kakaoJavaScriptAppKey.isNotEmpty;

  /// Firebase App Check 웹용 reCAPTCHA Enterprise 사이트 키.
  /// 콘솔 > App Check > 웹 앱에서 발급합니다.
  static const recaptchaSiteKey = String.fromEnvironment(
    'APP_CHECK_RECAPTCHA_SITE_KEY',
    defaultValue: '6Leq2LctAAAAAPxl0j0yQRHcPuSu1ipTx3jK8w8k',
  );

  /// iOS 디버그 App Check 토큰. 콘솔 > App Check > Pluto (iOS) > 디버그 토큰.
  static const appCheckIosDebugToken = String.fromEnvironment(
    'APP_CHECK_IOS_DEBUG_TOKEN',
    defaultValue: 'bb685018-7270-4edc-9cf3-e5644cb5f861',
  );
}
