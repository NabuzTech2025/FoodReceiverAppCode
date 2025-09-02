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

class _OrderScreenState extends State<OrderScreenNew> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  String  salesDelivery = '0', totalSales = '0', totalOrder = '0',
      totalTax = '0', cashTotal = '0', online = '0', net = '0', discount = '0',
      deliveryFee = '0', cashMethod = '0', delivery = '0', pickUp = '0',
      dineIn = '0', pending = '0', accepted = '0', declined = '0',
      tax19 = '0', tax7 = '0';
  bool _hasSocketData = false;
  Map<String, int> _liveApiData = {
    'accepted': 0,
    'declined': 0,
    'pending': 0,
    'pickup': 0,
    'delivery': 0,
    'totalOrders': 0,
  };
  bool isLoading=false;
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
    final cachedStoreId = prefs.getString('cached_store_id'); // âœ… NEW: Track store ID
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
    _internetCheckTimer?.cancel(); // ✅ Cancel internet check timer
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

    setState(() {
      isLoading = true;
    });

    try {
      setState(() {
        hasInternet = true; // ✅ Set internet status to true
      });

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

      if (storeID != null && storeID.isNotEmpty) {
        print("✅ Using existing store ID: $storeID");

        await getStoredta(bearerKey!);
        await _restoreUserSpecificData(storeID);

        // Call without showing individual loaders
        await getOrdersWithoutLoader(bearerKey, storeID);

        if (bearerKey != null && bearerKey!.isNotEmpty) {
          print("🔌 Initializing socket with store ID: $storeID");
          _initializeSocket();
        }
      } else {
        print("⚠ No store ID found, getting user data first");
        await getStoreUserMeDataWithoutLoader(bearerKey);
      }

      getCurrentDateReport();
      _loadCachedSalesData();
      _startNoOrderTimer();
      await getLiveSaleReportWithoutLoader();
      _initVarTimeoutTimer?.cancel();

    }catch (e) {
      print("Error in initVar: $e");
    } finally {
      setState(() {
        isLoading = false;
        _isInitialLoading = false;
      });
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
            content: Text("Cannot connect to server. Please logout and login again to continue."),
            actions: [

              ElevatedButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                  logutAPi(bearerKey);
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
  Future<void> logutAPi(String? bearerKey) async {
    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );
      print("🚪 Starting logout process...");

      final result = await ApiRepo().logoutAPi(bearerKey);
      if (result != null) {
        print("✅ Logout API successful");
        Get.offAll(() => LoginScreen());

        print("✅ Logout completed successfully");

      } else {
        showSnackbar("Error", "Failed to logout");
      }
    } catch (e) {
      Log.loga(title, "Logout Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
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
    } catch (e) {
      print("❌ Error in getOrders: $e");

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
        showSnackbar("Api Error", "An error occurred: $e");
      }
    }
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

  Future<void> getStoreUserMeDataWithoutLoader(String? bearerKey) async {
    try {
      final result = await ApiRepo().getUserMe(bearerKey);
      if (result != null) {
        setState(() {
          userMe = result;
        });

        await sharedPreferences.setString(valueShared_STORE_KEY, userMe.store_id.toString());
        print("âœ… Store ID saved from API: ${userMe.store_id}");

        await getStoredta(bearerKey!);
        await _restoreUserSpecificData(userMe.store_id.toString());
        await getOrdersWithoutLoader(bearerKey, userMe.store_id.toString());

        if (bearerKey != null && bearerKey!.isNotEmpty) {
          print("ðŸ”Œ Initializing socket after getting user data");
          _initializeSocket();
        }
      } else {
        showSnackbar("Error", "Failed to get user data");
      }
    } catch (e) {
      Log.loga(title, "getUserMe Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
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
          String? savedRemoteIP = prefs.getString('${userPrefix}printer_ip_remote_$i');
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

        int? selectedRemoteIndex = prefs.getInt('${userPrefix}selected_ip_remote_index');
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

        bool? autoRemoteAccept = prefs.getBool('${userPrefix}auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool('auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint = prefs.getBool('${userPrefix}auto_order_remote_print');
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

  Future<void> getStoreUserMeData(String? bearerKey) async {
    try {
      final result = await ApiRepo().getUserMe(bearerKey);
      if (result != null) {
        setState(() {
          userMe = result;
        });

        await sharedPreferences.setString(valueShared_STORE_KEY, userMe.store_id.toString());
        print("âœ… Store ID saved from API: ${userMe.store_id}");

        // âœ… Store data à¤­à¥€ fetch à¤•à¤°à¥‡à¤‚
        await getStoredta(bearerKey!);

        // âœ… NEW: Restore user-specific data after getting store ID
        await _restoreUserSpecificData(userMe.store_id.toString());

        getOrders(bearerKey, true, false, userMe.store_id.toString());

        if (bearerKey != null && bearerKey!.isNotEmpty) {
          print("ðŸ”Œ Initializing socket after getting user data");
          _initializeSocket();
        }
      } else {
        showSnackbar("Error", "Failed to get user data");
      }
    } catch (e) {
      Log.loga(title, "getUserMe Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID == null) {
        print("âŒ DEBUG - Store ID is null, cannot fetch store data");
        return null;
      }

      final result = await ApiRepo().getStoreData(bearerKey, storeID);

      if (result != null) {
        Store store = result;
        String fetchedStoreName = store.name?.toString() ?? "Unknown Store";
        String fetchedStoreId = store.code?.toString() ?? storeID;

        setState(() {
          storeName = fetchedStoreName;
          dynamicStoreId = fetchedStoreId;
        });

        // âœ… Store name à¤•à¥‹ SharedPreferences à¤®à¥‡à¤‚ save à¤•à¤°à¥‡à¤‚
        await sharedPreferences.setString('store_name', fetchedStoreName);
        await sharedPreferences.setString(valueShared_STORE_NAME, fetchedStoreName); // Backup key
        await sharedPreferences.setString(valueShared_STORE_KEY, fetchedStoreId);

        print("âœ… DEBUG - Store name saved: '$fetchedStoreName'");
        print("âœ… DEBUG - Store ID saved: '$fetchedStoreId'");
        return storeName;
      }
    } catch (e) {
      print("âŒ DEBUG - Exception in getStoredta: $e");
      return null;
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
            await sharedPreferences.setString('cached_store_name', result.name.toString());
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
        print("âŒ CRITICAL: Cannot parse store ID, socket connection may fail!");
        return;
      }
    } else {
      print("âŒ Store ID not found or empty in SharedPreferences");
      if (userMe != null && userMe.store_id != null) {
        dynamicStoreId = userMe.store_id!;
        print("âœ… Using userMe.store_id: $dynamicStoreId");
        sharedPreferences.setString(valueShared_STORE_KEY, dynamicStoreId.toString());
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
      if (data['store_id'] != null && data['store_id'].toString() != dynamicStoreId.toString()) {
        print('âš ï¸ Ignoring sales data for different store: ${data['store_id']}');
        return;
      }

      _handleSalesUpdate(data, isFromSocket: true);
    };

    _socketService.onConnected = () {
      print('ðŸ”¥ Socket connected for store $dynamicStoreId - Live data active');
      setState(() => _isLiveDataActive = true);
    };

    _socketService.onDisconnected = () {
      print('â„ï¸ Socket disconnected for store $dynamicStoreId - Live data inactive');
      if (mounted) {
        setState(() {
          _isLiveDataActive = false;
          _hasSocketData = false; // Reset socket data flag when disconnected
        });}
    };

    _socketService.onNewOrder = (data) {
      print('ðŸ†• New order received for store $dynamicStoreId: $data');

      // âœ… Verify this order is for current store
      if (data['store_id'] != null && data['store_id'].toString() != dynamicStoreId.toString()) {
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
      print("ðŸ“„ Starting getLiveSaleReport...");

      if (bearerKey == null || bearerKey!.isEmpty) {
        print("âŒ Bearer token is null or empty");
        _setEmptyValues();
        return;
      }

      print("âœ… Bearer token available: ${bearerKey!.substring(0, 20)}...");

      // Call the API with timeout
      GetTodayReport model = await CallService().getLiveSaleData().timeout(
        Duration(seconds: 4), // API timeout slightly less than loader timeout
        onTimeout: () {
          print("â° API call timeout");
          throw TimeoutException('API call timeout', Duration(seconds: 4));
        },
      );

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
      }

      print("âœ… API call completed successfully");

      // Check if model has error code
      if (model.code != null && model.code != 200) {
        print("âš ï¸ API returned code: ${model.code}, message: ${model.mess}");
        _setEmptyValues();
        return;
      }

      // âœ… Update state with received data from API
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

      print('âœ… State updated successfully');
      print('âœ… Accepted Value Is $accepted');
      print('âœ… declined Value Is $declined');
      print('âœ… pending Value is $pending');

    } on TimeoutException catch (e) {
      print('â° Timeout error in getLiveSaleReport: $e');
      _setEmptyValues();
      // Don't show snackbar as timeout timer already handles it

    } catch (e, stackTrace) {
      print('âŒ Error in getLiveSaleReport: $e');
      print('ðŸ“‹ Stack trace: $stackTrace');

      // âœ… Set empty values instead of crashing
      _setEmptyValues();

      // âœ… Don't show error to user for 204 responses or timeout
      if (!e.toString().contains('204') && !e.toString().contains('timeout')) {
        showSnackbar("Info", "Unable to load live sales data");
      }
    } finally {
      // Cancel timeout timer
      timeoutTimer?.cancel();

      // Ensure loader is closed
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
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

  void _handleSalesUpdate(Map<String, dynamic> salesData, {bool isFromSocket = false}) {
    print('ðŸ”„ Updating sales data: $salesData');
    if (isFromSocket) {
      SalesCacheHelper.saveSalesData(salesData);

      // Mark that we have socket data
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

  Future<void> _handleRefresh() async {                               // âœ¨ NEW
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, false, false, storeID);
  }

  Future<void> _manualRefresh() async {
    final storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    await getOrders(bearerKey, true, false, storeID);
  }

  Future<void> getOrders(String? bearerKey, bool orderType, bool isBellRunning, String? id) async {
    try {
      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      if (orderType) {
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
    if (_hasSocketData && _currentDateReport?.data?.approvalStatuses != null) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
        body: Builder(
            builder: (context) {
              print("🏗️ Building body - hasInternet: $hasInternet, isLoading: $isLoading");

              if (isLoading) {
                return Center(
                    child: Lottie.asset(
                      'assets/animations/burger.json',
                      width: 150,
                      height: 150,
                      repeat: true,
                    )
                );
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

              // Your existing Padding widget with ListView
              return Padding(
              padding: const EdgeInsets.all(10),
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
                          '${'total_order'.tr}: ${_getTotalOrders()}',
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
                        : !hasInternet  // ✅ First check internet condition
                        ? ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 100),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No Internet Connection",
                              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Please check your connection",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    )
                        : Obx(() {  // ✅ Then check orders condition
                      if (app.appController.searchResultOrder.isEmpty) {
                        return ListView(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 100),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/animations/empty.json',
                                  width: 150,
                                  height: 150,
                                ),
                                Text(
                                  'No orders found',
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
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: app.appController.searchResultOrder.length,
                          itemBuilder: (context, index) {
                            final order = app.appController.searchResultOrder[index];
                            DateTime startTime = DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now();
                            DateTime endTime = startTime.add(const Duration(minutes: 30));
                            String formattedEnd = DateFormat('hh:mm a').format(endTime);
                            DateTime dateTime = DateTime.parse(order.createdAt.toString());
                            String time = DateFormat('hh:mm a').format(dateTime);
                            String guestAddress=order.guestShippingJson?.zip?.toString()??'';
                            String guestName=order.guestShippingJson?.customerName?.toString()??'';
                            String guestPhone=order.guestShippingJson?.phone?.toString()??'';
                            print('guest name is $guestName');
                            print('guest name is $guestAddress');
                            print('guest name is $guestPhone');
                            return AnimatedBuilder(
                              animation: _opacityAnimation,
                              builder: (context, child) {
                                final bool isPending = (order.approvalStatus ?? 0) == 1;
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
                                  opacity: isPending ? _opacityAnimation.value : 1.0,
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: getContainerColor(),
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: (order.approvalStatus == 2)
                                            ? Color(0xffC3F2D9)
                                            : (order.approvalStatus == 3)
                                            ? Color(0xffFFD0D0)
                                            : Colors.grey.withOpacity(0.2),
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
                                                    Container(
                                                      width: MediaQuery.of(context).size.width*0.6,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            order.orderType == 2
                                                                ? 'pickup'.tr
                                                                : (order.shipping_address?.zip?.toString() ?? guestAddress),
                                                            style: const TextStyle(
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: 13,
                                                                fontFamily: "Mulish-Regular"
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible: order.shipping_address != null || order.guestShippingJson != null,
                                                            child: Text(
                                                              order.orderType == 1
                                                                  ? (order.shipping_address != null
                                                                  ? '${order.shipping_address!.line1!}, ${order.shipping_address!.city!}'
                                                                  : '${order.guestShippingJson?.line1 ?? ''}, '
                                                                  '${order.guestShippingJson?.city ?? ''}')
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
                                                      ),
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
                                                Container(
                                                  width: MediaQuery.of(context).size.width*0.5,
                                                  child: Text(
                                                    '${order.shipping_address?.customer_name ??
                                                        guestName ?? ""} / ${order.shipping_address?.phone ??
                                                        guestPhone}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontFamily: "Mulish",
                                                        fontSize: 13
                                                    ),
                                                  ),),
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
            )
          ],
        ),
      );})
    );
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
      showSnackbar("Api Error", "An error occurred: $e");
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
    final storeSpecificSalesKey = _getUserSpecificKey(_salesDataKey, currentStoreId);
    final storeSpecificDateKey = _getUserSpecificKey(_lastDateKey, currentStoreId);

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
    final storeSpecificSalesKey = _getUserSpecificKey(_salesDataKey, currentStoreId);
    final storeSpecificDateKey = _getUserSpecificKey(_lastDateKey, currentStoreId);

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

    print("â„¹ï¸ No valid cached data found for store $currentStoreId on $todayString");
    return null;
  }

  static Future<void> clearSalesData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStoreId = prefs.getString(valueShared_STORE_KEY);

    // âœ… Clear current store's data
    if (currentStoreId != null) {
      final storeSpecificSalesKey = _getUserSpecificKey(_salesDataKey, currentStoreId);
      final storeSpecificDateKey = _getUserSpecificKey(_lastDateKey, currentStoreId);

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