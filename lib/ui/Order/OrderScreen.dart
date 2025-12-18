//
// import 'dart:async';
// import 'dart:convert';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:food_app/api/Socket/socket_service.dart';
// import 'package:food_app/api/repository/api_repository.dart';
// import 'package:food_app/constants/constant.dart';
// import 'package:food_app/models/DailySalesReport.dart';
// import 'package:food_app/models/UserMe.dart';
// import 'package:food_app/ui/Order/OrderDetailEnglish.dart';
// import 'package:food_app/utils/log_util.dart';
// import 'package:food_app/utils/my_application.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:lottie/lottie.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../Database/databse_helper.dart';
// import '../../models/Topping.dart';
// import '../../models/order_model.dart';
// import '../../models/sync_order_response_model.dart';
// import '../../models/today_report.dart' hide TaxBreakdown;
// import '../Login/LoginScreen.dart';
// import '../../models/order_model.dart'; // Order model
// import '../../models/ShippingAddress.dart'; // ShippingAddress model
// import '../../models/OrderItem.dart'; // OrderItem model
// import '../../models/Payment.dart'; // Payment model
//
// class OrderScreenNew extends StatefulWidget {
//   const OrderScreenNew({super.key});
//
//   @override
//   _OrderScreenState createState() => _OrderScreenState();
// }
//
// class _OrderScreenState extends State<OrderScreenNew>
//     with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
//   Color getStatusColor(int status) {
//     switch (status) {
//       case 1:
//         return Colors.orange;
//       case 2:
//         return Colors.green;
//       case 3:
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   IconData getStatusIcon(int status) {
//     switch (status) {
//       case 1:
//         return Icons.visibility;
//       case 2:
//         return Icons.check;
//       case 3:
//         return Icons.close;
//       default:
//         return Icons.help;
//     }
//   }
//
//   late SharedPreferences sharedPreferences;
//   String? bearerKey;
//   String dateSeleted = "";
//   late UserMe userMe;
//   String? storeName;
//   String? dynamicStoreId;
//   late AnimationController _blinkController;
//   late Animation<double> _opacityAnimation;
//   DailySalesReport? _currentDateReport;
//   DailySalesReport reportsss = DailySalesReport();
//   List<DailySalesReport> reportList = [];
//   final SocketService _socketService = SocketService();
//   bool _isLiveDataActive = false;
//   DateTime? _lastUpdateTime;
//   bool _showNoOrderText = false;
//   Timer? _noOrderTimer;
//   bool _hasSocketData = false;
//   Map<String, int> _liveApiData = {
//     'accepted': 0,
//     'declined': 0,
//     'pending': 0,
//     'pickup': 0,
//     'delivery': 0,
//     'totalOrders': 0,
//   };
//   bool isLoading = false;
//   bool _isInitialLoading = true;
//   Timer? _initVarTimeoutTimer;
//   bool hasInternet = true;
//   Timer? _internetCheckTimer;
//   bool _isDialogShowing = false;
//   String? _storeType;
//   bool _isRefreshing = false;
//   DateTime? _lastRefreshTime;
//   String delivery = '0', pickUp = '0', pending = '0', accepted = '0', declined = '0';
//
//   // Add these with other state variables at the top
//   bool _isSyncingLocalOrders = false;
//   List<Order> _localOrders = [];
//   Timer? _syncTimer;
//   late AnimationController _syncRotationController;
//   late Animation<double> _syncRotationAnimation;
//   Timer? _autoSyncTimer;
//   int _autoSyncInterval = 60;
//   bool _syncTimeLoaded = false;
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     _blinkController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//
//     _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
//       CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
//     );
//     _syncRotationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat();
//
//     _syncRotationAnimation = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _syncRotationController, curve: Curves.linear),
//     );
//     _startInternetMonitoring();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       initVar();
//       _loadAndSyncLocalOrders();
//     });
//   }
//
//   Future<void> _checkAndClearOldData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedDate = prefs.getString('cached_sales_date');
//     final cachedOrderDate = prefs.getString('cached_order_date');
//     final cachedStoreId = prefs.getString('cached_store_id');
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final currentStoreId = prefs.getString(valueShared_STORE_KEY);
//
//     if (cachedDate != today || cachedStoreId != currentStoreId) {
//       await SalesCacheHelper.clearSalesData();
//       setState(() {
//         _currentDateReport = null;
//         reportsss = DailySalesReport();
//         reportList.clear();
//       });
//       if (currentStoreId != null) {
//         await prefs.setString('cached_store_id', currentStoreId);
//       }
//     }
//
//     if (cachedOrderDate != today || cachedStoreId != currentStoreId) {
//       setState(() {
//         app.appController.clearOrders();
//       });
//       await prefs.setString('cached_order_date', today);
//     }
//   }
//
//   @override
//   void dispose() {
//     _socketService.disconnect();
//     WidgetsBinding.instance.removeObserver(this);
//     _initVarTimeoutTimer?.cancel();
//     _internetCheckTimer?.cancel();
//     _blinkController.dispose();
//     _syncRotationController.dispose();
//     _noOrderTimer?.cancel();
//     _syncTimer?.cancel();
//     _autoSyncTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _loadAndSyncLocalOrders() async {
//     if (_isSyncingLocalOrders) return;
//
//     setState(() {
//       _isSyncingLocalOrders = true;
//     });
//
//     try {
//       final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//       if (storeID == null || storeID.isEmpty) {
//         setState(() {
//           _isSyncingLocalOrders = false;
//         });
//         return;
//       }
//
//       // Get unsynced orders from database
//       final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeID);
//
//       if (unsyncedOrders.isEmpty) {
//         setState(() {
//           _isSyncingLocalOrders = false;
//           _localOrders.clear();
//         });
//         return;
//       }
//
//       // Convert database orders to Order model format
//       List<Order> localOrdersList = [];
//
//       for (var dbOrder in unsyncedOrders) {
//         final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
//
//         if (orderDetails != null) {
//           Order order = await _convertDbOrderToOrderModel(orderDetails); // Add await here
//           localOrdersList.add(order);
//         }
//       }
//       setState(() {
//         _localOrders = localOrdersList;
//       });
//
//
//     } catch (e) {
//       print('Error loading local orders: $e');
//       setState(() {
//         _isSyncingLocalOrders = false;
//       });
//     }
//   }
//
//   Future<void> updateSyncInterval() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? syncTime = prefs.getString('sync_time');
//
//       if (syncTime != null && syncTime.isNotEmpty) {
//         int? syncTimeValue = int.tryParse(syncTime);
//         if (syncTimeValue != null && syncTimeValue > 0) {
//           _autoSyncInterval = syncTimeValue;
//           print('✅ Updated sync interval to: $_autoSyncInterval seconds');
//
//           // Restart timer with new interval
//           _startAutoSync();
//
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Auto sync interval updated to $_autoSyncInterval seconds'),
//                 backgroundColor: Colors.green,
//                 duration: const Duration(seconds: 2),
//               ),
//             );
//           }
//         }
//       }
//     } catch (e) {
//       print('❌ Error updating sync interval: $e');
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     if (state == AppLifecycleState.resumed) {
//       if (_isRefreshing) return;
//
//       if (_lastRefreshTime != null) {
//         final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
//         if (timeSinceLastRefresh.inSeconds < 2) return;
//       }
//
//       if (Get.isDialogOpen ?? false) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//       _reloadSyncTime();
//       _silentRefresh();
//     }
//   }
//
//   Future<void> _silentRefresh() async {
//     if (_isRefreshing) return;
//
//     _isRefreshing = true;
//     _lastRefreshTime = DateTime.now();
//
//     try {
//       final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//
//       if (storeID != null && storeID.isNotEmpty && !_isErrorCode(storeID)) {
//         await getOrdersWithoutLoader(bearerKey, storeID);
//         await getLiveSaleReportWithoutLoader();
//       }
//     } catch (e) {
//       // Handle error
//     } finally {
//       _isRefreshing = false;
//     }
//   }
//
//   Future<void> _reloadSyncTime() async {
//     try {
//       String? syncTime = sharedPreferences.getString('sync_time');
//
//       if (syncTime != null && syncTime.isNotEmpty) {
//         int? syncTimeSeconds = int.tryParse(syncTime);
//         if (syncTimeSeconds != null && syncTimeSeconds >= 60) { // ✅ Minimum 60 seconds
//           if (_autoSyncInterval != syncTimeSeconds) {
//             _autoSyncInterval = syncTimeSeconds;
//             int minutes = (syncTimeSeconds / 60).round();
//             print('🔄 Sync interval updated to: $minutes minutes ($syncTimeSeconds seconds)');
//
//             // Restart timer with new interval
//             _startAutoSync();
//
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Auto sync interval updated to $minutes minutes'),
//                   backgroundColor: Colors.green,
//                   duration: const Duration(seconds: 2),
//                 ),
//               );
//             }
//           }
//         }
//       }
//     } catch (e) {
//       print('❌ Error reloading sync time: $e');
//     }
//   }
//
//   Future<void> initVar() async {
//     _initVarTimeoutTimer?.cancel();
//
//     if (Get.isDialogOpen ?? false) {
//       try {
//         Get.back();
//       } catch (e) {
//         // Handle error
//       }
//     }
//
//     if (_isInitialLoading) {
//       setState(() {
//         isLoading = true;
//       });
//     }
//
//     Timer? timeoutTimer;
//
//     try {
//       timeoutTimer = Timer(const Duration(seconds: 10), () {
//         if (mounted) {
//           setState(() {
//             isLoading = false;
//             _isInitialLoading = false;
//           });
//         }
//       });
//
//       setState(() {
//         hasInternet = true;
//       });
//
//       if (_isDialogShowing) {
//         try {
//           Navigator.of(context).pop();
//           _isDialogShowing = false;
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       sharedPreferences = await SharedPreferences.getInstance();
//       bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
//       _storeType = sharedPreferences.getString(valueShared_STORE_TYPE);
//       if (!_syncTimeLoaded) {
//         await _loadSyncTimeAndStartAutoSync();
//         _syncTimeLoaded = true;
//       }
//
//       _socketService.disconnect();
//       setState(() {
//         _isLiveDataActive = false;
//         _lastUpdateTime = null;
//         _currentDateReport = null;
//         reportsss = DailySalesReport();
//       });
//
//       await _preloadStoreData();
//       await _checkAndClearOldData();
//
//       final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//
//       if (storeID != null && storeID.isNotEmpty && !_isErrorCode(storeID)) {
//         String? cachedStoreName = await DatabaseHelper().getStoreName(storeID);
//         if (cachedStoreName != null && cachedStoreName.isNotEmpty) {
//           setState(() {
//             storeName = cachedStoreName;
//             dynamicStoreId = storeID;
//           });
//           print("✅ OrderScreen: Loaded store name from cache: $storeName");
//         }
//         await _restoreUserSpecificData(storeID);
//         await getOrdersWithoutLoader(bearerKey, storeID);
//         await _loadAndSyncLocalOrders();
//         if (bearerKey != null && bearerKey!.isNotEmpty) {
//           _initializeSocket();
//         }
//       } else {
//         if (storeID != null && _isErrorCode(storeID)) {
//           await sharedPreferences.remove(valueShared_STORE_KEY);
//         }
//         await getStoreUserMeDataWithoutLoader(bearerKey);
//       }
//
//       getCurrentDateReport();
//       _loadCachedSalesData();
//       _startNoOrderTimer();
//       await getLiveSaleReportWithoutLoader();
//     } catch (e) {
//       // Handle error
//     } finally {
//       timeoutTimer?.cancel();
//       _initVarTimeoutTimer?.cancel();
//
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           _isInitialLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _loadSyncTimeAndStartAutoSync() async {
//     try {
//       String? syncTime = sharedPreferences.getString('sync_time');
//
//       if (syncTime != null && syncTime.isNotEmpty) {
//         int? syncTimeSeconds = int.tryParse(syncTime);
//         if (syncTimeSeconds != null && syncTimeSeconds >= 60) { // ✅ Minimum 60 seconds (1 minute)
//           _autoSyncInterval = syncTimeSeconds;
//           int minutes = (syncTimeSeconds / 60).round();
//           print('✅ Loaded sync interval: $minutes minutes ($syncTimeSeconds seconds)');
//         } else {
//           print('⚠️ Invalid sync time in preferences, using default');
//           _autoSyncInterval = 1800; // ✅ Default 30 minutes = 1800 seconds
//         }
//       } else {
//         print('📝 No sync time found, using default: 30 minutes');
//         _autoSyncInterval = 1800; // ✅ Default 30 minutes = 1800 seconds
//       }
//
//       // Start auto sync with loaded interval
//       _startAutoSync();
//     } catch (e) {
//       print('❌ Error loading sync time: $e');
//       _autoSyncInterval = 1800; // ✅ Default 30 minutes = 1800 seconds
//       _startAutoSync();
//     }
//   }
//
//   void _startAutoSync() {
//     _autoSyncTimer?.cancel(); // Cancel existing timer
//
//     int minutes = (_autoSyncInterval / 60).round();
//     print('🔄 Starting auto sync with interval: $minutes minutes ($_autoSyncInterval seconds)');
//     print('🕐 Next sync will occur at: ${DateTime.now().add(Duration(seconds: _autoSyncInterval))}');
//
//     _autoSyncTimer = Timer.periodic(Duration(seconds: _autoSyncInterval), (timer) async {
//       int mins = (_autoSyncInterval / 60).round();
//       print('⏰ Auto sync timer triggered at ${DateTime.now()} - Interval: $mins minutes');
//       await _autoSyncLocalOrders();
//     });
//   }
//
//   Future<Order> _convertDbOrderToOrderModel(Map<String, dynamic> orderDetails) async {
//     final orderData = orderDetails['order'] as Map<String, dynamic>;
//     final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;
//     final itemsData = orderDetails['items'] as List<dynamic>;
//     final paymentData = orderDetails['payment'] as Map<String, dynamic>?;
//
//     // Create shipping address
//     ShippingAddress? shippingAddress;
//     if (addressData != null) {
//       shippingAddress = ShippingAddress(
//         customer_name: addressData['customer_name'] as String?,
//         phone: addressData['phone'] as String?,
//         line1: addressData['line1'] as String?,
//         city: addressData['city'] as String?,
//         zip: addressData['zip'] as String?,
//         country: addressData['country'] as String?,
//         type: addressData['type'] as String?,
//       );
//     }
//
//     // Create guest shipping json (for fallback)
//     GuestShippingJson? guestShippingJson;
//     if (addressData != null) {
//       guestShippingJson = GuestShippingJson(
//         customerName: addressData['customer_name'] as String?,
//         phone: addressData['phone'] as String?,
//         line1: addressData['line1'] as String?,
//         city: addressData['city'] as String?,
//         zip: addressData['zip'] as String?,
//         country: addressData['country'] as String?,
//         type: addressData['type'] as String?,
//       );
//     }
//
//     // Create payment
//     Payment? payment;
//     if (paymentData != null) {
//       payment = Payment(
//         amount: (paymentData['amount'] as num?)?.toDouble(),
//         paymentMethod: paymentData['payment_method'] as String?,
//         status: paymentData['status'] as String?,
//       );
//     }
//
//
//
//     List<OrderItem>? orderItems;
//     if (itemsData.isNotEmpty) {
//       final itemFutures = itemsData.map((item) async {
//         String productName = 'Product';
//         try {
//           final productId = item['product_id'] as int?;
//           if (productId != null) {
//             final product = await DatabaseHelper().getProductById(productId.toString());
//             if (product != null) {
//               productName = product.name ?? 'Product';
//             }
//           }
//         } catch (e) {
//           print('Error getting product name: $e');
//         }
//
//         // ✅ Parse toppings from database
//         List<Topping>? toppings;
//         if (item['toppings'] != null && item['toppings'] is List) {
//           toppings = (item['toppings'] as List).map((t) => Topping(
//             toppingId: t['id'] as int?,
//             name: t['topping_name'] as String?,
//             price: (t['topping_price'] as num?)?.toDouble(),
//             quantity: t['topping_quantity'] as int?,
//           )).toList();
//         }
//
//         return OrderItem(
//           id: item['id'] as int?,
//           productId: item['product_id'] as int?,
//           productName: productName,
//           quantity: item['quantity'] as int?,
//           unitPrice: (item['unit_price'] as num?)?.toDouble(),
//           variantId: item['variant_id'] as int?,
//           note: item['note'] as String? ?? '',
//           variant: null,
//           toppings: toppings ?? [],
//         );
//       }).toList();
//
//       orderItems = await Future.wait(itemFutures);
//     }
//     // Create order
//     return Order(
//       id: orderData['id'] as int?,
//       orderNumber: orderData['id'] as int?,
//       orderType: orderData['order_type'] as int?,
//       orderStatus: orderData['order_status'] as int?,
//       approvalStatus: orderData['approval_status'] as int?,
//       note: orderData['note'] as String? ?? '',
//       deliveryTime: orderData['delivery_time'] as String?,
//       storeId: orderData['store_id'] != null
//           ? int.tryParse(orderData['store_id'].toString())
//           : null,
//       isActive: orderData['isActive'] == 1,
//       createdAt: DateTime.fromMillisecondsSinceEpoch(
//           orderData['created_at'] as int
//       ).toIso8601String(),
//       shipping_address: shippingAddress,
//       guestShippingJson: guestShippingJson,
//       payment: payment,
//       items: orderItems ?? [],
//       isLocalOrder: true,
//     );
//   }
//
//   bool _isErrorCode(String? value) {
//     if (value == null || value.isEmpty) return false;
//     int? code = int.tryParse(value);
//     if (code == null) return false;
//     List<int> errorCodes = [400, 401, 403, 404, 500, 502, 503, 504];
//     return errorCodes.contains(code);
//   }
//
//   Future<void> _offlineLogout() async {
//     bool loaderShown = false;
//     Timer? timeoutTimer;
//
//     try {
//       if (Get.isDialogOpen ?? false) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       Get.dialog(
//         Center(
//           child: Lottie.asset(
//             'assets/animations/burger.json',
//             width: 150,
//             height: 150,
//             repeat: true,
//           ),
//         ),
//         barrierDismissible: false,
//       );
//       loaderShown = true;
//
//       timeoutTimer = Timer(const Duration(seconds: 8), () {
//         if (loaderShown && (Get.isDialogOpen ?? false)) {
//           try {
//             Get.back();
//             loaderShown = false;
//           } catch (e) {
//             // Handle error
//           }
//         }
//         Get.offAll(() => const LoginScreen());
//       });
//       await DatabaseHelper().clearAllStores();
//       await _preserveUserIPDataOffline();
//       await _forceCompleteLogoutCleanupOffline();
//       app.appController.clearOnLogout();
//       await _disconnectSocketOffline();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         Get.back();
//         loaderShown = false;
//       }
//
//       Get.offAll(() => const LoginScreen());
//     } catch (e) {
//       // Handle error
//     } finally {
//       timeoutTimer?.cancel();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (!Get.currentRoute.contains('LoginScreen')) {
//         Get.offAll(() => const LoginScreen());
//       }
//     }
//   }
//
//   Future<void> _preserveUserIPDataOffline() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? currentStoreId = prefs.getString(valueShared_STORE_KEY);
//
//       if (currentStoreId != null && currentStoreId.isNotEmpty) {
//         String userPrefix = "user_${currentStoreId}_";
//
//         for (int i = 0; i < 5; i++) {
//           String? currentIP = prefs.getString('printer_ip_$i');
//           if (currentIP != null && currentIP.isNotEmpty) {
//             await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
//           }
//         }
//
//         for (int i = 0; i < 5; i++) {
//           String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
//           if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
//             await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
//           }
//         }
//
//         int? selectedIndex = prefs.getInt('selected_ip_index');
//         if (selectedIndex != null) {
//           await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
//         }
//
//         int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
//         if (selectedRemoteIndex != null) {
//           await prefs.setInt('${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
//         }
//
//         bool? autoOrderAccept = prefs.getBool('auto_order_accept');
//         if (autoOrderAccept != null) {
//           await prefs.setBool('${userPrefix}auto_order_accept', autoOrderAccept);
//         }
//
//         bool? autoOrderPrint = prefs.getBool('auto_order_print');
//         if (autoOrderPrint != null) {
//           await prefs.setBool('${userPrefix}auto_order_print', autoOrderPrint);
//         }
//
//         bool? autoRemoteAccept = prefs.getBool('auto_order_remote_accept');
//         if (autoRemoteAccept != null) {
//           await prefs.setBool('${userPrefix}auto_order_remote_accept', autoRemoteAccept);
//         }
//
//         bool? autoRemotePrint = prefs.getBool('auto_order_remote_print');
//         if (autoRemotePrint != null) {
//           await prefs.setBool('${userPrefix}auto_order_remote_print', autoRemotePrint);
//         }
//       }
//     } catch (e) {
//       // Handle error
//     }
//   }
//
//   Future<void> _forceCompleteLogoutCleanupOffline() async {
//     try {
//       await DatabaseHelper().clearAllStores();
//       for (int attempt = 0; attempt < 3; attempt++) {
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//
//         List<String> keysToRemove = [
//           valueShared_BEARER_KEY,
//           valueShared_STORE_KEY,
//           'printer_ip_backup',
//           'printer_ip_0_backup',
//           'last_save_timestamp',
//           'printer_ip_0',
//           'printer_ip_remote_0',
//           'selected_ip_index',
//           'selected_ip_remote_index',
//           'auto_order_accept',
//           'auto_order_print',
//           'auto_order_remote_accept',
//           'auto_order_remote_print',
//           'cached_sales_date',
//           'cached_order_date',
//           'cached_store_id',
//           'cached_store_name',
//           'store_name',
//           valueShared_STORE_NAME,
//         ];
//
//         for (String key in keysToRemove) {
//           await prefs.remove(key);
//           await Future.delayed(const Duration(milliseconds: 20));
//         }
//
//         for (int i = 0; i < 5; i++) {
//           await prefs.remove('printer_ip_$i');
//           await prefs.remove('printer_ip_remote_$i');
//         }
//
//         await SalesCacheHelper.clearSalesData();
//         await prefs.reload();
//         await Future.delayed(const Duration(milliseconds: 100));
//       }
//
//       SharedPreferences finalPrefs = await SharedPreferences.getInstance();
//       await finalPrefs.reload();
//     } catch (e) {
//       // Handle error
//     }
//   }
//
//   Future<void> _disconnectSocketOffline() async {
//     try {
//       _socketService.disconnect();
//       await Future.delayed(const Duration(milliseconds: 100));
//     } catch (e) {
//       // Handle error
//     }
//   }
//
//   void _showLogoutDialog() {
//     if (_isDialogShowing || !mounted) return;
//
//     _isDialogShowing = true;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async => false,
//           child: AlertDialog(
//             title: const Row(
//               children: [
//                 Icon(Icons.signal_wifi_off, color: Colors.red),
//                 SizedBox(width: 8),
//                 Text("Connection Error"),
//               ],
//             ),
//             content: const Text(
//                 "Cannot connect to server. Please logout and login again to continue."),
//             actions: [
//               ElevatedButton(
//                 onPressed: () {
//                   _isDialogShowing = false;
//                   Navigator.of(context).pop();
//                   _offlineLogout();
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 child: const Text("Logout", style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         );
//       },
//     ).then((_) {
//       _isDialogShowing = false;
//     });
//   }
//
//   void _startInternetMonitoring() {
//     _internetCheckTimer?.cancel();
//     _internetCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
//       final connectivityResult = await Connectivity().checkConnectivity();
//       bool hasConnection = connectivityResult != ConnectivityResult.none;
//
//       if (hasConnection && !hasInternet) {
//         setState(() {
//           hasInternet = true;
//         });
//
//         if (_isDialogShowing) {
//           try {
//             Navigator.of(context).pop();
//             _isDialogShowing = false;
//           } catch (e) {
//             // Handle error
//           }
//         }
//
//         initVar();
//       }
//     });
//   }
//
//   Future<void> getLiveSaleReportWithoutLoader() async {
//     try {
//       if (bearerKey == null || bearerKey!.isEmpty) {
//         _setEmptyValues();
//         return;
//       }
//
//       GetTodayReport model = await CallService().getLiveSaleData();
//
//       setState(() {
//         hasInternet = true;
//       });
//
//       if (_isDialogShowing) {
//         try {
//           Navigator.of(context).pop();
//           _isDialogShowing = false;
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (model.code != null && model.code != 200) {
//         _setEmptyValues();
//         return;
//       }
//
//       setState(() {
//         delivery = '${model.orderTypes?.delivery ?? 0}';
//         pickUp = '${model.orderTypes?.pickup ?? 0}';
//         pending = '${model.approvalStatuses?.pending ?? 0}';
//         accepted = '${model.approvalStatuses?.accepted ?? 0}';
//         declined = '${model.approvalStatuses?.declined ?? 0}';
//
//         _liveApiData = {
//           'accepted': model.approvalStatuses?.accepted ?? 0,
//           'declined': model.approvalStatuses?.declined ?? 0,
//           'pending': model.approvalStatuses?.pending ?? 0,
//           'pickup': model.orderTypes?.pickup ?? 0,
//           'delivery': model.orderTypes?.delivery ?? 0,
//           'totalOrders': model.totalOrders ?? 0,
//         };
//
//         _isLiveDataActive = true;
//         _lastUpdateTime = DateTime.now();
//       });
//     } catch (e) {
//       if (e.toString().contains('SocketException') ||
//           e.toString().contains('Failed host lookup') ||
//           e.toString().contains('API call failed with status null')) {
//         setState(() {
//           hasInternet = false;
//         });
//
//         Future.delayed(const Duration(milliseconds: 500), () {
//           _showLogoutDialog();
//         });
//       }
//
//       _setEmptyValues();
//     }
//   }
//
//   Future<void> _restoreUserSpecificData(String currentStoreId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String userPrefix = "user_${currentStoreId}_";
//
//       String? testKey = prefs.getString('${userPrefix}printer_ip_0');
//       if (testKey != null) {
//         for (int i = 0; i < 5; i++) {
//           String? savedIP = prefs.getString('${userPrefix}printer_ip_$i');
//           if (savedIP != null && savedIP.isNotEmpty) {
//             await prefs.setString('printer_ip_$i', savedIP);
//           }
//         }
//
//         for (int i = 0; i < 5; i++) {
//           String? savedRemoteIP = prefs.getString('${userPrefix}printer_ip_remote_$i');
//           if (savedRemoteIP != null && savedRemoteIP.isNotEmpty) {
//             await prefs.setString('printer_ip_remote_$i', savedRemoteIP);
//           }
//         }
//
//         int? selectedIndex = prefs.getInt('${userPrefix}selected_ip_index');
//         if (selectedIndex != null) {
//           await prefs.setInt('selected_ip_index', selectedIndex);
//         }
//
//         int? selectedRemoteIndex = prefs.getInt('${userPrefix}selected_ip_remote_index');
//         if (selectedRemoteIndex != null) {
//           await prefs.setInt('selected_ip_remote_index', selectedRemoteIndex);
//         }
//
//         bool? autoOrderAccept = prefs.getBool('${userPrefix}auto_order_accept');
//         if (autoOrderAccept != null) {
//           await prefs.setBool('auto_order_accept', autoOrderAccept);
//         }
//
//         bool? autoOrderPrint = prefs.getBool('${userPrefix}auto_order_print');
//         if (autoOrderPrint != null) {
//           await prefs.setBool('auto_order_print', autoOrderPrint);
//         }
//
//         bool? autoRemoteAccept = prefs.getBool('${userPrefix}auto_order_remote_accept');
//         if (autoRemoteAccept != null) {
//           await prefs.setBool('auto_order_remote_accept', autoRemoteAccept);
//         }
//
//         bool? autoRemotePrint = prefs.getBool('${userPrefix}auto_order_remote_print');
//         if (autoRemotePrint != null) {
//           await prefs.setBool('auto_order_remote_print', autoRemotePrint);
//         }
//       } else {
//         await _clearGeneralIPData();
//       }
//     } catch (e) {
//       // Handle error
//     }
//   }
//
//   Future<void> _clearGeneralIPData() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//
//       for (int i = 0; i < 5; i++) {
//         await prefs.remove('printer_ip_$i');
//         await prefs.remove('printer_ip_remote_$i');
//       }
//
//       await prefs.remove('selected_ip_index');
//       await prefs.remove('selected_ip_remote_index');
//       await prefs.remove('auto_order_accept');
//       await prefs.remove('auto_order_print');
//       await prefs.remove('auto_order_remote_accept');
//       await prefs.remove('auto_order_remote_print');
//     } catch (e) {
//       // Handle error
//     }
//   }
//
//   Future<String?> getStoredta(String bearerKey) async {
//     try {
//       String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//
//       if (storeID == null || storeID.isEmpty) {
//         return null;
//       }
//
//       final result = await ApiRepo().getStoreData(bearerKey, storeID);
//
//       setState(() {
//         hasInternet = true;
//       });
//
//       if (_isDialogShowing) {
//         try {
//           Navigator.of(context).pop();
//           _isDialogShowing = false;
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (result.code != null) {
//         if (result.code == 500 || result.code! >= 500) {
//           setState(() {
//             hasInternet = false;
//           });
//           Future.delayed(const Duration(milliseconds: 500), () {
//             _showLogoutDialog();
//           });
//         }
//         return null;
//       }
//
//       if (result.name != null && result.name!.isNotEmpty) {
//         String fetchedStoreName = result.name!;
//         String fetchedStoreId = storeID;
//         await DatabaseHelper().saveStore(fetchedStoreId, fetchedStoreName);
//
//         setState(() {
//           storeName = fetchedStoreName;
//           dynamicStoreId = fetchedStoreId;
//         });
//
//         await sharedPreferences.setString('store_name', fetchedStoreName);
//         await sharedPreferences.setString(valueShared_STORE_NAME, fetchedStoreName);
//
//         return storeName;
//       } else {
//         return null;
//       }
//     } catch (e) {
//       if (e.toString().contains('SocketException') ||
//           e.toString().contains('Failed host lookup')) {
//         setState(() {
//           hasInternet = false;
//         });
//         Future.delayed(const Duration(milliseconds: 500), () {
//           _showLogoutDialog();
//         });
//       }
//
//       return null;
//     }
//   }
//
//   Future<void> getStoreUserMeDataWithoutLoader(String? bearerKey) async {
//     try {
//       final result = await ApiRepo().getUserMe(bearerKey);
//
//       setState(() {
//         hasInternet = true;
//       });
//
//       if (_isDialogShowing) {
//         try {
//           Navigator.of(context).pop();
//           _isDialogShowing = false;
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (result.code != null) {
//         if (result.code == 500 || result.code! >= 500) {
//           setState(() {
//             hasInternet = false;
//           });
//           Future.delayed(const Duration(milliseconds: 500), () {
//             _showLogoutDialog();
//           });
//           return;
//         } else {
//           showSnackbar("error".tr, result.mess ?? "failed".tr);
//           return;
//         }
//       }
//
//       if (result.store_id != null && result.store_id! > 0) {
//         setState(() {
//           userMe = result;
//         });
//
//         String newStoreId = result.store_id.toString();
//         await sharedPreferences.setString(valueShared_STORE_KEY, newStoreId);
//
//         await getStoredta(bearerKey!);
//         await _restoreUserSpecificData(newStoreId);
//         await getOrdersWithoutLoader(bearerKey, newStoreId);
//
//         if (bearerKey.isNotEmpty) {
//           _initializeSocket();
//         }
//       } else {
//         showSnackbar("error".tr, "invalid_user".tr);
//       }
//     } catch (e) {
//       Log.loga("OrderScreen", "getUserMe Api:: e >>>>> $e");
//
//       if (e.toString().contains('SocketException') ||
//           e.toString().contains('Failed host lookup')) {
//         setState(() {
//           hasInternet = false;
//         });
//
//         Future.delayed(const Duration(milliseconds: 500), () {
//           _showLogoutDialog();
//         });
//       } else {
//         showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
//       }
//     }
//   }
//
//   Future<void> getOrdersWithoutLoader(String? bearerKey, String? id) async {
//     try {
//       DateTime formatted = DateTime.now();
//       String date = DateFormat('yyyy-MM-dd').format(formatted);
//
//       final Map<String, dynamic> data = {
//         "store_id": id,
//         "target_date": date,
//         "limit": 0,
//         "offset": 0,
//       };
//
//       final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);
//
//       if (!mounted) return; // ✅ Check before setState
//
//       setState(() {
//         hasInternet = true;
//       });
//
//       if (_isDialogShowing) {
//         try {
//           Navigator.of(context).pop();
//           _isDialogShowing = false;
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (result.isNotEmpty) {
//         final firstItem = result.first;
//         if (firstItem.code != null) {
//           if (firstItem.code == 500 || firstItem.code! >= 500) {
//             if (mounted) {
//               setState(() {
//                 hasInternet = false;
//               });
//             }
//             Future.delayed(const Duration(milliseconds: 500), () {
//               if (mounted) _showLogoutDialog();
//             });
//           }
//           _startNoOrderTimer();
//           return;
//         }
//
//         if (mounted) {
//           setState(() {
//             app.appController.setOrders(result);
//           });
//         }
//         _stopNoOrderTimer();
//       } else {
//         if (mounted) {
//           setState(() {
//             app.appController.setOrders([]);
//           });
//         }
//         _startNoOrderTimer();
//       }
//     } catch (e) {
//       if (e.toString().contains('SocketException') ||
//           e.toString().contains('Failed host lookup')) {
//         if (mounted) {
//           setState(() {
//             hasInternet = false;
//           });
//         }
//
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) _showLogoutDialog();
//         });
//       } else {
//         if (mounted) {
//           showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
//         }
//       }
//     }
//   }
//
//   Future<void> _preloadStoreData() async {
//     if (bearerKey != null) {
//       try {
//         String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//         if (storeID != null) {
//           final result = await ApiRepo().getStoreData(bearerKey!, storeID);
//           await sharedPreferences.setString('cached_store_name', result.name.toString());
//         }
//       } catch (e) {
//         // Handle error
//       }
//     }
//   }
//
//   void _initializeSocket() {
//     _socketService.disconnect();
//
//     setState(() {
//       _isLiveDataActive = false;
//       _lastUpdateTime = null;
//       _hasSocketData = false;
//     });
//
//     String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//
//     int dynamicStoreId;
//
//     if (storeID != null && storeID.isNotEmpty) {
//       int? parsedId = int.tryParse(storeID);
//
//       if (parsedId != null) {
//         dynamicStoreId = parsedId;
//       } else {
//         return;
//       }
//     } else {
//       if (userMe.store_id != null) {
//         dynamicStoreId = userMe.store_id!;
//         sharedPreferences.setString(valueShared_STORE_KEY, dynamicStoreId.toString());
//       } else {
//         return;
//       }
//     }
//
//     // ✅ Add mounted check to onSalesUpdate
//     _socketService.onSalesUpdate = (data) {
//       if (!mounted) return; // ✅ Critical: Check if widget is still mounted
//
//       if (data['store_id'] != null &&
//           data['store_id'].toString() != dynamicStoreId.toString()) {
//         return;
//       }
//
//       _handleSalesUpdate(data, isFromSocket: true);
//     };
//
//     // ✅ Add mounted check to onConnected
//     _socketService.onConnected = () {
//       if (!mounted) return; // ✅ Critical: Check if widget is still mounted
//       setState(() => _isLiveDataActive = true);
//     };
//
//     // ✅ Add mounted check to onDisconnected
//     _socketService.onDisconnected = () {
//       if (!mounted) return; // ✅ Critical: Check if widget is still mounted
//       setState(() {
//         _isLiveDataActive = false;
//         _hasSocketData = false;
//       });
//     };
//
//     // ✅ Add mounted check to onNewOrder
//     _socketService.onNewOrder = (data) {
//       if (!mounted) return; // ✅ Critical: Check if widget is still mounted
//
//       if (data['store_id'] != null &&
//           data['store_id'].toString() != dynamicStoreId.toString()) {
//         return;
//       }
//
//       _refreshCurrentDayData();
//       getLiveSaleReportWithoutLoader();
//     };
//
//     try {
//       _socketService.connect(bearerKey!, storeId: dynamicStoreId);
//     } catch (e) {
//       // Handle error
//     }
//   }
//
//   Future<void> getLiveSaleReport() async {
//     Timer? timeoutTimer;
//     bool loaderShown = false;
//
//     try {
//       if (bearerKey == null || bearerKey!.isEmpty) {
//         _setEmptyValues();
//         return;
//       }
//
//       if (Get.isDialogOpen ?? false) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       Get.dialog(
//         Center(
//           child: Lottie.asset(
//             'assets/animations/burger.json',
//             width: 150,
//             height: 150,
//             repeat: true,
//           ),
//         ),
//         barrierDismissible: false,
//       );
//       loaderShown = true;
//
//       timeoutTimer = Timer(const Duration(seconds: 8), () {
//         if (loaderShown && (Get.isDialogOpen ?? false)) {
//           try {
//             Get.back();
//             loaderShown = false;
//           } catch (e) {
//             // Handle error
//           }
//         }
//         _setEmptyValues();
//       });
//
//       GetTodayReport model = await CallService().getLiveSaleData().timeout(
//         const Duration(seconds: 6),
//         onTimeout: () {
//           throw TimeoutException('api_time'.tr, const Duration(seconds: 6));
//         },
//       );
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         Get.back();
//         loaderShown = false;
//       }
//
//       if (model.code != null && model.code != 200) {
//         _setEmptyValues();
//         return;
//       }
//
//       setState(() {
//         delivery = '${model.orderTypes?.delivery ?? 0}';
//         pickUp = '${model.orderTypes?.pickup ?? 0}';
//         pending = '${model.approvalStatuses?.pending ?? 0}';
//         accepted = '${model.approvalStatuses?.accepted ?? 0}';
//         declined = '${model.approvalStatuses?.declined ?? 0}';
//
//         _liveApiData = {
//           'accepted': model.approvalStatuses?.accepted ?? 0,
//           'declined': model.approvalStatuses?.declined ?? 0,
//           'pending': model.approvalStatuses?.pending ?? 0,
//           'pickup': model.orderTypes?.pickup ?? 0,
//           'delivery': model.orderTypes?.delivery ?? 0,
//           'totalOrders': model.totalOrders ?? 0,
//         };
//
//         _isLiveDataActive = true;
//         _lastUpdateTime = DateTime.now();
//       });
//     } on TimeoutException catch (e) {
//       _setEmptyValues();
//     } catch (e) {
//       _setEmptyValues();
//
//       if (!e.toString().contains('204') && !e.toString().contains('timeout')) {
//         showSnackbar("info".tr, "unable".tr);
//       }
//     } finally {
//       timeoutTimer?.cancel();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//     }
//   }
//
//   void _setEmptyValues() {
//     setState(() {
//       _isLiveDataActive = false;
//       delivery = '0';
//       pickUp = '0';
//       pending = '0';
//       accepted = '0';
//       declined = '0';
//     });
//   }
//
//   void _startNoOrderTimer() {
//     _noOrderTimer?.cancel();
//     _noOrderTimer = Timer(const Duration(seconds: 4), () {
//       if (mounted && app.appController.searchResultOrder.isEmpty) {
//         setState(() => _showNoOrderText = true);
//       }
//     });
//   }
//
//   void _stopNoOrderTimer() {
//     _noOrderTimer?.cancel();
//     setState(() => _showNoOrderText = false);
//   }
//
//   void _handleSalesUpdate(Map<String, dynamic> salesData, {bool isFromSocket = false}) {
//     if (!mounted) return;
//
//     if (isFromSocket) {
//       SalesCacheHelper.saveSalesData(salesData);
//       _hasSocketData = true;
//     }
//
//     if (mounted) {
//       setState(() => _lastUpdateTime = DateTime.now());
//     }
//
//     if (_currentDateReport != null) {
//       _currentDateReport!.totalOrders = salesData['total_orders'] as int?;
//
//       if (_currentDateReport!.data == null) {
//         _currentDateReport!.data = SalesData(
//           topItems: [],
//           cashTotal: 0.0,
//           byCategory: {},
//           orderTypes: {},
//           totalSales: 0.0,
//           onlineTotal: 0.0,
//           totalOrders: 0,
//           paymentMethods: {},
//           approvalStatuses: {},
//         );
//       }
//
//       _currentDateReport!.data = SalesData(
//         netTotal: (salesData['net_total'] as num?)?.toDouble(),
//         topItems: (salesData['top_items'] != null)
//             ? (salesData['top_items'] as List)
//             .map((item) => TopItem.fromJson(item))
//             .toList()
//             : _currentDateReport!.data?.topItems ?? [],
//         totalTax: (salesData['total_tax'] as num?)?.toDouble(),
//         cashTotal: (salesData['cash_total'] as num?)?.toDouble() ?? 0.0,
//         byCategory: salesData['by_category'] != null
//             ? Map<String, int>.from(salesData['by_category'])
//             : (_currentDateReport!.data?.byCategory ?? {}),
//         orderTypes: salesData['order_types'] != null
//             ? Map<String, int>.from(salesData['order_types'])
//             : {},
//         totalSales: (salesData['total_sales'] as num?)?.toDouble() ?? 0.0,
//         onlineTotal: (salesData['online_total'] as num?)?.toDouble() ?? 0.0,
//         totalOrders: (salesData['total_orders'] as num?)?.toInt() ?? 0,
//         taxBreakdown: salesData['tax_breakdown'] != null
//             ? TaxBreakdown.fromJson(salesData['tax_breakdown'])
//             : null,
//         deliveryTotal: (salesData['delivery_total'] as num?)?.toDouble(),
//         discountTotal: salesData['discount_total'] != null
//             ? (salesData['discount_total'] as num).toInt()
//             : null,
//         paymentMethods: salesData['payment_methods'] != null
//             ? Map<String, int>.from(salesData['payment_methods'])
//             : {},
//         approvalStatuses: salesData['approval_statuses'] != null
//             ? Map<String, int>.from(salesData['approval_statuses'])
//             : {},
//         totalSalesDelivery: (salesData['total_sales + delivery'] as num?)?.toDouble(),
//       );
//
//       if (mounted) {
//         setState(() => reportsss = _currentDateReport!);
//       }
//     }
//   }
//
//   Future<void> _loadCachedSalesData() async {
//     final cachedData = await SalesCacheHelper.loadSalesData();
//     if (cachedData != null) {
//       _handleSalesUpdate(cachedData);
//     }
//   }
//
//   void _refreshCurrentDayData() => getCurrentDateReport();
//
//   void getCurrentDateReport() {
//     final today = DateTime.now();
//     final todayString = DateFormat('yyyy-MM-dd').format(today);
//
//     DailySalesReport? foundReport;
//     for (var report in reportList) {
//       if (report.startDate != null) {
//         final reportDate = DateTime.tryParse(report.startDate!);
//         if (reportDate != null &&
//             DateFormat('yyyy-MM-dd').format(reportDate) == todayString) {
//           foundReport = report;
//           break;
//         }
//       }
//     }
//
//     if (foundReport != null) {
//       setState(() {
//         _currentDateReport = foundReport;
//         reportsss = foundReport!;
//       });
//     } else {
//       final defaultReport = DailySalesReport(
//         startDate: todayString,
//         totalSales: 0.0,
//         totalOrders: 0,
//         cashTotal: 0.0,
//         onlineTotal: 0.0,
//         totalTax: 0.0,
//         data: null,
//       );
//       setState(() {
//         _currentDateReport = defaultReport;
//         reportsss = defaultReport;
//         reportList.insert(0, defaultReport);
//       });
//     }
//   }
//
//   Future<void> _manualRefresh() async {
//     if (_isRefreshing) return;
//
//     if (_lastRefreshTime != null) {
//       final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
//       if (timeSinceLastRefresh.inSeconds < 1) return;
//     }
//
//     final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//     await getOrders(bearerKey, true, false, storeID);
//   }
//
//   Future<void> _handleRefresh() async {
//     if (_isRefreshing) return;
//
//     _isRefreshing = true;
//     _lastRefreshTime = DateTime.now();
//
//     try {
//       final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//       await getOrdersWithoutLoader(bearerKey, storeID);
//       await getLiveSaleReportWithoutLoader();
//     } finally {
//       _isRefreshing = false;
//     }
//   }
//
//   Future<void> getOrders(
//       String? bearerKey, bool orderType, bool isBellRunning, String? id) async
//   {
//     bool loaderShown = false;
//     Timer? timeoutTimer;
//
//     try {
//       DateTime formatted = DateTime.now();
//       String date = DateFormat('yyyy-MM-dd').format(formatted);
//
//       if (orderType) {
//         if (Get.isDialogOpen ?? false) {
//           try {
//             Get.back();
//           } catch (e) {
//             // Handle error
//           }
//         }
//
//         Get.dialog(
//           Center(
//             child: Lottie.asset(
//               'assets/animations/burger.json',
//               width: 150,
//               height: 150,
//               repeat: true,
//             ),
//           ),
//           barrierDismissible: false,
//         );
//         loaderShown = true;
//
//         timeoutTimer = Timer(const Duration(seconds: 8), () {
//           if (loaderShown && (Get.isDialogOpen ?? false)) {
//             try {
//               Get.back();
//               loaderShown = false;
//             } catch (e) {
//               // Handle error
//             }
//           }
//         });
//       }
//
//       final Map<String, dynamic> data = {
//         "store_id": id,
//         "target_date": date,
//         "limit": 0,
//         "offset": 0,
//       };
//
//       final result = await ApiRepo().orderGetApiFilter(bearerKey!, data).timeout(
//         const Duration(seconds: 6),
//         onTimeout: () {
//           throw TimeoutException('api_timeout'.tr, const Duration(seconds: 6));
//         },
//       );
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         Get.back();
//         loaderShown = false;
//       }
//
//       if (result.isNotEmpty && result.first.code == null) {
//         setState(() {
//           app.appController.setOrders(result);
//         });
//
//         if (result.isNotEmpty) {
//           _stopNoOrderTimer();
//         }
//       } else {
//         _startNoOrderTimer();
//       }
//     } on TimeoutException catch (e) {
//       // Handle timeout
//     } catch (e) {
//       Log.loga("OrderScreen", "getOrders Api:: e >>>>> $e");
//       showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
//     } finally {
//       timeoutTimer?.cancel();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//     }
//   }
//
//   String formatAmount(double amount) {
//     final locale = Get.locale?.languageCode ?? 'en';
//     String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
//     return NumberFormat('#,##0.0#', localeToUse).format(amount);
//   }
//
//   int _getApprovalStatusCount(String status) {
//     if (_hasSocketData && _currentDateReport?.data?.approvalStatuses != null) {
//       final approvalStatuses = _currentDateReport!.data!.approvalStatuses;
//
//       switch (status.toLowerCase()) {
//         case "accepted":
//           return approvalStatuses["accepted"] ??
//               approvalStatuses["approve"] ??
//               approvalStatuses["2"] ??
//               0;
//         case "declined":
//           return approvalStatuses["declined"] ??
//               approvalStatuses["decline"] ??
//               approvalStatuses["rejected"] ??
//               approvalStatuses["3"] ??
//               0;
//         case "pending":
//           return approvalStatuses["pending"] ?? approvalStatuses["1"] ?? 0;
//         default:
//           return 0;
//       }
//     }
//     return _liveApiData[status] ?? 0;
//   }
//
//   int _getOrderTypeCount(String type) {
//     if (_hasSocketData && _currentDateReport?.data?.orderTypes != null) {
//       final orderTypes = _currentDateReport!.data!.orderTypes;
//
//       switch (type.toLowerCase()) {
//         case "pickup":
//           return orderTypes["pickup"] ??
//               orderTypes["pick_up"] ??
//               orderTypes["takeaway"] ??
//               0;
//         case "delivery":
//           return orderTypes["delivery"] ?? orderTypes["home_delivery"] ?? 0;
//         case "dine_in":
//           return orderTypes["dine_in"] ?? orderTypes["dinein"] ?? 0;
//         default:
//           return 0;
//       }
//     }
//
//     return _liveApiData[type] ?? 0;
//   }
//
//   int _getTotalOrders() {
//     if (_hasSocketData && _currentDateReport?.totalOrders != null) {
//       return _currentDateReport!.totalOrders!;
//     }
//
//     return _liveApiData['totalOrders'] ?? 0;
//   }
//
//   String _extractTime(String deliveryTime) {
//     try {
//       DateTime dateTime = DateTime.parse(deliveryTime);
//       return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return deliveryTime;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: Builder(builder: (context) {
//         if (isLoading && _isInitialLoading) {
//           return Center(
//             child: Lottie.asset(
//               'assets/animations/burger.json',
//               width: 150,
//               height: 150,
//               repeat: true,
//             ),
//           );
//         }
//
//         if (!hasInternet) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
//                 const SizedBox(height: 16),
//                 const Text("No Internet Connection",
//                     style: TextStyle(fontSize: 18, color: Colors.grey)),
//                 const SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: () => _showLogoutDialog(),
//                   child: const Text("Show Logout Dialog"),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         return Padding(
//           padding: const EdgeInsets.all(6),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('order'.tr,
//                                 style: const TextStyle(
//                                     fontSize: 18, fontWeight: FontWeight.bold)),
//                             Text(
//                               dateSeleted.isEmpty
//                                   ? DateFormat('d MMMM, y')
//                                   .format(DateTime.now())
//                                   : dateSeleted,
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           Text(
//                             '${'total_order'.tr}: ${_getTotalOrders()}',
//                             style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w800,
//                                 fontFamily: "Mulish",
//                                 color: Colors.black),
//                           ),
//                           IconButton(
//                             iconSize: 30,
//                             icon: const Icon(Icons.refresh),
//                             onPressed: _manualRefresh,
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.sync),
//                             onPressed: () async {
//                               await syncLocalPosOrder();
//                             },
//                           )
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         _buildStatusContainer(
//                           '${'accepted'.tr} ${_getApprovalStatusCount("accepted")}',
//                           Colors.green.withOpacity(0.1),
//                         ),
//                         const SizedBox(width: 8),
//                         _buildStatusContainer(
//                           '${"decline".tr} ${_getApprovalStatusCount("declined")}',
//                           Colors.red.withOpacity(0.1),
//                         ),
//                         const SizedBox(width: 8),
//                         _buildStatusContainer(
//                           '${"pickup".tr} ${_getOrderTypeCount("pickup")}',
//                           Colors.blue.withOpacity(0.1),
//                         ),
//                         const SizedBox(width: 8),
//                         _buildStatusContainer(
//                           '${"delivery".tr} ${_getOrderTypeCount("delivery")}',
//                           Colors.purple.withOpacity(0.1),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 15),
//               Expanded(
//                   child: MediaQuery.removePadding(
//                     context: context,
//                     removeTop: false,
//                     removeBottom: true,
//                     child: RefreshIndicator(
//                       onRefresh: _handleRefresh,
//                       color: Colors.green,
//                       backgroundColor: Colors.white,
//                       displacement: 60,
//                       child: _isInitialLoading
//                           ? Container()
//                           : !hasInternet
//                           ? ListView(
//                         padding: EdgeInsets.zero,
//                         physics:
//                         const AlwaysScrollableScrollPhysics(),
//                         children: [
//                           const SizedBox(height: 100),
//                           Column(
//                             mainAxisAlignment:
//                             MainAxisAlignment.center,
//                             children: [
//                               const Icon(Icons.wifi_off,
//                                   size: 80, color: Colors.grey),
//                               const SizedBox(height: 16),
//                               Text("no_internet".tr,
//                                 style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.grey,
//                                     fontWeight: FontWeight.w600),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 "please".tr,
//                                 style: const TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ],
//                       )
//                           : Obx(() {
//                         List<Order> allOrders = [
//                           ..._localOrders,
//                           ...app.appController.searchResultOrder,
//                         ];
//                         // if (app.appController.searchResultOrder.isEmpty) {
//                         //   return ListView(
//                         //     padding: EdgeInsets.zero,
//                         //     physics: const AlwaysScrollableScrollPhysics(),
//                         //     children: [
//                         //       const SizedBox(height: 100),
//                         //       Column(mainAxisAlignment: MainAxisAlignment.center,
//                         //         children: [
//                         //           Lottie.asset('assets/animations/empty.json',
//                         //             width: 150,
//                         //             height: 150,
//                         //           ),
//                         //           Text(
//                         //             'no_order'.tr,
//                         //             style: const TextStyle(
//                         //               fontSize: 16,
//                         //               fontWeight: FontWeight.w500,
//                         //               color: Colors.grey,
//                         //             ),
//                         //           ),
//                         //         ],
//                         //       ),
//                         //     ],
//                         //   );
//                         // }
//                         if (allOrders.isEmpty) {
//                           return ListView(
//                             padding: EdgeInsets.zero,
//                             physics: const AlwaysScrollableScrollPhysics(),
//                             children: [
//                               const SizedBox(height: 100),
//                               Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Lottie.asset('assets/animations/empty.json',
//                                     width: 150,
//                                     height: 150,
//                                   ),
//                                   Text(
//                                     'no_order'.tr,
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           );
//                         }
//                         return ListView.builder(
//                           physics: const AlwaysScrollableScrollPhysics(),
//                           padding: EdgeInsets.zero,
//                           itemCount: allOrders.length,
//                           itemBuilder: (context, index) {
//                             final order = allOrders[index];
//                             final isLocalOrder = _localOrders.contains(order);
//                           // itemCount: app.appController.searchResultOrder.length,
//                           // itemBuilder: (context, index) {
//                           //   final order = app.appController.searchResultOrder[index];
//                             DateTime dateTime = DateTime.parse(order.createdAt.toString());
//                             String time = DateFormat('hh:mm a').format(dateTime);
//                             String guestAddress = order.guestShippingJson?.zip?.toString() ?? '';
//                             String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
//                             String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';
//
//                             return AnimatedBuilder(
//                               animation: _opacityAnimation,
//                               builder: (context, child) {
//                                 final bool isPending = (order.approvalStatus ?? 0) == 1;
//                                 Color getContainerColor() {
//                                   switch (order.approvalStatus) {
//                                     case 2:
//                                       return const Color(0xffEBFFF4);
//                                     case 3:
//                                       return const Color(0xffFFEFEF);
//                                     case 1:
//                                       return Colors.white;
//                                     default:
//                                       return Colors.white;
//                                   }
//                                 }
//
//                                 return Opacity(
//                                   opacity: isPending ? _opacityAnimation.value : 1.0,
//                                   child: Container(
//                                     margin: const EdgeInsets.only(bottom: 12),
//                                     decoration: BoxDecoration(
//                                       color: getContainerColor(),
//                                       borderRadius: BorderRadius.circular(7),
//                                       border: Border.all(
//                                         color: (order.approvalStatus == 2)
//                                             ? const Color(0xffC3F2D9) : (order.approvalStatus == 3)
//                                             ? const Color(0xffFFD0D0) : Colors.grey.withOpacity(0.2),
//                                         width: 1,
//                                       ),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.black.withOpacity(0.1),
//                                           spreadRadius: 0,
//                                           blurRadius: 4,
//                                           offset:
//                                           const Offset(0, 2),
//                                         ),
//                                       ],
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8),
//                                       child: GestureDetector(
//                                         behavior: HitTestBehavior.opaque,
//                                         onLongPress: () {
//                                           if (order.approvalStatus == 2) {
//                                             _showDeliveryTimeDialog(order);
//                                           }
//                                         },
//                                         onTap: () => Get.to(() => OrderDetailEnglish(order)),
//                                         child: Column(crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Row(crossAxisAlignment: CrossAxisAlignment.start,
//                                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                               children: [
//                                                 Row(
//                                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                                   children: [
//                                                     CircleAvatar(
//                                                       radius: 17,
//                                                       backgroundColor: Colors.green,
//                                                       child:
//                                                       SvgPicture.asset(
//                                                         order.orderType == 1
//                                                             ? 'assets/images/ic_delivery.svg'
//                                                             : order.orderType == 2
//                                                             ? 'assets/images/ic_pickup.svg'
//                                                             : order.orderType == 3
//                                                             ? 'assets/images/table.svg'
//                                                             : 'assets/images/ic_pickup.svg',
//                                                         height: 14,
//                                                         width: 14,
//                                                         color: Colors.white,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 6),
//                                                     Column(crossAxisAlignment: CrossAxisAlignment.start,
//                                                       children: [
//                                                         SizedBox(width: MediaQuery.of(context).size.width * 0.6,
//                                                           child:
//                                                           Row(crossAxisAlignment: CrossAxisAlignment.start,
//                                                             children: [
//                                                               Container(
//                                                                 width: MediaQuery.of(context).size.width * (_storeType == '2' ? 0.35 :
//                                                                 (order.orderType == 2 ? 0.18 : 0.18)),
//                                                                 child: Text(order.orderType == 2 ? 'pickup'.tr : (_storeType == '2'
//                                                                     ? _getFullAddress(
//                                                                     order.shipping_address ?? order.guestShippingJson,
//                                                                     order.shipping_address == null)
//                                                                     : (order.shipping_address?.zip?.toString() ?? guestAddress)),
//                                                                   style: const TextStyle(
//                                                                       fontWeight: FontWeight.w700,
//                                                                       fontSize: 13,
//                                                                       fontFamily: "Mulish-Regular"),
//                                                                 ),
//                                                               ),
//                                                               if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
//                                                                 SizedBox(width: MediaQuery.of(context).size.width * 0.25,
//                                                                   child: Text(
//                                                                     '${'time'.tr}: ${_extractTime(order.deliveryTime!)}',
//                                                                     style: const TextStyle(fontWeight: FontWeight.w700,
//                                                                         fontSize: 13, fontFamily: "Mulish-Regular"),
//                                                                   ),
//                                                                 ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                         Visibility(
//                                                           visible: (_storeType != '2') && (order.shipping_address != null || order.guestShippingJson != null),
//                                                           child: SizedBox(width: MediaQuery.of(context).size.width * 0.5,
//                                                             child: Text(
//                                                               order.orderType == 1 ? (order.shipping_address != null
//                                                                   ? '${order.shipping_address!.line1!}, ${order.shipping_address!.city!}'
//                                                                   : '${order.guestShippingJson?.line1 ?? ''}, ${order.guestShippingJson?.city ?? ''}')
//                                                                   : '',
//                                                               style: const TextStyle(
//                                                                   fontWeight: FontWeight.w500,
//                                                                   fontSize: 11,
//                                                                   letterSpacing: 0,
//                                                                   height: 0,
//                                                                   fontFamily: "Mulish"),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     )
//                                                   ],
//                                                 ),
//                                                 Row(
//                                                   children: [
//                                                     const Icon(Icons.access_time, size: 20,),
//                                                     Text(time, style: const TextStyle(
//                                                         fontWeight:
//                                                         FontWeight.w500,
//                                                         fontFamily: "Mulish",
//                                                         fontSize: 10,
//                                                       ),
//                                                     )
//                                                   ],
//                                                 )
//                                               ],
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Row(
//                                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                               children: [
//                                                 // ✅ Wrap this SizedBox with Flexible
//                                                 Flexible(
//                                                   child: SizedBox(
//                                                     width: MediaQuery.of(context).size.width * 0.5,
//                                                     child: Text(
//                                                       '${order.shipping_address?.customer_name ?? guestName ?? ""} / ${order.shipping_address?.phone ?? guestPhone}',
//                                                       style: const TextStyle(
//                                                           fontWeight: FontWeight.w700,
//                                                           fontFamily: "Mulish",
//                                                           fontSize: 13),
//                                                       overflow: TextOverflow.ellipsis, // ✅ Add this
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 Row(
//                                                   children: [
//                                                     Text(
//                                                       '${order.orderNumber != null ? 'order_number'.tr : 'Order ID'} : ',
//                                                       style: const TextStyle(
//                                                           fontWeight: FontWeight.w700,
//                                                           fontSize: 11,
//                                                           fontFamily: "Mulish"),
//                                                     ),
//                                                     Text(
//                                                       '${order.orderNumber ?? order.id ?? 'N/A'}',
//                                                       style: const TextStyle(
//                                                           fontWeight: FontWeight.w500,
//                                                           fontSize: 11,
//                                                           fontFamily: "Mulish"),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Row(
//                                               mainAxisAlignment:
//                                               MainAxisAlignment
//                                                   .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   order.payment != null
//                                                       ? '${'currency'.tr} ${formatAmount(order.payment!.amount ?? 0)}'
//                                                       : '${'currency'.tr} ${formatAmount(0)}',
//                                                   style: const TextStyle(
//                                                       fontWeight:
//                                                       FontWeight.w800,
//                                                       fontFamily:
//                                                       "Mulish",
//                                                       fontSize: 16),
//                                                 ),
//                                                 // Row(
//                                                 //   children: [
//                                                 //     Text(
//                                                 //       getApprovalStatusText(order.approvalStatus),
//                                                 //       style: const TextStyle(
//                                                 //           fontWeight:
//                                                 //           FontWeight
//                                                 //               .w800,
//                                                 //           fontFamily:
//                                                 //           "Mulish-Regular",
//                                                 //           fontSize: 13),
//                                                 //     ),
//                                                 //     const SizedBox(
//                                                 //         width: 6),
//                                                 //     CircleAvatar(
//                                                 //       radius: 14,
//                                                 //       backgroundColor:
//                                                 //       getStatusColor(order.approvalStatus ?? 0),
//                                                 //       child: Icon(
//                                                 //         getStatusIcon(order.approvalStatus ?? 0),
//                                                 //         color: Colors.white,
//                                                 //         size: 16,
//                                                 //       ),
//                                                 //     ),
//                                                 //   ],
//                                                 // ),
//                                                 // In your itemBuilder, update the status icon section:
//                                                 Row(
//                                                   children: [
//                                                     Text(
//                                                       isLocalOrder ? "syncing".tr : getApprovalStatusText(order.approvalStatus),
//                                                       style: const TextStyle(
//                                                           fontWeight: FontWeight.w400,
//                                                           fontFamily: "Mulish-Regular",
//                                                           fontSize: 13
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 6),
//                                                     isLocalOrder
//                                                         ? RotationTransition(
//                                                       turns: _syncRotationAnimation,
//                                                       child: SvgPicture.asset('assets/images/sync.svg'),
//                                                     )
//                                                         : CircleAvatar(
//                                                       radius: 14,
//                                                       backgroundColor: getStatusColor(order.approvalStatus ?? 0),
//                                                       child: Icon(
//                                                         getStatusIcon(order.approvalStatus ?? 0),
//                                                         color: Colors.white,
//                                                         size: 16,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         );
//                       }),
//                     ),
//                   )
//               )
//             ],
//           ),
//         );
//       }),
//     );
//   }
//   Future<void> getOrdersWithoutLoaderSilent(String? bearerKey, String? id) async {
//     try {
//       DateTime formatted = DateTime.now();
//       String date = DateFormat('yyyy-MM-dd').format(formatted);
//
//       final Map<String, dynamic> data = {
//         "store_id": id,
//         "target_date": date,
//         "limit": 0,
//         "offset": 0,
//       };
//
//       final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);
//
//       if (!mounted) return;
//
//       if (result.isNotEmpty) {
//         final firstItem = result.first;
//         if (firstItem.code != null) {
//           return;
//         }
//
//         if (mounted) {
//           setState(() {
//             app.appController.setOrders(result);
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             app.appController.setOrders([]);
//           });
//         }
//       }
//     } catch (e) {
//       print('❌ Silent API error: $e');
//       // ✅ Don't show any errors during background sync
//     }
//   }
//   String _getFullAddress(dynamic shippingAddress, bool isGuest) {
//     if (shippingAddress == null) return '';
//
//     List<String> parts = [];
//
//     if (isGuest) {
//       if (shippingAddress.line1 != null && shippingAddress.line1.toString().isNotEmpty) {
//         parts.add(shippingAddress.line1.toString());
//       }
//       if (shippingAddress.city != null && shippingAddress.city.toString().isNotEmpty) {
//         parts.add(shippingAddress.city.toString());
//       }
//       if (shippingAddress.zip != null &&
//           shippingAddress.zip.toString().isNotEmpty &&
//           shippingAddress.zip.toString() != '00000') {
//         parts.add(shippingAddress.zip.toString());
//       }
//       if (shippingAddress.country != null && shippingAddress.country.toString().isNotEmpty) {
//         parts.add(shippingAddress.country.toString());
//       }
//     } else {
//       if (shippingAddress.line1 != null && shippingAddress.line1!.isNotEmpty) {
//         parts.add(shippingAddress.line1!);
//       }
//       if (shippingAddress.city != null && shippingAddress.city!.isNotEmpty) {
//         parts.add(shippingAddress.city!);
//       }
//       if (shippingAddress.zip != null &&
//           shippingAddress.zip!.isNotEmpty &&
//           shippingAddress.zip != '00000') {
//         parts.add(shippingAddress.zip!);
//       }
//       if (shippingAddress.country != null && shippingAddress.country!.isNotEmpty) {
//         parts.add(shippingAddress.country!);
//       }
//     }
//
//     return parts.join(', ');
//   }
//
//   Widget _buildStatusContainer(String text, Color backgroundColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: Colors.grey.withOpacity(0.2)),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//             fontFamily: "Mulish",
//             fontWeight: FontWeight.w700,
//             fontSize: 11,
//             color: Colors.black87),
//       ),
//     );
//   }
//
//   String getApprovalStatusText(int? status) {
//     switch (status) {
//       case 1:
//         return "pending".tr;
//       case 2:
//         return "accepted".tr;
//       case 3:
//         return "decline".tr;
//       default:
//         return "Unknown";
//     }
//   }
//
//   void _showDeliveryTimeDialog(Order order) {
//     if (order.approvalStatus != 2) return; // Only for accepted orders
//
//     DateTime currentDeliveryTime;
//     try {
//       currentDeliveryTime = order.deliveryTime != null && order.deliveryTime!.isNotEmpty
//           ? DateTime.parse(order.deliveryTime!)
//           : DateTime.now().add(const Duration(minutes: 30));
//     } catch (e) {
//       currentDeliveryTime = DateTime.now().add(const Duration(minutes: 30));
//     }
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         DateTime updatedTime = currentDeliveryTime;
//
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: Text('update_delivery_time'.tr),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     DateFormat('HH:mm').format(updatedTime),
//                     style: const TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       IconButton(
//                         onPressed: () {
//                           setDialogState(() {
//                             updatedTime = updatedTime.subtract(const Duration(minutes: 15));
//                           });
//                         },
//                         icon: const Icon(Icons.remove_circle, size: 40, color: Colors.red),
//                       ),
//                       IconButton(
//                         onPressed: () {
//                           setDialogState(() {
//                             updatedTime = updatedTime.add(const Duration(minutes: 15));
//                           });
//                         },
//                         icon: const Icon(Icons.add_circle, size: 40, color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text('cancel'.tr),
//                 ),
//                 GestureDetector(
//                   onTap: () async {
//                     Navigator.pop(context);
//                     print('order id is ${order.id}');
//                     await _updateDeliveryTime(
//                         order, updatedTime);
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                      borderRadius: BorderRadius.circular(12),
//                       color: Color(0xff14b65f)
//                     ),
//                     child: Text('saved'.tr, style: const TextStyle(color: Colors.white)),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _updateDeliveryTime(Order order, DateTime newTime) async {
//     if (!mounted) return;
//
//     bool loaderShown = false;
//     Timer? timeoutTimer;
//
//     try {
//       if (Get.isDialogOpen ?? false) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       Get.dialog(
//         Center(
//           child: Lottie.asset(
//             'assets/animations/burger.json',
//             width: 150,
//             height: 150,
//             repeat: true,
//           ),
//         ),
//         barrierDismissible: false,
//       );
//       loaderShown = true;
//
//       timeoutTimer = Timer(const Duration(seconds: 8), () {
//         if (loaderShown && (Get.isDialogOpen ?? false)) {
//           try {
//             Get.back();
//             loaderShown = false;
//           } catch (e) {
//             // Handle error
//           }
//         }
//       });
//
//       Map<String, dynamic> jsonData = {
//         "order_status": 2,
//         "approval_status": 2,
//         "delivery_time": newTime.toIso8601String()
//         //"delivery_time": "2025-12-07T00:15:00.000"
//       };
//       print('map value is $jsonData');
//       final result = await ApiRepo().orderAcceptDecline(
//           bearerKey!,
//           jsonData,
//           order.id ?? 0
//       ).timeout(
//         const Duration(seconds: 6),
//         onTimeout: () {
//           throw TimeoutException('Request timeout', const Duration(seconds: 6));
//         },
//       );
//
//       timeoutTimer?.cancel();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         Get.back();
//         loaderShown = false;
//       }
//
//       if (!mounted) return;
//
//       if (result.code == null) {
//         app.appController.updateOrder(result);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('delivery_time_updated'.tr),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result.mess ?? 'failed'.tr),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } on TimeoutException catch (e) {
//       timeoutTimer?.cancel();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Request timed out. Please try again.'),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       timeoutTimer?.cancel();
//
//       if (loaderShown && (Get.isDialogOpen ?? false)) {
//         try {
//           Get.back();
//         } catch (e) {
//           // Handle error
//         }
//       }
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     }
//   }
//   @override
//   bool get wantKeepAlive => true;
//
//   Future<void> getNewOrder(int orderID) async {
//     try {
//       final result = await ApiRepo().getNewOrderData(bearerKey!, orderID);
//       app.appController.addNewOrder(result);
//
//       await getLiveSaleReportWithoutLoader();
//     } catch (e) {
//       Log.loga("OrderScreen", "getNewOrder Api:: e >>>>> $e");
//       showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
//     }
//   }
//
//   Future<bool> syncLocalPosOrder() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var StoreId = prefs.getString(valueShared_STORE_KEY);
//
//     try {
//       final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(StoreId!);
//
//       if (unsyncedOrders.isEmpty) {
//         if (!mounted) return false;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('No orders to sync'.tr),
//                 backgroundColor: Colors.orange,
//                 duration: const Duration(seconds: 2),
//               ),
//             );
//           }
//         });
//         return false;
//       }
//
//       print('📦 Found ${unsyncedOrders.length} unsynced orders');
//
//       // ✅ Store order IDs for later verification
//       List<int> localOrderIds = unsyncedOrders.map((o) => o['id'] as int).toList();
//       print('📋 Local Order IDs to sync: $localOrderIds');
//
//       List<Map<String, dynamic>> ordersToSync = [];
//       for (var dbOrder in unsyncedOrders) {
//         final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
//         if (orderDetails != null) {
//           ordersToSync.add(await _buildSyncOrderMap(orderDetails));
//         }
//       }
//
//       print('📤 Syncing ${ordersToSync.length} orders');
//
//       SyncLocalOrder model = await CallService().syncLocalOrder(ordersToSync);
//
//       print('📡 API Response - Status: ${model.status}');
//       print('📡 API Response - Synced IDs from server: ${model.syncedOrderIds}');
//
//       if (model.status == 'ok' && model.syncedOrderIds != null && model.syncedOrderIds!.isNotEmpty) {
//
//         // ✅ Mark ALL local orders as synced (not just the ones from server response)
//         for (int localOrderId in localOrderIds) {
//           print('🔄 Marking order $localOrderId as synced...');
//           await DatabaseHelper().markOrderAsSynced(localOrderId);
//         }
//
//         // ✅ Wait a moment for database to update
//         await Future.delayed(const Duration(milliseconds: 100));
//
//         // ✅ Verify orders are marked as synced
//         final stillUnsynced = await DatabaseHelper().getUnsyncedOrders(StoreId);
//         print('🔍 After marking - Still unsynced orders: ${stillUnsynced.length}');
//
//         // ✅ Clear local orders list immediately
//         setState(() {
//           _localOrders.clear();
//           _isSyncingLocalOrders = false;
//         });
//
//         // ✅ Reload from database
//         await _loadAndSyncLocalOrders();
//
//         // ✅ Refresh server orders
//         await getOrdersWithoutLoader(bearerKey, StoreId);
//
//         if (!mounted) return true;
//
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('${ordersToSync.length} Order(s) Synced Successfully'.tr),
//                 backgroundColor: Colors.green,
//                 duration: const Duration(seconds: 2),
//               ),
//             );
//           }
//         });
//
//         return true;
//       } else {
//         print('❌ Sync failed - Status: ${model.status}');
//
//         if (!mounted) return false;
//
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Sync failed. Please try again.'.tr),
//                 backgroundColor: Colors.red,
//                 duration: const Duration(seconds: 2),
//               ),
//             );
//           }
//         });
//
//         return false;
//       }
//
//     } catch (e) {
//       print('❌ Syncing error: $e');
//
//       if (!mounted) return false;
//
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('${'Failed to sync order'.tr}: ${e.toString()}'),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 2),
//             ),
//           );
//         }
//       });
//
//       return false;
//     }
//   }
//
//   Future<void> _autoSyncLocalOrders() async {
//     if (!mounted) return; // ✅ Check if widget is mounted
//
//     try {
//       final storeId = sharedPreferences.getString(valueShared_STORE_KEY);
//       if (storeId == null || storeId.isEmpty) return;
//
//       final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeId);
//       print('📊 Checking unsynced orders: ${unsyncedOrders.length} found');
//
//       if (unsyncedOrders.isEmpty) {
//         print('✅ No orders to auto-sync');
//         return;
//       }
//
//       List<Map<String, dynamic>> ordersToSync = [];
//
//       for (var dbOrder in unsyncedOrders) {
//         final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
//         if (orderDetails != null) {
//           ordersToSync.add(await _buildSyncOrderMap(orderDetails));
//         }
//       }
//
//       if (ordersToSync.isNotEmpty) {
//         print('📤 Auto-syncing ${ordersToSync.length} orders');
//
//         var result = await CallService().syncLocalOrder(ordersToSync);
//
//         if (result.status == 'ok' && result.syncedOrderIds != null && result.syncedOrderIds!.isNotEmpty) {
//           print('✅ Auto-sync success - Synced IDs: ${result.syncedOrderIds}');
//
//           for (var dbOrder in unsyncedOrders) {
//             await DatabaseHelper().markOrderAsSynced(dbOrder['id'] as int);
//           }
//
//           // ✅ Only call API, don't refresh UI
//           await getOrdersWithoutLoaderSilent(bearerKey, storeId);
//
//           // ✅ Update local orders list
//           if (mounted) {
//             final newUnsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeId);
//             setState(() {
//               if (newUnsyncedOrders.isEmpty) {
//                 _localOrders.clear();
//                 _isSyncingLocalOrders = false;
//               }
//             });
//           }
//
//           print('✅ Auto-sync completed: ${ordersToSync.length} orders synced');
//         } else {
//           print('❌ Auto-sync failed - Status: ${result.status}');
//         }
//       }
//     } catch (e) {
//       print('❌ Auto-sync error: $e');
//     }
//   }
//
//   Future<Map<String, dynamic>> _buildSyncOrderMap(Map<String, dynamic> orderDetails) async {
//     final orderData = orderDetails['order'] as Map<String, dynamic>;
//     final itemsData = orderDetails['items'] as List<dynamic>;
//     final paymentData = orderDetails['payment'] as Map<String, dynamic>?;
//     final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;
//
//     // ✅ Build items array
//     List<Map<String, dynamic>> items = [];
//     for (var item in itemsData) {
//       // ✅ Convert toppings - keep empty array if no toppings
//       List<Map<String, dynamic>> toppings = [];
//
//
//       if (item['toppings'] != null && item['toppings'] is List && (item['toppings'] as List).isNotEmpty) {
//         for (var t in item['toppings']) {
//           toppings.add({
//             'topping_id': t['id'] ?? 0,
//             'quantity': t['topping_quantity'] ?? 1,
//           });
//         }
//       }
//
//       items.add({
//         'product_id': item['product_id'],
//         'quantity': item['quantity'],
//         'unit_price': (item['unit_price'] as num?)?.toInt() ?? 0,
//         'note': item['note'] ?? '',
//         'variant_id': item['variant_id'] ?? 0,
//         'toppings': toppings,
//       });
//     }
//
//     final orderMap = {
//       'client_uuid': orderData['client_uuid'],
//       'store_id': int.tryParse(orderData['store_id'].toString()) ?? 0,
//       'order_type': orderData['order_type'] ?? 3,
//       'created_at': DateTime.fromMillisecondsSinceEpoch(orderData['created_at'] as int).toIso8601String(),
//       'note': orderData['note'] ?? '',
//       'items': items,
//       'payment': {
//         'payment_method': 'cash',
//         'status': 'paid',
//         'amount': (paymentData?['amount'] as num?)?.toInt() ?? 0,
//         'order_id': 0,
//       },
//       'customer': {
//         "customer_name": addressData?['customer_name'] ?? 'Walk-in Customer',
//         "phone": addressData?['phone'],
//         "email": orderData['email'],
//         "line1": addressData?['line1'],
//         "city": addressData?['city'],
//         "zip": addressData?['zip'],
//         "country": addressData?['country']
//       },
//     };
//
//     print('🔍 Built order map: ${jsonEncode(orderMap)}');
//     return orderMap;
//   }
//
// }
//
// class SalesCacheHelper {
//   static const _salesDataKey = 'cached_sales_data';
//   static const _lastDateKey = 'cached_sales_date';
//   static const _orderDateKey = 'cached_order_date';
//   static const _storeIdKey = 'cached_store_id';
//
//   static String _getUserSpecificKey(String baseKey, String? storeId) {
//     if (storeId != null && storeId.isNotEmpty) {
//       return "${baseKey}_store_$storeId";
//     }
//     return baseKey;
//   }
//
//   static Future<void> saveSalesData(Map<String, dynamic> salesData) async {
//     final prefs = await SharedPreferences.getInstance();
//     final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final currentStoreId = prefs.getString(valueShared_STORE_KEY);
//
//     final storeSpecificSalesKey =
//     _getUserSpecificKey(_salesDataKey, currentStoreId);
//     final storeSpecificDateKey =
//     _getUserSpecificKey(_lastDateKey, currentStoreId);
//
//     await prefs.setString(storeSpecificSalesKey, jsonEncode(salesData));
//     await prefs.setString(storeSpecificDateKey, todayString);
//     await prefs.setString(_storeIdKey, currentStoreId ?? '');
//   }
//
//   static Future<Map<String, dynamic>?> loadSalesData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     final currentStoreId = prefs.getString(valueShared_STORE_KEY);
//     final cachedStoreId = prefs.getString(_storeIdKey);
//
//     final storeSpecificSalesKey =
//     _getUserSpecificKey(_salesDataKey, currentStoreId);
//     final storeSpecificDateKey =
//     _getUserSpecificKey(_lastDateKey, currentStoreId);
//
//     final cachedDate = prefs.getString(storeSpecificDateKey);
//     final cachedData = prefs.getString(storeSpecificSalesKey);
//
//     if (cachedDate == todayString &&
//         cachedStoreId == currentStoreId &&
//         cachedData != null &&
//         currentStoreId != null &&
//         currentStoreId.isNotEmpty) {
//       return jsonDecode(cachedData);
//     }
//
//     return null;
//   }
//
//   static Future<void> clearSalesData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final currentStoreId = prefs.getString(valueShared_STORE_KEY);
//
//     if (currentStoreId != null) {
//       final storeSpecificSalesKey =
//       _getUserSpecificKey(_salesDataKey, currentStoreId);
//       final storeSpecificDateKey =
//       _getUserSpecificKey(_lastDateKey, currentStoreId);
//
//       await prefs.remove(storeSpecificSalesKey);
//       await prefs.remove(storeSpecificDateKey);
//     }
//
//     await prefs.remove(_salesDataKey);
//     await prefs.remove(_lastDateKey);
//     await prefs.remove(_storeIdKey);
//   }
//
//   static Future<void> clearOrderDate() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_orderDateKey);
//   }
//
//   static Future<void> saveOrderDate() async {
//     final prefs = await SharedPreferences.getInstance();
//     final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     await prefs.setString(_orderDateKey, todayString);
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/Socket/socket_service.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/DailySalesReport.dart';
import 'package:food_app/models/UserMe.dart';
import 'package:food_app/ui/Order/OrderDetailEnglish.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Database/databse_helper.dart';
import '../../models/Topping.dart';
import '../../models/order_model.dart';
import '../../models/sync_order_response_model.dart';
import '../../models/today_report.dart' hide TaxBreakdown;
import '../Login/LoginScreen.dart';
import '../../models/order_model.dart'; // Order model
import '../../models/ShippingAddress.dart'; // ShippingAddress model
import '../../models/OrderItem.dart'; // OrderItem model
import '../../models/Payment.dart'; // Payment model

class OrderScreenNew extends StatefulWidget {
  const OrderScreenNew({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreenNew>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
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
  bool _hasSocketData = false;
  Map<String, int> _liveApiData = {
    'accepted': 0,
    'declined': 0,
    'pending': 0,
    'pickup': 0,
    'delivery': 0,
    'totalOrders': 0,
  };
  bool isLoading = false;
  bool _isInitialLoading = true;
  Timer? _initVarTimeoutTimer;
  bool hasInternet = true;
  Timer? _internetCheckTimer;
  bool _isDialogShowing = false;
  String? _storeType;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  String delivery = '0', pickUp = '0', pending = '0', accepted = '0', declined = '0';

  // Add these with other state variables at the top
  bool _isSyncingLocalOrders = false;
  List<Order> _localOrders = [];
  Timer? _syncTimer;
  late AnimationController _syncRotationController;
  late Animation<double> _syncRotationAnimation;
  Timer? _autoSyncTimer;
  int _autoSyncInterval = 60;
  bool _syncTimeLoaded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _syncRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _syncRotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _syncRotationController, curve: Curves.linear),
    );
    _startInternetMonitoring();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initVar();
      _loadAndSyncLocalOrders();
    });
  }

  Future<void> _checkAndClearOldData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString('cached_sales_date');
    final cachedOrderDate = prefs.getString('cached_order_date');
    final cachedStoreId = prefs.getString('cached_store_id');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    if (cachedDate != today || cachedStoreId != currentStoreId) {
      await SalesCacheHelper.clearSalesData();
      setState(() {
        _currentDateReport = null;
        reportsss = DailySalesReport();
        reportList.clear();
      });
      if (currentStoreId != null) {
        await prefs.setString('cached_store_id', currentStoreId);
      }
    }

    if (cachedOrderDate != today || cachedStoreId != currentStoreId) {
      setState(() {
        app.appController.clearOrders();
      });
      await prefs.setString('cached_order_date', today);
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();

    WidgetsBinding.instance.removeObserver(this);
    _initVarTimeoutTimer?.cancel();
    _internetCheckTimer?.cancel();
    _noOrderTimer?.cancel();
    _syncTimer?.cancel();
    _autoSyncTimer?.cancel();

    _blinkController.dispose();
    _syncRotationController.dispose();

    // ✅ Call super.dispose() LAST
    super.dispose();
  }


  Future<void> _loadAndSyncLocalOrders() async {
    if (_isSyncingLocalOrders) return;

    setState(() {
      _isSyncingLocalOrders = true;
    });

    try {
      final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      if (storeID == null || storeID.isEmpty) {
        setState(() {
          _isSyncingLocalOrders = false;
        });
        return;
      }

      // Get unsynced orders from database
      final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeID);

      if (unsyncedOrders.isEmpty) {
        setState(() {
          _isSyncingLocalOrders = false;
          _localOrders.clear();
        });
        return;
      }

      // Convert database orders to Order model format
      List<Order> localOrdersList = [];

      for (var dbOrder in unsyncedOrders) {
        final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);

        if (orderDetails != null) {
          Order order = await _convertDbOrderToOrderModel(orderDetails); // Add await here
          localOrdersList.add(order);
        }
      }
      setState(() {
        _localOrders = localOrdersList;
      });


    } catch (e) {
      print('Error loading local orders: $e');
      setState(() {
        _isSyncingLocalOrders = false;
      });
    }
  }

  Future<void> updateSyncInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? syncTime = prefs.getString('sync_time');

      if (syncTime != null && syncTime.isNotEmpty) {
        int? syncTimeValue = int.tryParse(syncTime);
        if (syncTimeValue != null && syncTimeValue > 0) {
          _autoSyncInterval = syncTimeValue;
          print('✅ Updated sync interval to: $_autoSyncInterval seconds');

          // Restart timer with new interval
          _startAutoSync();
        }
      }
    } catch (e) {
      print('❌ Error updating sync interval: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_isRefreshing) return;

      if (_lastRefreshTime != null) {
        final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
        if (timeSinceLastRefresh.inSeconds < 2) return;
      }

      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }
      _reloadSyncTime();
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    try {
      final storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID != null && storeID.isNotEmpty && !_isErrorCode(storeID)) {
        await getOrdersWithoutLoader(bearerKey, storeID);
        await getLiveSaleReportWithoutLoader();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _reloadSyncTime() async {
    try {
      String? syncTime = sharedPreferences.getString('sync_time');

      if (syncTime != null && syncTime.isNotEmpty) {
        int? syncTimeSeconds = int.tryParse(syncTime);
        if (syncTimeSeconds != null && syncTimeSeconds >= 60) { // ✅ Minimum 60 seconds
          if (_autoSyncInterval != syncTimeSeconds) {
            _autoSyncInterval = syncTimeSeconds;
            int minutes = (syncTimeSeconds / 60).round();
            print('🔄 Sync interval updated to: $minutes minutes ($syncTimeSeconds seconds)');

            // Restart timer with new interval
            _startAutoSync();
          }
        }
      }
    } catch (e) {
      print('❌ Error reloading sync time: $e');
    }
  }

  Future<void> initVar() async {
    _initVarTimeoutTimer?.cancel();

    if (Get.isDialogOpen ?? false) {
      try {
        Get.back();
      } catch (e) {
        // Handle error
      }
    }

    if (_isInitialLoading) {
      setState(() {
        isLoading = true;
      });
    }

    Timer? timeoutTimer;

    try {
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            isLoading = false;
            _isInitialLoading = false;
          });
        }
      });

      setState(() {
        hasInternet = true;
      });

      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
        } catch (e) {
          // Handle error
        }
      }

      sharedPreferences = await SharedPreferences.getInstance();
      bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
      _storeType = sharedPreferences.getString(valueShared_STORE_TYPE);
      if (!_syncTimeLoaded) {
        await _loadSyncTimeAndStartAutoSync();
        _syncTimeLoaded = true;
      }

      _socketService.disconnect();
      setState(() {
        _isLiveDataActive = false;
        _lastUpdateTime = null;
        _currentDateReport = null;
        reportsss = DailySalesReport();
      });

      await _preloadStoreData();
      await _checkAndClearOldData();

      final storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID != null && storeID.isNotEmpty && !_isErrorCode(storeID)) {
        String? cachedStoreName = await DatabaseHelper().getStoreName(storeID);
        if (cachedStoreName != null && cachedStoreName.isNotEmpty) {
          setState(() {
            storeName = cachedStoreName;
            dynamicStoreId = storeID;
          });
          print("✅ OrderScreen: Loaded store name from cache: $storeName");
        }
        await _restoreUserSpecificData(storeID);
        await getOrdersWithoutLoader(bearerKey, storeID);
        await _loadAndSyncLocalOrders();
        if (bearerKey != null && bearerKey!.isNotEmpty) {
          _initializeSocket();
        }
      } else {
        if (storeID != null && _isErrorCode(storeID)) {
          await sharedPreferences.remove(valueShared_STORE_KEY);
        }
        await getStoreUserMeDataWithoutLoader(bearerKey);
      }

      getCurrentDateReport();
      _loadCachedSalesData();
      _startNoOrderTimer();
      await getLiveSaleReportWithoutLoader();
    } catch (e) {
      // Handle error
    } finally {
      timeoutTimer?.cancel();
      _initVarTimeoutTimer?.cancel();

      if (mounted) {
        setState(() {
          isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadSyncTimeAndStartAutoSync() async {
    try {
      String? syncTime = sharedPreferences.getString('sync_time');

      if (syncTime != null && syncTime.isNotEmpty) {
        int? syncTimeSeconds = int.tryParse(syncTime);
        if (syncTimeSeconds != null && syncTimeSeconds >= 60) { // ✅ Minimum 60 seconds (1 minute)
          _autoSyncInterval = syncTimeSeconds;
          int minutes = (syncTimeSeconds / 60).round();
          print('✅ Loaded sync interval: $minutes minutes ($syncTimeSeconds seconds)');
        } else {
          print('⚠️ Invalid sync time in preferences, using default');
          _autoSyncInterval = 1800; // ✅ Default 30 minutes = 1800 seconds
        }
      } else {
        print('📝 No sync time found, using default: 30 minutes');
        _autoSyncInterval = 1800; // ✅ Default 30 minutes = 1800 seconds
      }

      // Start auto sync with loaded interval
      _startAutoSync();
    } catch (e) {
      print('❌ Error loading sync time: $e');
      _autoSyncInterval = 1800; // ✅ Default 30 minutes = 1800 seconds
      _startAutoSync();
    }
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel(); // Cancel existing timer

    int minutes = (_autoSyncInterval / 60).round();
    print('🔄 Starting auto sync with interval: $minutes minutes ($_autoSyncInterval seconds)');
    print('🕐 Next sync will occur at: ${DateTime.now().add(Duration(seconds: _autoSyncInterval))}');

    _autoSyncTimer = Timer.periodic(Duration(seconds: _autoSyncInterval), (timer) async {
      int mins = (_autoSyncInterval / 60).round();
      print('⏰ Auto sync timer triggered at ${DateTime.now()} - Interval: $mins minutes');
      await _autoSyncLocalOrders();
    });
  }

  Future<Order> _convertDbOrderToOrderModel(Map<String, dynamic> orderDetails) async {
    final orderData = orderDetails['order'] as Map<String, dynamic>;
    final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;
    final itemsData = orderDetails['items'] as List<dynamic>;
    final paymentData = orderDetails['payment'] as Map<String, dynamic>?;

    // Create shipping address
    ShippingAddress? shippingAddress;
    if (addressData != null) {
      shippingAddress = ShippingAddress(
        customer_name: addressData['customer_name'] as String?,
        phone: addressData['phone'] as String?,
        line1: addressData['line1'] as String?,
        city: addressData['city'] as String?,
        zip: addressData['zip'] as String?,
        country: addressData['country'] as String?,
        type: addressData['type'] as String?,
      );
    }

    // Create guest shipping json (for fallback)
    GuestShippingJson? guestShippingJson;
    if (addressData != null) {
      guestShippingJson = GuestShippingJson(
        customerName: addressData['customer_name'] as String?,
        phone: addressData['phone'] as String?,
        line1: addressData['line1'] as String?,
        city: addressData['city'] as String?,
        zip: addressData['zip'] as String?,
        country: addressData['country'] as String?,
        type: addressData['type'] as String?,
      );
    }

    // Create payment
    Payment? payment;
    if (paymentData != null) {
      payment = Payment(
        amount: (paymentData['amount'] as num?)?.toDouble(),
        paymentMethod: paymentData['payment_method'] as String?,
        status: paymentData['status'] as String?,
      );
    }



    List<OrderItem>? orderItems;
    if (itemsData.isNotEmpty) {
      final itemFutures = itemsData.map((item) async {
        String productName = 'Product';
        try {
          final productId = item['product_id'] as int?;
          if (productId != null) {
            final product = await DatabaseHelper().getProductById(productId.toString());
            if (product != null) {
              productName = product.name ?? 'Product';
            }
          }
        } catch (e) {
          print('Error getting product name: $e');
        }

        // ✅ Parse toppings from database
        List<Topping>? toppings;
        if (item['toppings'] != null && item['toppings'] is List) {
          toppings = (item['toppings'] as List).map((t) => Topping(
            toppingId: t['id'] as int?,
            name: t['topping_name'] as String?,
            price: (t['topping_price'] as num?)?.toDouble(),
            quantity: t['topping_quantity'] as int?,
          )).toList();
        }

        return OrderItem(
          id: item['id'] as int?,
          productId: item['product_id'] as int?,
          productName: productName,
          quantity: item['quantity'] as int?,
          unitPrice: (item['unit_price'] as num?)?.toDouble(),
          variantId: item['variant_id'] as int?,
          note: item['note'] as String? ?? '',
          variant: null,
          toppings: toppings ?? [],
        );
      }).toList();

      orderItems = await Future.wait(itemFutures);
    }
    // Create order
    return Order(
      id: orderData['id'] as int?,
      orderNumber: orderData['id'] as int?,
      orderType: orderData['order_type'] as int?,
      orderStatus: orderData['order_status'] as int?,
      approvalStatus: orderData['approval_status'] as int?,
      note: orderData['note'] as String? ?? '',
      deliveryTime: orderData['delivery_time'] as String?,
      storeId: orderData['store_id'] != null
          ? int.tryParse(orderData['store_id'].toString())
          : null,
      isActive: orderData['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          orderData['created_at'] as int
      ).toIso8601String(),
      shipping_address: shippingAddress,
      guestShippingJson: guestShippingJson,
      payment: payment,
      items: orderItems ?? [],
      isLocalOrder: true,
    );
  }

  bool _isErrorCode(String? value) {
    if (value == null || value.isEmpty) return false;
    int? code = int.tryParse(value);
    if (code == null) return false;
    List<int> errorCodes = [400, 401, 403, 404, 500, 502, 503, 504];
    return errorCodes.contains(code);
  }

  Future<void> _offlineLogout() async {
    bool loaderShown = false;
    Timer? timeoutTimer;

    try {
      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      Get.dialog(
        Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
        barrierDismissible: false,
      );
      loaderShown = true;

      timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          try {
            Get.back();
            loaderShown = false;
          } catch (e) {
            // Handle error
          }
        }
        Get.offAll(() => const LoginScreen());
      });
      await DatabaseHelper().clearAllStores();
      await _preserveUserIPDataOffline();
      await _forceCompleteLogoutCleanupOffline();
      app.appController.clearOnLogout();
      await _disconnectSocketOffline();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
      }

      Get.offAll(() => const LoginScreen());
    } catch (e) {
      // Handle error
    } finally {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      if (!Get.currentRoute.contains('LoginScreen')) {
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  Future<void> _preserveUserIPDataOffline() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentStoreId = prefs.getString(valueShared_STORE_KEY);

      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        String userPrefix = "user_${currentStoreId}_";

        for (int i = 0; i < 5; i++) {
          String? currentIP = prefs.getString('printer_ip_$i');
          if (currentIP != null && currentIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
          }
        }

        for (int i = 0; i < 5; i++) {
          String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
          if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
          }
        }

        int? selectedIndex = prefs.getInt('selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
        }

        bool? autoOrderAccept = prefs.getBool('auto_order_accept');
        if (autoOrderAccept != null) {
          await prefs.setBool('${userPrefix}auto_order_accept', autoOrderAccept);
        }

        bool? autoOrderPrint = prefs.getBool('auto_order_print');
        if (autoOrderPrint != null) {
          await prefs.setBool('${userPrefix}auto_order_print', autoOrderPrint);
        }

        bool? autoRemoteAccept = prefs.getBool('auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool('${userPrefix}auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint = prefs.getBool('auto_order_remote_print');
        if (autoRemotePrint != null) {
          await prefs.setBool('${userPrefix}auto_order_remote_print', autoRemotePrint);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _forceCompleteLogoutCleanupOffline() async {
    try {
      await DatabaseHelper().clearAllStores();
      for (int attempt = 0; attempt < 3; attempt++) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,
          'printer_ip_backup',
          'printer_ip_0_backup',
          'last_save_timestamp',
          'printer_ip_0',
          'printer_ip_remote_0',
          'selected_ip_index',
          'selected_ip_remote_index',
          'auto_order_accept',
          'auto_order_print',
          'auto_order_remote_accept',
          'auto_order_remote_print',
          'cached_sales_date',
          'cached_order_date',
          'cached_store_id',
          'cached_store_name',
          'store_name',
          valueShared_STORE_NAME,
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(const Duration(milliseconds: 20));
        }

        for (int i = 0; i < 5; i++) {
          await prefs.remove('printer_ip_$i');
          await prefs.remove('printer_ip_remote_$i');
        }

        await SalesCacheHelper.clearSalesData();
        await prefs.reload();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      SharedPreferences finalPrefs = await SharedPreferences.getInstance();
      await finalPrefs.reload();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _disconnectSocketOffline() async {
    try {
      _socketService.disconnect();
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Handle error
    }
  }

  void _showLogoutDialog() {
    if (_isDialogShowing || !mounted) return;

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.red),
                SizedBox(width: 8),
                Text("Connection Error"),
              ],
            ),
            content: const Text(
                "Cannot connect to server. Please logout and login again to continue."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                  _offlineLogout();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _startInternetMonitoring() {
    _internetCheckTimer?.cancel();
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnection = connectivityResult != ConnectivityResult.none;

      if (hasConnection && !hasInternet) {
        setState(() {
          hasInternet = true;
        });

        if (_isDialogShowing) {
          try {
            Navigator.of(context).pop();
            _isDialogShowing = false;
          } catch (e) {
            // Handle error
          }
        }

        initVar();
      }
    });
  }

  Future<void> getLiveSaleReportWithoutLoader() async {
    try {
      if (bearerKey == null || bearerKey!.isEmpty) {
        _setEmptyValues();
        return;
      }

      GetTodayReport model = await CallService().getLiveSaleData();

      setState(() {
        hasInternet = true;
      });

      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
        } catch (e) {
          // Handle error
        }
      }

      if (model.code != null && model.code != 200) {
        _setEmptyValues();
        return;
      }

      setState(() {
        delivery = '${model.orderTypes?.delivery ?? 0}';
        pickUp = '${model.orderTypes?.pickup ?? 0}';
        pending = '${model.approvalStatuses?.pending ?? 0}';
        accepted = '${model.approvalStatuses?.accepted ?? 0}';
        declined = '${model.approvalStatuses?.declined ?? 0}';

        _liveApiData = {
          'accepted': model.approvalStatuses?.accepted ?? 0,
          'declined': model.approvalStatuses?.declined ?? 0,
          'pending': model.approvalStatuses?.pending ?? 0,
          'pickup': model.orderTypes?.pickup ?? 0,
          'delivery': model.orderTypes?.delivery ?? 0,
          'totalOrders': model.totalOrders ?? 0,
        };

        _isLiveDataActive = true;
        _lastUpdateTime = DateTime.now();
      });
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('API call failed with status null')) {
        setState(() {
          hasInternet = false;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      }

      _setEmptyValues();
    }
  }

  Future<void> _restoreUserSpecificData(String currentStoreId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userPrefix = "user_${currentStoreId}_";

      String? testKey = prefs.getString('${userPrefix}printer_ip_0');
      if (testKey != null) {
        for (int i = 0; i < 5; i++) {
          String? savedIP = prefs.getString('${userPrefix}printer_ip_$i');
          if (savedIP != null && savedIP.isNotEmpty) {
            await prefs.setString('printer_ip_$i', savedIP);
          }
        }

        for (int i = 0; i < 5; i++) {
          String? savedRemoteIP = prefs.getString('${userPrefix}printer_ip_remote_$i');
          if (savedRemoteIP != null && savedRemoteIP.isNotEmpty) {
            await prefs.setString('printer_ip_remote_$i', savedRemoteIP);
          }
        }

        int? selectedIndex = prefs.getInt('${userPrefix}selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex = prefs.getInt('${userPrefix}selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt('selected_ip_remote_index', selectedRemoteIndex);
        }

        bool? autoOrderAccept = prefs.getBool('${userPrefix}auto_order_accept');
        if (autoOrderAccept != null) {
          await prefs.setBool('auto_order_accept', autoOrderAccept);
        }

        bool? autoOrderPrint = prefs.getBool('${userPrefix}auto_order_print');
        if (autoOrderPrint != null) {
          await prefs.setBool('auto_order_print', autoOrderPrint);
        }

        bool? autoRemoteAccept = prefs.getBool('${userPrefix}auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool('auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint = prefs.getBool('${userPrefix}auto_order_remote_print');
        if (autoRemotePrint != null) {
          await prefs.setBool('auto_order_remote_print', autoRemotePrint);
        }
      } else {
        await _clearGeneralIPData();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _clearGeneralIPData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      for (int i = 0; i < 5; i++) {
        await prefs.remove('printer_ip_$i');
        await prefs.remove('printer_ip_remote_$i');
      }

      await prefs.remove('selected_ip_index');
      await prefs.remove('selected_ip_remote_index');
      await prefs.remove('auto_order_accept');
      await prefs.remove('auto_order_print');
      await prefs.remove('auto_order_remote_accept');
      await prefs.remove('auto_order_remote_print');
    } catch (e) {
      // Handle error
    }
  }

  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID == null || storeID.isEmpty) {
        return null;
      }

      final result = await ApiRepo().getStoreData(bearerKey, storeID);

      setState(() {
        hasInternet = true;
      });

      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
        } catch (e) {
          // Handle error
        }
      }

      if (result.code != null) {
        if (result.code == 500 || result.code! >= 500) {
          setState(() {
            hasInternet = false;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            _showLogoutDialog();
          });
        }
        return null;
      }

      if (result.name != null && result.name!.isNotEmpty) {
        String fetchedStoreName = result.name!;
        String fetchedStoreId = storeID;
        await DatabaseHelper().saveStore(fetchedStoreId, fetchedStoreName);

        setState(() {
          storeName = fetchedStoreName;
          dynamicStoreId = fetchedStoreId;
        });

        await sharedPreferences.setString('store_name', fetchedStoreName);
        await sharedPreferences.setString(valueShared_STORE_NAME, fetchedStoreName);

        return storeName;
      } else {
        return null;
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        setState(() {
          hasInternet = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      }

      return null;
    }
  }

  Future<void> getStoreUserMeDataWithoutLoader(String? bearerKey) async {
    try {
      final result = await ApiRepo().getUserMe(bearerKey);

      setState(() {
        hasInternet = true;
      });

      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
        } catch (e) {
          // Handle error
        }
      }

      if (result.code != null) {
        if (result.code == 500 || result.code! >= 500) {
          setState(() {
            hasInternet = false;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            _showLogoutDialog();
          });
          return;
        } else {
          showSnackbar("error".tr, result.mess ?? "failed".tr);
          return;
        }
      }

      if (result.store_id != null && result.store_id! > 0) {
        setState(() {
          userMe = result;
        });

        String newStoreId = result.store_id.toString();
        await sharedPreferences.setString(valueShared_STORE_KEY, newStoreId);

        await getStoredta(bearerKey!);
        await _restoreUserSpecificData(newStoreId);
        await getOrdersWithoutLoader(bearerKey, newStoreId);

        if (bearerKey.isNotEmpty) {
          _initializeSocket();
        }
      } else {
        showSnackbar("error".tr, "invalid_user".tr);
      }
    } catch (e) {
      Log.loga("OrderScreen", "getUserMe Api:: e >>>>> $e");

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        setState(() {
          hasInternet = false;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      } else {
        showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
      }
    }
  }

  Future<void> getOrdersWithoutLoader(String? bearerKey, String? id) async {
    try {
      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      final Map<String, dynamic> data = {
        "store_id": id,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (!mounted) return; // ✅ Check before setState

      setState(() {
        hasInternet = true;
      });

      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
        } catch (e) {
          // Handle error
        }
      }

      if (result.isNotEmpty) {
        final firstItem = result.first;
        if (firstItem.code != null) {
          if (firstItem.code == 500 || firstItem.code! >= 500) {
            if (mounted) {
              setState(() {
                hasInternet = false;
              });
            }
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _showLogoutDialog();
            });
          }
          _startNoOrderTimer();
          return;
        }

        if (mounted) {
          setState(() {
            app.appController.setOrders(result);
          });
        }
        _stopNoOrderTimer();
      } else {
        if (mounted) {
          setState(() {
            app.appController.setOrders([]);
          });
        }
        _startNoOrderTimer();
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        if (mounted) {
          setState(() {
            hasInternet = false;
          });
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showLogoutDialog();
        });
      } else {
        if (mounted) {
          showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
        }
      }
    }
  }

  Future<void> _preloadStoreData() async {
    if (bearerKey != null) {
      try {
        String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
        if (storeID != null) {
          final result = await ApiRepo().getStoreData(bearerKey!, storeID);
          await sharedPreferences.setString('cached_store_name', result.name.toString());
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  void _initializeSocket() {
    _socketService.disconnect();

    // ✅ Add mounted check before setState
    if (mounted) {
      setState(() {
        _isLiveDataActive = false;
        _lastUpdateTime = null;
        _hasSocketData = false;
      });
    }

    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

    int dynamicStoreId;

    if (storeID != null && storeID.isNotEmpty) {
      int? parsedId = int.tryParse(storeID);

      if (parsedId != null) {
        dynamicStoreId = parsedId;
      } else {
        return;
      }
    } else {
      if (userMe.store_id != null) {
        dynamicStoreId = userMe.store_id!;
        sharedPreferences.setString(valueShared_STORE_KEY, dynamicStoreId.toString());
      } else {
        return;
      }
    }

    _socketService.onSalesUpdate = (data) {
      if (!mounted) return; // ✅ ADD THIS LINE

      if (data['store_id'] != null &&
          data['store_id'].toString() != dynamicStoreId.toString()) {
        return;
      }

      _handleSalesUpdate(data, isFromSocket: true);
    };
    _socketService.onConnected = () {
      if (!mounted) return; // ✅ ADD THIS LINE
      setState(() => _isLiveDataActive = true);
    };
    _socketService.onDisconnected = () {
      if (!mounted) return;
      setState(() {
        _isLiveDataActive = false;
        _hasSocketData = false;
      });
    };
    _socketService.onNewOrder = (data) {
      if (!mounted) return; // ✅ ADD THIS LINE

      if (data['store_id'] != null &&
          data['store_id'].toString() != dynamicStoreId.toString()) {
        return;
      }

      _refreshCurrentDayData();
      getLiveSaleReportWithoutLoader();
    };

    try {
      _socketService.connect(bearerKey!, storeId: dynamicStoreId);
    } catch (e) {
      print('❌ Socket connection error: $e');
    }
  }


  Future<void> getLiveSaleReport() async {
    Timer? timeoutTimer;
    bool loaderShown = false;

    try {
      if (bearerKey == null || bearerKey!.isEmpty) {
        _setEmptyValues();
        return;
      }

      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      Get.dialog(
        Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
        barrierDismissible: false,
      );
      loaderShown = true;

      timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          try {
            Get.back();
            loaderShown = false;
          } catch (e) {
            // Handle error
          }
        }
        _setEmptyValues();
      });

      GetTodayReport model = await CallService().getLiveSaleData().timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('api_time'.tr, const Duration(seconds: 6));
        },
      );

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
      }

      if (model.code != null && model.code != 200) {
        _setEmptyValues();
        return;
      }

      setState(() {
        delivery = '${model.orderTypes?.delivery ?? 0}';
        pickUp = '${model.orderTypes?.pickup ?? 0}';
        pending = '${model.approvalStatuses?.pending ?? 0}';
        accepted = '${model.approvalStatuses?.accepted ?? 0}';
        declined = '${model.approvalStatuses?.declined ?? 0}';

        _liveApiData = {
          'accepted': model.approvalStatuses?.accepted ?? 0,
          'declined': model.approvalStatuses?.declined ?? 0,
          'pending': model.approvalStatuses?.pending ?? 0,
          'pickup': model.orderTypes?.pickup ?? 0,
          'delivery': model.orderTypes?.delivery ?? 0,
          'totalOrders': model.totalOrders ?? 0,
        };

        _isLiveDataActive = true;
        _lastUpdateTime = DateTime.now();
      });
    } on TimeoutException catch (e) {
      _setEmptyValues();
    } catch (e) {
      _setEmptyValues();

      if (!e.toString().contains('204') && !e.toString().contains('timeout')) {
        showSnackbar("info".tr, "unable".tr);
      }
    } finally {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }
    }
  }

  void _setEmptyValues() {
    setState(() {
      _isLiveDataActive = false;
      delivery = '0';
      pickUp = '0';
      pending = '0';
      accepted = '0';
      declined = '0';
    });
  }

  void _startNoOrderTimer() {
    _noOrderTimer?.cancel();
    _noOrderTimer = Timer(const Duration(seconds: 4), () {
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
    if (!mounted) return;

    if (isFromSocket) {
      SalesCacheHelper.saveSalesData(salesData);
      _hasSocketData = true;
    }

    if (mounted) {
      setState(() => _lastUpdateTime = DateTime.now());
    }

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
            ? (salesData['top_items'] as List)
            .map((item) => TopItem.fromJson(item))
            .toList()
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

      if (mounted) {
        setState(() => reportsss = _currentDateReport!);
      }
    }
  }

  Future<void> _loadCachedSalesData() async {
    final cachedData = await SalesCacheHelper.loadSalesData();
    if (cachedData != null) {
      _handleSalesUpdate(cachedData);
    }
  }

  void _refreshCurrentDayData() => getCurrentDateReport();

  void getCurrentDateReport() {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

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
    } else {
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
    }
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;

    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh.inSeconds < 1) return;
    }

    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, true, false, storeID);
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    try {
      final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      await getOrdersWithoutLoader(bearerKey, storeID);
      await getLiveSaleReportWithoutLoader();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> getOrders(
      String? bearerKey, bool orderType, bool isBellRunning, String? id) async
  {
    bool loaderShown = false;
    Timer? timeoutTimer;

    try {
      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      if (orderType) {
        if (Get.isDialogOpen ?? false) {
          try {
            Get.back();
          } catch (e) {
            // Handle error
          }
        }

        Get.dialog(
          Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
          barrierDismissible: false,
        );
        loaderShown = true;

        timeoutTimer = Timer(const Duration(seconds: 8), () {
          if (loaderShown && (Get.isDialogOpen ?? false)) {
            try {
              Get.back();
              loaderShown = false;
            } catch (e) {
              // Handle error
            }
          }
        });
      }

      final Map<String, dynamic> data = {
        "store_id": id,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('api_timeout'.tr, const Duration(seconds: 6));
        },
      );

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
      }

      if (result.isNotEmpty && result.first.code == null) {
        setState(() {
          app.appController.setOrders(result);
        });

        if (result.isNotEmpty) {
          _stopNoOrderTimer();
        }
      } else {
        _startNoOrderTimer();
      }
    } on TimeoutException catch (e) {
      // Handle timeout
    } catch (e) {
      Log.loga("OrderScreen", "getOrders Api:: e >>>>> $e");
      showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
    } finally {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }
    }
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
  }

  int _getApprovalStatusCount(String status) {
    if (_hasSocketData && _currentDateReport?.data?.approvalStatuses != null) {
      final approvalStatuses = _currentDateReport!.data!.approvalStatuses;

      switch (status.toLowerCase()) {
        case "accepted":
          return approvalStatuses["accepted"] ??
              approvalStatuses["approve"] ??
              approvalStatuses["2"] ??
              0;
        case "declined":
          return approvalStatuses["declined"] ??
              approvalStatuses["decline"] ??
              approvalStatuses["rejected"] ??
              approvalStatuses["3"] ??
              0;
        case "pending":
          return approvalStatuses["pending"] ?? approvalStatuses["1"] ?? 0;
        default:
          return 0;
      }
    }
    return _liveApiData[status] ?? 0;
  }

  int _getOrderTypeCount(String type) {
    if (_hasSocketData && _currentDateReport?.data?.orderTypes != null) {
      final orderTypes = _currentDateReport!.data!.orderTypes;

      switch (type.toLowerCase()) {
        case "pickup":
          return orderTypes["pickup"] ??
              orderTypes["pick_up"] ??
              orderTypes["takeaway"] ??
              0;
        case "delivery":
          return orderTypes["delivery"] ?? orderTypes["home_delivery"] ?? 0;
        case "dine_in":
          return orderTypes["dine_in"] ?? orderTypes["dinein"] ?? 0;
        default:
          return 0;
      }
    }

    return _liveApiData[type] ?? 0;
  }

  int _getTotalOrders() {
    if (_hasSocketData && _currentDateReport?.totalOrders != null) {
      return _currentDateReport!.totalOrders!;
    }

    return _liveApiData['totalOrders'] ?? 0;
  }

  String _extractTime(String deliveryTime) {
    try {
      DateTime dateTime = DateTime.parse(deliveryTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return deliveryTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      body: Builder(builder: (context) {
        if (isLoading && _isInitialLoading) {
          return Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          );
        }

        if (!hasInternet) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("No Internet Connection",
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showLogoutDialog(),
                  child: const Text("Show Logout Dialog"),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('order'.tr,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              dateSeleted.isEmpty
                                  ? DateFormat('d MMMM, y')
                                  .format(DateTime.now())
                                  : dateSeleted,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${'total_order'.tr}: ${_getTotalOrders()}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: "Mulish",
                                color: Colors.black),
                          ),
                          IconButton(
                            iconSize: 30,
                            icon: const Icon(Icons.refresh),
                            onPressed: _manualRefresh,
                          ),
                          IconButton(
                            icon: Icon(Icons.sync),
                            onPressed: () async {
                              await syncLocalPosOrder();
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusContainer(
                          '${'accepted'.tr} ${_getApprovalStatusCount("accepted")}',
                          Colors.green.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusContainer(
                          '${"decline".tr} ${_getApprovalStatusCount("declined")}',
                          Colors.red.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusContainer(
                          '${"pickup".tr} ${_getOrderTypeCount("pickup")}',
                          Colors.blue.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusContainer(
                          '${"delivery".tr} ${_getOrderTypeCount("delivery")}',
                          Colors.purple.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: false,
                    removeBottom: true,
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: Colors.green,
                      backgroundColor: Colors.white,
                      displacement: 60,
                      child: _isInitialLoading
                          ? Container()
                          : !hasInternet
                          ? ListView(
                        padding: EdgeInsets.zero,
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off,
                                  size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text("no_internet".tr,
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "please".tr,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      )
                          : Obx(() {
                        List<Order> allOrders = [
                          ..._localOrders,
                          ...app.appController.searchResultOrder,
                        ];
                        // if (app.appController.searchResultOrder.isEmpty) {
                        //   return ListView(
                        //     padding: EdgeInsets.zero,
                        //     physics: const AlwaysScrollableScrollPhysics(),
                        //     children: [
                        //       const SizedBox(height: 100),
                        //       Column(mainAxisAlignment: MainAxisAlignment.center,
                        //         children: [
                        //           Lottie.asset('assets/animations/empty.json',
                        //             width: 150,
                        //             height: 150,
                        //           ),
                        //           Text(
                        //             'no_order'.tr,
                        //             style: const TextStyle(
                        //               fontSize: 16,
                        //               fontWeight: FontWeight.w500,
                        //               color: Colors.grey,
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ],
                        //   );
                        // }
                        if (allOrders.isEmpty) {
                          return ListView(
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.asset('assets/animations/empty.json',
                                    width: 150,
                                    height: 150,
                                  ),
                                  Text(
                                    'no_order'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: allOrders.length,
                          itemBuilder: (context, index) {
                            final order = allOrders[index];
                            final isLocalOrder = _localOrders.contains(order);
                            // itemCount: app.appController.searchResultOrder.length,
                            // itemBuilder: (context, index) {
                            //   final order = app.appController.searchResultOrder[index];
                            DateTime dateTime = DateTime.parse(order.createdAt.toString());
                            String time = DateFormat('hh:mm a').format(dateTime);
                            String guestAddress = order.guestShippingJson?.zip?.toString() ?? '';
                            String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
                            String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';

                            return AnimatedBuilder(
                              animation: _opacityAnimation,
                              builder: (context, child) {
                                final bool isPending = (order.approvalStatus ?? 0) == 1;
                                Color getContainerColor() {
                                  switch (order.approvalStatus) {
                                    case 2:
                                      return const Color(0xffEBFFF4);
                                    case 3:
                                      return const Color(0xffFFEFEF);
                                    case 1:
                                      return Colors.white;
                                    default:
                                      return Colors.white;
                                  }
                                }

                                return Opacity(
                                  opacity: isPending ? _opacityAnimation.value : 1.0,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: getContainerColor(),
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: (order.approvalStatus == 2)
                                            ? const Color(0xffC3F2D9) : (order.approvalStatus == 3)
                                            ? const Color(0xffFFD0D0) : Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 0,
                                          blurRadius: 4,
                                          offset:
                                          const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onLongPress: () {
                                          if (order.approvalStatus == 2) {
                                            _showDeliveryTimeDialog(order);
                                          }
                                        },
                                        onTap: () => Get.to(() => OrderDetailEnglish(order)),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 17,
                                                      backgroundColor: Colors.green,
                                                      child:
                                                      SvgPicture.asset(
                                                        order.orderType == 1
                                                            ? 'assets/images/ic_delivery.svg'
                                                            : order.orderType == 2
                                                            ? 'assets/images/ic_pickup.svg'
                                                            : order.orderType == 3
                                                            ? 'assets/images/table.svg'
                                                            : 'assets/images/ic_pickup.svg',
                                                        height: 14,
                                                        width: 14,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        SizedBox(width: MediaQuery.of(context).size.width * 0.6,
                                                          child:
                                                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Container(
                                                                width: MediaQuery.of(context).size.width * (_storeType == '2' ? 0.35 :
                                                                (order.orderType == 2 ? 0.18 : 0.18)),
                                                                child: Text(order.orderType == 2 ? 'pickup'.tr : (_storeType == '2'
                                                                    ? _getFullAddress(
                                                                    order.shipping_address ?? order.guestShippingJson,
                                                                    order.shipping_address == null)
                                                                    : (order.shipping_address?.zip?.toString() ?? guestAddress)),
                                                                  style: const TextStyle(
                                                                      fontWeight: FontWeight.w700,
                                                                      fontSize: 13,
                                                                      fontFamily: "Mulish-Regular"),
                                                                ),
                                                              ),
                                                              if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
                                                                SizedBox(width: MediaQuery.of(context).size.width * 0.25,
                                                                  child: Text(
                                                                    '${'time'.tr}: ${_extractTime(order.deliveryTime!)}',
                                                                    style: const TextStyle(fontWeight: FontWeight.w700,
                                                                        fontSize: 13, fontFamily: "Mulish-Regular"),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible: (_storeType != '2') && (order.shipping_address != null || order.guestShippingJson != null),
                                                          child: SizedBox(width: MediaQuery.of(context).size.width * 0.5,
                                                            child: Text(
                                                              order.orderType == 1 ? (order.shipping_address != null
                                                                  ? '${order.shipping_address!.line1!}, ${order.shipping_address!.city!}'
                                                                  : '${order.guestShippingJson?.line1 ?? ''}, ${order.guestShippingJson?.city ?? ''}')
                                                                  : '',
                                                              style: const TextStyle(
                                                                  fontWeight: FontWeight.w500,
                                                                  fontSize: 11,
                                                                  letterSpacing: 0,
                                                                  height: 0,
                                                                  fontFamily: "Mulish"),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.access_time, size: 20,),
                                                    Text(time, style: const TextStyle(
                                                      fontWeight:
                                                      FontWeight.w500,
                                                      fontFamily: "Mulish",
                                                      fontSize: 10,
                                                    ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // ✅ Wrap this SizedBox with Flexible
                                                Flexible(
                                                  child: SizedBox(
                                                    width: MediaQuery.of(context).size.width * 0.5,
                                                    child: Text(
                                                      '${order.shipping_address?.customer_name ?? guestName ?? ""} / ${order.shipping_address?.phone ?? guestPhone}',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontFamily: "Mulish",
                                                          fontSize: 13),
                                                      overflow: TextOverflow.ellipsis, // ✅ Add this
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${order.orderNumber != null ? 'order_number'.tr : 'Order ID'} : ',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 11,
                                                          fontFamily: "Mulish"),
                                                    ),
                                                    Text(
                                                      '${order.orderNumber ?? order.id ?? 'N/A'}',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 11,
                                                          fontFamily: "Mulish"),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  order.payment != null
                                                      ? '${'currency'.tr} ${formatAmount(order.payment!.amount ?? 0)}'
                                                      : '${'currency'.tr} ${formatAmount(0)}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                      FontWeight.w800,
                                                      fontFamily:
                                                      "Mulish",
                                                      fontSize: 16),
                                                ),
                                                // Row(
                                                //   children: [
                                                //     Text(
                                                //       getApprovalStatusText(order.approvalStatus),
                                                //       style: const TextStyle(
                                                //           fontWeight:
                                                //           FontWeight
                                                //               .w800,
                                                //           fontFamily:
                                                //           "Mulish-Regular",
                                                //           fontSize: 13),
                                                //     ),
                                                //     const SizedBox(
                                                //         width: 6),
                                                //     CircleAvatar(
                                                //       radius: 14,
                                                //       backgroundColor:
                                                //       getStatusColor(order.approvalStatus ?? 0),
                                                //       child: Icon(
                                                //         getStatusIcon(order.approvalStatus ?? 0),
                                                //         color: Colors.white,
                                                //         size: 16,
                                                //       ),
                                                //     ),
                                                //   ],
                                                // ),
                                                // In your itemBuilder, update the status icon section:
                                                Row(
                                                  children: [
                                                    Text(
                                                      isLocalOrder ? "syncing".tr : getApprovalStatusText(order.approvalStatus),
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w400,
                                                          fontFamily: "Mulish-Regular",
                                                          fontSize: 13
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    isLocalOrder
                                                        ? RotationTransition(
                                                      turns: _syncRotationAnimation,
                                                      child: SvgPicture.asset('assets/images/sync.svg'),
                                                    )
                                                        : CircleAvatar(
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
                          },
                        );
                      }),
                    ),
                  )
              )
            ],
          ),
        );
      }),
    );
  }

  Future<void> getOrdersWithoutLoaderSilent(String? bearerKey, String? id) async {
    try {
      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      final Map<String, dynamic> data = {
        "store_id": id,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (!mounted) return;

      if (result.isNotEmpty) {
        final firstItem = result.first;
        if (firstItem.code != null) {
          return;
        }

        if (mounted) {
          setState(() {
            app.appController.setOrders(result);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            app.appController.setOrders([]);
          });
        }
      }
    } catch (e) {
      print('❌ Silent API error: $e');
      // ✅ Don't show any errors during background sync
    }
  }

  String _getFullAddress(dynamic shippingAddress, bool isGuest) {
    if (shippingAddress == null) return '';

    List<String> parts = [];

    if (isGuest) {
      if (shippingAddress.line1 != null && shippingAddress.line1.toString().isNotEmpty) {
        parts.add(shippingAddress.line1.toString());
      }
      if (shippingAddress.city != null && shippingAddress.city.toString().isNotEmpty) {
        parts.add(shippingAddress.city.toString());
      }
      if (shippingAddress.zip != null &&
          shippingAddress.zip.toString().isNotEmpty &&
          shippingAddress.zip.toString() != '00000') {
        parts.add(shippingAddress.zip.toString());
      }
      if (shippingAddress.country != null && shippingAddress.country.toString().isNotEmpty) {
        parts.add(shippingAddress.country.toString());
      }
    } else {
      if (shippingAddress.line1 != null && shippingAddress.line1!.isNotEmpty) {
        parts.add(shippingAddress.line1!);
      }
      if (shippingAddress.city != null && shippingAddress.city!.isNotEmpty) {
        parts.add(shippingAddress.city!);
      }
      if (shippingAddress.zip != null &&
          shippingAddress.zip!.isNotEmpty &&
          shippingAddress.zip != '00000') {
        parts.add(shippingAddress.zip!);
      }
      if (shippingAddress.country != null && shippingAddress.country!.isNotEmpty) {
        parts.add(shippingAddress.country!);
      }
    }

    return parts.join(', ');
  }

  Widget _buildStatusContainer(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontFamily: "Mulish",
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Colors.black87),
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

  void _showDeliveryTimeDialog(Order order) {
    if (order.approvalStatus != 2) return; // Only for accepted orders

    DateTime currentDeliveryTime;
    try {
      currentDeliveryTime = order.deliveryTime != null && order.deliveryTime!.isNotEmpty
          ? DateTime.parse(order.deliveryTime!)
          : DateTime.now().add(const Duration(minutes: 30));
    } catch (e) {
      currentDeliveryTime = DateTime.now().add(const Duration(minutes: 30));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime updatedTime = currentDeliveryTime;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('update_delivery_time'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(updatedTime),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            updatedTime = updatedTime.subtract(const Duration(minutes: 15));
                          });
                        },
                        icon: const Icon(Icons.remove_circle, size: 40, color: Colors.red),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            updatedTime = updatedTime.add(const Duration(minutes: 15));
                          });
                        },
                        icon: const Icon(Icons.add_circle, size: 40, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr),
                ),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    print('order id is ${order.id}');
                    await _updateDeliveryTime(
                        order, updatedTime);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color(0xff14b65f)
                    ),
                    child: Text('saved'.tr, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateDeliveryTime(Order order, DateTime newTime) async {
    if (!mounted) return;

    bool loaderShown = false;
    Timer? timeoutTimer;

    try {
      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      Get.dialog(
        Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
        barrierDismissible: false,
      );
      loaderShown = true;

      timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          try {
            Get.back();
            loaderShown = false;
          } catch (e) {
            // Handle error
          }
        }
      });

      Map<String, dynamic> jsonData = {
        "order_status": 2,
        "approval_status": 2,
        "delivery_time": newTime.toIso8601String()
        //"delivery_time": "2025-12-07T00:15:00.000"
      };
      print('map value is $jsonData');
      final result = await ApiRepo().orderAcceptDecline(
          bearerKey!,
          jsonData,
          order.id ?? 0
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('Request timeout', const Duration(seconds: 6));
        },
      );

      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
      }

      if (!mounted) return;

      if (result.code == null) {
        app.appController.updateOrder(result);
        print('✅ Delivery time updated successfully');
      } else {
        print('❌ Failed to update delivery time: ${result.mess}');
      }
    } on TimeoutException catch (e) {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      print('⚠️ Request timed out');
    } catch (e) {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      print('❌ Error updating delivery time: $e');
    }
  }
  @override
  bool get wantKeepAlive => true;

  Future<void> getNewOrder(int orderID) async {
    try {
      final result = await ApiRepo().getNewOrderData(bearerKey!, orderID);
      app.appController.addNewOrder(result);

      await getLiveSaleReportWithoutLoader();
    } catch (e) {
      Log.loga("OrderScreen", "getNewOrder Api:: e >>>>> $e");
      showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
    }
  }

  Future<bool> syncLocalPosOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var StoreId = prefs.getString(valueShared_STORE_KEY);

    try {
      final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(StoreId!);

      if (unsyncedOrders.isEmpty) {
        print('ℹ️ No orders to sync');
        return false;
      }

      print('📦 Found ${unsyncedOrders.length} unsynced orders');

      // ✅ Store order IDs for later verification
      List<int> localOrderIds = unsyncedOrders.map((o) => o['id'] as int).toList();
      print('📋 Local Order IDs to sync: $localOrderIds');

      List<Map<String, dynamic>> ordersToSync = [];
      for (var dbOrder in unsyncedOrders) {
        final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
        if (orderDetails != null) {
          ordersToSync.add(await _buildSyncOrderMap(orderDetails));
        }
      }

      print('📤 Syncing ${ordersToSync.length} orders');

      SyncLocalOrder model = await CallService().syncLocalOrder(ordersToSync);

      print('📡 API Response - Status: ${model.status}');
      print('📡 API Response - Synced IDs from server: ${model.syncedOrderIds}');

      if (model.status == 'ok' && model.syncedOrderIds != null && model.syncedOrderIds!.isNotEmpty) {

        // ✅ Mark ALL local orders as synced (not just the ones from server response)
        for (int localOrderId in localOrderIds) {
          print('🔄 Marking order $localOrderId as synced...');
          await DatabaseHelper().markOrderAsSynced(localOrderId);
        }

        // ✅ Wait a moment for database to update
        await Future.delayed(const Duration(milliseconds: 100));

        // ✅ Verify orders are marked as synced
        final stillUnsynced = await DatabaseHelper().getUnsyncedOrders(StoreId);
        print('🔍 After marking - Still unsynced orders: ${stillUnsynced.length}');

        // ✅ Clear local orders list immediately
        setState(() {
          _localOrders.clear();
          _isSyncingLocalOrders = false;
        });

        // ✅ Reload from database
        await _loadAndSyncLocalOrders();

        // ✅ Refresh server orders
        await getOrdersWithoutLoader(bearerKey, StoreId);

        print('✅ Successfully synced ${ordersToSync.length} orders');

        return true;
      } else {
        print('❌ Sync failed - Status: ${model.status}');
        return false;
      }

    } catch (e) {
      print('❌ Syncing error: $e');
      return false;
    }
  }

  Future<void> _autoSyncLocalOrders() async {
    if (!mounted) return; // ✅ Check if widget is mounted

    try {
      final storeId = sharedPreferences.getString(valueShared_STORE_KEY);
      if (storeId == null || storeId.isEmpty) return;

      final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeId);
      print('📊 Checking unsynced orders: ${unsyncedOrders.length} found');

      if (unsyncedOrders.isEmpty) {
        print('✅ No orders to auto-sync');
        return;
      }

      List<Map<String, dynamic>> ordersToSync = [];

      for (var dbOrder in unsyncedOrders) {
        final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
        if (orderDetails != null) {
          ordersToSync.add(await _buildSyncOrderMap(orderDetails));
        }
      }

      if (ordersToSync.isNotEmpty) {
        print('📤 Auto-syncing ${ordersToSync.length} orders');

        var result = await CallService().syncLocalOrder(ordersToSync);

        if (result.status == 'ok' && result.syncedOrderIds != null && result.syncedOrderIds!.isNotEmpty) {
          print('✅ Auto-sync success - Synced IDs: ${result.syncedOrderIds}');

          for (var dbOrder in unsyncedOrders) {
            await DatabaseHelper().markOrderAsSynced(dbOrder['id'] as int);
          }

          // ✅ Only call API, don't refresh UI
          await getOrdersWithoutLoaderSilent(bearerKey, storeId);

          // ✅ Update local orders list
          if (mounted) {
            final newUnsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeId);
            setState(() {
              if (newUnsyncedOrders.isEmpty) {
                _localOrders.clear();
                _isSyncingLocalOrders = false;
              }
            });
          }

          print('✅ Auto-sync completed: ${ordersToSync.length} orders synced');
        } else {
          print('❌ Auto-sync failed - Status: ${result.status}');
        }
      }
    } catch (e) {
      print('❌ Auto-sync error: $e');
    }
  }

  Future<Map<String, dynamic>> _buildSyncOrderMap(
      Map<String, dynamic> orderDetails) async {

    final orderData = orderDetails['order'] as Map<String, dynamic>;
    final itemsData = orderDetails['items'] as List<dynamic>;
    final paymentData = orderDetails['payment'] as Map<String, dynamic>?;
    final addressData =
    orderDetails['shipping_address'] as Map<String, dynamic>?;

    int storedMillis = orderData['created_at'] as int;

    // ✅ STEP 1: millis → UTC
    DateTime utcTime = DateTime.fromMillisecondsSinceEpoch(
      storedMillis,
      isUtc: true,
    );

    // ✅ STEP 2: UTC → Germany (DST auto if device Germany me hai)
    DateTime germanTime = utcTime.toLocal();

    String isoTimestamp = germanTime.toIso8601String();

    print('🕐 Stored millis (UTC): $storedMillis');
    print('🕐 Germany ISO time: $isoTimestamp');

    // ✅ Build items
    List<Map<String, dynamic>> items = [];

    for (var item in itemsData) {
      List<Map<String, dynamic>> toppings = [];

      if (item['toppings'] != null &&
          item['toppings'] is List &&
          (item['toppings'] as List).isNotEmpty) {
        for (var t in item['toppings']) {
          toppings.add({
            'topping_id': t['id'] ?? 0,
            'quantity': t['topping_quantity'] ?? 1,
          });
        }
      }

      items.add({
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'unit_price': (item['unit_price'] as num?)?.toInt() ?? 0,
        'note': item['note'] ?? '',
        'variant_id': item['variant_id'] ?? 0,
        'toppings': toppings,
      });
    }

    final orderMap = {
      'client_uuid': orderData['client_uuid'],
      'store_id': int.tryParse(orderData['store_id'].toString()) ?? 0,
      'order_type': orderData['order_type'] ?? 3,
      'created_at': isoTimestamp, // ✅ GERMANY TIME
      'note': orderData['note'] ?? '',
      'items': items,
      'payment': {
        'payment_method': 'cash',
        'status': 'paid',
        'amount': (paymentData?['amount'] as num?)?.toInt() ?? 0,
        'order_id': 0,
      },
      'customer': {
        "customer_name":
        addressData?['customer_name'] ?? 'Walk-in Customer',
        "phone": addressData?['phone'],
        "email": orderData['email'],
        "line1": addressData?['line1'],
        "city": addressData?['city'],
        "zip": addressData?['zip'],
        "country": addressData?['country']
      },
    };

    print('🔍 Built order map: ${jsonEncode(orderMap)}');
    return orderMap;
  }

}

class SalesCacheHelper {
  static const _salesDataKey = 'cached_sales_data';
  static const _lastDateKey = 'cached_sales_date';
  static const _orderDateKey = 'cached_order_date';
  static const _storeIdKey = 'cached_store_id';

  static String _getUserSpecificKey(String baseKey, String? storeId) {
    if (storeId != null && storeId.isNotEmpty) {
      return "${baseKey}_store_$storeId";
    }
    return baseKey;
  }

  static Future<void> saveSalesData(Map<String, dynamic> salesData) async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    final storeSpecificSalesKey =
    _getUserSpecificKey(_salesDataKey, currentStoreId);
    final storeSpecificDateKey =
    _getUserSpecificKey(_lastDateKey, currentStoreId);

    await prefs.setString(storeSpecificSalesKey, jsonEncode(salesData));
    await prefs.setString(storeSpecificDateKey, todayString);
    await prefs.setString(_storeIdKey, currentStoreId ?? '');
  }

  static Future<Map<String, dynamic>?> loadSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);
    final cachedStoreId = prefs.getString(_storeIdKey);

    final storeSpecificSalesKey =
    _getUserSpecificKey(_salesDataKey, currentStoreId);
    final storeSpecificDateKey =
    _getUserSpecificKey(_lastDateKey, currentStoreId);

    final cachedDate = prefs.getString(storeSpecificDateKey);
    final cachedData = prefs.getString(storeSpecificSalesKey);

    if (cachedDate == todayString &&
        cachedStoreId == currentStoreId &&
        cachedData != null &&
        currentStoreId != null &&
        currentStoreId.isNotEmpty) {
      return jsonDecode(cachedData);
    }

    return null;
  }

  static Future<void> clearSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    if (currentStoreId != null) {
      final storeSpecificSalesKey =
      _getUserSpecificKey(_salesDataKey, currentStoreId);
      final storeSpecificDateKey =
      _getUserSpecificKey(_lastDateKey, currentStoreId);

      await prefs.remove(storeSpecificSalesKey);
      await prefs.remove(storeSpecificDateKey);
    }

    await prefs.remove(_salesDataKey);
    await prefs.remove(_lastDateKey);
    await prefs.remove(_storeIdKey);
  }

  static Future<void> clearOrderDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderDateKey);
  }

  static Future<void> saveOrderDate() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_orderDateKey, todayString);
  }
}
