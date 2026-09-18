import 'package:firebase_app_check_web/firebase_app_check_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerAppCheckWebPlugin() {
  FirebaseAppCheckWeb.registerWith(webPluginRegistrar);
}
