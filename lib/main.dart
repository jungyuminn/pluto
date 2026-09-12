import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:pluto/app.dart';
import 'package:pluto/core/constants/oauth_config.dart';
import 'package:pluto/core/home_widget/home_screen_widget_service.dart';
import 'package:pluto/data/datasources/app_check_service.dart';
import 'package:pluto/data/datasources/kakao_web_auth.dart';
import 'package:pluto/firebase_options.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AppCheckService.activate();
    }
  } catch (error) {
    debugPrint('Firebase init failed: $error');
  }
  try {
    if (OauthConfig.kakaoEnabled || OauthConfig.kakaoWebEnabled) {
      await KakaoSdk.init(
        nativeAppKey: OauthConfig.kakaoNativeAppKey.isEmpty
            ? null
            : OauthConfig.kakaoNativeAppKey,
        javaScriptAppKey: OauthConfig.kakaoJavaScriptAppKey.isEmpty
            ? null
            : OauthConfig.kakaoJavaScriptAppKey,
      );
    }
    if (kIsWeb && OauthConfig.kakaoWebEnabled) {
      try {
        await prepareKakaoWebSdk(OauthConfig.kakaoJavaScriptAppKey);
      } catch (error) {
        debugPrint('Kakao JS SDK init failed: $error');
      }
    }
  } catch (error) {
    debugPrint('Kakao init failed: $error');
  }
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(HomeScreenWidgetService.appGroupId);
      }
      await HomeWidget.registerInteractivityCallback(
        homeWidgetInteractiveCallback,
      );
    } catch (error) {
      debugPrint('HomeWidget interactivity failed: $error');
    }
  }
  runApp(const JobPlannerApp());
}
