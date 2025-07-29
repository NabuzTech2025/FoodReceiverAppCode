import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/Socket/socket_service.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/DailySalesReport.dart';
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

import '../models/Store.dart';

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
  String? storeName;
  String? dynamicStoreId;
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;
  DailySalesReport? _currentDateReport;
  DailySalesReport reportsss = DailySalesReport();
  List<DailySalesReport> reportList = [];
  final SocketService _socketService = SocketService();
  bool _isLiveDataActive = false;
  DateTime? _lastUpdateTime;
  bool _showNoOrderText = false;
  Timer? _noOrderTimer;
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
  Future<void> _checkAndClearOldData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString('cached_sales_date');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (cachedDate != today) {
      print("📆 Date changed. Clearing old data.");
      await SalesCacheHelper.clearSalesData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);// Clean up observer
    //socketService.dispose();
    _blinkController.dispose();
    _socketService.disconnect();
    _noOrderTimer?.cancel();
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

    await _preloadStoreData();
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    if (storeID != null) {
      getOrders(bearerKey, false, false, storeID);
    } else {
      getStoreUserMeData(bearerKey);
    }
    getCurrentDateReport();
    _checkAndClearOldData();      // पुराना डेटा साफ़ करो
    _loadCachedSalesData();       // Cached data load करो
    _initializeSocket();

    // Start timer for "no order" text
    _startNoOrderTimer();
    // Initialize socket ONLY if bearerKey is not null and not empty
    if (bearerKey != null && bearerKey!.isNotEmpty) {
      print("Initializing socket with bearer key"); // Debug print
      _initializeSocket();
    } else {
      print("Bearer key is null or empty, socket not initialized"); // Debug print
    }
  }
  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID == null) {
        print("❌ DEBUG - Store ID is null, cannot fetch store data");
        return null;
      }

      final result = await ApiRepo().getStoreData(bearerKey, storeID);

      if (result != null) {
        Store store = result;
        String fetchedStoreName = store.name?.toString() ?? "Unknown Store";
        String fetchedStoreId = store.code?.toString() ?? storeID; // Get store ID from API

        setState(() {
          storeName = fetchedStoreName;
          dynamicStoreId = fetchedStoreId; // Store API fetched ID
        });

        // Save the API store ID to SharedPreferences for next use
        await sharedPreferences.setString(valueShared_STORE_KEY, fetchedStoreId);

        print("✅ DEBUG - Final storeName: '$storeName', apiStoreId: '$dynamicStoreId'");
        return storeName;
      }
    } catch (e) {
      print("❌ DEBUG - Exception in getStoredta: $e");
      return null;
    }
  }
// Alternative approach - get store name from SharedPreferences if available:
  Future<String?> getStoreNameFallback() async {
    try {
      // Try to get from previous session
      String? cachedName = sharedPreferences.getString('last_store_name');
      if (cachedName != null && cachedName.isNotEmpty) {
        print("✅ Using cached store name: $cachedName");
        return cachedName;
      }

      // Try to get from user preferences or default
      return "Default Restaurant"; // Replace with your app's default name
    } catch (e) {
      print("❌ Fallback failed: $e");
      return "Restaurant";
    }
  }


  Future<void> _preloadStoreData() async {
    if (bearerKey != null) {
      try {
        String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
        if (storeID != null) {
          final result = await ApiRepo().getStoreData(bearerKey!, storeID);
          if (result != null) {
            // Cache store name for quick access by OrderDetail screen
            await sharedPreferences.setString('cached_store_name', result.name.toString());
            print("✅ Store data pre-loaded and cached");
          }
        }
      } catch (e) {
        print("❌ Store data preload failed: $e");
      }
    }
  }

  void _initializeSocket() {
    print("🔥 Starting socket initialization");

    // Get dynamic store ID
    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    int dynamicStoreId = int.tryParse(storeID ?? "13") ?? 13;

    print("🆔 Using store ID: $dynamicStoreId"); // Debug print

    _socketService.onSalesUpdate = (data) {
      print('📊 Sales update received in ReportScreen: $data');
      _handleSalesUpdate(data, isFromSocket: true);
    };

    _socketService.onConnected = () {
      print('🔥 Socket connected - Live data active');
      setState(() => _isLiveDataActive = true);
    };

    _socketService.onDisconnected = () {
      print('❄️ Socket disconnected - Live data inactive');
      setState(() => _isLiveDataActive = false);
    };

    _socketService.onNewOrder = (data) {
      print('🆕 New order received: $data');
      _refreshCurrentDayData();
    };

    try {
      print("🔌 Attempting to connect socket with bearer: $bearerKey");
      print("🔌 Attempting to connect socket with storeId: $dynamicStoreId");
      _socketService.connect(bearerKey!, storeId: dynamicStoreId); // ✅ Use dynamic ID
    } catch (e) {
      print("❌ Socket connection failed: $e");
    }
  }

  void _startNoOrderTimer() {
    _noOrderTimer?.cancel();
    _noOrderTimer = Timer(Duration(seconds: 4), () {
      if (mounted && app.appController.searchResultOrder.isEmpty) {
        setState(() => _showNoOrderText = true);
      }
    });
  }

  void _stopNoOrderTimer() {
    _noOrderTimer?.cancel();
    setState(() => _showNoOrderText = false);
  }

  void _handleSalesUpdate(Map<String, dynamic> salesData, {bool isFromSocket = false}) {
    print('🔄 Updating sales data: $salesData');

    // यदि socket से आ रहा है तो SharedPreferences में store करो
    if (isFromSocket) {
      SalesCacheHelper.saveSalesData(salesData);
    }

    setState(() => _lastUpdateTime = DateTime.now());

    // Update current date report with live data
    if (_currentDateReport != null) {
      _currentDateReport!.totalOrders = salesData['total_orders'] as int?;

      if (_currentDateReport!.data == null) {
        _currentDateReport!.data = SalesData(
          topItems: [],
          cashTotal: 0.0,
          byCategory: {},
          orderTypes: {},
          totalSales: 0.0,
          onlineTotal: 0.0,
          totalOrders: 0,
          paymentMethods: {},
          approvalStatuses: {},
        );
      }

      _currentDateReport!.data = SalesData(
        netTotal: (salesData['net_total'] as num?)?.toDouble(),
        topItems: (salesData['top_items'] != null)
            ? (salesData['top_items'] as List).map((item) => TopItem.fromJson(item)).toList()
            : _currentDateReport!.data?.topItems ?? [],
        totalTax: (salesData['total_tax'] as num?)?.toDouble(),
        cashTotal: (salesData['cash_total'] as num?)?.toDouble() ?? 0.0,
        byCategory: salesData['by_category'] != null
            ? Map<String, int>.from(salesData['by_category'])
            : (_currentDateReport!.data?.byCategory ?? {}),
        orderTypes: salesData['order_types'] != null
            ? Map<String, int>.from(salesData['order_types'])
            : {},
        totalSales: (salesData['total_sales'] as num?)?.toDouble() ?? 0.0,
        onlineTotal: (salesData['online_total'] as num?)?.toDouble() ?? 0.0,
        totalOrders: (salesData['total_orders'] as num?)?.toInt() ?? 0,
        taxBreakdown: salesData['tax_breakdown'] != null
            ? TaxBreakdown.fromJson(salesData['tax_breakdown'])
            : null,
        deliveryTotal: (salesData['delivery_total'] as num?)?.toDouble(),
        discountTotal: salesData['discount_total'] != null
            ? (salesData['discount_total'] as num).toInt()
            : null,
        paymentMethods: salesData['payment_methods'] != null
            ? Map<String, int>.from(salesData['payment_methods'])
            : {},
        approvalStatuses: salesData['approval_statuses'] != null
            ? Map<String, int>.from(salesData['approval_statuses'])
            : {},
        totalSalesDelivery: (salesData['total_sales + delivery'] as num?)?.toDouble(),
      );

      setState(() => reportsss = _currentDateReport!);

      print('✅ Sales data updated successfully');
    } else {
      print('❌ Current date report is null, cannot update');
    }
  }

  Future<void> _loadCachedSalesData() async {
    final cachedData = await SalesCacheHelper.loadSalesData();
    if (cachedData != null) {
      print("📥 Loading cached sales data into UI");
      _handleSalesUpdate(cachedData);
    } else {
      print("ℹ️ No cached data found, waiting for live socket data");
    }
  }

  void _refreshCurrentDayData() => getCurrentDateReport();

  void getCurrentDateReport() {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    print("🔍 Looking for current date report: $todayString");
    DailySalesReport? foundReport;
    for (var report in reportList) {
      if (report.startDate != null) {
        final reportDate = DateTime.tryParse(report.startDate!);
        if (reportDate != null &&
            DateFormat('yyyy-MM-dd').format(reportDate) == todayString) {
          foundReport = report;
          break;
        }
      }
    }

    if (foundReport != null) {
      setState(() {
        _currentDateReport = foundReport;
        reportsss = foundReport!;
      });
      print("✅ Current date report set successfully");
    } else {
      print("❌ No report found for today's date: $todayString");
      final defaultReport = DailySalesReport(
        startDate: todayString,
        totalSales: 0.0,
        totalOrders: 0,
        cashTotal: 0.0,
        onlineTotal: 0.0,
        totalTax: 0.0,
        data: null,
      );
      setState(() {
        _currentDateReport = defaultReport;
        reportsss = defaultReport;
        reportList.insert(0, defaultReport);
      });
      print("🆕 Created default report for today");
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
          sharedPreferences.setString(valueShared_STORE_KEY, userMe.store_id.toString());
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
        if (result.isNotEmpty && result.first.code == null) {
          setState(() {
            app.appController.setOrders(result);
          });
          // Stop timer if orders found
          if (result.isNotEmpty) {
            _stopNoOrderTimer();
          }
        } else {
          // Restart timer if no orders
          _startNoOrderTimer();
        }
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

  int _getApprovalStatusCount(String status) {
    if (_currentDateReport?.data?.approvalStatuses == null) return 0;

    // Different possible keys for approval statuses
    final approvalStatuses = _currentDateReport!.data!.approvalStatuses!;

    switch (status.toLowerCase()) {
      case "accepted":
        return approvalStatuses["accepted"] ??
            approvalStatuses["approve"] ??
            approvalStatuses["2"] ?? 0;
      case "declined":
        return approvalStatuses["declined"] ??
            approvalStatuses["decline"] ??
            approvalStatuses["rejected"] ??
            approvalStatuses["3"] ?? 0;
      case "pending":
        return approvalStatuses["pending"] ??
            approvalStatuses["1"] ?? 0;
      default:
        return 0;
    }
  }

// Order Type count get करने के लिए
  int _getOrderTypeCount(String type) {
    if (_currentDateReport?.data?.orderTypes == null) return 0;

    final orderTypes = _currentDateReport!.data!.orderTypes!;

    switch (type.toLowerCase()) {
      case "pickup":
        return orderTypes["pickup"] ??
            orderTypes["pick_up"] ??
            orderTypes["takeaway"] ?? 0;
      case "delivery":
        return orderTypes["delivery"] ??
            orderTypes["home_delivery"] ?? 0;
      case "dine_in":
        return orderTypes["dine_in"] ??
            orderTypes["dinein"] ?? 0;
      default:
        return 0;
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ────────── Header section ──────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row - Date + Title + Total Orders + Refresh
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

                    // Total Orders + Refresh button
                    Row(
                      children: [
                        Text(
                          'Total Orders: ${_currentDateReport?.totalOrders ?? 0}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: "Mulish",
                              color: Colors.black
                          ),
                        ),
                        IconButton(
                          iconSize: 33,
                          icon: const Icon(Icons.refresh),
                          onPressed: _manualRefresh,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Second row - Status containers
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Accepted Orders
                      _buildStatusContainer(
                        'Accepted: ${_getApprovalStatusCount("accepted")}',
                        Colors.green.withOpacity(0.1),
                      ),
                      SizedBox(width: 8),

                      // Declined Orders
                      _buildStatusContainer(
                        'Decline: ${_getApprovalStatusCount("declined")}',
                        Colors.red.withOpacity(0.1),
                      ),
                      SizedBox(width: 8),

                      // Pending Orders
                      _buildStatusContainer(
                        'Pending: ${_getApprovalStatusCount("pending")}',
                        Colors.orange.withOpacity(0.1),
                      ),
                      SizedBox(width: 8),

                      // Pickup Orders
                      _buildStatusContainer(
                        'PickUp: ${_getOrderTypeCount("pickup")}',
                        Colors.blue.withOpacity(0.1),
                      ),
                      SizedBox(width: 8),

                      // Delivery Orders
                      _buildStatusContainer(
                        'Delivery: ${_getOrderTypeCount("delivery")}',
                        Colors.purple.withOpacity(0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ────────── Orders list with pull‑to‑refresh ──────────
            Expanded(
              child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.green,
                  backgroundColor: Colors.white,
                  displacement: 60,
                  child: Obx(() {
                    if (app.appController.searchResultOrder.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 100),
                          Center(
                              child: _showNoOrderText
                                  ? Text(
                                'No orders yet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              )
                                  : Lottie.asset(
                                'assets/animations/burger.json',
                                width: 150,
                                height: 150,
                                repeat: true,
                              )
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: app.appController.searchResultOrder.length,
                        itemBuilder: (context, index) {
                          final order = app.appController.searchResultOrder[index];

                          DateTime startTime = DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now();
                          DateTime endTime = startTime.add(const Duration(minutes: 30));
                          String formattedEnd = DateFormat('hh:mm a').format(endTime);
                          DateTime dateTime = DateTime.parse(order.createdAt.toString());
                          String time = DateFormat('hh:mm a').format(dateTime);

                          return AnimatedBuilder(
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
                                        spreadRadius: 0,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => Get.to(() => OrderDetailEnglish(order)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // top row
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: Colors.green,
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
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                  order.orderType == 2 ?'pickup'.tr:order.shipping_address!.zip.toString(),
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 13,
                                                            fontFamily: "Mulish-Regular"
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible: order.shipping_address != null,
                                                        child: Text(
                                                          order.orderType == 1 && order.shipping_address != null
                                                              ? '${order.shipping_address!.line1!}, ${order.shipping_address!.city!}'
                                                              : '',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 11,
                                                              letterSpacing: 0,
                                                              height: 0,
                                                              fontFamily: "Mulish"
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time,size: 20,),
                                                  Text(time,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontFamily: "Mulish",
                                                      fontSize: 10,
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                          SizedBox(height: 8),

                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${order.shipping_address?.customer_name ?? "User"} / ${order.shipping_address?.phone ?? "0000000000"}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: "Mulish",
                                                    fontSize: 13
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${'order_id'.tr} :',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 11,
                                                        fontFamily: "Mulish"
                                                    ),
                                                  ),
                                                  Text(
                                                    '${order.id}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 11,
                                                        fontFamily: "Mulish"
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                order.payment != null
                                                    ? '${'currency'.tr} ${formatAmount(order.payment!.amount ?? 0)}'
                                                    : '${'currency'.tr} ${formatAmount(0)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: "Mulish",
                                                    fontSize: 16
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    getApprovalStatusText(order.approvalStatus),
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontFamily: "Mulish-Regular",
                                                        fontSize: 13
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: getStatusColor(order.approvalStatus ?? 0),
                                                    child: Icon(
                                                      getStatusIcon(order.approvalStatus ?? 0),
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
                        }
                    );
                  })
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Helper method for status containers
  Widget _buildStatusContainer(String text, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontFamily: "Mulish",
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Colors.black87
        ),
      ),
    );
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return "pending".tr;
      case 2:
        return "accepted".tr;
      case 3:
        return "decline".tr;
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
class SalesCacheHelper {
  static const _salesDataKey = 'cached_sales_data';
  static const _lastDateKey = 'cached_sales_date';

  static Future<void> saveSalesData(Map<String, dynamic> salesData) async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_salesDataKey, jsonEncode(salesData));
    await prefs.setString(_lastDateKey, todayString);
    print("💾 Cached sales data for $todayString");
  }

  static Future<Map<String, dynamic>?> loadSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cachedDate = prefs.getString(_lastDateKey);
    final cachedData = prefs.getString(_salesDataKey);

    if (cachedDate == todayString && cachedData != null) {
      return jsonDecode(cachedData);
    }
    return null;
  }

  static Future<void> clearSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_salesDataKey);
    await prefs.remove(_lastDateKey);
  }
}