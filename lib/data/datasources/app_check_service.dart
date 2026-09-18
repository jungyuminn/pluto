import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/core/constants/oauth_config.dart';
import 'package:pluto/data/datasources/app_check_web_register.dart';

abstract final class AppCheckService {
  static void registerWebPlugin() {
    registerAppCheckWebPlugin();
  }

  static Future<void> activate() async {
    if (Firebase.apps.isEmpty) return;
    registerWebPlugin();
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? AppleDebugProvider(
                debugToken: OauthConfig.appCheckIosDebugToken.isEmpty
                    ? null
                    : OauthConfig.appCheckIosDebugToken,
              )
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        providerWeb: _webProvider(),
      );
    } catch (error) {
      debugPrint('App Check init failed: $error');
    }
  }

  static WebProvider _webProvider() {
    if (kDebugMode) return WebDebugProvider();
    final key = OauthConfig.recaptchaSiteKey;
    if (key.isNotEmpty) return ReCaptchaEnterpriseProvider(key);
    return WebDebugProvider();
  }
}
