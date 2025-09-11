import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/models/get_discount_percentage_response_model.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/discount_change_response_model.dart';

class Discount extends StatefulWidget {
  const Discount({super.key});

  @override
  State<Discount> createState() => _DiscountState();
}

class _DiscountState extends State<Discount> {
  late PageController _pageController;
  SharedPreferences? sharedPreferences; // Changed to nullable
  String? storeId;
  bool isLoading = false;
  final TextEditingController _discountDeliveryController = TextEditingController();
  final TextEditingController _pickUpDiscountController = TextEditingController();
  DateTime _selectedDate = DateTime.now(); // Start with today's date
  String? deliveryDiscountId; // int se string change karo
  String? pickupDiscountId;
  // Store current discounts from API
  List<GetDiscountPercentageResponseModel> currentDiscounts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences(); // Initialize SharedPreferences first
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getPercentage();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _discountDeliveryController.dispose();
    _pickUpDiscountController.dispose();
    super.dispose();
  }

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  // Function to show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate, // Ensure initialDate is not before today
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('managee'.tr,
                style: TextStyle(fontSize: 18,fontWeight: FontWeight.w800,fontFamily: 'Mulish'),),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Text('${'delivery_discount'.tr} (%)',
                        style: TextStyle(fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 13),),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 44,
                        padding: EdgeInsets.only(left: 12,bottom: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _discountDeliveryController,
                          textAlign: TextAlign.left,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,fontFamily: 'Mulish'
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            // Handle value change
                            print('Discount changed to: $value');
                          },
                        ),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${'pickup_discount'.tr} (%)',
                        style: TextStyle(fontFamily: 'Mulish',fontWeight: FontWeight.w700,fontSize: 13),),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 44,
                        padding: EdgeInsets.only(left: 12,bottom: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _pickUpDiscountController,
                          textAlign: TextAlign.left,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,fontFamily: 'Mulish'
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            // Handle value change
                            print('Pickup changed to: $value');
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('expiry'.tr,
                style: TextStyle(fontSize: 13,fontWeight: FontWeight.w700,fontFamily: 'Mulish'),),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _selectDate, // Add tap functionality
                child: Container(
                  height: 44,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate), // Format selected date
                        style: TextStyle(fontFamily: 'Mulish',fontSize: 15,fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.calendar_month_rounded,color: Colors.black,)
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: (){
                  _saveDiscounts();
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration:BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Color(0xFF0C831F),
                  ) ,
                  child:Center(
                    child: Text('saved'.tr,style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700,fontSize: 20,fontFamily: 'Mulish',
                    ),),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('current'.tr,
                style: TextStyle(fontSize: 14,fontWeight: FontWeight.w800,fontFamily: 'Mulish'),),
              SizedBox(height: 10),
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECF8FF),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width*0.5,
                          child:  Text('type'.tr,style: TextStyle(
                              fontWeight: FontWeight.w700,fontSize: 13,fontFamily: 'Mulish'
                          ),),
                        ) ,
                        Text('value'.tr,style: TextStyle(
                            fontWeight: FontWeight.w700,fontSize: 13,fontFamily: 'Mulish'
                        ),)
                      ],
                    ),
                  ),
                  // Dynamically build discount rows from API data
                  if (currentDiscounts.isEmpty)
                    Container(
                      padding: EdgeInsets.all(15),
                      child: Text('no_current'.tr,
                        style: TextStyle(fontFamily: 'Mulish', fontSize: 12),
                      ),
                    )
                  else
                    ...currentDiscounts.map((discount) => Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width*0.5,
                                child: Text(discount.code ?? 'Unknown',style: const TextStyle(
                                    fontWeight: FontWeight.w500,fontSize: 12,fontFamily: 'Mulish'
                                ),),
                              ),
                              Text('${discount.valueAsInt}%',style: const TextStyle(
                                  fontWeight: FontWeight.w500,fontSize: 12,fontFamily: 'Mulish'
                              ),)
                            ],
                          ),
                        ),
                        if (discount != currentDiscounts.last)
                          Divider(color: Color(0xFFAEC2DF)),
                      ],
                    )).toList(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getPercentage() async {

    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      setState(() {
        isLoading = false;
      });
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
      List<GetDiscountPercentageResponseModel> discounts = await CallService().getDiscountPercentage(storeId!);
      Get.back();
      setState(() {
        isLoading = false;
        if (discounts.isNotEmpty) {
          print('Getting Discount Percentage Response - Found ${discounts.length} discounts');
          currentDiscounts = discounts;

          // Populate text fields with API values
          // Populate text fields with API values
          // Populate text fields with API values
          for (var discount in discounts) {
            print('Discount type: ${discount.type}, value: ${discount.value}, code: ${discount.code}, ID: ${discount.id}');

            if (discount.code?.toLowerCase().contains('delivery') == true) {
              _discountDeliveryController.text = '${discount.valueAsInt}';
              deliveryDiscountId = discount.id?.toString(); // Convert to string
              print('Setting delivery discount: ${discount.valueAsInt}, ID: ${deliveryDiscountId}');
            } else if (discount.code?.toLowerCase().contains('pickup') == true) {
              _pickUpDiscountController.text = '${discount.valueAsInt}';
              pickupDiscountId = discount.id?.toString(); // Convert to string
              print('Setting pickup discount: ${discount.valueAsInt}, ID: ${pickupDiscountId}');
            }
          }
        }
      });

    } catch (e) {
      Get.back();
      print('Error getting discount percentage: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveDiscounts() async {
    if (sharedPreferences == null) {
      Get.snackbar('error'.tr, 'shared'.tr);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('error'.tr, 'storeId'.tr);
      return;
    }

    // Validation - check if at least one field has value
    if (_discountDeliveryController.text.isEmpty && _pickUpDiscountController.text.isEmpty) {
      Get.snackbar('error'.tr, 'at_least'.tr);
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

      // Create list of maps for both discounts
      List<Map<String, dynamic>> discountMaps = [];
// Add delivery discount if controller has value
      if (_discountDeliveryController.text.isNotEmpty && deliveryDiscountId != null) {
        var deliveryMap = {
          "code": "DELIVERY_DISCOUNT",
          "type": "percentage",
          "value": int.tryParse(_discountDeliveryController.text) ?? 0,
          "expires_at": _selectedDate.toIso8601String(),
          "store_id": storeId
        };
        print("Delivery Discount ID: $deliveryDiscountId");
        print("Delivery Discount Map: $deliveryMap");

        ChangeDiscountPercentageResponseModel model = await CallService().changeDiscount(deliveryMap, deliveryDiscountId!);
      }

// Add pickup discount if controller has value
      if (_pickUpDiscountController.text.isNotEmpty && pickupDiscountId != null) {
        var pickupMap = {
          "code": "PICKUP_DISCOUNT",
          "type": "percentage",
          "value": int.tryParse(_pickUpDiscountController.text) ?? 0,
          "expires_at": _selectedDate.toIso8601String(),
          "store_id": storeId
        };
        print("Pickup Discount ID: $pickupDiscountId");
        print("Pickup Discount Map: $pickupMap");

        ChangeDiscountPercentageResponseModel model = await CallService().changeDiscount(pickupMap, pickupDiscountId!);
      }


      setState(() {
        isLoading = false;
      });

      await getPercentage(); // Refresh data
      Get.back(); // Close loading dialog
      Get.snackbar('success'.tr, 'discoun'.tr);

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.back();
      print('Save discount error: $e');
      Get.snackbar('error'.tr, '${'failed_discoun'.tr}: ${e.toString()}');
    }
  }

}