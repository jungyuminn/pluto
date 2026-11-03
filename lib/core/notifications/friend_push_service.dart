import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/notifications/todo_reminder_service.dart';

@pragma('vm:entry-point')
Future<void> friendPushBackgroundHandler(RemoteMessage message) async {}

class FriendPushService {
  FriendPushService._();

  static final instance = FriendPushService._();
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const payload = 'friend';
  static const friendsRoute = '/friends';
  static WidgetBuilder? friendsPage;

  var _attached = false;
  var _pendingOpen = false;
  StreamSubscription<String>? _tokenSub;
  String? _token;

  Future<void> attach() async {
    if (kIsWeb || _attached) return;
    if (Firebase.apps.isEmpty) return;
    _attached = true;
    TodoReminderService.instance.onTap = (value) {
      if (value == payload) openFriends();
    };
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: false,
        sound: true,
      );
    } catch (error) {
      debugPrint('FriendPushService presentation failed: $error');
    }
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => openFriends());
    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) openFriends();
      }),
    );
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        unawaited(_dropLocal());
      } else {
        unawaited(sync());
      }
    });
    if (FirebaseAuth.instance.currentUser != null) {
      unawaited(sync());
    }
  }

  Future<void> sync() async {
    if (kIsWeb) return;
    if (Firebase.apps.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) return;
      if (!kIsWeb && Platform.isAndroid) {
        await TodoReminderService.instance.requestPermission(
          requestExactAlarms: false,
        );
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(uid, token);
      _tokenSub ??=
          FirebaseMessaging.instance.onTokenRefresh.listen((next) {
        final current = FirebaseAuth.instance.currentUser?.uid;
        if (current == null) return;
        unawaited(_saveToken(current, next));
      });
    } catch (error) {
      debugPrint('FriendPushService.sync failed: $error');
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = _token;
    if (uid != null && token != null && token.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .doc(_tokenId(token))
            .delete();
      } catch (error) {
        debugPrint('FriendPushService token delete failed: $error');
      }
    }
    await _dropLocal();
  }

  void openFriends() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingOpen = true;
      return;
    }
    var onFriends = false;
    nav.popUntil((route) {
      if (route.settings.name == friendsRoute) {
        onFriends = true;
      }
      return true;
    });
    if (onFriends) return;
    final page = friendsPage;
    if (page == null) {
      _pendingOpen = true;
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: friendsRoute),
        builder: page,
      ),
    );
  }

  void consumePending() {
    if (!_pendingOpen) return;
    _pendingOpen = false;
    openFriends();
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final type = message.data['type'] ?? '';
    const friendTypes = {
      'friend_request',
      'friend_accepted',
      'todo_request',
      'todo_accepted',
    };
    if (!friendTypes.contains(type)) {
      if (message.notification == null) return;
    }
    if (!kIsWeb && Platform.isIOS) return;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty) return;
    await TodoReminderService.instance.showNow(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _saveToken(String uid, String token) async {
    _token = token;
    final platform = !kIsWeb && Platform.isIOS ? 'ios' : 'android';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(_tokenId(token))
        .set({
      'token': token,
      'platform': platform,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _dropLocal() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    final had = _token;
    _token = null;
    if (had == null) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  String _tokenId(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
