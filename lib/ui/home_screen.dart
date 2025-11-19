import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:food_app/main.dart';
import 'package:food_app/ui/PrinterSettingsScreen.dart';
import 'package:food_app/ui/table%20Book/reservation.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constant.dart';
import '../constants/item_bottom_bar.dart';
import '../constants/app_color.dart';
import '../customView/CustomAppBar.dart';
import '../customView/CustomDrawer.dart';
import '../utils/global.dart';
import '../utils/keep_alive_page.dart';
import '../utils/my_application.dart';
import 'OrderScreen.dart';
import 'ReportScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int lastIndex = 0;
  int floatIndex = 0;
  bool isSelected = false;
  bool _isDataLoaded = false;
  BuildContext? dialogContext;
  bool _fcmInitialized = false;
  int? _lastProcessedOrderId;
  String? _storeType;
  int? _roleId;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _setupFCMListeners();
    _loadInitialData();
    _setupLocalNotificationTap();

    final arguments = Get.arguments;
    if (arguments != null && arguments['initialTab'] != null) {
      final int initialTab = arguments['initialTab'];
      // âœ… Increase delay to ensure PageController is attached
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _openTab(initialTab);
        }
      });
    }
    super.initState();
  }

  void _setupLocalNotificationTap() {
    // Listen for local notification taps when app is in foreground
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
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
    SharedPreferences freshPrefs = await SharedPreferences.getInstance();
    _storeType = freshPrefs.getString(valueShared_STORE_TYPE);
    //_roleId = freshPrefs.getInt(valueShared_ROLE_ID); // Add this

    await Future.wait([
      getOrdersInBackground(),
      getReservationsInBackground(),
    ]);
    setState(() {
      _isDataLoaded = true;
    });
  }
  DateTime? _lastProcessedTime;

  void _setupFCMListeners() {
    if (_fcmInitialized) return;
    _fcmInitialized = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("DataNotification ${message.notification}");
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
              now.difference(_lastProcessedTime!) > const Duration(seconds: 3);

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
        appBar: const CustomAppBar(),
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: !_isDataLoaded ? const SizedBox.shrink() : Obx(() {
          if (app.appController.selectedTabIndex == 1) {
            return floatingButton(context);
          }
          return const SizedBox.shrink();
        }),
        bottomNavigationBar: _buildBottomBar(),
        body: _isDataLoaded ? _buildBody() : Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ))
      ),
    );
  }

  Widget floatingButton(BuildContext context) {
    if (_roleId != 1 && (_storeType == '1' || _storeType == '2')) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: const [
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
          child: const Center(
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
    // Don't show bottom bar until data is loaded
    if (!_isDataLoaded) {
      return const SizedBox.shrink();
    }

    double bottomBarHeight = Platform.isIOS ? 90 : 75;
    return Container(
      height: bottomBarHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        color: Colors.grey[100],
      ),
      child: BottomAppBar(
        color: appColor.white,
        child: Obx(() => Row(  // Obx only around Row for observing app.appController
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ItemBottomBar(
              selected: app.appController.selectedTabIndex == 0,
              icon: "assets/images/ic_order.png",
              iconHeight: 20,
              iconWidth: 20,
              name: 'order'.tr,
              showBadge: app.appController.getPendingOrder > 0,
              badgeValue: app.appController.getPendingOrder,
              onPressed: () {
                _openTab(0);
              },
            ),
            // Only show reservation for storeType '0'
            if (_roleId == 1 || _storeType == '0')
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 1,
                icon: "assets/images/reservationIcon.png",
                iconHeight: 25,
                iconWidth: 30,
                name: 'reserv'.tr,
                showBadge: app.appController.getPendingReservations > 0,
                badgeValue: app.appController.getPendingReservations,
                onPressed: () {
                  _openTab(1);
                },
              ),
            ItemBottomBar(
              selected: app.appController.selectedTabIndex == 2,
              icon: "assets/images/ic_reports.png",
              iconHeight: 20,
              iconWidth: 20,
              name: 'reports'.tr,
              onPressed: () {
                _openTab(2);
              },
            ),
            ItemBottomBar(
              selected: app.appController.selectedTabIndex == 3,
              icon: "assets/images/ic_setting.png",
              iconHeight: 20,
              iconWidth: 20,
              name: 'setting'.tr,
              onPressed: () {
                _openTab(3);
              },
            ),
          ],
        )),
      ),
    );
  }


  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        print("Page changedto: $index");
      },
      children: [
        // KeepAlivePage(child: HomeTab()),
        KeepAlivePage(child: const OrderScreenNew()),
        KeepAlivePage(child: const Reservation()),
        KeepAlivePage(child: ReportScreen()),
        KeepAlivePage(child: const PrinterSettingsScreen()),
      ],
    );
  }


  void _openTab(int index) {
    // ✅ First update the controller index immediately
    app.appController.onTabChanged(index);

    if (!_pageController.hasClients) {
      print("PageController not ready yet. Scheduling navigation to tab $index");
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _openTab(index);
        }
      });
      return;
    }

    if (_pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");

      if (index == 3) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
      return;
    }

    print("Switching to Tab 1 : $index");
    _pageController.jumpToPage(index);

    Future.delayed(const Duration(milliseconds: 50), () {
      print("Switching to Tab 2 : $index");
      if (index == 2) {
        app.appController.reportRefreshTrigger.refresh();
      }
      if (index == 3 && mounted) {
        setState(() {});
      }
    });
  }


}