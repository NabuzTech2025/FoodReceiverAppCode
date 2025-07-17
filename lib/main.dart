import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:food_app/push/NotificationService.dart';
import 'package:food_app/utils/AppTranslations.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:food_app/init_app.dart';
import 'package:food_app/utils/battery_optimization.dart';
import 'package:food_app/utils/global.dart';

import 'constants/routes.dart';

// -----------------------------------------------------------------------------
//  GLOBALS
// -----------------------------------------------------------------------------

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final FirebaseMessaging _fcm = FirebaseMessaging.instance;

int badgeCount = 0;

// -----------------------------------------------------------------------------
//  MAIN ENTRY
// -----------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase --------------------------------------------------------------
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // iOS-specific: request permissions *before* getting the token ----------
  await _requestIOSPermissions();

  // Present notifications when app is in foreground (iOS 10+) ------------
  await _fcm.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Local-notifications ---------------------------------------------------
  await _initializeLocalNotifications();

  // Push-notification service wrapper (custom logic) ---------------------
  NotificationService.initialize();

  // Register foreground / opened-app listeners ---------------------------
  _registerForegroundListeners();

  // Device orientation ---------------------------------------------------
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Your own boot-strap routine -----------------------------------------
  await initApp();

  // Battery optimisation (Android) – optional ----------------------------
  // await askIgnoreBatteryOptimizations();
  // checkBatteryOptimization();

  runApp(const AppLifecycleObserver(child: MyApp()));
}

// -----------------------------------------------------------------------------
//  iOS permission helper
// -----------------------------------------------------------------------------

Future<void> _requestIOSPermissions() async {
  if (Platform.isIOS) {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }
}

// -----------------------------------------------------------------------------
//  LISTENERS (foreground, background-tap, cold-start)
// -----------------------------------------------------------------------------

// void _registerForegroundListeners() {
//   // Foreground messages
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//     final title = message.notification?.title ?? '';
//     final body = message.notification?.body ?? '';
//
//     // You can choose to show a local notification here too
//     if (title.contains('New Order')) {
//       await _showOrderNotification(title, body);
//     }
//     badgeCount++;
//
//     try {
//       await AppBadgePlus.updateBadge(badgeCount);
//     } catch (e) {
//       debugPrint('Badge update failed: $e');
//     }
//
//   });
//
//   // User tapped a notification
//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     callOrderApiFromNotification();
//   });
//
//   // App launched by tapping a notification (cold start)
//   _fcm.getInitialMessage().then((message) {
//     if (message != null) {
//       callOrderApiFromNotification();
//     }
//   });
// }
void _registerForegroundListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    if (title.contains('New Order')) {
      await _showOrderNotification(title, body);
    }

    badgeCount++;

    try {
      await AppBadgePlus.updateBadge(badgeCount);
    } catch (e) {
      debugPrint('Badge update failed: $e');
    }

  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    callOrderApiFromNotification();
  });

  _fcm.getInitialMessage().then((message) {
    if (message != null) {
      callOrderApiFromNotification();
    }
  });
}

// -----------------------------------------------------------------------------
//  BATTERY OPTIMISATION HELPERS (ANDROID-ONLY)
// -----------------------------------------------------------------------------

void checkBatteryOptimization() async {
  bool isIgnored = await isIgnoringBatteryOptimizations();
  if (!isIgnored) {
    await askIgnoreBatteryOptimizations();
  }
}

Future<void> askIgnoreBatteryOptimizations() async {
  if (Platform.isAndroid) {
    const platform = MethodChannel('com.food.mandeep.food_app/battery');

    try {
      final bool isIgnoring =
      await platform.invokeMethod('isIgnoringBatteryOptimizations');

      if (!isIgnoring) {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          data: 'package:com.food.mandeep.food_app',
        );
        await intent.launch();
      }
    } on PlatformException {
      debugPrint('❌ Failed to request battery-optimisation exemption');
    }
  }
}

// -----------------------------------------------------------------------------
//  LOCAL NOTIFICATIONS (ANDROID + iOS)
// -----------------------------------------------------------------------------

Future<void> _initializeLocalNotifications() async {
  // --- Android settings --------------------------------------------------
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  // --- iOS / macOS settings ---------------------------------------------
  const darwinInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Combine for all platforms -------------------------------------------
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
    macOS: darwinInit,
  );

  // Initialise plugin ----------------------------------------------------
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (_) => callOrderApiFromNotification(),
  );

  // Android notification channel (high importance) ----------------------
  const channel = AndroidNotificationChannel(
    'order_channel',
    'Order Notifications',
    description: 'This channel is used for order alerts',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('alarm'),
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Runtime permission (Android 13+) ------------------------------------
  if (Platform.isAndroid && await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

// Helper that both foreground and background code can call
// Future<void> _showOrderNotification(String title, String body) async {
//   const androidDetails = AndroidNotificationDetails(
//     'order_channel',
//     'Order Notifications',
//     channelDescription: 'This channel is used for order alerts',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     sound: RawResourceAndroidNotificationSound('alarm'),
//   );
//
//   const iosDetails = DarwinNotificationDetails(
//     presentAlert: true,
//     presentBadge: true,
//     presentSound: true,
//     sound: 'alarm', // alarm.caf in ios/Runner
//   );
//
//   const platformDetails = NotificationDetails(
//     android: androidDetails,
//     iOS: iosDetails,
//     macOS: iosDetails,
//   );
//
//   await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
// }

Future<void> _showOrderNotification(String title, String body) async {
  final androidDetails = AndroidNotificationDetails(
    'order_channel',
    'Order Notifications',
    channelDescription: 'This channel is used for order alerts',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    badgeNumber: badgeCount, // ✅ Yeh add kiya
    sound: 'alarm',
  );

  final platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
    macOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
      0, title, body, platformDetails
  );
}

// -----------------------------------------------------------------------------
//  BACKGROUND FCM HANDLER
// -----------------------------------------------------------------------------

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//
//   final title = message.notification?.title ?? '';
//   final body = message.notification?.body ?? '';
//   debugPrint('📥 Background title: $title');
//   debugPrint('📥 Background body: $body');
//
//   if (title.contains('New Order')) {
//     await _showOrderNotification(title, body);
//   }
//   badgeCount++;
//
//   try {
//     await AppBadgePlus.updateBadge(badgeCount);
//   } catch (e) {
//     debugPrint('Badge update failed: $e');
//   }
// }
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final title = message.notification?.title ?? '';
  final body = message.notification?.body ?? '';

  debugPrint('📥 Background title: $title');
  debugPrint('📥 Background body: $body');

  if (title.contains('New Order')) {
    await _showOrderNotification(title, body);
  }

  badgeCount++;

  try {
    await AppBadgePlus.updateBadge(badgeCount);
  } catch (e) {
    debugPrint('Badge update failed: $e');
  }

}


// -----------------------------------------------------------------------------
//  NOTIFICATION TAP HANDLER
// -----------------------------------------------------------------------------

Future<void> callOrderApiFromNotification() async {
  debugPrint('📞 API called from notification tap!');
  await getOrdersInBackground();
}

// -----------------------------------------------------------------------------
//  ROOT WIDGET
// -----------------------------------------------------------------------------


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: appRoutes(),
      theme: ThemeData(primaryColor: Colors.blue),
      translations: AppTranslations(),
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      builder: (_, child) => child ?? const SizedBox.shrink(),
    );
  }
}

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clearBadgeOnAppOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      clearBadgeOnAppOpen();
    }
  }

  void clearBadgeOnAppOpen() async {
    badgeCount = 0;

    try {
      await AppBadgePlus.updateBadge(0);
    } catch (e) {
      debugPrint('Badge clear failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}