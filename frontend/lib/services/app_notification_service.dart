import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: settings,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> createInboxNotification({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? payload,
    String? uniqueKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    if (uniqueKey != null && uniqueKey.trim().isNotEmpty) {
      final existing = await collection
          .where('uniqueKey', isEqualTo: uniqueKey)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return;
      }
    }

    await collection.add({
      'title': title,
      'body': body,
      'type': type,
      'uniqueKey': uniqueKey,
      'isRead': false,
      'payload': payload ?? <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await showLocalNotification(title: title, body: body);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'moneo_general_notifications',
        'Monéo Notifications',
        channelDescription: 'General notifications for Monéo app',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }
  }
}
