import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:sweet_cengsations/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweet_cengsations/services/api_service.dart';
import 'package:sweet_cengsations/services/local_notification_service.dart';

/// Must be a top-level function. Runs in a background isolate.
@pragma('vm:entry-point')
Future<void> fvmService(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
}

// Future<String?> _readAccessToken() async {
//   final storage = AuthStorage(await SharedPreferences.getInstance());
//   return storage.readAccessToken();
// }

/// Registers this Android device + FCM token via [DeviceService].
/// No-ops if there is no saved access token (user not signed in).
// Future<void> registerDeviceWithFcmToken(String fcmToken) async {
//   if (fcmToken.isEmpty || !Platform.isAndroid) return;

//   final accessToken = await _readAccessToken();
//   if (accessToken == null || accessToken.isEmpty) return;

//   final android = await DeviceInfoPlugin().androidInfo;

//   final request = DeviceRegisterRequest(
//     deviceToken: fcmToken,
//     platform: 'android',
//     deviceId: android.id,
//     deviceName: '${android.manufacturer} ${android.model}'.trim(),
//   );

//   await ApiService().registerDevice(
//     request: request,
//     accessToken: accessToken,
//   );
// }

// /// Uses the current FCM token and saved auth token. Call after sign-in or session restore.
// Future<void> syncDeviceRegistrationWithBackend() async {
//   if (!Platform.isAndroid) return;
//   final fcmToken = await FirebaseMessaging.instance.getToken();
//   if (fcmToken == null || fcmToken.isEmpty) return;
//   await registerDeviceWithFcmToken(fcmToken);
// }

// /// Call after [Firebase.initializeApp] succeeds. Android only.
// Future<void> setupFcmAndroid() async {
//   if (!Platform.isAndroid) return;

//   final messaging = FirebaseMessaging.instance;

//   await LocalNotificationService.instance.init();

//   final notificationStatus = await Permission.notification.request();
//   if (kDebugMode) {
//     debugPrint('Notification permission: $notificationStatus');
//   }

//   await messaging.requestPermission(alert: true, badge: true, sound: true);

//   final token = await messaging.getToken();
//   if (kDebugMode) {
//     debugPrint('FCM token: $token');
//   }

//   if (token != null && token.isNotEmpty) {
//     try {
//       await registerDeviceWithFcmToken(token);
//     } catch (e, st) {
//       if (kDebugMode) {
//         debugPrint('registerDevice failed: $e');
//         debugPrint('$st');
//       }
//     }
//   }

//   messaging.onTokenRefresh.listen((newToken) async {
//     if (kDebugMode) debugPrint('FCM token refresh: $newToken');
//     try {
//       await registerDeviceWithFcmToken(newToken);
//     } catch (e, st) {
//       if (kDebugMode) {
//         debugPrint('registerDevice (refresh) failed: $e');
//         debugPrint('$st');
//       }
//     }
//   });

//   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//     if (kDebugMode) {
//       debugPrint('Foreground message id: ${message.messageId}');
//       debugPrint('Foreground data: ${message.data}');
//     }
//     try {
//       await LocalNotificationService.instance.showFromRemoteMessage(message);
//     } catch (e, st) {
//       if (kDebugMode) {
//         debugPrint('showFromRemoteMessage failed: $e');
//         debugPrint('$st');
//       }
//     }
//   });

//   final initial = await messaging.getInitialMessage();
//   if (initial != null && kDebugMode) {
//     debugPrint('App opened from terminated state via notification');
//   }

//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     if (kDebugMode) {
//       debugPrint('Notification opened from background: ${message.messageId}');
//     }
//   });
// }
