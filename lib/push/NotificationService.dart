import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../ui/SuperAdmin/super_admin.dart';
import '../utils/global.dart';

class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // ✅ REQUEST NOTIFICATION PERMISSIONS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🛡️ Permission granted: ${settings.authorizationStatus}');

    // ✅ DISPLAY NOTIFICATIONS IN FOREGROUND
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ LISTEN FOR FOREGROUND MESSAGES
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("🔔 FirebaseMessaging onMessage: ${message.toMap()}");

      String title = message.notification?.title ?? message.data['title'] ?? '';
      String body = message.notification?.body ?? message.data['body'] ?? '';

      print('🔊 Foreground notification received');
      print('📢 Title: $title');
      print('📄 Body: $body');

      // ✅ PLAY ALARM SOUND FOR NEW ORDERS
      if ((title.contains('New Order') || title.contains('Reservation')) && body.isNotEmpty) {
        await _playAlarmSound();

        // Show local notification with sound
        await _showLocalNotification(title, body);
      }

      // ✅ HANDLE RESERVATION NOTIFICATIONS
      if (title.contains('Reservation') || title.contains('New Reservation')) {
        if (body.isNotEmpty) {
          RegExp regExp = RegExp(r'#(\d+)');
          Match? match = regExp.firstMatch(body);

          if (match != null) {
            int reservationID = int.parse(match.group(1)!);
            print('🎫 Reservation ID extracted: $reservationID');
            await getReservationInForeground(reservationID);
          }
        }
      }

      // âœ… HANDLE ORDER NOTIFICATIONS
      if (title.contains('New Order') && body.isNotEmpty) {
        print('âœ… New Order notification - triggering refresh');
        await getOrdersInBackground();

        // âœ… Refresh Super Admin if controller exists
        try {
          if (Get.isRegistered<SuperAdminController>()) {
            final controller = Get.find<SuperAdminController>();
            await controller.triggerRefresh();
            print('âœ… Super Admin refreshed from notification');
          }
        } catch (e) {
          print('â„¹ï¸ Super Admin not active: $e');
        }
      }});

    // ✅ HANDLE BACKGROUND MESSAGE TAP (App in background, notification tapped)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🎯 Notification clicked from background');
      String title = message.notification?.title ?? message.data['title'] ?? '';
      print('🔨 Title from tap: $title');

      if (title.contains('New Order')) {
        Get.offAllNamed('/home', arguments: {'initialTab': 0});
      } else if (title.contains('Reservation')) {
        Get.offAllNamed('/home', arguments: {'initialTab': 1});
      }
    });

    // ✅ HANDLE NOTIFICATION THAT LAUNCHED APP
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App launched by notification');
      String? title = initialMessage.notification?.title ?? initialMessage.data['title'];
      String? body = initialMessage.notification?.body ?? initialMessage.data['body'];

      print('📌 Initial notification title: $title');
      print('📌 Initial notification body: $body');

      if (title != null) {
        if (title.contains('New Order')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/home', arguments: {'initialTab': 0});
          });
        } else if (title.contains('Reservation')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/home', arguments: {'initialTab': 1});
          });
        }
      }
    }

    print('✅ Notification Service initialized successfully');
  }

  // ✅ PLAY ALARM SOUND
  static Future<void> _playAlarmSound() async {
    try {
      print('🔊 Attempting to play alarm sound...');

      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Play the alarm sound from assets
      await _audioPlayer.play(AssetSource('alarm.mp3'));
      print('✅ Alarm sound started playing');

      // Stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          await _audioPlayer.stop();
          print('✅ Alarm sound stopped');
        } catch (e) {
          print('❌ Error stopping sound: $e');
        }
      });
    } catch (e) {
      print('❌ Error playing alarm sound: $e');
    }
  }

  // ✅ SHOW LOCAL NOTIFICATION WITH SOUND
  static Future<void> _showLocalNotification(String title, String body) async {
    try {
      print('📢 Showing local notification');

      final androidDetails = AndroidNotificationDetails(
        'order_channel',  // ✅ Changed from 'order_notifications_v1' to match
        'Order Notifications',
        channelDescription: 'Notifications for new orders and reservations',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        autoCancel: true,
        ongoing: false,
        onlyAlertOnce: false,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm.caf',  // ✅ iOS uses .caf format
        categoryIdentifier: 'ORDER_NOTIFICATION',
        interruptionLevel: InterruptionLevel.critical,  // ✅ Critical for iOS 18
        threadIdentifier: 'order-notifications',
        subtitle: 'Order Alert',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: title.contains('New Order') ? '0' : '1',
      );

      print('✅ Local notification shown successfully');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // ✅ CLEANUP
  static Future<void> dispose() async {
    await _audioPlayer.stop();
    await _audioPlayer.release();
  }
}

/*info.plist
//
// <?xml version="1.0" encoding="UTF-8"?>
// <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
// <plist version="1.0">
// <dict>
// <key>BGTaskSchedulerPermittedIdentifiers</key>
// <array>
// <string>com.food.mandeep.foodApp112</string>
// </array>
// <key>CADisableMinimumFrameDurationOnPhone</key>
// <true/>
// <key>CFBundleDevelopmentRegion</key>
// <string>$(DEVELOPMENT_LANGUAGE)</string>
// <key>CFBundleDisplayName</key>
// <string>Food App</string>
// <key>CFBundleExecutable</key>
// <string>$(EXECUTABLE_NAME)</string>
// <key>CFBundleIdentifier</key>
// <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
// <key>CFBundleInfoDictionaryVersion</key>
// <string>6.0</string>
// <key>CFBundleName</key>
// <string>food_app</string>
// <key>CFBundlePackageType</key>
// <string>APPL</string>
// <key>CFBundleShortVersionString</key>
// <string>1.0.12</string>
// <key>CFBundleSignature</key>
// <string>????</string>
// <key>CFBundleVersion</key>
// <string>12</string>
// <key>LSRequiresIPhoneOS</key>
// <true/>
// <key>UIApplicationSupportsIndirectInputEvents</key>
// <true/>
// <key>UIBackgroundModes</key>
// <array>
// <string>remote-notification</string>
// <string>fetch</string>
// <string>audio</string> <!-- ✅ ADD THIS - For notification sounds -->
// <string>processing</string> <!-- ✅ ADD THIS - For background processing -->
// </array>
// <key>UILaunchStoryboardName</key>
// <string>LaunchScreen</string>
// <key>UIMainStoryboardFile</key>
// <string>Main</string>
// <key>UISupportedInterfaceOrientations</key>
// <array>
// <string>UIInterfaceOrientationPortrait</string>
// <string>UIInterfaceOrientationLandscapeLeft</string>
// <string>UIInterfaceOrientationLandscapeRight</string>
// </array>
// <key>UISupportedInterfaceOrientations~ipad</key>
// <array>
// <string>UIInterfaceOrientationPortrait</string>
// <string>UIInterfaceOrientationPortraitUpsideDown</string>
// <string>UIInterfaceOrientationLandscapeLeft</string>
// <string>UIInterfaceOrientationLandscapeRight</string>
// </array>
//
// <!-- ✅ ADD THESE NEW KEYS -->
// <key>UIUserNotificationSettings</key>
// <dict>
// <key>UIUserNotificationTypeAlert</key>
// <true/>
// <key>UIUserNotificationTypeBadge</key>
// <true/>
// <key>UIUserNotificationTypeSound</key>
// <true/>
// </dict>
//
// <!-- ✅ Firebase messaging -->
// <key>FirebaseAppDelegateProxyEnabled</key>
// <false/>
//
// <!-- ✅ Notification alert style -->
// <key>UIUserNotificationAlertStyle</key>
// <string>alert</string>
// </dict>
// </plist>*/


/* App delegate.swift
import UIKit
import Flutter
import UserNotifications  // ✅ ADD THIS

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ✅ ADD THIS SECTION - Notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ iOS Notification permission granted")
          } else {
            print("❌ iOS Notification permission denied")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ ADD THIS - Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // ✅ ADD THIS - Handle notification tap
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
 */