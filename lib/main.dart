import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../theme/app_theme.dart';
import '../screens/splash_screen.dart';

// This function runs in the background when a notification arrives
// even if the app is closed — Firebase requires this to be outside any class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// This is the first thing that runs when the app opens
// Makes sure Flutter is ready before we do anything else
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start up Firebase so notifications and other services work
  await Firebase.initializeApp();

  // Tell Firebase to use our background handler for notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Ask the user if it's okay to send them notifications
  await FirebaseMessaging.instance.requestPermission(
    alert: true, // show notification text
    badge: true, // show number badge on app icon
    sound: true, // play a sound
  );
  // Make the top status bar (where the clock is) transparent and use dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Launch the app!
  runApp(const SweetCengsationsApp());
}

// The root widget — this is the "wrapper" that holds the entire app
class SweetCengsationsApp extends StatelessWidget {
  const SweetCengsationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweet Cengsations',
      debugShowCheckedModeBanner:
          false, // hides the red "DEBUG" banner on screen
      theme:
          AppTheme.lightTheme, // applies our custom bakeshop colors and fonts
      home: const SplashScreen(), // the first screen the user sees
    );
  }
}
