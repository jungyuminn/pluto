import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:job_planner/app.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.registerInteractivityCallback(homeWidgetInteractiveCallback);
  runApp(const JobPlannerApp());
}
