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
import 'package:food_app/utils/printer_helper_english.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:food_app/init_app.dart';
import 'package:food_app/utils/battery_optimization.dart';
import 'package:food_app/utils/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/repository/api_repository.dart';
import 'constants/constant.dart';
import 'constants/routes.dart';
import 'models/order_model.dart';

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
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // INITIALIZE GETX AND TRANSLATIONS FOR BACKGROUND
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String savedLocale = prefs.getString('selected_language') ?? 'en';

  // Initialize GetX in isolation
  Get.put(AppTranslations());
  Get.updateLocale(Locale(savedLocale));

  final title = message.notification?.title ?? '';
  final body = message.notification?.body ?? '';

  print('📥 Background title: $title');
  print('📥 Background body: $body');
  print('🌐 Background locale set to: $savedLocale');

  // Rest of your background handler code...
  if (title.contains('New Order')) {
    await _showOrderNotification(title, body);

    RegExp regex = RegExp(r'#(\d+)');
    Match? match = regex.firstMatch(body);

    if (match != null) {
      String orderNumberStr = match.group(1)!;
      try {
        int orderNumber = int.parse(orderNumberStr);
        print("🆔 Background - Processing Order ID: $orderNumber");

        bool autoAccept = prefs.getBool('auto_order_accept') ?? false;
        bool autoPrint = prefs.getBool('auto_order_print') ?? false;

        if (autoAccept || autoPrint) {
          await handleBackgroundOrderComplete(orderNumber);
        }
      } catch (e) {
        print('❌ DEBUG: Error parsing order number: $e');
      }
    }
  }

  badgeCount++;
  try {
    await AppBadgePlus.updateBadge(badgeCount);
  } catch (e) {
    print('❌ DEBUG: Badge update failed: $e');
  }
}

// Enhanced handleBackgroundOrderComplete with more debug logs


Future<void> handleBackgroundOrderComplete(int orderNumber) async {
  try {
    print("🚀 Background order processing started for: $orderNumber");

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    String? storeID = prefs.getString(valueShared_STORE_KEY);
    bool autoAccept = prefs.getBool('auto_order_accept') ?? false;
    bool autoPrint = prefs.getBool('auto_order_print') ?? false;

    print("🔍 DEBUG: Bearer key exists: ${bearerKey != null}");
    print("🔍 DEBUG: Store ID exists: ${storeID != null}");
    print("🔍 DEBUG: Auto Accept: $autoAccept");
    print("🔍 DEBUG: Auto Print: $autoPrint");

    if (bearerKey == null) {
      print("❌ Background - Bearer key not found");
      return;
    }

    if (storeID == null) {
      print("❌ Background - Store ID not found");
      return;
    }

    // If both are disabled, don't proceed
    if (!autoAccept && !autoPrint) {
      print("ℹ️ Background - Both auto accept and auto print disabled");
      return;
    }

    // Step 1: Get order data
    print("📥 Background - Fetching order data for order: $orderNumber");

    try {
      final orderData = await ApiRepo().getNewOrderData(bearerKey, orderNumber);

      if (orderData == null) {
        print("❌ Background - Failed to get order data (null response)");
        return;
      }

      print("✅ Background - Order data retrieved: ID ${orderData.id}");
      print("🔍 DEBUG: Order status: ${orderData.orderStatus}");

      // Step 2: Auto Accept if enabled
      if (autoAccept) {
        print("🤖 Background - Auto accepting order: $orderNumber");

        Map<String, dynamic> jsonData = {
          "order_status": 2,  // 2 = Accepted
          "approval_status": 2,
        };

        print("🔍 DEBUG: Sending accept request with data: $jsonData");

        final acceptResult = await ApiRepo().orderAcceptDecline(
            bearerKey, jsonData, orderData.id ?? 0);

        if (acceptResult != null) {
          print("✅ Background - Order auto-accepted successfully");
          print("🔍 DEBUG: Accept result: $acceptResult");

          // Step 3: Auto Print if enabled (after successful accept)
          if (autoPrint) {
            print("🖨️ Background - Starting auto print process...");

            // Wait for invoice to be generated
            print("⏳ Background - Waiting 3 seconds for invoice generation...");
            await Future.delayed(Duration(seconds: 3));

            // Get updated order with invoice data
            print("📥 Background - Fetching updated order data...");
            final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderNumber);

            if (updatedOrder?.invoice != null &&
                (updatedOrder?.invoice?.invoiceNumber ?? '').isNotEmpty) {

              print("✅ Background - Invoice found, printing with invoice...");
              await backgroundPrintOrder(updatedOrder!, prefs);

            } else {
              print("⚠️ Background - Invoice not ready, printing without invoice...");
              await backgroundPrintOrder(orderData, prefs);
            }
          }
        } else {
          print("❌ Background - Failed to auto-accept order (null response)");
        }
      } else if (autoPrint) {
        // If only auto print is enabled (without auto accept)
        print("🖨️ Background - Auto print enabled, processing without accept...");
        await backgroundPrintOrder(orderData, prefs);
      }

      // Step 4: Refresh orders in background
      print("🔄 Background - Refreshing orders list...");
      await refreshOrdersInBackground(bearerKey, storeID);

      print("🎉 Background processing completed for order: $orderNumber");

    } catch (apiError) {
      print("❌ Background - API Error: $apiError");
    }

  } catch (e) {
    print("❌ Background handler error: $e");
    print("❌ Background handler stack trace: ${e.toString()}");
  }
}

// Enhanced background print function with better error handling:

Future<void> backgroundPrintOrder(Order order, SharedPreferences prefs) async {
  try {
    debugPrint("🖨️ Background printing started for order: ${order.id}");

    // Get printer IP from settings
    String? selectedIp = prefs.getString('printer_ip_0') ?? '';

    if (selectedIp.isEmpty) {
      debugPrint("❌ Background - Printer IP not configured");

      // Try to get any available printer IP
      for (int i = 0; i < 5; i++) {
        String? ip = prefs.getString('printer_ip_$i');
        if (ip != null && ip.isNotEmpty) {
          selectedIp = ip;
          debugPrint("🔄 Background - Using alternative printer IP: $selectedIp");
          break;
        }
      }

      if (selectedIp!.isEmpty) {
        debugPrint("❌ Background - No printer IP configured at all");
        return;
      }
    }

    debugPrint("🖨️ Background - Using printer IP: $selectedIp");

    // Background printing using your existing printer helper
    await PrinterHelperEnglish.printInBackground(
        order: order,
        ipAddress: selectedIp!,
        store: ''
    );

    debugPrint("✅ Background print completed successfully for order: ${order.id}");

    // Store successful print in preferences for tracking
    List<String> printedOrders = prefs.getStringList('printed_orders_bg') ?? [];
    printedOrders.add('${order.id}_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setStringList('printed_orders_bg', printedOrders);

  } catch (e) {
    debugPrint("❌ Background print error: $e");

    // Store failed print for retry later
    List<String> failedPrints = prefs.getStringList('failed_prints_bg') ?? [];
    failedPrints.add('${order.id}_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setStringList('failed_prints_bg', failedPrints);
  }
}

// BACKGROUND ORDERS REFRESH
Future<void> refreshOrdersInBackground(String bearerKey, String storeID) async {
  try {
    print("🔄 Background - Refreshing orders from server...");

    DateTime formatted = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(formatted);

    final Map<String, dynamic> data = {
      "store_id": storeID,
      "target_date": date,
      "limit": 0,
      "offset": 0,
    };

    final result = await ApiRepo().orderGetApiFilter(bearerKey, data);

    if (result.isNotEmpty && result.first.code == null) {
      print("✅ Background - Orders refreshed successfully: ${result.length} orders");
    } else {
      print("⚠️ Background - Orders refresh returned no data");
    }

  } catch (e) {
    print("❌ Background refresh error: $e");
  }
}

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