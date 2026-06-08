import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fintech/services/app_notification_service.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onMessageOpenedApp(initial);
    }

    _messaging.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await syncTokenForCurrentUser();
      }
    });

    if (FirebaseAuth.instance.currentUser != null) {
      await syncTokenForCurrentUser();
    }
  }

  Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FCM] Permission request failed: $e');
    }
  }

  Future<void> syncTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(user.uid, token);
      }
    } catch (e) {
      debugPrint('[FCM] Token sync failed: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _messaging.deleteToken();
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': FieldValue.delete()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[FCM] Clear token failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;

    AppNotificationService.instance.showLocalNotification(
      title: title,
      body: body,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
  }
}
