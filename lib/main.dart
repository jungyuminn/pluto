import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:job_planner/app.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
