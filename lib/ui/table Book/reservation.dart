import 'package:flutter/material.dart';
import 'package:food_app/ui/table%20Book/reservation_details.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/Socket/socket_service.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/reservation/add_new_reservation_response_model.dart';
import '../../models/reservation/get_user_reservation_details.dart';
import '../../utils/global.dart';
import '../../utils/log_util.dart';
import '../../utils/my_application.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../LoginScreen.dart';
import '../OrderScreen.dart';
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
    _internetCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
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
  // Add this method to OrderScreen.dart _OrderScreenState class
  // Initialize SharedPreferences
  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
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
      Get.offAll(() => LoginScreen());

      print("✅ Offline logout completed successfully");

    } catch (e) {
      print("❌ Error in offline logout: $e");
      // Close loader if error occurs
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      // Still navigate to login even if error occurs
      Get.offAll(() => LoginScreen());
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
      await Future.delayed(Duration(milliseconds: 100));
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
  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
    WidgetsBinding.instance.addObserver(this);
    ever(app.appController.triggerAddReservation, (_) {
      if (mounted) {
        showAddReservationForm();
      }
    });
    // ✅ Start internet monitoring
    _startInternetMonitoring();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExistingReservations();
    });
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
          padding: EdgeInsets.all(6),
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
                      // Add Today button
                      if (dateSeleted.isNotEmpty && dateSeleted != DateFormat('d MMMM, y').format(DateTime.now()))
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              dateSeleted = "";
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: Row(
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
                      Row(
                        children: [
                          Obx(() {
                            int filteredCount = app.appController.getFilteredReservationsCount(
                                dateSeleted.isEmpty ? null : convertDisplayDateToApiFormat(dateSeleted));

                            return Text(
                              '${'total_reserv'.tr}: $filteredCount',
                              style: TextStyle(
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
                              })
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
                    physics: NeverScrollableScrollPhysics(),
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
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.all(5),
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
                                      SizedBox(width: 10),
                                      Text(
                                        '${formatDateTime(reserv.reservedFor.toString())}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Mulish',
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 20),
                                      SizedBox(width: 5),
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
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.5,
                                    child: Text(
                                      '${reserv.customerName.toString()}/${reserv.customerPhone.toString()}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          fontFamily: "Mulish"),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${'order_id'.tr} :',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            fontFamily: "Mulish"),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        reserv.id.toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                            fontFamily: "Mulish"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
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
                                      SizedBox(width: 10),
                                      Text(
                                        reserv.guestCount.toString(),
                                        style: TextStyle(
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
    _reservationTimer = Timer(Duration(seconds: 7), () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
        showSnackbar("order Timeout", "get Details request timed out. Please try again.");
      }
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Close loader immediately
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        setState(() {
          isLoading = false;
          hasInternet = false;
        });

        // Show logout dialog
        Future.delayed(Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
        return;
      }
      List<GetUserReservationDetailsResponseModel> reservations =
      await CallService().getReservationDetailsList();
      _reservationTimer?.cancel();
      if (Get.isDialogOpen == true) {
        Get.back(); // Close dialog
      }
      setState(() {
        hasInternet = true;
        isLoading = false;
      });// Close dialog
      app.appController.setReservations(reservations);

      setState(() {
        isLoading = false;
      });

      print('✅ Loaded ${reservations.length} reservations into controller');
    } catch (e) {
      _reservationTimer?.cancel();
      // ✅ Always close loader in catch block
      if (Get.isDialogOpen == true) {
        Get.back();
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
        Future.delayed(Duration(milliseconds: 500), () {
          _showLogoutDialog();
        });
      } else {
        print('❌ Error getting reservation details: $e');
        Get.snackbar(
          'error'.tr,
          'load'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
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
              child: ReportScreenBottom(),
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
      enterBottomSheetDuration: Duration(milliseconds: 400),
      exitBottomSheetDuration: Duration(milliseconds: 300),
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
        decoration: BoxDecoration(
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
              margin: EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
               width: double.infinity,
               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
               margin: EdgeInsets.all(8),
              child: Center(
                child: Text(
                  'new_reservation'.tr,
                  style: TextStyle(
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
                padding: EdgeInsets.symmetric(horizontal: 10),
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildAddReservationField('customer_name'.tr, nameController, Icons.person),
                    _buildAddReservationField('phone_number'.tr, phoneController, Icons.phone),
                    _buildAddReservationField('email_address'.tr, emailController, Icons.email),
                    _buildAddReservationField('guest_count'.tr, guestController, Icons.group),
                    _buildAddReservationField('reservation_date'.tr, reservationController, Icons.calendar_today, isDateField: true),
                    _buildAddReservationField('special_note'.tr, noteController, Icons.note, maxLines: 3),

                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            child: Text('cancel'.tr,style: TextStyle(
                              fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 16,),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              minimumSize: Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          flex: 2,
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
                              backgroundColor: Color(0xff0C831F),
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child:  Center(child: Text('book'.tr,style: TextStyle(
                              fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 16,
                            ),)),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
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
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
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
              style: TextStyle(
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
                  padding: EdgeInsets.all(8),
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
      lastDate: DateTime.now().add(Duration(days: 365)),
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
    // Get day of week (1 = Monday, 7 = Sunday)
    int weekday = selectedDate.weekday;

    List<TimeSlot> timeSlots = [];

    // Generate time slots based on restaurant opening hours
    if (weekday >= 2 && weekday <= 5) {
      // Tuesday - Friday: 11:00 - 22:45
      timeSlots = _generateTimeSlots(11, 0, 22, 45);
    } else if (weekday == 6) {
      // Saturday: 12:00 - 22:45
      timeSlots = _generateTimeSlots(12, 0, 22, 45);
    } else if (weekday == 7 || weekday == 1) {
      // Sunday/Monday (Public Holidays): 11:00 - 22:45
      timeSlots = _generateTimeSlots(11, 0, 22, 45);
    }

    // Filter time slots based on current time if selected date is today
    List<TimeSlot> availableSlots = timeSlots;
    bool isToday = selectedDate.day == DateTime.now().day &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.year == DateTime.now().year;

    if (isToday) {
      DateTime currentTime = DateTime.now();

      availableSlots = timeSlots.where((slot) {
        List<String> timeParts = slot.time.split(':');
        int slotHour = int.parse(timeParts[0]);
        int slotMinute = int.parse(timeParts[1]);

        DateTime slotDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          slotHour,
          slotMinute,
        );

        return slotDateTime.isAfter(currentTime);
      }).toList();

      if (availableSlots.isEmpty) {
        Get.snackbar(
          'closed'.tr,
          'slot'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 1),
        );
        return;
      }
    }

    // Show day info
    String dayInfo = _getDayInfo(weekday);

    // Show time slot picker
    await Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade800], // Blue se Orange
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'time_slot'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    dayInfo,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Date Display
            Container(
              padding: EdgeInsets.all(16),
              child:Text(
                '${'date'.tr}: ${DateFormat('dd-MM-yyyy (EEEE)').format(selectedDate)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Mulish',
                  color: Colors.orange.shade800, // Blue se Orange
                ),
              ),
            ),

            // Time Slots Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: availableSlots.length,
                  itemBuilder: (context, index) {
                    TimeSlot slot = availableSlots[index];
                    return GestureDetector(
                      onTap: () {
                        List<String> timeParts = slot.time.split(':');
                        DateTime finalDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          int.parse(timeParts[0]),
                          int.parse(timeParts[1]),
                        );

                        String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
                        controller.text = formattedDateTime;

                        Get.back(); // Close time picker
                        Get.snackbar(
                          'time_selected'.tr,
                          '${'updated'.tr} ${slot.displayTime}',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 1),
                        );
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            slot.displayTime,
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

            SizedBox(height: 20),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  List<TimeSlot> _generateTimeSlots(int startHour, int startMinute, int endHour, int endMinute) {
    List<TimeSlot> slots = [];
    DateTime startTime = DateTime(2023, 1, 1, startHour, startMinute);
    DateTime endTime = DateTime(2023, 1, 1, endHour, endMinute);

    // Generate slots every 30 minutes
    DateTime currentSlot = startTime;

    while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
      String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      String time12 = DateFormat('h:mm a').format(currentSlot);

      slots.add(TimeSlot(time24, time12));
      currentSlot = currentSlot.add(Duration(minutes: 20));
    }

    return slots;
  }

  String _getDayInfo(int weekday) {
    switch (weekday) {
      case 2:
      case 3:
      case 4:
      case 5:
        return 'Tuesday - Friday: 11:00 AM - 10:45 PM';
      case 6:
        return 'Saturday: 12:00 PM - 10:45 PM';
      case 7:
      case 1:
        return 'Sunday/Monday: 11:00 AM - 10:45 PM';
      default:
        return '';
    }
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

      Get.back();
      Get.back();

      await getReservationDetails();

      Get.snackbar(
        'success'.tr,
        'created'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 1),
      );

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.back(); // Close loading dialog
      print('Create reservation error: $e');
      Get.snackbar(
        'error'.tr,
        '${'create_reserv'.tr}: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 1),
      );
    }
  }

}