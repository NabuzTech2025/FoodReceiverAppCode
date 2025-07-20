import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/UserMe.dart';
import 'package:food_app/ui/OrderDetailEnglish.dart';
import 'package:food_app/ui/ReportBottomDialogSheet.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreenNew extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreenNew> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // ─────────────────── Helpers ───────────────────
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

  // ─────────────────── State ───────────────────
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  //final SocketService socketService = SocketService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String dateSeleted = "";
  late UserMe userMe;

  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    print("Callingapp When refresh reumed 1111 ");

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    initVar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);// Clean up observer
    //socketService.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("Callingapp When refresh reumed 2222 ");
      initVar(); // refresh when app returns to foreground
    }
  }

  // ─────────────────── Initialisation ───────────────────
  Future<void> initVar() async {
    print("Callingapp When refresh reumed 3333 ");
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);

    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    if (storeID != null) {
      getOrders(bearerKey, false, false, storeID);
    } else {
      getStoreUserMeData(bearerKey);
    }
  }

  // ─────────────────── Refresh logic ───────────────────
  /// Used by the RefreshIndicator (pull‑to‑refresh) – **silent** refresh
  Future<void> _handleRefresh() async {                               // ✨ NEW
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, false, false, storeID);
  }

  /// Used by the toolbar icon – shows the loading dialog
  Future<void> _manualRefresh() async {                               // ✨ NEW
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, true, false, storeID);
  }

  // ─────────────────── API calls – unchanged except for params ───────────────────
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

  Future<void> getOrders(String? bearerKey, bool orderType, bool isBellRunning, String? id) async {
    try {
      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      if (orderType) {
        // show modal loader
        Get.dialog(
           Center(
             child:  Lottie.asset(
               'assets/animations/burger.json',
               width: 150,
               height: 150,
               repeat: true, )
             //CupertinoActivityIndicator(radius: 20, color: Colors.orange),
          ),
          barrierDismissible: false,
        );
      }

      final Map<String, dynamic> data = {
        "store_id": id,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (orderType) Get.back(); // close loader

      if (result.isNotEmpty && result.first.code == null) {
        setState(() {
          app.appController.setOrders(result);
        });
      } else {
       /* String errorMessage = result.isNotEmpty
            ? result.first.mess ?? "Unknown error"
            : "No data returned";
        showSnackbar("Error", errorMessage);*/
      }
    } catch (e) {
      if (orderType) Get.back();
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
  }
  // ─────────────────── UI ───────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context); // needed when using AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ────────── Header row ──────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date + title
                GestureDetector(
                  onTap: openCalendarScreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('order'.tr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        dateSeleted.isEmpty
                            ? DateFormat('d MMMM, y').format(DateTime.now())
                            : dateSeleted,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text('Total Orders:20',style: TextStyle(
                      fontSize: 14,fontWeight: FontWeight.w800,fontFamily: "Mulish",color: Colors.black
                    ),),
                    IconButton(
                      iconSize: 33,
                      icon: const Icon(Icons.refresh),
                      onPressed: _manualRefresh,                    // ✨ NEW
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Accepted : 20',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Decline : 2',style: TextStyle(
                    fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Pending : 2',style: TextStyle(
                    fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('PickUp : 2',style: TextStyle(
                    fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 2,),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Delivery : 2',style: TextStyle(
                    fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
              ],
            ),
            // ────────── Orders list with pull‑to‑refresh ──────────
            SizedBox(height: 10,),
            Expanded(
              child: RefreshIndicator(                          // ✨ NEW
                onRefresh: _handleRefresh,
                color: Colors.green, // Loader (circular progress) color
                backgroundColor: Colors.white, // Background behind the loader// ✨ NEW
                displacement: 60,                               // optional
                child: Obx(() {
                  if (app.appController.searchResultOrder.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 100),
                        Center(
                            child: Lottie.asset(
                              'assets/animations/burger.json',
                              width: 150,
                              height: 150,
                              repeat: true,)
                          // Text(
                          //   'There is no order at this time',
                          //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                          // ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(), // ✨ NEW
                      itemCount: app.appController.searchResultOrder.length,
                      itemBuilder: (context, index) {
                        final order = app.appController
                            .searchResultOrder[index];


                        // … existing card code unchanged …
                        DateTime startTime = DateTime.tryParse(
                            order.createdAt ?? '') ??
                            DateTime.now();
                        DateTime endTime = startTime.add(const Duration(
                            minutes: 30));
                        String formattedEnd =
                        DateFormat('hh:mm a').format(endTime);

                        return
                          AnimatedBuilder(
                            animation: _opacityAnimation,
                            builder: (context, child) {
                              final bool isPending = (order.approvalStatus ?? 0) == 1;

                              return Opacity(
                                opacity: isPending ? _opacityAnimation.value : 1.0,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(7),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        // Light shadow
                                        spreadRadius: 0,
                                        // How much the shadow spreads
                                        blurRadius: 4,
                                        // How soft the shadow is
                                        offset: Offset(0,
                                            2), // Shadow position: x=0, y=4 (downwards)
                                      ),
                                    ],
                                  ),
                                  // shape: RoundedRectangleBorder(
                                  //   borderRadius: BorderRadius.circular(12),
                                  // ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          Get.to(() =>
                                              OrderDetailEnglish(order)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          // top row
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start,
                                            mainAxisAlignment: MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: Colors
                                                        .green,
                                                    child: SvgPicture.asset(
                                                      order.orderType == 1
                                                          ? 'assets/images/ic_delivery.svg'
                                                          : order.orderType == 2
                                                          ? 'assets/images/ic_pickup.svg'
                                                          : 'assets/images/ic_pickup.svg',
                                                      height: 14,
                                                      width: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  // Text(
                                                  //   order.orderType == 1
                                                  //       ? 'delivery'.tr + ' : $formattedEnd' : order.orderType == 2
                                                  //       ? 'pickup'.tr +
                                                  //       ' : $formattedEnd'
                                                  //       : order.orderType == 3
                                                  //       ? 'dine_in'.tr +
                                                  //       ' : $formattedEnd'
                                                  //       : '',
                                                  //   style: const TextStyle(
                                                  //       fontWeight: FontWeight.bold),
                                                  // ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Text(order
                                                          .shipping_address!.zip
                                                          .toString(),
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .w700,
                                                            fontSize: 13,
                                                            fontFamily: "Mulish-Regular"
                                                        ),),
                                                      Visibility(
                                                        visible: order
                                                            .shipping_address !=
                                                            null,
                                                        child: Text(
                                                          order.orderType ==
                                                              1 &&
                                                              order
                                                                  .shipping_address !=
                                                                  null
                                                              ? '${order
                                                              .shipping_address!
                                                              .line1!}, '
                                                              '${order
                                                              .shipping_address!
                                                              .city!}'
                                                              : '',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                              fontSize: 11,
                                                              letterSpacing: 0,
                                                              height: 0,
                                                              fontFamily: "Mulish"),
                                                        ),
                                                      ),

                                                    ],
                                                  )
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${'order_id'.tr} :',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight
                                                            .w700,
                                                        fontSize: 11,
                                                        fontFamily: "Mulish"),
                                                  ), Text(
                                                    '${order.id}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight
                                                            .w500,
                                                        fontSize: 11,
                                                        fontFamily: "Mulish"),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 1),
                                          SizedBox(height: 6),

                                          Text(
                                            '${order.shipping_address
                                                ?.customer_name ?? "User"} '
                                                '/ ${order.shipping_address
                                                ?.phone ?? "0000000000"}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontFamily: "Mulish",
                                                fontSize: 13),
                                          ),

                                          const SizedBox(height: 8),

                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Text(
                                              //   order.payment != null
                                              //       ? '${'currency'.tr} '
                                              //       '${order.payment!.amount}'
                                              //       : '${'currency'.tr} 00',
                                              //   style: const TextStyle(
                                              //       fontWeight: FontWeight.bold,
                                              //       fontSize: 18),
                                              // ),
                                              Text(
                                                order.payment != null
                                                    ? '${'currency'
                                                    .tr} ${formatAmount(
                                                    order.payment!.amount ??
                                                        0)}'
                                                    : '${'currency'
                                                    .tr} ${formatAmount(0)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: "Mulish",
                                                    fontSize: 16),
                                              ),
                                              Row(
                                                children: [
                                                  Text(getApprovalStatusText(
                                                      order.approvalStatus),
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight
                                                            .w800,
                                                        fontFamily: "Mulish-Regular",
                                                        fontSize: 13
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: getStatusColor(
                                                        order.approvalStatus ??
                                                            0),
                                                    child: Icon(
                                                      getStatusIcon(order
                                                          .approvalStatus ?? 0),
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
                                ),
                              );
                            },
                          );
                      });
                })
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── Misc helpers (unchanged) ───────────────────
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
                  onPressed: () => Navigator.of(context).pop(),
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
      setState(() => dateSeleted = result);
    }
  }

  Future<void> getNewOrder(int orderID) async {
    try {
      final result = await ApiRepo().getNewOrderData(bearerKey!, orderID);
      if (result != null) {
        app.appController.addNewOrder(result);
      } else {
        String errorMessage = result.mess ?? "Unknown error";
      //  showSnackbar("Error", errorMessage);
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }
}
