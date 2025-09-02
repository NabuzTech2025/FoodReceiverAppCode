import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../models/reservation/accept_decline_reservation_response_model.dart';
import '../../models/reservation/get_reservation_table_full_details.dart';

class ReservationDetails extends StatefulWidget {
  final String id;
  const ReservationDetails(this.id, {super.key});

  @override
  State<ReservationDetails> createState() => _ReservationDetailsState();
}

class _ReservationDetailsState extends State<ReservationDetails> {
  bool isLoading = false;
  String orderId = '',
      date = '',
      customerName = '',
      phone = '',
      guest = '',
      reservation = '',
      note = '',
      status = ''; // Added status variable

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding.instance.addPostFrameCallback to delay the call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getFullReservationDetails();
    });
  }

  // Method to get status color based on string status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'booked':
      case 'accepted':
        return Colors.green;
      case 'cancelled':
      case 'decline':
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'details'.tr,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Get.back(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/images/reservationIcon.png',
                height: 20,
                width: 20,
              ),
            ),
          ],
        ),
        leadingWidth: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Color(0xff757B8F)),
            Center(
              child: Text(
                'Order ID: ${orderId}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFamily: 'Mulish'),
              ),
            ),
            Center(
              child: Text(
                'Date: ${date}',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Mulish'),
              ),
            ),
            Divider(color: Color(0xff757B8F)),
            Text(
              'Customer : ${customerName}',
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Text(
              'Phone : ${phone} ',
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Text(
              'Guest : ${guest}',
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Divider(color: Color(0xff757B8F)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation Date :  ${reservation}',
                  style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 5)
              ],
            ),
            SizedBox(height: 5),
            Divider(color: Color(0xff757B8F)),
            SizedBox(height: 5),
            Text(
              'Note:  ${note}',
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            Spacer(),

            // Show status if reservation is already processed, otherwise show buttons
            status.toLowerCase() == 'pending' || status.isEmpty
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    acceptDeclineReservation('booked'); // Accept with 'booked' status
                  },
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.green, borderRadius: BorderRadius.circular(5)),
                    child: const Center(
                      child: Text(
                        'Accept',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    acceptDeclineReservation('cancelled'); // Decline with 'cancelled' status
                  },
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red, borderRadius: BorderRadius.circular(5)),
                    child: const Center(
                      child: Text(
                        'Decline',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: getStatusColor(status),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Status: ${status.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Mulish',
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> getFullReservationDetails() async {
    String reservationId = widget.id;
    print('reservatiod id is $reservationId');

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
      GetOrderDetailsResponseModel model =
      await CallService().getReservationFullDetails(reservationId);
      orderId = model.id.toString();
      date = model.createdAt.toString();
      customerName = model.customerName.toString();
      phone = model.customerPhone.toString();
      guest = model.guestCount.toString();
      reservation = model.reservedFor.toString();
      note = model.note.toString();
      status = model.status.toString();

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      setState(() {
        isLoading = false;
        print('Reservation Table Customer Name is $customerName');
        print('Reservation Status is $status');
      });
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> acceptDeclineReservation(String statusToUpdate) async {
    String id = widget.id;
    try {
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

      var map = {"user_id": 0, "status": statusToUpdate};

      print("Status Map: $map");

      GetOrderStatusResponseModel model =
      await CallService().acceptDeclineReservation(map, id);

      await Future.delayed(Duration(seconds: 2));

      print("Reservation status updated successfully to: $statusToUpdate");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      Get.back(); // Close loading dialog

      // Refresh the reservation details to show updated status
      await getFullReservationDetails();

      Get.snackbar(
        'Success',
        'Reservation ${statusToUpdate == 'booked' ? 'accepted' : 'declined'} successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: statusToUpdate == 'booked' ? Colors.green : Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 1),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      Get.back(); // Close loading dialog
      print('Status error: $e');
      Get.snackbar('Error', 'Failed to Update Status: ${e.toString()}');
    }
  }
}