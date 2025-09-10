import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/reservation/accept_decline_reservation_response_model.dart';
import '../../models/reservation/edit_reservation_details_response_model.dart';
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
      status = '',
      email = '';
  Timer? _orderTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getFullReservationDetails();
    });
  }
  @override
  void dispose() {
    _orderTimer?.cancel();
    super.dispose();
  }
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
      body: isLoading == true
          ? Center(
        child: Lottie.asset(
          'assets/animations/burger.json',
          width: 150,
          height: 150,
          repeat: true,
        ),
      ) : Padding(
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
                'Date: ${formatDateTime(date)}',
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
                  'Reservation Date :  ${formatDateTime(reservation)}',
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
            status.toLowerCase() == 'pending' || status.isEmpty
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    acceptDeclineReservation('cancelled');
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
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    acceptDeclineReservation('booked');
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
              ],
            )
                : Center(
              child: InkWell(
                onLongPress: status.toLowerCase() == 'booked' ? () {
                  _showEditBottomSheet();
                } : null,
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
      email = model.customerEmail.toString();

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
      _orderTimer = Timer(Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("order Timeout", "request timed out. Please try again.");
        }
      });

      var map = {"user_id": 0, "status": statusToUpdate};

      print("Status Map: $map");

      GetOrderStatusResponseModel model =
      await CallService().acceptDeclineReservation(map, id);

      await Future.delayed(Duration(seconds: 2));
      _orderTimer?.cancel();
      print("Reservation status updated successfully to: $statusToUpdate");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      Get.back(); // Close loading dialog
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
      _orderTimer?.cancel();
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

  Future<void> _editReservationDetail(String name, String phoneNum, String emailText,
      String guestCount, String reservationDate, String noteText) async
  {

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

      var map = {
        "user_id": 0,
        "guest_count": int.tryParse(guestCount) ?? 2,
        "reserved_for": reservationDate,
        "status": "booked",
        "table_number": 0,
        "customer_name": name,
        "customer_phone": phoneNum,
        "customer_email": emailText,
        "note": noteText,
        "isActive": true
      };

      print("Edit Reservation Map: $map");
      EditReservationDetailsResponseModel model = await CallService().editReservationDetails(map, widget.id.toString());

      print("Reservation updated successfully");

      setState(() {
        isLoading = false;
      });

      Get.back();
      Get.back();
      await getFullReservationDetails();

      Get.snackbar(
        'Success',
        'Reservation updated successfully',
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
      print('Edit error: $e');
      Get.snackbar(
        'Error',
        'Failed to update reservation: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 1),
      );
    }
  }

  void _showEditBottomSheet() {
    final TextEditingController nameController = TextEditingController(text: customerName);
    final TextEditingController phoneController = TextEditingController(text: phone);
    final TextEditingController guestController = TextEditingController(text: guest);
    final TextEditingController reservationController = TextEditingController(text: reservation);
    final TextEditingController noteController = TextEditingController(text: note);
    final TextEditingController emailController = TextEditingController(text: email);
    Get.bottomSheet(
      Stack(clipBehavior: Clip.none,
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
              // Drag Handle
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
                child: const Center(
                  child: Text(
                    'Edit Reservation',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                      _buildEditableField('Customer Name', nameController, Icons.person),
                      _buildEditableField('Phone Number', phoneController, Icons.phone),
                      _buildEditableField('Email Address', emailController, Icons.email),
                      _buildEditableField('Guest Count', guestController, Icons.group),
                      _buildEditableField('Reservation Date & Time', reservationController, Icons.calendar_today),
                      _buildEditableField('Special Note', noteController, Icons.note, maxLines: 3),

                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.symmetric(horizontal: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: 20),
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.orange,
                                                  size: 50,
                                                ),
                                                SizedBox(height: 15),
                                                Text(
                                                  'Cancel Reservation?',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.black,
                                                      fontFamily: 'Mulish'
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  'Are you sure you want to cancel this reservation? This action cannot be undone.',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.grey[600],
                                                      fontFamily: 'Mulish'
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 30),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.grey[300],
                                                          foregroundColor: Colors.black87,
                                                          minimumSize: Size(0, 45),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'No',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w700,
                                                              fontFamily: 'Mulish',
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 15),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          Navigator.of(context).pop();
                                                          Get.back();
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
                                                          await cancelReservation('cancelled');
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Color(0xFFE25454),
                                                          foregroundColor: Colors.white,
                                                          minimumSize: Size(0, 45),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'Yes',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w700,
                                                              fontFamily: 'Mulish',
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: -15,
                                            child: Center(
                                              child: GestureDetector(
                                                onTap: () => Navigator.of(context).pop(),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFED4C5C),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black12,
                                                        blurRadius: 6,
                                                        offset: Offset(0, 2),
                                                      )
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text('Cancel Reserv',style: TextStyle(
                                fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 14,),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _editReservationDetail(
                                  nameController.text,
                                  phoneController.text,
                                  emailController.text,
                                  guestController.text,
                                  reservationController.text,
                                  noteController.text,
                                );
                              },
                              child: Text(
                                'Save Reserv.',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
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
      ]),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      enterBottomSheetDuration: Duration(milliseconds: 300),
      exitBottomSheetDuration: Duration(milliseconds: 200),
    );
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

  Widget _buildEditableField(String label, TextEditingController controller,
      IconData icon, {int maxLines = 1}) {
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
              keyboardType: _getKeyboardType(label),
              readOnly: label == 'Reservation Date & Time' ? true : false,
              onTap: label == 'Reservation Date & Time' ? () => _selectReservationDateTime(controller) : null,
              style: TextStyle(
                fontFamily: 'Mulish',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _getEditHintText(label),
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Mulish',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                ),
                suffixIcon: label == 'Reservation Date & Time'
                    ? Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 24)
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
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

  String _getEditHintText(String label) {
    switch (label) {
      case 'Customer Name':
        return 'Enter customer name';
      case 'Phone Number':
        return 'Enter phone number';
      case 'Email Address':
        return 'Enter email address';
      case 'Guest Count':
        return 'Enter guest count';
      case 'Reservation Date & Time':
        return 'Select date and time';
      case 'Special Note':
        return 'Add special note';
      default:
        return '';
    }
  }

  Future<void> _selectReservationDateTime(TextEditingController controller) async {
    // Step 1: Select Date
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Start date is current date
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Step 2: Select Time Slot
      await _selectTimeSlot(selectedDate, controller);
    }
  }

  Future<void> _selectTimeSlot(DateTime selectedDate, TextEditingController controller) async {
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
          'Restaurant Closed',
          'No available time slots for today. Restaurant might be closed or all slots are past.',
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
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
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
                        'Select Time Slot',
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
              child: Text(
                'Date: ${DateFormat('dd-MM-yyyy (EEEE)').format(selectedDate)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Mulish',
                  color: Colors.blue.shade800,
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
                          'Time Selected',
                          'Reservation time updated to ${slot.displayTime}',
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

  Future<void> cancelReservation(String statusToUpdate) async {
    String id = widget.id;
    try {
      // Timer for timeout (loader is already shown from the button press)
      _orderTimer = Timer(Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("Order Timeout", "Request timed out. Please try again.");
        }
      });

      var map = {"user_id": 0, "status": statusToUpdate};
      print("Status Map: $map");

      GetOrderStatusResponseModel model = await CallService().acceptDeclineReservation(map, id);

      await Future.delayed(Duration(seconds: 1));
      _orderTimer?.cancel();

      print("Reservation status updated successfully to: $statusToUpdate");

      // Close the loader
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Refresh the reservation details
      await getFullReservationDetails();

      // Show success message
      Get.snackbar(
        'Success',
        'Reservation cancelled successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 1),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );

    } catch (e) {
      _orderTimer?.cancel();
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('Cancel reservation error: $e');
      Get.snackbar(
        'Error',
        'Failed to cancel reservation: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }
}

class TimeSlot {
  final String time;
  final String displayTime;

  TimeSlot(this.time, this.displayTime);
}