import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:job_planner/app.dart';
import 'package:job_planner/core/constants/oauth_config.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/firebase_options.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (error) {
    debugPrint('Firebase init failed: $error');
  }
  try {
    if (OauthConfig.kakaoEnabled) {
      await KakaoSdk.init(nativeAppKey: OauthConfig.kakaoNativeAppKey);
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
