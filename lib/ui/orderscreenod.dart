import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/models/StoreDetail.dart';
import 'package:food_app/ui/OrderDetail.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../customView/CustomAppBar.dart';
import '../customView/CustomDrawer.dart';
import '../models/UserMe.dart';
import '../models/order_model.dart';
import '../utils/SocketService.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';
import 'OrderDetailBottomSheet.dart';
import 'dart:async';

import 'OrderDetailEnglish.dart';
import 'ReportBottomDialogSheet.dart';
import 'ReportScreen.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin,
    AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.visibility;
      case 2:
        return Icons.check;

      case 3:
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  late SharedPreferences sharedPreferences;
  String? bearerKey;
  final SocketService socketService = SocketService();

  //Timer? _orderTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String dateSeleted = "";
  late UserMe userMe;

  @override
  void initState() {
    super.initState();
    initVar();
    /* WidgetsBinding.instance.addObserver(this);
    _startOrderRefreshIfVisible();*/
    //socketCall();
    WidgetsBinding.instance.addObserver(this);
  }

  void socketCall() {
    socketService.initSocket(
      onNewOrder: (data) {
        setState(() async {
          //getOrders(bearerKey, false, true);
          // Extract and print order_id
          if (data is Map && data.containsKey('order_id')) {
            int orderID = data['order_id'];
            await getNewOrder(orderID);
            print("🆕 New Order ID: ${data['order_id']}");
          } else {
            print("⚠️ order_id not found in data");
          }
          // Play sound for 5 seconds
          print("UpdateStrig Scoket 1 " + data.toString());
        });
      },
      onOrderUpdated: (data) {
        setState(() {
          // Optionally update the existing order by ID
          print("UpdateStrig Scoket 2 " + data.toString());
          /* final index = orders.indexWhere((o) => o['id'] == data['id']);
         if (index != -1) {
           orders[index] = Map<String, dynamic>.from(data);
         }*/
        });
      },
    );
  }

  @override
  void dispose() {
    // _orderTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    socketService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      initVar();
    }
  }

/*  void _startOrderRefreshIfVisible() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);

    _orderTimer?.cancel();
    _orderTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_isScreenVisible()) {
        getOrders(bearerKey,false);
      }
    });
  }*/

// You can refine this based on actual visibility checks
/*  bool _isScreenVisible() {
    return app.appController.selectedTabIndex == 0;
  }*/
  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    String? storeID = sharedPreferences
        .getString(valueShared_STORE_KEY);
    if(storeID!=null)
    {
      String? storeID = sharedPreferences
          .getString(valueShared_STORE_KEY);
      getOrders(bearerKey, false, false, storeID);
    }
    else{
      getStoreUserMeData(bearerKey);
    }

  }

  Future<void> getStoreUserMeData(String? bearerKey) async {
    try {
      final result = await ApiRepo().getUserMe(bearerKey);
      if (result != null) {
        setState(() {
          userMe = result;
          sharedPreferences.setString(
              valueShared_STORE_KEY, userMe.store_id.toString());
          getOrders(bearerKey, true, false, userMe.store_id.toString());
        });
      } else {
        showSnackbar("Error", "Failed to update order status");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> getOrders(
      String? bearerKey, bool orderType, bool isBellRunning, String? id) async {
    try {

      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);
      if (orderType) {
        Get.dialog(
          Center(
              child: CupertinoActivityIndicator(
                radius: 20,
                color: Colors.orange,
              )),
          barrierDismissible: false,
        );
      }
      /* if (isBellRunning) {
        await _audioPlayer.play(AssetSource('alarm.mp3'));

        // Stop after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          _audioPlayer.stop();
        });
      }*/
      final Map<String, dynamic> data = {
        "store_id": id,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);
      // Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      if (orderType) {
        Get.back();
      }
      if (result.isNotEmpty && result.first.code == null) {
        setState(() {
          app.appController.setOrders(result);
        });
      } else {
        String errorMessage = result.isNotEmpty
            ? result.first.mess ?? "Unknown error"
            : "No data returned";
        showSnackbar("Error", errorMessage);
      }
    } catch (e) {
      Get.back();
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

/*  Future<void> getOrders(
      String? bearerKey, bool orderType, bool isBellRunning) async {
    try {
      if (orderType) {
        Get.dialog(
          Center(
              child: CupertinoActivityIndicator(
            radius: 20,
            color: Colors.orange,
          )),
          barrierDismissible: false,
        );
      }

      if (isBellRunning) {
        await _audioPlayer.play(AssetSource('alarm.mp3'));

        // Stop after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          _audioPlayer.stop();
        });
      }
      final result = await ApiRepo().orderGetApi(bearerKey!);
      // Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      if (orderType) {
        Get.back();
      }
      if (result.isNotEmpty && result.first.code == null) {
        setState(() {
          app.appController.setOrders(result);
        });
      } else {
        String errorMessage = result.isNotEmpty
            ? result.first.mess ?? "Unknown error"
            : "No data returned";
        showSnackbar("Error", errorMessage);
      }
    } catch (e) {
      Get.back();
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Padding(
            padding: const EdgeInsets.all(12),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      openCalendarScreen();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Aligns children to the start horizontally
                      mainAxisAlignment: MainAxisAlignment.start,
                      // Aligns children to the top vertically
                      children: [
                        Text(
                          'order'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateSeleted.isEmpty
                              ? DateFormat('d MMMM, y').format(DateTime.now())
                              : dateSeleted,
                          // e.g., 21 April, 2025
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        child: IconButton(
                          iconSize: 33,
                          icon: Icon(Icons.refresh),
                          onPressed: () {
                            String? storeID = sharedPreferences
                                .getString(valueShared_STORE_KEY);
                            getOrders(bearerKey, true, false, storeID);
                            // Your refresh logic here
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 7),
              Expanded(child: Obx(() {
                return ListView.builder(
                  itemCount: app.appController.searchResultOrder.length,
                  itemBuilder: (context, index) {
                    final order = app.appController.searchResultOrder[index];

                    /*DateTime startTime = DateTime.parse(
                        order.createdAt != null ? order.createdAt! : "");
                    DateTime endTime = startTime.add(Duration(minutes: 30));
*/

                    DateTime startTime;
                    try {
                      startTime = DateTime.parse(order.createdAt ?? "");
                    } catch (_) {
                      startTime = DateTime.now(); // or any default
                    }
                    DateTime endTime = startTime.add(Duration(minutes: 30));

                    String formattedEnd = DateFormat('hh:mm a').format(endTime);
                    return Card(
                      color: Colors.white,
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // _openBottomSheet(order);
                            // Get.to(() => OrderDetail(order));
                            Get.to(() => OrderDetailEnglish(order));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      order.orderType == 1
                                          ? CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.green,
                                        child: SvgPicture.asset(
                                          'assets/images/ic_delivery.svg',
                                          height: 14,
                                          width: 14,
                                          color: Colors
                                              .white, // Optional: to tint the SVG
                                        ),
                                      )
                                          : CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.green,
                                        child: SvgPicture.asset(
                                          'assets/images/ic_pickup.svg',
                                          height: 14,
                                          width: 14,
                                          color: Colors
                                              .white, // Optional: to tint the SVG
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        order.orderType == 1
                                            ? 'delivery'.tr + ' : ${formattedEnd}'
                                            : order.orderType == 2
                                            ? 'pickup'.tr + ' : ${formattedEnd}'
                                            : order.orderType == 3
                                            ? 'dine_in'.tr + ' : ${formattedEnd}'
                                            : '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),

                                    ],
                                  ),
                                  Text(
                                    '${'order_id'.tr} : ${order.id}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                ],
                              ),
                              SizedBox(height: 1),
                              Visibility(
                                visible: order.shipping_address != null
                                    ? true
                                    : false,
                                child: Text(
                                  order.orderType == 1
                                      ? order.shipping_address != null
                                      ? order.shipping_address!.line1! +
                                      " , " +
                                      order.shipping_address!.city!
                                      : ""
                                      : "",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "${order.shipping_address?.customer_name ?? "User"} / ${order.shipping_address?.phone ?? "0000000000"}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.payment != null
                                        ? "${'currency'.tr} ${order.payment!.amount.toString()}"
                                        : "${'currency'.tr} 00",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        getApprovalStatusText(
                                            order.approvalStatus),
                                        style: TextStyle(
                                          color: Colors
                                              .black /*getStatusColor(
                                              order.approvalStatus != null
                                                  ? order.approvalStatus!
                                                  : 0)*/
                                          ,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: getStatusColor(
                                            order.approvalStatus != null
                                                ? order.approvalStatus!
                                                : 0),
                                        child: Icon(
                                          getStatusIcon(
                                              order.approvalStatus != null
                                                  ? order.approvalStatus!
                                                  : 0),
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }))
            ])));
  }

/*  void _openBottomSheet(Order order) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderDetailBottomSheet(order),
    ).then((_) {
      // This will still be called after bottom sheet closes
      print("Modal closed");
      getOrders(bearerKey, true);
      setState(() {});
    });
  }*/

  void _openBottomSheet(Order order) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(), // Return true
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: OrderDetailBottomSheet(order),
            ),
          ],
        );
      },
    );

    /* if (result == true) {
      print("Modal closed via cross button");
      getOrders(bearerKey, true);
      setState(() {});
    } else {
      print("Modal closed via back tap or swipe down");
    }*/
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return "Pending";
      case 2:
        return "Accepted";
      case 3:
        return "Declined";
      default:
        return "Unknown";
    }
  }

  @override
  bool get wantKeepAlive => true;

  void openCalendarScreen() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(), // Return true
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ReportScreenBottom(),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        print("ResltData " + result.toString());
        dateSeleted = result.toString();
      });
    }
  }

  Future<void> getNewOrder(int orderID) async {
    try {
      final result = await ApiRepo().getNewOrderData(bearerKey!, orderID);

      if (result != null) {
        /* await _audioPlayer.play(AssetSource('alarm.mp3'));
        // Stop after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          _audioPlayer.stop();
        });*/

        app.appController.addNewOrder(result); // Wrap in a list if needed
      } else {
        String errorMessage = result.mess ?? "Unknown error";
        showSnackbar("Error", errorMessage);
      }
    } catch (e) {
      Get.back();
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }
}
