import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/ui/table%20Book/reservation_details.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/Socket/reservation_socket_service.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/reservation/add_new_reservation_response_model.dart';
import '../../models/reservation/get_user_reservation_details.dart';
import '../../utils/my_application.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Login/LoginScreen.dart';
import '../Order/OrderScreen.dart';
import 'ReservationBottomDialogSheet.dart';

class Reservation extends StatefulWidget {
  const Reservation({super.key});

  @override
  State<Reservation> createState() => _ReservationState();
}

// Make your class extend with WidgetsBindingObserver
class _ReservationState extends State<Reservation> with WidgetsBindingObserver {
  String dateSeleted = "";
  bool hasInternet = true;
  Timer? _internetCheckTimer;
  bool _isDialogShowing = false;
  Timer? _reservationTimer;
  final SocketService _socketService = SocketService();
  Map<String, dynamic>? storeStatusData;
  List<Map<String, String>> availableTimeSlots = [];
  bool isStoreOpen = false;
  Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'booked':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String? status) {
    if (status == null) return Icons.help;

    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.visibility;
      case 'booked':
        return Icons.check;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
  String? storeId;
  SharedPreferences? sharedPreferences;
  bool isLoading = false;

  void _startInternetMonitoring() {
    _internetCheckTimer?.cancel();
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnection = connectivityResult != ConnectivityResult.none;

      if (hasConnection != hasInternet) {
        setState(() {
          hasInternet = hasConnection;
        });

        if (hasConnection) {
          print("🌐 Internet restored in reservation screen, refreshing data...");
          loadExistingReservations();
        }
      }
    });
  }

  String? convertDisplayDateToApiFormat(String displayDate) {
    try {
      // If displayDate is in format "1 September, 2024", convert to "2024-09-01"
      DateTime parsedDate = DateFormat('d MMMM, y').parse(displayDate);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      print("Error parsing display date: $e");
      return null;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

      // ✅ Start listening to store status after getting storeId
      if (storeId != null && mounted) {
        _listenToStoreStatus();
      }
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }


  Future<void> _offlineLogout() async {
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

      print("🚪 Starting offline logout process...");

      // ✅ STEP 1: Save IP data before clearing everything (same as online logout)
      await _preserveUserIPDataOffline();

      // ✅ STEP 2: Force complete logout cleanup (without clearing IP data)
      await _forceCompleteLogoutCleanupOffline();

      // ✅ STEP 3: Clear app controller
      app.appController.clearOnLogout();

      // ✅ STEP 4: Disconnect socket
      await _disconnectSocketOffline();

      // ✅ STEP 5: Close loader
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // ✅ STEP 6: Navigate to login with complete reset
      Get.offAll(() => const LoginScreen());

      print("✅ Offline logout completed successfully");

    } catch (e) {
      print("❌ Error in offline logout: $e");
      // Close loader if error occurs
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      // Still navigate to login even if error occurs
      Get.offAll(() => const LoginScreen());
    }
  }

// ✅ Preserve IP data for offline logout
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
            await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
            print("💾 Saved ${userPrefix}printer_ip_remote_$i: $currentRemoteIP");
          }
        }

        // Preserve selected indices
        int? selectedIndex = prefs.getInt('selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
        }

        // Preserve toggle settings
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

        print("✅ IP data preserved for store: $currentStoreId (offline)");
      } else {
        print("⚠️ No store ID found, cannot preserve IP data (offline)");
      }
    } catch (e) {
      print("❌ Error preserving IP data (offline): $e");
    }
  }

// ✅ Complete offline logout cleanup WITHOUT clearing IP data
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
          await Future.delayed(const Duration(milliseconds: 20));
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
        await Future.delayed(const Duration(milliseconds: 100));
        await prefs.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        // ✅ Verify cleanup for this attempt
        String? testToken = prefs.getString(valueShared_BEARER_KEY);
        String? testStoreKey = prefs.getString(valueShared_STORE_KEY);
        if (testToken == null && testStoreKey == null) {
          print("✅ Offline cleanup attempt ${attempt + 1}: SUCCESS");
        } else {
          print("⚠️ Offline cleanup attempt ${attempt + 1}: Data still exists, retrying...");
        }
      }

      // ✅ Final verification
      SharedPreferences finalPrefs = await SharedPreferences.getInstance();
      await finalPrefs.reload();
      String? finalToken = finalPrefs.getString(valueShared_BEARER_KEY);
      String? finalStoreKey = finalPrefs.getString(valueShared_STORE_KEY);

      if (finalToken == null && finalStoreKey == null) {
        print("✅ Complete offline logout cleanup SUCCESS - All auth data removed");
      } else {
        print("❌ Offline logout cleanup FAILED - Auth data still exists");
      }

    } catch (e) {
      print("❌ Error in complete offline logout cleanup: $e");
    }
  }

// ✅ Disconnect socket for offline logout
  Future<void> _disconnectSocketOffline() async {
    try {
      print("🔌 Disconnecting socket (offline)...");
      _socketService.disconnect();
      await Future.delayed(const Duration(milliseconds: 100));
      print("✅ Socket disconnected (offline)");
    } catch (e) {
      print("⚠️ Error disconnecting socket (offline): $e");
    }
  }

// ✅ Update the _showLogoutDialog method in OrderScreen.dart
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
            title: const Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.red),
                SizedBox(width: 8),
                Text("Connection Error"),
              ],
            ),
            content: const Text("Cannot connect to server. Please logout and login again to continue."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                  // ✅ Call offline logout instead of API logout
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

  @override
  void initState() {
    super.initState();

    // ✅ Initialize and connect socket first
    _initializeSocketConnection();

    WidgetsBinding.instance.addObserver(this);

    ever(app.appController.triggerAddReservation, (_) {
      if (mounted) {
        showAddReservationForm();
      }
    });

    _startInternetMonitoring();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExistingReservations();
    });
  }

  Future<void> _initializeSocketConnection() async {
    try {
      await _initializeSharedPreferences();

      // ✅ Connect to socket
      await _socketService.connect();

      // ✅ Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 2000));

      // ✅ Start listening to store status
      if (storeId != null && mounted) {
        _listenToStoreStatus();
      } else {
        print("⚠️ Socket connection failed or storeId is null");
      }
    } catch (e) {
      print("❌ Error initializing socket: $e");
    }
  }

  void _listenToStoreStatus() {
    if (storeId == null) {
      print("⚠️ Store ID is null, cannot listen to store status");
      return;
    }

    // ✅ Tell socket service to listen with this storeId (for compatibility)
    _socketService.listenToStoreStatus(storeId!);

    // ✅ Subscribe to the stream
    _socketService.storeStatusStream.listen((data) {
      if (mounted) {
        setState(() {
          storeStatusData = data;
          isStoreOpen = data['is_open'] ?? false;
          availableTimeSlots = _parseTimeSlots(data['today_hours']);
        });
        print("📡 Store status updated: Open=$isStoreOpen, Slots=${availableTimeSlots.length}");
      }
    }, onError: (error) {
      print("❌ Store status stream error: $error");
    });
  }

  List<Map<String, String>> _parseTimeSlots(List<dynamic>? todayHours) {
    List<Map<String, String>> slots = [];

    if (todayHours == null || todayHours.isEmpty) {
      print("⚠️ No today_hours data available");
      return slots;
    }

    for (var timeSlot in todayHours) {
      String? openTime = timeSlot['open_time'];
      String? closeTime = timeSlot['close_time'];

      if (openTime != null && closeTime != null) {
        List<String> openParts = openTime.split(':');
        List<String> closeParts = closeTime.split(':');

        int openHour = int.parse(openParts[0]);
        int openMinute = int.parse(openParts[1]);
        int closeHour = int.parse(closeParts[0]);
        int closeMinute = int.parse(closeParts[1]);

        DateTime currentSlot = DateTime(2023, 1, 1, openHour, openMinute);
        DateTime endTime = DateTime(2023, 1, 1, closeHour, closeMinute);

        while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
          String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
          String time12 = DateFormat('h:mm a').format(currentSlot);

          slots.add({
            'time24': time24,
            'time12': time12, // Keep for reference but won't use
          });

          currentSlot = currentSlot.add(const Duration(minutes: 20));
        }
      }
    }

    print("✅ Generated ${slots.length} time slots from WebSocket data");
    return slots;
  }



  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String date = DateFormat('dd-MM-yyyy').format(dateTime);
      String time = DateFormat('HH:mm').format(dateTime);
      return '$date  $time';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed, refreshing reservations");
      loadExistingReservations(); // Refresh when app returns to foreground
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _internetCheckTimer?.cancel();
    _reservationTimer?.cancel();
    super.dispose();
  }

  Future<void> loadExistingReservations() async {
    if (app.appController.reservationsList.isNotEmpty) {
      print("📋 Using existing ${app.appController.reservationsList.length} reservations from controller");
    }

    // Then refresh with latest data
    await getReservationDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('reserv'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            )),
                        GestureDetector(
                          onTap: () {
                            openCalendarScreen();
                          },
                          child: Text(
                            dateSeleted.isEmpty
                                ? DateFormat('d MMMM, y').format(DateTime.now())
                                : dateSeleted,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0,top: 5),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  openCalendarScreen();
                                },
                                child: Row(
                                  children: [
                                    Text('history'.tr, style: const TextStyle(fontFamily: "Mulish", fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xff1F1E1E))),
                                    const SizedBox(width: 5),
                                    SvgPicture.asset('assets/images/dropdown.svg', height: 5, width: 11),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10,),
                              if (dateSeleted.isNotEmpty && dateSeleted != DateFormat('d MMMM, y').format(DateTime.now()))
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    dateSeleted = "";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue, width: 1),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.today, size: 14, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text(
                                        'Today',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Obx(() {
                            int filteredCount = app.appController.getFilteredReservationsCount(
                                dateSeleted.isEmpty ? null : convertDisplayDateToApiFormat(dateSeleted));

                            return Text(
                              '${'total_reserv'.tr}: $filteredCount',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: "Mulish",
                                  color: Colors.black),
                            );
                          }),
                          IconButton(
                              iconSize: 24,
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await getReservationsInBackground();
                              }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Obx(() {
                app.appController.reservationsList.length;
                List<GetUserReservationDetailsResponseModel> filteredReservations =
                app.appController.getFilteredReservations(
                    dateSeleted.isEmpty ? null : convertDisplayDateToApiFormat(dateSeleted));

                if (filteredReservations.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Lottie.asset('assets/animations/empty.json', height: 150, width: 150),
                        Text('no_reservation'.tr)
                      ],
                    ),
                  );
                }

                return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredReservations.length,
                    itemBuilder: (context, index) {
                      var reserv = filteredReservations[index];

                      return GestureDetector(
                        onTap: () async {
                          await Get.to(
                                () => ReservationDetails(reserv.id.toString()),
                          )?.then((result) async {
                            print("Returned from ReservationDetails, refreshing reservations");
                            await getReservationDetails();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/reservation.png',
                                        height: 25,
                                        width: 25,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        formatDateTime(reserv.reservedFor.toString()),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Mulish',
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 5),
                                      Text(
                                        reserv.createdAt != null
                                            ? DateFormat('HH:mm').format(DateTime.parse(reserv.createdAt!))
                                            : '--:--',
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
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.5,
                                    child: Text(
                                      '${reserv.customerName.toString()}/${reserv.customerPhone.toString()}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          fontFamily: "Mulish"),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${'order_id'.tr} :',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            fontFamily: "Mulish"),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        reserv.id.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                            fontFamily: "Mulish"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/person.png',
                                        height: 18,
                                        width: 14,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        reserv.guestCount.toString(),
                                        style: const TextStyle(
                                            fontFamily: 'Mulish',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        reserv.status.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontFamily: "Mulish-Regular",
                                            fontSize: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      CircleAvatar(
                                          radius: 14,
                                          backgroundColor: getStatusColor(reserv.status),
                                          child: Icon(
                                            getStatusIcon(reserv.status),
                                            color: Colors.white,
                                            size: 16,
                                          )),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    });
              })
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getReservationDetails() async {
    setState(() {
      isLoading = true;
    });

    // Only show dialog if not already open
    if (!(Get.isDialogOpen ?? false)) {
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
    }

    _reservationTimer = Timer(const Duration(seconds: 7), () {
      if (Get.isDialogOpen ?? false) {
        Navigator.of(Get.overlayContext!).pop();
        showSnackbar("order Timeout", "get Details request timed out. Please try again.");
      }
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Close loader immediately
        if (Get.isDialogOpen == true) {
          Navigator.of(Get.overlayContext!).pop();
        }

        setState(() {
          isLoading = false;
          hasInternet = false;
        });

        // Show logout dialog
        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
        return;
      }
      List<GetUserReservationDetailsResponseModel> reservations = await CallService().getReservationDetailsList();
      _reservationTimer?.cancel();
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }
      setState(() {
        hasInternet = true;
        isLoading = false;
      });
      app.appController.setReservations(reservations);

      print('✅ Loaded ${reservations.length} reservations into controller');
    } catch (e) {
      _reservationTimer?.cancel();
      // ✅ Always close loader in catch block
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      setState(() {
        isLoading = false;
      });

      // ✅ Check if it's a network error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {

        setState(() {
          hasInternet = false;
        });

        // Show logout dialog for network errors
        Future.delayed(const Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      } else {
        print('❌ Error getting reservation details: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr} - ${'load'.tr}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void openCalendarScreen() async {
    if (app.appController.reservationsList.isEmpty) {
      await getReservationDetails();
    }
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
              child: const ReportScreenBottom(),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => dateSeleted = result);

      // Refresh reservations after date selection
      await getReservationDetails();

      print("Selected date: $result");
      print("Refreshing reservations for selected date");
    }
  }

  Future<void> getReservationsInBackground() async {
    await getReservationDetails();
  }
  TextInputType _getKeyboardType(String label) {
    switch (label) {
      case 'Phone Number':
        return TextInputType.phone;
      case 'Guest Count':
        return TextInputType.number;
      case 'Email Address':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }
  void showAddReservationForm() {
    Get.bottomSheet(
      _buildAddReservationBottomSheet(),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      enterBottomSheetDuration: const Duration(milliseconds: 400),
      exitBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildAddReservationBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController guestController = TextEditingController(text: "2");
    final TextEditingController reservationController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    return Stack(
        clipBehavior: Clip.none,
        children:[
          Container(
            height: Get.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  margin: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      'new_reservation'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildAddReservationField('customer_name'.tr, nameController, Icons.person),
                        _buildAddReservationField('phone_number'.tr, phoneController, Icons.phone),
                        _buildAddReservationField('email_address'.tr, emailController, Icons.email),
                        _buildAddReservationField('guest_count'.tr, guestController, Icons.group),
                        _buildAddReservationField('reservation_date'.tr, reservationController, Icons.calendar_today, isDateField: true),
                        _buildAddReservationField('special_note'.tr, noteController, Icons.note, maxLines: 3),

                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Close bottom sheet without triggering Get.back() multiple times
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  minimumSize: const Size(0, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                child: Text('cancel'.tr,style: const TextStyle(
                                  fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 16,),),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              //flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  _createNewReservation(
                                    nameController.text,
                                    phoneController.text,
                                    emailController.text,
                                    guestController.text,
                                    reservationController.text,
                                    noteController.text,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff0C831F),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                child:  Center(child: Text('book'.tr,style: const TextStyle(
                                  fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 16,
                                ),)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -60,
            right: 0,
            left: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.black),
                ),
              ),
            ),
          ),
        ]
    );
  }

  Widget _buildAddReservationField(String label, TextEditingController controller,
      IconData icon, {int maxLines = 1, bool isDateField = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Mulish',
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              readOnly: isDateField,
              keyboardType: _getKeyboardType(label),
              onTap: isDateField ? () => _selectNewReservationDateTime(controller) : null,
              style: const TextStyle(
                fontFamily: 'Mulish',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _getHintText(label),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Mulish',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ),
                suffixIcon: isDateField
                    ? Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 24)
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: maxLines > 1 ? 16 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Customer Name':
        return 'name'.tr;
      case 'Phone Number':
        return 'contact_number'.tr;
      case 'Email Address':
        return 'email'.tr;
      case 'Guest Count':
        return 'guest_count'.tr;
      case 'Reservation Date':
        return 'dd'.tr;
      case 'Special Note':
        return 'type_note'.tr;
      default:
        return '';
    }
  }

  Future<void> _selectNewReservationDateTime(TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      await _selectNewTimeSlot(selectedDate, controller);
    }
  }

  Future<void> _selectNewTimeSlot(DateTime selectedDate, TextEditingController controller) async {
    List<Map<String, String>> timeSlots = [];

    // ✅ Check if WebSocket data is available
    if (availableTimeSlots.isEmpty) {
      print("⚠️ No time slots from WebSocket. Trying to reconnect...");

      await _socketService.ensureConnected();
      await Future.delayed(const Duration(milliseconds: 1500));

      if (availableTimeSlots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Store timing data not available. Using default timings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }

        timeSlots = _generateDefaultTimeSlots();
      } else {
        timeSlots = List.from(availableTimeSlots);
      }
    } else {
      timeSlots = List.from(availableTimeSlots);
    }

    // ✅ Filter time slots based on Germany time
    List<Map<String, String>> availableSlots = timeSlots;
    bool isToday = selectedDate.day == DateTime.now().day &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.year == DateTime.now().year;

    if (isToday) {
      // ✅ Get current time in UTC
      DateTime nowUtc = DateTime.now().toUtc();

      // ✅ Germany timezone offset (check if DST is active)
      bool isDST = _isDaylightSavingTime(nowUtc);
      int germanyOffset = isDST ? 2 : 1; // UTC+2 in summer, UTC+1 in winter

      // ✅ Get current Germany time
      DateTime nowGermany = nowUtc.add(Duration(hours: germanyOffset));

      // ✅ CRITICAL FIX: Get current Germany hour and minute for comparison
      int currentHour = nowGermany.hour;
      int currentMinute = nowGermany.minute;

      print("⏰ Current Germany time: ${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}");
      print("🌍 UTC time: ${DateFormat('HH:mm').format(nowUtc)}");
      print("☀️ DST Active: $isDST (Offset: +$germanyOffset hours)");

      availableSlots = timeSlots.where((slot) {
        List<String> timeParts = slot['time24']!.split(':');
        int slotHour = int.parse(timeParts[0]);
        int slotMinute = int.parse(timeParts[1]);

        // ✅ FIXED: Compare slot time directly with current Germany time
        // Convert to total minutes for accurate comparison
        int slotTotalMinutes = (slotHour * 60) + slotMinute;
        int currentTotalMinutes = (currentHour * 60) + currentMinute;

        // ✅ Slot must be after current Germany time
        bool isAvailable = slotTotalMinutes > currentTotalMinutes;

        if (!isAvailable) {
          print("❌ Slot ${slot['time24']} is in past ($slotTotalMinutes <= $currentTotalMinutes)");
        } else {
          print("✅ Slot ${slot['time24']} is available ($slotTotalMinutes > $currentTotalMinutes)");
        }

        return isAvailable;
      }).toList();

      print("✅ Available slots after filtering: ${availableSlots.length}");

      if (availableSlots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'closed'.tr} - No available time slots for today'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    String dayInfo = isStoreOpen
        ? '✅ Store is Open - ${availableSlots.length} slots available'
        : '⚠️ Store is Closed - Showing available slots';

    final scaffoldContext = context;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          height: Get.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'time_slot'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayInfo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${'date'.tr}: ${DateFormat('dd-MM-yyyy (EEEE)').format(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: Colors.orange.shade800,
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      var slot = availableSlots[index];
                      return GestureDetector(
                        onTap: () {
                          List<String> timeParts = slot['time24']!.split(':');
                          DateTime finalDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            int.parse(timeParts[0]),
                            int.parse(timeParts[1]),
                          );

                          String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
                          controller.text = formattedDateTime;

                          Navigator.pop(bottomSheetContext);

                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted) {
                              try {
                                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                  SnackBar(
                                    content: Text('${'time_selected'.tr}: ${slot['time24']}'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } catch (e) {
                                print('Error showing snackbar: $e');
                              }
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade100, Colors.green.shade200],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              slot['time24']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

// ✅ NEW: Check if Daylight Saving Time is active in Germany
  bool _isDaylightSavingTime(DateTime dateTime) {
    // Germany DST: Last Sunday of March to Last Sunday of October
    int year = dateTime.year;

    // Find last Sunday of March
    DateTime marchEnd = DateTime.utc(year, 3, 31);
    while (marchEnd.weekday != DateTime.sunday) {
      marchEnd = marchEnd.subtract(const Duration(days: 1));
    }

    // Find last Sunday of October
    DateTime octoberEnd = DateTime.utc(year, 10, 31);
    while (octoberEnd.weekday != DateTime.sunday) {
      octoberEnd = octoberEnd.subtract(const Duration(days: 1));
    }

    // DST starts at 2:00 AM on last Sunday of March
    DateTime dstStart = DateTime.utc(year, marchEnd.month, marchEnd.day, 2, 0);

    // DST ends at 3:00 AM on last Sunday of October
    DateTime dstEnd = DateTime.utc(year, octoberEnd.month, octoberEnd.day, 3, 0);

    bool isDST = dateTime.isAfter(dstStart) && dateTime.isBefore(dstEnd);

    return isDST;
  }

  List<Map<String, String>> _generateDefaultTimeSlots() {
    List<Map<String, String>> slots = [];

    // Default timing: 10:00 AM to 10:00 PM, 20 min intervals
    DateTime startTime = DateTime(2023, 1, 1, 10, 0);
    DateTime endTime = DateTime(2023, 1, 1, 22, 0);

    DateTime currentSlot = startTime;

    while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
      String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      String time12 = DateFormat('h:mm a').format(currentSlot);

      slots.add({
        'time24': time24,
        'time12': time12,
      });

      currentSlot = currentSlot.add(const Duration(minutes: 20));
    }

    print("✅ Generated ${slots.length} default time slots as fallback");
    return slots;
  }


  Future<void> _createNewReservation(String name, String phone, String email, String guestCount, String reservationDate, String note) async {
    if (sharedPreferences == null) {
      Get.snackbar('error'.tr, 'shared'.tr);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('error'.tr, 'storeId'.tr);
      return;
    }

    // Validate inputs
    if (name.isEmpty || phone.isEmpty || reservationDate.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'fill'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

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

      var map =
      {
        "store_id": storeId,
        "user_id": 0,
        "guest_count": int.tryParse(guestCount),
        "reserved_for": reservationDate,
        "status": "booked",
        "table_number": 0,
        "customer_name": name,
        "customer_email":email,
        "customer_phone": phone,
        "note": note,
        "isActive": true
      };

      print("Create Reservation Map: $map");
      AddNewReservationResponseModel model = await CallService().addReservation(map);

      setState(() {
        isLoading = false;
      });

      // ✅ Close loading dialog first
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      // Wait a bit to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ Close the add reservation bottom sheet FIRST
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // ✅ Wait for bottom sheet to close completely
      await Future.delayed(const Duration(milliseconds: 400));

      // Refresh reservations
      await getReservationDetails();

      // ✅ Show success snackbar AFTER everything is closed and we're back to main screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'success'.tr} - ${'created'.tr}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // ✅ Close loading dialog if open
      if (Get.isDialogOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      print('Create reservation error: $e');

      // ✅ Use ScaffoldMessenger instead of Get.snackbar for error too
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr} - ${'create_reserv'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

}

class TimeSlot {
  final String time;
  final String displayTime;

  TimeSlot(this.time, this.displayTime);
}