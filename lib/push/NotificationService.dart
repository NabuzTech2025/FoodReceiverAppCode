import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/global.dart';

class NotificationService {
  static Future<void> initialize() async {
    print('push Notification Logs');
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    final AudioPlayer audioPlayer = AudioPlayer();
    // 🔐 Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🛑 Permission granted: ${settings.authorizationStatus}');

    // ✅ Display notifications in foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔔 Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("NotificationSettings $message");
      print('📬 Foreground notification: ${message.notification?.title}');
      // await _audioPlayer.play(AssetSource('alarm.mp3'));
      // Future.delayed(Duration(seconds: 5), () {
      //   _audioPlayer.stop();
      // });
    });

    // Add reservation notification handling:

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      String title = message.notification?.title ?? '';
      String body = message.notification?.body ?? '';

      // Handle order notifications
      if (title.contains('New Order') && body.isNotEmpty) {
        // existing order logic
      }

      // Handle reservation notifications
      if (title.contains('New Reservation') || title.contains('Reservation')) {
        if (body.isNotEmpty) {
          // Extract reservation ID from message
          RegExp regExp = RegExp(r'#(\d+)');
          Match? match = regExp.firstMatch(body);

          if (match != null) {
            int reservationID = int.parse(match.group(1)!);
            await getReservationInForeground(reservationID);
          }
        }
      }
    });



    // 🚀 Handle background-to-foreground tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Notification clicked: ${message.notification?.title}');
    });
    // 🧪 Check if launched from notification
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      String? body = initialMessage.notification?.body;
      print(
          '🚀 App launched by notification: ${initialMessage.notification?.title}');
      print('📨 Body: $body');
      if (body != null) {}
      print(
          '🚀 App launched by notification: ${initialMessage.notification?.title}');
    }
    // 🔗 Subscribe to topic (store_4_orders)
    //  await messaging.subscribeToTopic("store_4_orders");
    print('📦 Subscribed to topic: store_4_orders');
    // 🎯 Print token (optional, useful for testing)
    final token = await messaging.getToken();
    print('📲 FCM Token: $token');
  }

}
