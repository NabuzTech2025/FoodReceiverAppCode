import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/ui/PrinterSettingsScreen.dart';
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

    final arguments = Get.arguments;
    if (arguments != null && arguments['initialTab'] != null) {
      final int initialTab = arguments['initialTab'];
      Future.delayed(Duration(milliseconds: 100), () {
        _openTab(initialTab);
      });
    }
    super.initState();
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

      if (title.contains("New Order")) {
        print("inside the order");

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
            getOrdersInForegrund(context,orderNumber);
          } else {
            print("Duplicate order received too soon. Skipping API call for order: $orderNumber");
          }
        } else {
          print("No order number found");
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      getOrdersInBackground();
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
        resizeToAvoidBottomInset: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
         /*   floatingActionButton: floatingButton(context),*/
        bottomNavigationBar: _buildBottomBar(),
        body: _buildBody(),
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
        padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
        height: 85,
        color: Colors.grey[100],
        child: BottomAppBar(
          color: appColor.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //ic_project_home.png
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 0,
                icon: "assets/images/ic_order.png",
                name: 'order'.tr,
                showBadge  : app.appController.getPendingOrder > 0,
                badgeValue : app.appController.getPendingOrder,
                onPressed: () {
                  _openTab(0);
                },
              ),
              /*ItemBottomBar(
                selected: app.appController.selectedTabIndex == 1,
                icon: "assets/images/ic_customer.png",
                name: 'customer'.tr,
                showBadge: true,
                // badgeValue: app.appController.favCount,
                onPressed: () {},
              ),*/
             /* SizedBox(
                width: 15,
              ),*/
              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 1,
                icon: "assets/images/ic_reports.png",
                name: 'reports'.tr,
                onPressed: () {
                  _openTab(1);
                },
              ),

              ItemBottomBar(
                selected: app.appController.selectedTabIndex == 2,
                icon: "assets/images/ic_setting.png",
                name: 'setting'.tr,
                onPressed: () {
                  _openTab(2);
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

   /* if (index == 5) {
      //  app.appController.setSyncLoading(true);
    } else {
      //  app.appController.setSyncLoading(false);
    }*/

    Future.delayed(Duration(milliseconds: 50), () {
      print("Switching to Tab 2 : " + index.toString());
      app.appController.onTabChanged(index);
    });
  }

  Widget floatingButton(BuildContext context) {
    return Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        color: Colors.yellow[600],
        borderRadius: BorderRadius.circular(50), // Adjust for roundness
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
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // BottomDialog().showBottomDialog(context)
          },
          child: Center(
            child: Icon(
              Icons.add,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
