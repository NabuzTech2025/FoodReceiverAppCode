import 'package:flutter/material.dart';
import 'package:food_app/ui/table%20Book/reservation_details.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/reservation/get_user_reservation_details.dart';
import '../../utils/global.dart';
import '../../utils/log_util.dart';
import '../../utils/my_application.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../LoginScreen.dart';
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
  void _showLogoutDialog() {
    if (_isDialogShowing || !mounted) return;

    _isDialogShowing = true;
    print("📱 Showing logout dialog from reservation screen");

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
            content: Text("Please check your Internet. Please logout and login again to continue."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                  logutAPi(valueShared_BEARER_KEY);
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
    WidgetsBinding.instance.addObserver(this);

    // ✅ Start internet monitoring
    _startInternetMonitoring();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExistingReservations();
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
        // ✅ STEP 5: Close drawer
        Navigator.of(context).pop();

        // ✅ STEP 6: Navigate to login with complete reset
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
    _internetCheckTimer?.cancel(); // ✅ Cancel internet timer
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
          padding: EdgeInsets.all(10),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: "Mulish",
                                  color: Colors.black),
                            );
                          }),
                          IconButton(
                              iconSize: 33,
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
                        Text('No reservations found')
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
                          // Navigate to ReservationDetails with callback
                          await Get.to(
                                () => ReservationDetails(reserv.id.toString()),
                          )?.then((result) async {
                            // This callback executes when returning from ReservationDetails
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
                                        '${reserv.reservedFor.toString()}',
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
                                        'Order ID :',
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
          'Error',
          'Failed to load reservation details',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
  // Update the openCalendarScreen method
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
}