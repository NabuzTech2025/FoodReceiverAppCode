import 'dart:io';
import 'dart:math' as Math;

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:food_app/push/NotificationService.dart';
import 'package:food_app/ui/LoginScreen.dart';
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("🔥 Background handler triggered");

  // ✅ Multiple attempts to get fresh SharedPreferences
  SharedPreferences? prefs;
  String? bearerKey;
  String? storeID;

  for (int attempt = 0; attempt < 5; attempt++) { // Increased attempts
    try {
      print("🔄 Attempt ${attempt + 1}/5 to get fresh preferences");

      prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      await Future.delayed(Duration(milliseconds: 500)); // Increased delay

      bearerKey = prefs.getString(valueShared_BEARER_KEY);
      storeID = prefs.getString(valueShared_STORE_KEY);

      print("🔍 Attempt ${attempt + 1} - Token: ${bearerKey?.substring(0, 20) ?? 'NULL'}...");
      print("🔍 Attempt ${attempt + 1} - Store: $storeID");

      if (bearerKey != null && bearerKey.isNotEmpty) {
        print("✅ Token found on attempt ${attempt + 1}");
        break;
      }

      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      print("❌ Attempt ${attempt + 1} failed: $e");
    }
  }

  final title = message.notification?.title ?? '';
  final body = message.notification?.body ?? '';

  print('📥 Background title: $title');
  print('📥 Background body: $body');

  // ✅ Show notification regardless of token status
  if (title.contains('New Order')) {
    await _showOrderNotification(title, body);
  }

  badgeCount++;
  try {
    await AppBadgePlus.updateBadge(badgeCount);
  } catch (e) {
    print('❌ Badge update failed: $e');
  }

  // ✅ Token validation - More lenient check
  if (bearerKey == null || bearerKey.isEmpty) {
    print("❌ Background - No bearer token found after all attempts, skipping processing");
    return;
  }

  // ✅ Get and log current settings with multiple attempts
  bool autoAccept = false;
  bool autoPrint = false;

  for (int i = 0; i < 5; i++) { // Increased attempts
    try {
      print("🔄 Settings read attempt ${i + 1}/5");

      // Force reload SharedPreferences
      await prefs!.reload();
      await Future.delayed(Duration(milliseconds: 300));

      autoAccept = prefs.getBool('auto_order_accept') ?? false;
      autoPrint = prefs.getBool('auto_order_print') ?? false;

      print("🔍 Settings attempt ${i + 1}:");
      print("🔍 Auto Accept: $autoAccept");
      print("🔍 Auto Print: $autoPrint");

      // If we got any true value, settings are probably correct
      if (autoAccept || autoPrint) {
        print("✅ Found enabled settings on attempt ${i + 1}");
        break;
      }

      // Try to get fresh instance
      if (i < 4) {
        prefs = await SharedPreferences.getInstance();
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print("❌ Settings read attempt ${i + 1} failed: $e");
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

// ✅ Additional debugging - check all keys
  try {
    Set<String> keys = prefs!.getKeys();
    print("🔍 All SharedPreferences keys: $keys");

    for (String key in keys) {
      if (key.contains('auto_')) {
        var value = prefs.get(key);
        print("🔍 Key: $key, Value: $value, Type: ${value.runtimeType}");
      }
    }
  } catch (e) {
    print("❌ Error checking keys: $e");
  }

  print("✅ Background - Valid token found: ${bearerKey.substring(0, 20)}...");
  print("✅ Background - Store ID: ${storeID ?? 'MISSING'}");
  print("✅ Background - Final Auto Accept: $autoAccept");
  print("✅ Background - Final Auto Print: $autoPrint");

  // ✅ ADDED: Early exit if both features are disabled
  if (!autoAccept && !autoPrint) {
    print("ℹ️ Background - Both auto features disabled, showing notification only");
    return; // Exit early, don't process order
  }

  String savedLocale = prefs!.getString('selected_language') ?? 'de';

  // Initialize GetX in isolation
  try {
    Get.put(AppTranslations());
    Get.updateLocale(Locale(savedLocale));
  } catch (e) {
    print("⚠️ GetX initialization error: $e");
  }

  print('🌐 Background locale set to: $savedLocale');

  if (title.contains('New Order')) {
    RegExp regex = RegExp(r'#(\d+)');
    Match? match = regex.firstMatch(body);

    if (match != null) {
      String orderNumberStr = match.group(1)!;
      try {
        int orderNumber = int.parse(orderNumberStr);
        print("🆔 Background - Processing Order ID: $orderNumber");

        print("🔍 Final Check - Auto Accept: $autoAccept");
        print("🔍 Final Check - Auto Print: $autoPrint");

        // ✅ FIXED: Only process if at least one feature is enabled
        if (autoAccept || autoPrint) {
          print("✅ Background - At least one auto feature enabled, processing order");
          await handleBackgroundOrderComplete(orderNumber, prefs, bearerKey, storeID);
        } else {
          print("ℹ️ Background - Auto features disabled - Accept: $autoAccept, Print: $autoPrint");
          print("ℹ️ Background - Order notification shown but not processed");
        }
      } catch (e) {
        print('❌ Error parsing order number: $e');
      }
    } else {
      print("❌ Could not extract order number from: $body");
    }
  }
}

// ✅ Updated background order handler with proper condition checks
Future<void> handleBackgroundOrderComplete(int orderNumber, SharedPreferences prefs, String bearerKey, String? storeID) async {
  try {
    print("🚀 Background order processing started for: $orderNumber");
    print("🔑 Using token: ${bearerKey.substring(0, 20)}...");
    print("🏪 Using store: ${storeID ?? 'NULL'}");

    bool autoAccept = prefs.getBool('auto_order_accept') ?? false; // ✅ Default false instead of true
    bool autoPrint = prefs.getBool('auto_order_print') ?? false;   // ✅ Default false instead of true

    print("🔍 Auto Accept: $autoAccept");
    print("🔍 Auto Print: $autoPrint");

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
      print("🔍 Order status: ${orderData.orderStatus}");

      // ✅ FIXED LOGIC: Process based on order status
      if (orderData.orderStatus == 2) {
        print("✅ Background - Order already accepted");

        // ✅ Only print if auto print is enabled
        if (autoPrint) {
          print("🖨️ Background - Auto printing already accepted order");
          await backgroundPrintOrder(orderData, prefs);
          print("✅ Background - Auto print attempt completed");
        } else {
          print("ℹ️ Background - Auto print disabled for accepted order");
        }
      } else if (orderData.orderStatus == 1) {
        print("⏳ Background - Order is pending (status: 1)");

        // ✅ FIXED: Only proceed if auto accept is enabled
        if (autoAccept) {
          print("🤖 Background - Auto accepting pending order: $orderNumber");

          Map<String, dynamic> jsonData = {
            "order_status": 2,
            "approval_status": 2,
          };

          final acceptResult = await ApiRepo().orderAcceptDecline(
              bearerKey, jsonData, orderData.id ?? 0);

          if (acceptResult != null) {
            print("✅ Background - Order auto-accepted successfully");

            // ✅ Only print after accept if auto print is also enabled
            if (autoPrint) {
              print("🖨️ Background - Auto printing after accept");
              await Future.delayed(Duration(seconds: 3));

              final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderNumber);

              if (updatedOrder != null) {
                print("📋 Background - Updated order retrieved for printing");
                await backgroundPrintOrder(updatedOrder, prefs);
                print("✅ Background - Auto print after accept completed");
              } else {
                print("❌ Background - Could not get updated order for printing");
              }
            } else {
              print("ℹ️ Background - Auto print disabled, only accepted order");
            }
          } else {
            print("❌ Background - Failed to auto-accept order");
          }
        } else {
          // ✅ FIXED: This was the main issue - removed auto print for pending orders
          print("ℹ️ Background - Auto accept disabled, ignoring pending order");
          print("ℹ️ Background - Pending orders should NOT be printed without acceptance");
          // ✅ Removed the auto print call for pending orders
          return; // Exit without processing
        }
      } else {
        print("⚠️ Background - Unknown order status: ${orderData.orderStatus}");
        return;
      }

      // Step 4: Refresh orders if store ID available
      if (storeID != null && storeID.isNotEmpty) {
        print("🔄 Background - Refreshing orders list...");
        await refreshOrdersInBackground(bearerKey, storeID);
      } else {
        print("⚠️ Background - Skipping orders refresh (no store ID)");
      }

      print("🎉 Background processing completed for order: $orderNumber");

    } catch (apiError) {
      print("❌ Background - API Error: $apiError");
    }

  } catch (e) {
    print("❌ Background handler error: $e");
    print("❌ Error stack: ${e.toString()}");
  }
}
Future<void> backgroundPrintOrder(Order order, SharedPreferences prefs) async {
  try {
    print("🖨️ ========== BACKGROUND PRINT STARTED ==========");
    print("🖨️ Order ID: ${order.id}");
    print("🖨️ Order Status: ${order.orderStatus}");
    print("🖨️ Invoice: ${order.invoice?.invoiceNumber ?? 'NULL'}");

    // ✅ Enhanced printer IP detection with multiple attempts
    String selectedIp = '';

    // Method 1: Try primary printer IP
    String? primaryIp = prefs.getString('printer_ip_0');
    print("🖨️ Primary printer_ip_0: '${primaryIp ?? 'NULL'}'");

    if (primaryIp != null && primaryIp.trim().isNotEmpty) {
      selectedIp = primaryIp.trim();
      print("✅ Using primary printer IP: '$selectedIp'");
    } else {
      print("⚠️ Primary printer IP empty, searching alternatives...");

      // Method 2: Search all possible printer IP keys
      List<String> possibleKeys = [
        'printer_ip_0',
        'printer_ip_1',
        'printer_ip_2',
        'printer_ip_3',
        'printer_ip_4',
        'selected_printer_ip',
        'printer_ip',
        'default_printer_ip'
      ];

      for (String key in possibleKeys) {
        String? ip = prefs.getString(key);
        print("🔍 Checking $key: '${ip ?? 'NULL'}'");

        if (ip != null && ip.trim().isNotEmpty) {
          selectedIp = ip.trim();
          print("✅ Found printer IP in $key: '$selectedIp'");
          break;
        }
      }

      // Method 3: Check all keys containing 'printer' or 'ip'
      if (selectedIp.isEmpty) {
        print("🔍 Searching all SharedPreferences keys...");
        Set<String> allKeys = prefs.getKeys();

        for (String key in allKeys) {
          if (key.toLowerCase().contains('printer') || key.toLowerCase().contains('ip')) {
            var value = prefs.get(key);
            print("🔍 Found key '$key': $value");

            if (value is String && value.trim().isNotEmpty) {
              selectedIp = value.trim();
              print("✅ Using IP from $key: '$selectedIp'");
              break;
            }
          }
        }
      }
    }

    if (selectedIp.isEmpty) {
      print("❌ Background - No printer IP found in any location");
      print("🔍 All SharedPreferences keys: ${prefs.getKeys()}");
      return;
    }

    // ✅ Validate IP format (basic check)
    if (!selectedIp.contains('.')) {
      print("❌ Background - Invalid IP format: '$selectedIp'");
      return;
    }

    // ✅ Enhanced Store Name Detection
    String storeName = '';

    // Method 1: Try common store name keys (OrderScreen से आने वाले)
    List<String> storeNameKeys = [
      'store_name',                    // OrderScreen से save होता है
      valueShared_STORE_NAME,         // Backup key
      'cached_store_name',            // _preloadStoreData से
      'restaurant_name',
      'shop_name',
      'business_name',
      'outlet_name'
    ];

    for (String key in storeNameKeys) {
      String? name = prefs.getString(key);
      print("🏪 Checking store key '$key': '${name ?? 'NULL'}'");

      if (name != null && name.trim().isNotEmpty) {
        storeName = name.trim();
        print("✅ Found store name in '$key': '$storeName'");
        break;
      }
    }

    // Method 2: Search all keys containing 'store' or 'restaurant' or 'shop'
    if (storeName.isEmpty) {
      print("🔍 Searching all keys for store name...");
      Set<String> allKeys = prefs.getKeys();

      for (String key in allKeys) {
        String lowerKey = key.toLowerCase();
        if (lowerKey.contains('store') || lowerKey.contains('restaurant') ||
            lowerKey.contains('shop') || lowerKey.contains('business')) {
          var value = prefs.get(key);
          print("🔍 Found potential store key '$key': $value");

          if (value is String && value.trim().isNotEmpty && !value.contains('@') && !value.contains('.')) {
            storeName = value.trim();
            print("✅ Using store name from '$key': '$storeName'");
            break;
          }
        }
      }
    }

    // Method 3: Fallback - check if any string value looks like a store name
    if (storeName.isEmpty) {
      print("🔍 Final fallback - checking all string values...");
      Set<String> allKeys = prefs.getKeys();

      for (String key in allKeys) {
        var value = prefs.get(key);
        if (value is String && value.trim().isNotEmpty &&
            value.length > 2 && value.length < 50 &&
            !value.contains('@') && !value.contains('http') &&
            !value.contains('.com') && !value.contains('Bearer') &&
            !RegExp(r'^\d+$').hasMatch(value)) {

          print("🔍 Potential store name in '$key': '$value'");
          // You can add more filtering logic here if needed
        }
      }
    }

    if (storeName.isEmpty) {
      storeName = 'Restaurant'; // Fallback name
      print("⚠️ No store name found, using fallback: '$storeName'");
    }

    // ✅ Check invoice data
    if (order.invoice == null || (order.invoice?.invoiceNumber ?? '').isEmpty) {
      print("⚠️ Background - Invoice data missing, attempting print anyway");
    }

    String savedLocale = prefs.getString('selected_language') ?? 'de';
    print("🌐 Background - Using locale: $savedLocale");
    print("🖨️ Background - Final printer IP: '$selectedIp'");
    print("🏪 Background - Final store name: '$storeName'");

    // ✅ Call print function with detailed logging
    print("🖨️ Background - Calling PrinterHelperEnglish.printInBackground...");

    await PrinterHelperEnglish.printInBackground(
      order: order,
      ipAddress: selectedIp,
      store: storeName,  // ✅ Now passing actual store name
      locale: savedLocale,
    );

    print("✅ Background print function call completed");
    print("🖨️ ========== BACKGROUND PRINT ENDED ==========");

  } catch (e) {
    print("❌ Background print error: $e");
    print("❌ Print error stack: ${e.toString()}");
  }
}

// ✅ Enhanced background orders refresh
Future<void> refreshOrdersInBackground(String bearerKey, String storeID) async {
  try {
    print("🔄 Background - Refreshing orders from server...");
    print("🔑 Token: ${bearerKey.substring(0, 20)}...");
    print("🏪 Store: $storeID");

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

  // ✅ Check if user is logged in and sync settings
  await _checkAndSyncSettings();

  runApp(const AppLifecycleObserver(child: MyApp()));
}

// ✅ Add this method to check and sync settings on app start
Future<void> _checkAndSyncSettings() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    String? storeID = prefs.getString(valueShared_STORE_KEY);

    if (bearerKey != null && bearerKey.isNotEmpty && storeID != null && storeID.isNotEmpty) {
      print("🔄 User is logged in, syncing settings on app start...");
      await SettingsSync.syncSettingsAfterLogin();
    } else {
      print("ℹ️ User not logged in, skipping settings sync");
    }
  } catch (e) {
    print("❌ Error checking settings on app start: $e");
  }
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