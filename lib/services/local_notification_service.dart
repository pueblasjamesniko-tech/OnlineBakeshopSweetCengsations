import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Foreground (and other in-app) notifications via [FlutterLocalNotificationsPlugin].
/// Android notification permission is requested in [setupFcmAndroid]; this service
/// only creates the channel and shows notifications.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'online_bakeshop_default';
  static const String _channelName = 'General';
  static const String _channelDescription = 'App notifications';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint(
        'Local notification tapped: id=${response.id}, payload=${response.payload}',
      );
    }
  }

  /// Shows a notification for an FCM message (e.g. foreground, where the system
  /// does not display the notification payload automatically on Android).
  Future<void> showFromRemoteMessage(RemoteMessage message) async {
    if (!_initialized) await init();

    final n = message.notification;
    var title = n?.title?.trim() ?? '';
    var body = n?.body?.trim() ?? '';

    if (title.isEmpty && body.isEmpty) {
      final data = message.data;
      title = data['title']?.toString().trim() ?? '';
      body = data['body']?.toString().trim() ??
          data['message']?.toString().trim() ??
          '';
    }

    if (title.isEmpty && body.isEmpty) return;

    final id = _notificationId(message);

    String? payload;
    if (message.data.isNotEmpty) {
      try {
        payload = jsonEncode(message.data);
      } catch (_) {
        payload = message.messageId;
      }
    } else {
      payload = message.messageId;
    }

    await _plugin.show(
      id,
      title.isEmpty ? 'Notification' : title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  static int _notificationId(RemoteMessage message) {
    final raw = message.messageId;
    if (raw != null && raw.isNotEmpty) {
      return raw.hashCode.abs() % 2147483647;
    }
    return Object.hash(
          message.hashCode,
          DateTime.now().millisecondsSinceEpoch,
        ).abs() %
        2147483647;
  }
}
