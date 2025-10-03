import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/Socket/socket_service.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/DailySalesReport.dart';
import 'package:food_app/models/UserMe.dart';
import 'package:food_app/ui/OrderDetailEnglish.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/Store.dart';
import '../models/today_report.dart' hide TaxBreakdown;
import 'LoginScreen.dart';

class OrderScreenNew extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreenNew> with TickerProviderStateMixin,
    AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
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
  String salesDelivery = '0',
      totalSales = '0',
      totalOrder = '0',
      totalTax = '0',
      cashTotal = '0',
      online = '0',
      net = '0',
      discount = '0',
      deliveryFee = '0',
      cashMethod = '0',
      delivery = '0',
      pickUp = '0',
      dineIn = '0',
      pending = '0',
      accepted = '0',
      declined = '0',
      tax19 = '0',
      tax7 = '0';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("Callingapp When refresh reumed 1111 ");

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // ✅ Start internet monitoring
    _startInternetMonitoring();

    // ✅ Wait for the frame to complete before calling initVar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initVar();
    });
  }

  Future<void> _checkAndClearOldData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString('cached_sales_date');
    final cachedOrderDate = prefs.getString('cached_order_date');
    final cachedStoreId =
        prefs.getString('cached_store_id'); // âœ… NEW: Track store ID
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    // âœ… Clear sales data if date changed OR store ID changed
    if (cachedDate != today || cachedStoreId != currentStoreId) {
      print("ðŸ“† Date or Store ID changed. Clearing old sales data.");
      await SalesCacheHelper.clearSalesData();

      // âœ… Clear current report data to prevent cross-user contamination
      setState(() {
        _currentDateReport = null;
        reportsss = DailySalesReport();
        reportList.clear();
      });

      // âœ… Save new store ID for tracking
      if (currentStoreId != null) {
        await prefs.setString('cached_store_id', currentStoreId);
      }
    }

    // âœ… Clear order list if date changed OR store ID changed
    if (cachedOrderDate != today || cachedStoreId != currentStoreId) {
      print("ðŸ“† Date or Store ID changed. Clearing old order list.");
      setState(() {
        app.appController.clearOrders(); // This will reset order list to empty
      });
      await prefs.setString('cached_order_date', today);
      print("âœ… Order list reset for new day/user: $today / $currentStoreId");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initVarTimeoutTimer?.cancel();
    _internetCheckTimer?.cancel();
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

  Future<void> initVar() async {
    print("Callingapp When refresh resumed 3333");
    _initVarTimeoutTimer?.cancel();

    // Close any existing dialogs first
    if (Get.isDialogOpen ?? false) {
      try {
        Get.back();
        print("Closed existing dialog in initVar");
      } catch (e) {
        print("Error closing existing dialog: $e");
      }
    }

    setState(() {
      isLoading = true;
    });

    Timer? timeoutTimer;

    try {
      // Set 10 second timeout for entire initVar process
      timeoutTimer = Timer(Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            isLoading = false;
            _isInitialLoading = false;
          });
          print("initVar timeout reached - forcing loader close");
        }
      });

      setState(() {
        hasInternet = true;
      });

      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
          print("✅ Logout dialog closed in initVar");
        } catch (e) {
          print("Error closing dialog in initVar: $e");
        }
      }

      sharedPreferences = await SharedPreferences.getInstance();
      bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
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
      print("🆔 DEBUG - initVar storeID: '$storeID'");

      if (storeID != null && storeID.isNotEmpty && !_isErrorCode(storeID)) {
        print("✅ Using existing valid store ID: $storeID");

        await getStoredta(bearerKey!);
        await _restoreUserSpecificData(storeID);
        await getOrdersWithoutLoader(bearerKey, storeID);

        if (bearerKey != null && bearerKey!.isNotEmpty) {
          print("📌 Initializing socket with store ID: $storeID");
          _initializeSocket();
        }
      } else {
        print("⚠️ Invalid or no store ID found, getting user data first");
        if (storeID != null && _isErrorCode(storeID)) {
          await sharedPreferences.remove(valueShared_STORE_KEY);
          print("🗑️ Cleared error code store ID: $storeID");
        }
        await getStoreUserMeDataWithoutLoader(bearerKey);
      }

      getCurrentDateReport();
      _loadCachedSalesData();
      _startNoOrderTimer();
      await getLiveSaleReportWithoutLoader();
    } catch (e) {
      print("Error in initVar: $e");
    } finally {
      // Always close loader and cancel timeout
      timeoutTimer?.cancel();
      _initVarTimeoutTimer?.cancel();

      if (mounted) {
        setState(() {
          isLoading = false;
          _isInitialLoading = false;
        });
      }
      print("initVar completed - loader closed");
    }
  }

  bool _isErrorCode(String? value) {
    if (value == null || value.isEmpty) return false;

    int? code = int.tryParse(value);
    if (code == null) return false;

    // Common HTTP error codes
    List<int> errorCodes = [400, 401, 403, 404, 500, 502, 503, 504];
    return errorCodes.contains(code);
  }

  Future<void> _offlineLogout() async {
    bool loaderShown = false;
    Timer? timeoutTimer;

    try {
      // Close any existing loader first
      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
          print("Closed existing dialog before logout");
        } catch (e) {
          print("Error closing existing dialog: $e");
        }
      }

      // Show loader
      Get.dialog(
        Center(
            child: Lottie.asset(
          'assets/animations/burger.json',
          width: 150,
          height: 150,
          repeat: true,
        )),
        barrierDismissible: false,
      );
      loaderShown = true;

      // Set timeout for logout process - maximum 8 seconds
      timeoutTimer = Timer(Duration(seconds: 8), () {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          try {
            Get.back();
            loaderShown = false;
            print("⏰ Forced logout loader close due to timeout");
          } catch (e) {
            print("Error force closing logout loader: $e");
          }
        }
        // Force navigate to login even if timeout
        Get.offAll(() => LoginScreen());
      });

      print("🚪 Starting offline logout process...");

      // STEP 1: Save IP data before clearing everything
      await _preserveUserIPDataOffline();

      // STEP 2: Force complete logout cleanup
      await _forceCompleteLogoutCleanupOffline();

      // STEP 3: Clear app controller
      app.appController.clearOnLogout();

      // STEP 4: Disconnect socket
      await _disconnectSocketOffline();

      // Close loader before navigation
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
        print("✅ Logout loader closed before navigation");
      }

      // STEP 5: Navigate to login with complete reset
      Get.offAll(() => LoginScreen());

      print("✅ Offline logout completed successfully");
    } catch (e) {
      print("❌ Error in offline logout: $e");
    } finally {
      // Always cancel timeout
      timeoutTimer?.cancel();

      // Ensure loader is closed
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
          print("✅ Logout loader closed in finally block");
        } catch (e) {
          print("Error closing logout loader in finally: $e");
        }
      }

      // Ensure navigation happens even if there's an error
      if (!Get.currentRoute.contains('LoginScreen')) {
        Get.offAll(() => LoginScreen());
      }
    }
  }

  Future<void> _preserveUserIPDataOffline() async {
    try {
      print("💾 Preserving IP data for current user (offline)...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentStoreId = prefs.getString(valueShared_STORE_KEY);

      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        // Save current IP data with store ID prefix
        String userPrefix = "user_${currentStoreId}_";

        // Preserve local printer IPs
        for (int i = 0; i < 5; i++) {
          String? currentIP = prefs.getString('printer_ip_$i');
          if (currentIP != null && currentIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
            print("💾 Saved ${userPrefix}printer_ip_$i: $currentIP");
          }
        }

        // Preserve remote printer IPs
        for (int i = 0; i < 5; i++) {
          String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
          if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
            await prefs.setString(
                '${userPrefix}printer_ip_remote_$i', currentRemoteIP);
            print(
                "💾 Saved ${userPrefix}printer_ip_remote_$i: $currentRemoteIP");
          }
        }

        // Preserve selected indices
        int? selectedIndex = prefs.getInt('selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt(
              '${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
        }

        // Preserve toggle settings
        bool? autoOrderAccept = prefs.getBool('auto_order_accept');
        if (autoOrderAccept != null) {
          await prefs.setBool(
              '${userPrefix}auto_order_accept', autoOrderAccept);
        }

        bool? autoOrderPrint = prefs.getBool('auto_order_print');
        if (autoOrderPrint != null) {
          await prefs.setBool('${userPrefix}auto_order_print', autoOrderPrint);
        }

        bool? autoRemoteAccept = prefs.getBool('auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool(
              '${userPrefix}auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint = prefs.getBool('auto_order_remote_print');
        if (autoRemotePrint != null) {
          await prefs.setBool(
              '${userPrefix}auto_order_remote_print', autoRemotePrint);
        }

        print("✅ IP data preserved for store: $currentStoreId (offline)");
      } else {
        print("⚠️ No store ID found, cannot preserve IP data (offline)");
      }
    } catch (e) {
      print("❌ Error preserving IP data (offline): $e");
    }
  }

  Future<void> _forceCompleteLogoutCleanupOffline() async {
    try {
      print("🧹 Starting complete offline logout cleanup...");

      // ✅ Multiple cleanup attempts to ensure complete removal
      for (int attempt = 0; attempt < 3; attempt++) {
        print("🔥 Cleanup attempt ${attempt + 1}/3 (offline)");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Clear only authentication-related data (NOT IP data)
        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,
          // ✅ Clear backup IP keys that are created by PrinterSettingsScreen
          'printer_ip_backup',
          'printer_ip_0_backup',
          'last_save_timestamp',
          // ✅ Clear current session IP data (will be restored from user-prefixed data on next login)
          'printer_ip_0',
          'printer_ip_remote_0',
          'selected_ip_index',
          'selected_ip_remote_index',
          // ✅ Clear current session auto settings (will be restored from user-prefixed data)
          'auto_order_accept',
          'auto_order_print',
          'auto_order_remote_accept',
          'auto_order_remote_print',
          // ✅ Clear cached data
          'cached_sales_date',
          'cached_order_date',
          'cached_store_id',
          'cached_store_name',
          'store_name',
          valueShared_STORE_NAME,
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(Duration(milliseconds: 20));
          print("🗑️ Removed: $key");
        }

        // ✅ Also clear all printer IP keys (0-4) to ensure complete cleanup
        for (int i = 0; i < 5; i++) {
          await prefs.remove('printer_ip_$i');
          await prefs.remove('printer_ip_remote_$i');
        }

        // ✅ Clear sales cache data
        await SalesCacheHelper.clearSalesData();

        // ✅ Force multiple reloads to ensure changes are committed
        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));
        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));

        // ✅ Verify cleanup for this attempt
        String? testToken = prefs.getString(valueShared_BEARER_KEY);
        String? testStoreKey = prefs.getString(valueShared_STORE_KEY);
        if (testToken == null && testStoreKey == null) {
          print("✅ Offline cleanup attempt ${attempt + 1}: SUCCESS");
        } else {
          print(
              "⚠️ Offline cleanup attempt ${attempt + 1}: Data still exists, retrying...");
        }
      }

      // ✅ Final verification
      SharedPreferences finalPrefs = await SharedPreferences.getInstance();
      await finalPrefs.reload();
      String? finalToken = finalPrefs.getString(valueShared_BEARER_KEY);
      String? finalStoreKey = finalPrefs.getString(valueShared_STORE_KEY);

      if (finalToken == null && finalStoreKey == null) {
        print(
            "✅ Complete offline logout cleanup SUCCESS - All auth data removed");
      } else {
        print("❌ Offline logout cleanup FAILED - Auth data still exists");
      }
    } catch (e) {
      print("❌ Error in complete offline logout cleanup: $e");
    }
  }

  Future<void> _disconnectSocketOffline() async {
    try {
      print("🔌 Disconnecting socket (offline)...");
      _socketService.disconnect();
      await Future.delayed(Duration(milliseconds: 100));
      print("✅ Socket disconnected (offline)");
    } catch (e) {
      print("⚠️ Error disconnecting socket (offline): $e");
    }
  }

  void _showLogoutDialog() {
    if (_isDialogShowing || !mounted) return;

    _isDialogShowing = true;
    print("📱 Showing logout dialog");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.red),
                SizedBox(width: 8),
                Text("Connection Error"),
              ],
            ),
            content: Text(
                "Cannot connect to server. Please logout and login again to continue."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                  // ✅ Call offline logout instead of API logout
                  _offlineLogout();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Logout", style: TextStyle(color: Colors.white)),
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
    _internetCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnection = connectivityResult != ConnectivityResult.none;

      if (hasConnection && !hasInternet) {
        // ✅ Internet restored
        setState(() {
          hasInternet = true;
        });

        // ✅ NEW: Force close logout dialog if it's showing
        if (_isDialogShowing) {
          try {
            Navigator.of(context).pop(); // Use Navigator instead of Get.back()
            _isDialogShowing = false;
            print("✅ Logout dialog closed - Internet restored");
          } catch (e) {
            print("Error closing dialog: $e");
          }
        }

        print("Internet restored, refreshing data...");
        initVar(); // Refresh data
      }
    });
  }

  Future<void> getLiveSaleReportWithoutLoader() async {
    try {
      print("🔥 Starting getLiveSaleReport...");

      if (bearerKey == null || bearerKey!.isEmpty) {
        print("❌ Bearer token is null or empty");
        _setEmptyValues();
        return;
      }

      // Try API call with explicit error handling
      GetTodayReport model = await CallService().getLiveSaleData();

      // If we reach here, API call was successful
      print("✅ API call completed successfully");
      setState(() {
        hasInternet = true; // Set internet to true on success
      });
      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
          print("✅ Logout dialog closed - API successful");
        } catch (e) {
          print("Error closing dialog after API: $e");
        }
      }
      if (model.code != null && model.code != 200) {
        print("⚠️ API returned code: ${model.code}, message: ${model.mess}");
        _setEmptyValues();
        return;
      }

      // Update UI with data
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
    } catch (e, stackTrace) {
      print('❌ Caught error in getLiveSaleReport: $e');
      print('📋 Stack trace: $stackTrace');

      // Check if it's a network error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('API call failed with status null')) {
        print("🌐 Network error detected, setting hasInternet = false");
        setState(() {
          hasInternet = false;
        });

        // Show popup after a small delay
        Future.delayed(Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      }

      _setEmptyValues();
    }
  }

  Future<void> _restoreUserSpecificData(String currentStoreId) async {
    try {
      print("ðŸ”„ Checking for user-specific data: $currentStoreId");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userPrefix = "user_${currentStoreId}_";

      // Check if user-specific data exists
      String? testKey = prefs.getString('${userPrefix}printer_ip_0');
      if (testKey != null) {
        print("âœ… Found user-specific data, restoring...");

        // Restore local printer IPs
        for (int i = 0; i < 5; i++) {
          String? savedIP = prefs.getString('${userPrefix}printer_ip_$i');
          if (savedIP != null && savedIP.isNotEmpty) {
            await prefs.setString('printer_ip_$i', savedIP);
            print("ðŸ”„ Restored printer_ip_$i: $savedIP");
          }
        }

        // Restore remote printer IPs
        for (int i = 0; i < 5; i++) {
          String? savedRemoteIP =
              prefs.getString('${userPrefix}printer_ip_remote_$i');
          if (savedRemoteIP != null && savedRemoteIP.isNotEmpty) {
            await prefs.setString('printer_ip_remote_$i', savedRemoteIP);
            print("ðŸ”„ Restored printer_ip_remote_$i: $savedRemoteIP");
          }
        }

        // Restore other settings...
        int? selectedIndex = prefs.getInt('${userPrefix}selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex =
            prefs.getInt('${userPrefix}selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt('selected_ip_remote_index', selectedRemoteIndex);
        }

        // Restore toggle settings
        bool? autoOrderAccept = prefs.getBool('${userPrefix}auto_order_accept');
        if (autoOrderAccept != null) {
          await prefs.setBool('auto_order_accept', autoOrderAccept);
        }

        bool? autoOrderPrint = prefs.getBool('${userPrefix}auto_order_print');
        if (autoOrderPrint != null) {
          await prefs.setBool('auto_order_print', autoOrderPrint);
        }

        bool? autoRemoteAccept =
            prefs.getBool('${userPrefix}auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool('auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint =
            prefs.getBool('${userPrefix}auto_order_remote_print');
        if (autoRemotePrint != null) {
          await prefs.setBool('auto_order_remote_print', autoRemotePrint);
        }

        print("âœ… User-specific data restored for: $currentStoreId");
      } else {
        print("â„¹ï¸ No user-specific data found for: $currentStoreId");
        // Clear any existing general data to prevent cross-user contamination
        await _clearGeneralIPData();
      }
    } catch (e) {
      print("âŒ Error restoring user-specific data: $e");
    }
  }

  Future<void> _clearGeneralIPData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Clear general printer settings
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

      print("ðŸ§¹ Cleared general IP data to prevent cross-user contamination");
    } catch (e) {
      print("âŒ Error clearing general IP data: $e");
    }
  }

  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID == null || storeID.isEmpty) {
        print("❌ DEBUG - Store ID is null or empty, cannot fetch store data");
        return null;
      }

      print("🔄 Fetching store data for ID: $storeID");
      final result = await ApiRepo().getStoreData(bearerKey, storeID);
      print("✅ API call completed successfully");
      setState(() {
        hasInternet = true; // Set internet to true on success
      });
      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
          print("✅ Logout dialog closed - API successful");
        } catch (e) {
          print("Error closing dialog after API: $e");
        }
      }
      // ✅ Check if result is an error response by checking for 'code' property
      if (result.code != null) {
        print(
            "❌ API returned error - Code: ${result.code}, Message: ${result.mess}");

        // Handle network errors specifically
        if (result.code == 500 || result.code! >= 500) {
          print("🌐 Server error detected, setting hasInternet = false");
          setState(() {
            hasInternet = false;
          });
          Future.delayed(Duration(milliseconds: 500), () {
            _showLogoutDialog();
          });
        }
        return null;
      }

      // ✅ If no error code, this is valid store data
      if (result.name != null && result.name!.isNotEmpty) {
        String fetchedStoreName = result.name!;
        // ✅ Keep using original store ID, don't use result.code for store ID
        String fetchedStoreId =
            storeID; // Use original store ID from SharedPreferences

        setState(() {
          storeName = fetchedStoreName;
          dynamicStoreId = fetchedStoreId;
        });

        // ✅ Save store name to SharedPreferences
        await sharedPreferences.setString('store_name', fetchedStoreName);
        await sharedPreferences.setString(
            valueShared_STORE_NAME, fetchedStoreName);
        // ✅ Don't overwrite store ID - keep the original one

        print("✅ DEBUG - Store name saved: '$fetchedStoreName'");
        print("✅ DEBUG - Using original Store ID: '$fetchedStoreId'");
        return storeName;
      } else {
        print("⚠️ Invalid store data received - name is null or empty");
        return null;
      }
    } catch (e) {
      print("❌ DEBUG - Exception in getStoredta: $e");

      // ✅ Handle network exceptions
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        print(
            "🌐 Network exception in getStoredta, setting hasInternet = false");
        setState(() {
          hasInternet = false;
        });
        Future.delayed(Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      }

      return null;
    }
  }

  Future<void> getStoreUserMeDataWithoutLoader(String? bearerKey) async {
    try {
      print("🔄 Fetching user data...");
      final result = await ApiRepo().getUserMe(bearerKey);
      print("✅ API call completed successfully");
      setState(() {
        hasInternet = true; // Set internet to true on success
      });
      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
          print("✅ Logout dialog closed - API successful");
        } catch (e) {
          print("Error closing dialog after API: $e");
        }
      }
      // ✅ Check if result is an error response by checking for 'code' property
      if (result.code != null) {
        print(
            "❌ getUserMe API returned error - Code: ${result.code}, Message: ${result.mess}");

        // Handle network/server errors specifically
        if (result.code == 500 || result.code! >= 500) {
          print("🌐 Server error in getUserMe, setting hasInternet = false");
          setState(() {
            hasInternet = false;
          });
          Future.delayed(Duration(milliseconds: 500), () {
            _showLogoutDialog();
          });
          return;
        } else {
          showSnackbar("error".tr, result.mess ?? "failed".tr);
          return;
        }
      }

      // ✅ If no error code, validate the actual user data
      if (result.store_id != null && result.store_id! > 0) {
        setState(() {
          userMe = result;
        });

        String newStoreId = result.store_id.toString();
        await sharedPreferences.setString(valueShared_STORE_KEY, newStoreId);
        print("✅ Store ID saved from UserMe API: $newStoreId");

        await getStoredta(bearerKey!);
        await _restoreUserSpecificData(newStoreId);
        await getOrdersWithoutLoader(bearerKey, newStoreId);

        if (bearerKey != null && bearerKey!.isNotEmpty) {
          print("🔌 Initializing socket after getting user data");
          _initializeSocket();
        }
      } else {
        print("❌ Invalid store_id in user data: ${result.store_id}");
          showSnackbar("error".tr, "invalid_user".tr);
      }
    } catch (e) {
      print("❌ Exception in getUserMe: $e");
      Log.loga(title, "getUserMe Api:: e >>>>> $e");

      // ✅ Handle network errors properly
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        print("🌐 Network exception in getUserMe, setting hasInternet = false");
        setState(() {
          hasInternet = false;
        });

        Future.delayed(Duration(milliseconds: 500), () {
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

      // If we reach here, API was successful
      setState(() {
        hasInternet = true;
      });
      if (_isDialogShowing) {
        try {
          Navigator.of(context).pop();
          _isDialogShowing = false;
          print("✅ Logout dialog closed - API successful");
        } catch (e) {
          print("Error closing dialog after API: $e");
        }
      }
      // ✅ Check if result contains error responses
      if (result.isNotEmpty) {
        // Check first item for error
        final firstItem = result.first;
        if (firstItem.code != null) {
          print("❌ Orders API returned error - Code: ${firstItem.code}");
          if (firstItem.code == 500 || firstItem.code! >= 500) {
            setState(() {
              hasInternet = false;
            });
            Future.delayed(Duration(milliseconds: 500), () {
              _showLogoutDialog();
            });
          }
          _startNoOrderTimer();
          return;
        }

        // Valid orders received
        setState(() {
          app.appController.setOrders(result);
        });
        _stopNoOrderTimer();
      } else {
        // No orders but API was successful
        setState(() {
          app.appController.setOrders([]);
        });
        _startNoOrderTimer();
      }
    } catch (e) {
      print("❌ Error in getOrdersWithoutLoader: $e");

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        print("🌐 Network error in getOrders, setting hasInternet = false");
        setState(() {
          hasInternet = false;
        });

        Future.delayed(Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      } else {
        showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
      }
    }
  }

  Future<String?> getStoreNameFallback() async {
    try {
      // Try to get from previous session
      String? cachedName = sharedPreferences.getString('last_store_name');
      if (cachedName != null && cachedName.isNotEmpty) {
        print("âœ… Using cached store name: $cachedName");
        return cachedName;
      }

      return "Default Restaurant";
    } catch (e) {
      print("âŒ Fallback failed: $e");
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
            await sharedPreferences.setString(
                'cached_store_name', result.name.toString());
            print("âœ… Store data pre-loaded and cached");
          }
        }
      } catch (e) {
        print("âŒ Store data preload failed: $e");
      }
    }
  }

  void _initializeSocket() {
    print("ðŸ”¥ Starting socket initialization");

    // âœ… First disconnect any existing socket to prevent cross-contamination
    _socketService.disconnect();

    // âœ… Clear any existing socket data
    setState(() {
      _isLiveDataActive = false;
      _lastUpdateTime = null;
      _hasSocketData = false; // Reset socket data flag
    });

    // Get dynamic store ID from SharedPreferences
    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

    print("ðŸ†” Raw storeID from SharedPreferences: '$storeID'");
    print("ðŸ†” storeID type: ${storeID.runtimeType}");
    print("ðŸ†” storeID isEmpty: ${storeID?.isEmpty}");
    print("ðŸ†” storeID isNull: ${storeID == null}");

    int dynamicStoreId;

    if (storeID != null && storeID.isNotEmpty) {
      int? parsedId = int.tryParse(storeID);
      print("ðŸ†” Parse attempt result: $parsedId");

      if (parsedId != null) {
        dynamicStoreId = parsedId;
        print("âœ… Successfully parsed storeID: $dynamicStoreId");
      } else {
        print("âŒ Parse failed for storeID: '$storeID'");
        print(
            "âŒ CRITICAL: Cannot parse store ID, socket connection may fail!");
        return;
      }
    } else {
      print("âŒ Store ID not found or empty in SharedPreferences");
      if (userMe != null && userMe.store_id != null) {
        dynamicStoreId = userMe.store_id!;
        print("âœ… Using userMe.store_id: $dynamicStoreId");
        sharedPreferences.setString(
            valueShared_STORE_KEY, dynamicStoreId.toString());
      } else {
        print("âŒ No store ID available anywhere, cannot connect socket");
        return;
      }
    }

    print("ðŸ†” Final store ID for socket: $dynamicStoreId");

    // âœ… Store-specific socket callbacks
    _socketService.onSalesUpdate = (data) {
      print('ðŸ“Š Sales update received for store $dynamicStoreId: $data');

      // âœ… Verify this data is for current store
      if (data['store_id'] != null &&
          data['store_id'].toString() != dynamicStoreId.toString()) {
        print(
            'âš ï¸ Ignoring sales data for different store: ${data['store_id']}');
        return;
      }

      _handleSalesUpdate(data, isFromSocket: true);
    };

    _socketService.onConnected = () {
      print(
          'ðŸ”¥ Socket connected for store $dynamicStoreId - Live data active');
      setState(() => _isLiveDataActive = true);
    };

    _socketService.onDisconnected = () {
      print(
          'â„ï¸ Socket disconnected for store $dynamicStoreId - Live data inactive');
      if (mounted) {
        setState(() {
          _isLiveDataActive = false;
          _hasSocketData = false; // Reset socket data flag when disconnected
        });
      }
    };

    _socketService.onNewOrder = (data) {
      print('ðŸ†• New order received for store $dynamicStoreId: $data');

      // âœ… Verify this order is for current store
      if (data['store_id'] != null &&
          data['store_id'].toString() != dynamicStoreId.toString()) {
        print('âš ï¸ Ignoring order for different store: ${data['store_id']}');
        return;
      }

      _refreshCurrentDayData();
    };

    try {
      print("ðŸ”Œ Attempting to connect socket:");
      print("   Bearer: ${bearerKey?.substring(0, 20)}...");
      print("   Store ID: $dynamicStoreId");

      _socketService.connect(bearerKey!, storeId: dynamicStoreId);
    } catch (e) {
      print("âŒ Socket connection failed: $e");
    }
  }

  Future<void> getLiveSaleReport() async {
    Timer? timeoutTimer;
    bool loaderShown = false;

    try {
      print("🔥 Starting getLiveSaleReport...");

      if (bearerKey == null || bearerKey!.isEmpty) {
        print("❌ Bearer token is null or empty");
        _setEmptyValues();
        return;
      }

      // Close any existing loaders first
      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
          print("Closed existing loader before starting new one");
        } catch (e) {
          print("Error closing existing loader: $e");
        }
      }

      // Show loader
      Get.dialog(
        Center(
            child: Lottie.asset(
          'assets/animations/burger.json',
          width: 150,
          height: 150,
          repeat: true,
        )),
        barrierDismissible: false,
      );
      loaderShown = true;

      // Set timeout timer for loader - force close after 8 seconds
      timeoutTimer = Timer(Duration(seconds: 8), () {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          try {
            Get.back();
            loaderShown = false;
            print("⏰ Forced loader close due to timeout");
          } catch (e) {
            print("Error force closing loader: $e");
          }
        }
        _setEmptyValues();
      });

      print("✅ Bearer token available: ${bearerKey!.substring(0, 20)}...");

      GetTodayReport model = await CallService().getLiveSaleData().timeout(
        Duration(seconds: 6),
        onTimeout: () {
          print("⏰ API call timeout");
          throw TimeoutException('api_time'.tr, Duration(seconds: 6));
        },
      );

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
        print("✅ Loader closed after API success");
      }

      print("✅ API call completed successfully");

      // Check if model has error code
      if (model.code != null && model.code != 200) {
        print("⚠️ API returned code: ${model.code}, message: ${model.mess}");
        _setEmptyValues();
        return;
      }

      // Update state with received data from API
      setState(() {
        delivery = '${model.orderTypes?.delivery ?? 0}';
        pickUp = '${model.orderTypes?.pickup ?? 0}';
        pending = '${model.approvalStatuses?.pending ?? 0}';
        accepted = '${model.approvalStatuses?.accepted ?? 0}';
        declined = '${model.approvalStatuses?.declined ?? 0}';

        // Store API data for fallback
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

      print('✅ State updated successfully');
    } on TimeoutException catch (e) {
      print('⏰ Timeout error in getLiveSaleReport: $e');
      _setEmptyValues();
    } catch (e, stackTrace) {
      print('❌ Error in getLiveSaleReport: $e');
      print('📋 Stack trace: $stackTrace');

      _setEmptyValues();

      if (!e.toString().contains('204') && !e.toString().contains('timeout')) {
        showSnackbar("info".tr, "unable".tr);
      }
    } finally {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
          print("✅ Loader closed in finally block");
        } catch (e) {
          print("Error closing loader in finally: $e");
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

    print("ðŸ“Š Set empty/default values for UI");
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

  void _handleSalesUpdate(Map<String, dynamic> salesData,
      {bool isFromSocket = false})
  {
    print('ðŸ”„ Updating sales data: $salesData');
    if (isFromSocket) {
      SalesCacheHelper.saveSalesData(salesData);

      _hasSocketData = true;
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
        totalSalesDelivery:
            (salesData['total_sales + delivery'] as num?)?.toDouble(),
      );

      setState(() => reportsss = _currentDateReport!);

      print('âœ… Sales data updated successfully');
    } else {
      print('âŒ Current date report is null, cannot update');
    }
  }

  Future<void> _loadCachedSalesData() async {
    final cachedData = await SalesCacheHelper.loadSalesData();
    if (cachedData != null) {
      print("ðŸ“¥ Loading cached sales data into UI");
      _handleSalesUpdate(cachedData);
    } else {
      print("â„¹ï¸ No cached data found, waiting for live socket data");
    }
  }

  void _refreshCurrentDayData() => getCurrentDateReport();

  void getCurrentDateReport() {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    print("ðŸ” Looking for current date report: $todayString");
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
      print("âœ… Current date report set successfully");
    } else {
      print("âŒ No report found for today's date: $todayString");
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
      print("ðŸ†• Created default report for today");
    }
  }

  Future<void> _handleRefresh() async {
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, false, false, storeID);
  }

  Future<void> _manualRefresh() async {
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, true, false, storeID);
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
        // Close any existing loader first
        if (Get.isDialogOpen ?? false) {
          try {
            Get.back();
            print("Closed existing loader before showing new one");
          } catch (e) {
            print("Error closing existing loader: $e");
          }
        }

        // Show loader
        Get.dialog(
          Center(
              child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          )),
          barrierDismissible: false,
        );
        loaderShown = true;

        // Set timeout for loader - force close after 8 seconds
        timeoutTimer = Timer(Duration(seconds: 8), () {
          if (loaderShown && (Get.isDialogOpen ?? false)) {
            try {
              Get.back();
              loaderShown = false;
              print("⏰ Forced getOrders loader close due to timeout");
            } catch (e) {
              print("Error force closing getOrders loader: $e");
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

      // API call with timeout
      final result =
          await ApiRepo().orderGetApiFilter(bearerKey!, data).timeout(
        Duration(seconds: 6),
        onTimeout: () {
          print("⏰ getOrders API timeout");
          throw TimeoutException('api_timeout'.tr, Duration(seconds: 6));
        },
      );

      // Close loader immediately after API response
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
        print("✅ getOrders loader closed after API response");
      }

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
    } on TimeoutException catch (e) {
      print("⏰ Timeout in getOrders: $e");
    } catch (e) {
      print("❌ Error in getOrders: $e");
      Log.loga(title, "getOrders Api:: e >>>>> $e");
      showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
    } finally {
      // Always cancel timeout timer
      timeoutTimer?.cancel();

      // Always close loader if it was shown
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
          print("✅ getOrders loader closed in finally block");
        } catch (e) {
          print("Error closing getOrders loader in finally: $e");
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
      final approvalStatuses = _currentDateReport!.data!.approvalStatuses!;

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
    // If socket data is available, use socket data
    if (_hasSocketData && _currentDateReport?.data?.orderTypes != null) {
      final orderTypes = _currentDateReport!.data!.orderTypes!;

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

    // Otherwise, use API data
    return _liveApiData[type] ?? 0;
  }

  int _getTotalOrders() {
    // If socket data is available, use socket data
    if (_hasSocketData && _currentDateReport?.totalOrders != null) {
      return _currentDateReport!.totalOrders!;
    }

    // Otherwise, use API data
    return _liveApiData['totalOrders'] ?? 0;
  }

  String _extractTime(String deliveryTime) {
    try {
      // Parse the ISO string and extract time
      DateTime dateTime = DateTime.parse(deliveryTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return deliveryTime; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF5F5F5),
        body: Builder(builder: (context) {
          print(
              "🏗️ Building body - hasInternet: $hasInternet, isLoading: $isLoading");

          if (isLoading) {
            return Center(
                child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ));
          }

          if (!hasInternet) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No Internet Connection",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _showLogoutDialog(),
                    child: Text("Show Logout Dialog"),
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
                        // Date + title
                        GestureDetector(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('order'.tr,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
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

                        // Total Orders + Refresh button
                        Row(
                          children: [
                            Text(
                              '${'total_order'.tr}: ${_getTotalOrders()}',
                              style: TextStyle(
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
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Accepted Orders
                          _buildStatusContainer(
                            '${'accepted'.tr} ${_getApprovalStatusCount("accepted")}',
                            Colors.green.withOpacity(0.1),
                          ),
                          SizedBox(width: 8),

                          // Declined Orders
                          _buildStatusContainer(
                            '${"decline".tr} ${_getApprovalStatusCount("declined")}',
                            Colors.red.withOpacity(0.1),
                          ),
                          SizedBox(width: 8),

                          // // Pending Orders
                          // _buildStatusContainer(
                          //   'Pending: ${_getApprovalStatusCount("pending")}',
                          //   Colors.yellow.withOpacity(0.2),
                          // ),
                          //SizedBox(width: 8),

                          // Pickup Orders
                          _buildStatusContainer(
                            '${"pickup".tr} ${_getOrderTypeCount("pickup")}',
                            Colors.blue.withOpacity(0.1),
                          ),
                          SizedBox(width: 8),

                          // Delivery Orders
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
                // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Orders list with pullâ€‘toâ€‘refresh â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                            : !hasInternet // ✅ First check internet condition
                                ? ListView(
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(height: 100),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.wifi_off,
                                              size: 80, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text(
                                            "no_internet".tr,
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "please".tr,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Obx(() {
                                    // ✅ Then check orders condition
                                    if (app.appController.searchResultOrder
                                        .isEmpty) {
                                      return ListView(
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          SizedBox(height: 100),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Lottie.asset(
                                                'assets/animations/empty.json',
                                                width: 150,
                                                height: 150,
                                              ),
                                              Text(
                                                'no_order'.tr,
                                                style: TextStyle(
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
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemCount: app.appController.searchResultOrder.length,
                                        itemBuilder: (context, index) {
                                          final order = app.appController.searchResultOrder[index];
                                          DateTime startTime = DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now();
                                          DateTime endTime = startTime.add(const Duration(minutes: 30));
                                          String formattedEnd = DateFormat('hh:mm a').format(endTime);
                                          DateTime dateTime = DateTime.parse(order.createdAt.toString());
                                          String time = DateFormat('hh:mm a').format(dateTime);
                                          String guestAddress = order.guestShippingJson?.zip?.toString() ?? '';
                                          String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
                                          String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';
                                          print('guest name is $guestName');
                                          print('guest name is $guestAddress');
                                          print('guest name is $guestPhone');
                                          return AnimatedBuilder(
                                            animation: _opacityAnimation,
                                            builder: (context, child) {
                                              final bool isPending =
                                                  (order.approvalStatus ?? 0) == 1;
                                              Color getContainerColor() {
                                                switch (order.approvalStatus) {
                                                  case 2: // Accepted
                                                    return Color(0xffEBFFF4);
                                                  case 3: // Declined
                                                    return Color(0xffFFEFEF);
                                                  case 1: // Pending
                                                    return Colors.white;
                                                  default:
                                                    return Colors.white;
                                                }
                                              }

                                              return Opacity(
                                                opacity: isPending
                                                    ? _opacityAnimation.value : 1.0,
                                                child: Container(
                                                  margin: EdgeInsets.only(bottom: 12),
                                                  decoration: BoxDecoration(
                                                    color: getContainerColor(),
                                                    borderRadius: BorderRadius.circular(7),
                                                    border: Border.all(
                                                      color: (order.approvalStatus == 2)
                                                          ? Color(0xffC3F2D9)
                                                          : (order.approvalStatus == 3) ? Color(0xffFFD0D0) : Colors.grey.withOpacity(0.2),
                                                      width: 1,
                                                    ),
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
                                                    padding: EdgeInsets.all(8),
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior.opaque,
                                                      onTap: () => Get.to(() =>
                                                          OrderDetailEnglish(order)),
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
                                                                    child: SvgPicture.asset(order.orderType == 1
                                                                          ? 'assets/images/ic_delivery.svg'
                                                                          : order.orderType == 2
                                                                              ? 'assets/images/ic_pickup.svg'
                                                                              : 'assets/images/ic_pickup.svg',
                                                                      height: 14,
                                                                      width: 14,
                                                                      color: Colors.white,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 6),
                                                                  Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Container(
                                                                        width: MediaQuery.of(context).size.width * 0.6,
                                                                        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            Container(
                                                                              width: MediaQuery.of(context).size.width * (order.orderType == 2 ? 0.18 : 0.3),
                                                                              child: Text(
                                                                                order.orderType == 2 ? 'pickup'.tr : (order.shipping_address?.zip?.toString() ?? guestAddress),
                                                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: "Mulish-Regular"),
                                                                              ),
                                                                            ),
                                                                            if (order.deliveryTime != null &&
                                                                                order.deliveryTime!.isNotEmpty)
                                                                              Container(
                                                                                width: MediaQuery.of(context).size.width * 0.3,
                                                                                child: Text(
                                                                                  '${'time'.tr}: ${_extractTime(order.deliveryTime!)}',
                                                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: "Mulish-Regular"),
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      Visibility(
                                                                        visible: order.shipping_address != null || order.guestShippingJson != null,
                                                                        child: Container(width: MediaQuery.of(context).size.width * 0.5,
                                                                          child: Text(order.orderType == 1
                                                                                ? (order.shipping_address != null
                                                                                    ? '${order.shipping_address!.line1!}, ${order.shipping_address!.city!}'
                                                                                    : '${order.guestShippingJson?.line1 ?? ''}, '
                                                                                        '${order.guestShippingJson?.city ?? ''}') : '',
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
                                                                  Icon(Icons.access_time, size: 20,),
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
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Container(
                                                                width: MediaQuery.of(context).size.width * 0.5,
                                                                child: Text(
                                                                  '${order.shipping_address?.customer_name ?? guestName ?? ""} / ${order.shipping_address?.phone ?? guestPhone}',
                                                                  style: const TextStyle(fontWeight: FontWeight.w700,
                                                                      fontFamily: "Mulish",
                                                                      fontSize: 13),
                                                                ),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '${'order_number'.tr} : ',
                                                                    style: const TextStyle(fontWeight: FontWeight.w700,
                                                                        fontSize: 11,
                                                                        fontFamily: "Mulish"),
                                                                  ),
                                                                  Text(
                                                                    '${order.orderNumber}',
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
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                order.payment != null
                                                                    ? '${'currency'.tr} ${formatAmount(order.payment!.amount ?? 0)}'
                                                                    : '${'currency'.tr} ${formatAmount(0)}',
                                                                style: const TextStyle(
                                                                    fontWeight: FontWeight.w800,
                                                                    fontFamily: "Mulish",
                                                                    fontSize: 16),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    getApprovalStatusText(order.approvalStatus),
                                                                    style: const TextStyle(
                                                                        fontWeight: FontWeight.w800,
                                                                        fontFamily: "Mulish-Regular",
                                                                        fontSize: 13),
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
                                        });
                                  })),
                  ),
                )
              ],
            ),
          );
        }));
  }

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

  @override
  bool get wantKeepAlive => true;

  Future<void> getNewOrder(int orderID) async {
    try {
      final result = await ApiRepo().getNewOrderData(bearerKey!, orderID);
      if (result != null) {
        app.appController.addNewOrder(result);
      } else {
        String errorMessage = result.mess ?? "Unknown error";
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("api_error".tr, "${'an_error'.tr}: $e");
    }
  }
}

class SalesCacheHelper {
  static const _salesDataKey = 'cached_sales_data';
  static const _lastDateKey = 'cached_sales_date';
  static const _orderDateKey = 'cached_order_date';
  static const _storeIdKey = 'cached_store_id'; // âœ… NEW: Store ID tracking

  // âœ… NEW: Get user-specific cache keys
  static String _getUserSpecificKey(String baseKey, String? storeId) {
    if (storeId != null && storeId.isNotEmpty) {
      return "${baseKey}_store_${storeId}";
    }
    return baseKey;
  }

  static Future<void> saveSalesData(Map<String, dynamic> salesData) async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    // âœ… Use store-specific keys
    final storeSpecificSalesKey =
        _getUserSpecificKey(_salesDataKey, currentStoreId);
    final storeSpecificDateKey =
        _getUserSpecificKey(_lastDateKey, currentStoreId);

    await prefs.setString(storeSpecificSalesKey, jsonEncode(salesData));
    await prefs.setString(storeSpecificDateKey, todayString);
    await prefs.setString(_storeIdKey, currentStoreId ?? '');

    print("ðŸ’¾ Cached sales data for store $currentStoreId on $todayString");
  }

  static Future<Map<String, dynamic>?> loadSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);
    final cachedStoreId = prefs.getString(_storeIdKey);

    // âœ… Use store-specific keys
    final storeSpecificSalesKey =
        _getUserSpecificKey(_salesDataKey, currentStoreId);
    final storeSpecificDateKey =
        _getUserSpecificKey(_lastDateKey, currentStoreId);

    final cachedDate = prefs.getString(storeSpecificDateKey);
    final cachedData = prefs.getString(storeSpecificSalesKey);

    // âœ… Load only if same date AND same store
    if (cachedDate == todayString &&
        cachedStoreId == currentStoreId &&
        cachedData != null &&
        currentStoreId != null &&
        currentStoreId.isNotEmpty) {
      print("ðŸ“¥ Loading cached sales data for store $currentStoreId");
      return jsonDecode(cachedData);
    }

    print(
        "â„¹ï¸ No valid cached data found for store $currentStoreId on $todayString");
    return null;
  }

  static Future<void> clearSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    // âœ… Clear current store's data
    if (currentStoreId != null) {
      final storeSpecificSalesKey =
          _getUserSpecificKey(_salesDataKey, currentStoreId);
      final storeSpecificDateKey =
          _getUserSpecificKey(_lastDateKey, currentStoreId);

      await prefs.remove(storeSpecificSalesKey);
      await prefs.remove(storeSpecificDateKey);
      print("ðŸ§¹ Cleared sales data for store $currentStoreId");
    }

    // âœ… Also clear general keys for safety
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
