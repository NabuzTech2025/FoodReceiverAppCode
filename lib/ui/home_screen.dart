import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:food_app/main.dart';
import 'package:food_app/ui/PrinterSettingsScreen.dart';
import 'package:food_app/ui/table%20Book/reservation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constant.dart';
import '../constants/item_bottom_bar.dart';
import '../constants/app_color.dart';
import '../customView/CustomAppBar.dart';
import '../customView/CustomDrawer.dart';
import '../utils/global.dart';
import '../utils/keep_alive_page.dart';
import '../utils/my_application.dart';
import '../utils/validators.dart';

import 'LoginScreen.dart';
import 'OrderScreen.dart';
import 'ReportScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final _pageController = PageController(initialPage: 0);
  late PageController _pageController;
  int lastIndex = 0;
  int floatIndex = 0;
  bool isSelected = false;

  // Declare a variable to hold the dialog context
  BuildContext? dialogContext;
  bool _fcmInitialized = false;
  int? _lastProcessedOrderId;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _setupFCMListeners();
    _loadInitialData();
    _setupLocalNotificationTap(); // Add this line

    final arguments = Get.arguments;
    if (arguments != null && arguments['initialTab'] != null) {
      final int initialTab = arguments['initialTab'];
      Future.delayed(Duration(milliseconds: 100), () {
        _openTab(initialTab);
      });
    }
    super.initState();
  }
  void _setupLocalNotificationTap() {
    // Listen for local notification taps when app is in foreground
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        String? payload = response.payload;
        if (payload != null) {
          int tabIndex = int.parse(payload);
          _openTab(tabIndex); // Navigate to appropriate tab
        }
      },
    );
  }
  Future<void> _loadInitialData() async {
    await Future.wait([
      getOrdersInBackground(),
      getReservationsInBackground(), // Add this method call
    ]);
  }
  DateTime? _lastProcessedTime;

  void _setupFCMListeners() {
    if (_fcmInitialized) return;
    _fcmInitialized = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("DataNotification " + message.notification.toString());
      print('Foreground message received: Home Screen ${message.notification?.title}');
      print('Message body: ${message.notification?.body}');

      final title = message.notification?.title ?? '';

      // केवल data refresh करें, auto navigation नहीं करें
      if (title.contains("New Order")) {
        final body = message.notification?.body ?? '';
        RegExp regex = RegExp(r'#(\d+)');
        Match? match = regex.firstMatch(body);

        if (match != null) {
          int orderNumber = int.parse(match.group(1)!);
          DateTime now = DateTime.now();

          bool isNewOrder = _lastProcessedOrderId != orderNumber;
          bool isTimedOut = _lastProcessedTime == null ||
              now.difference(_lastProcessedTime!) > Duration(seconds: 3);

          if (isNewOrder || isTimedOut) {
            _lastProcessedOrderId = orderNumber;
            _lastProcessedTime = now;

            print("Order number: $orderNumber - calling API");
            getOrdersInForegrund(context, orderNumber);
            // Remove _openTab(0); - no auto navigation
          }
        }
      } else if (title.contains("New Reservation") || title.contains("Reservation")) {
        final body = message.notification?.body ?? ''; // Add this line
        RegExp regex = RegExp(r'#(\d+)');
        Match? match = regex.firstMatch(body);

        if (match != null) {
          int reservationNumber = int.parse(match.group(1)!);
          print("Reservation number: $reservationNumber - refreshing data");
          getReservationsInBackground();
        }
      }
    });

    // यह notification tap पर ही चलेगा
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '';

      if (title.contains("New Order")) {
        _openTab(0);
        getOrdersInBackground();
      } else if (title.contains("Reservation")) {
        _openTab(1);
        getReservationsInBackground();
      }

      print('Notification Screen tapped (app opened): ${message.notification?.title}');
    });
  }

  Future<bool> _onWillPop() async {
    // Direct exit from app without any dialog
    SystemNavigator.pop();
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: CustomDrawer(onSelectTab: _openTab),
        appBar: CustomAppBar(),
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        // Add conditional floating action button
        floatingActionButton: Obx(() {
          print("Current selected tab index: ${app.appController.selectedTabIndex}");
          if (app.appController.selectedTabIndex == 1) {
            print("Should show floating button");
            return floatingButton(context);
          }
          print("Should hide floating button");
          return SizedBox.shrink();
        }),
        bottomNavigationBar: _buildBottomBar(),
        body: _buildBody(),
      ),
    );
  }
  Widget floatingButton(BuildContext context) {
    return Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27.5),
          onTap: () {
            if (app.appController.selectedTabIndex == 1) {
              app.appController.triggerAddReservation.value = !app.appController.triggerAddReservation.value;
            }
          },
          child: Center(
            child: AnimatedRotation(
              turns: 0.0,
              duration: Duration(milliseconds: 200),
              child: Icon(
                Icons.add,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildBottomBar() {
    return Obx(() {
      return Container(
        height: 75,
        color: Colors.grey[100],
        child: BottomAppBar(
          color: appColor.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //ic_project_home.png
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 0,
                icon: "assets/images/ic_order.png",iconHeight: 20,iconWidth: 20,
                name: 'order'.tr,
                showBadge  : app.appController.getPendingOrder > 0,
                badgeValue : app.appController.getPendingOrder,
                onPressed: () {
                  _openTab(0);
                },
              ),
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 1,
                icon: "assets/images/reservationIcon.png",iconHeight: 25,iconWidth: 30,
                name: 'reserv'.tr,
                showBadge: app.appController.getPendingReservations > 0,
                badgeValue: app.appController.getPendingReservations,
                onPressed: () {
                  _openTab(1);
                },
              ),
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 2,
                icon: "assets/images/ic_reports.png",iconHeight: 20,iconWidth: 20,
                name: 'reports'.tr,
                onPressed: () {
                  _openTab(2);
                },
              ),
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 3,
                icon: "assets/images/ic_setting.png",iconHeight: 20,iconWidth: 20,
                name: 'setting'.tr,
                onPressed: () {
                  _openTab(3);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      physics: NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        print("Page changedto: $index");
      },
      children: [
        // KeepAlivePage(child: HomeTab()),
        KeepAlivePage(child: OrderScreenNew()),
        KeepAlivePage(child: Reservation()),
        KeepAlivePage(child: ReportScreen()),
        KeepAlivePage(child: PrinterSettingsScreen()),
      ],
    );
  }

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }

    print("Switching to Tab 1 : " + index.toString());
    _pageController.jumpToPage(index);

    Future.delayed(Duration(milliseconds: 50), () {
      print("Switching to Tab 2 : " + index.toString());
      app.appController.onTabChanged(index);
      if (index == 2) {
        app.appController.reportRefreshTrigger.refresh();
      }
    });

  }


}