import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/customView/CustomAppBar.dart';
import 'package:food_app/customView/CustomDrawer.dart';
import 'package:food_app/models/driver/get_deliver_driver_response_model.dart';
import 'package:food_app/ui/Driver/create_driver.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/constant.dart';
import 'delivery_order.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  late PageController _pageController;
  late SharedPreferences sharedPreferences; // ✅ Added SharedPreferences instance
  String? storeId;
  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
    _initializeData(); // ✅ Initialize data on screen load
  }

  bool isLoading = false;

  // ✅ NEW: Initialize SharedPreferences and get store ID
  Future<void> _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    storeId = sharedPreferences.getString(valueShared_STORE_KEY);
    print("✅ Driver Screen - Store ID loaded: $storeId");

    // Automatically load driver data when screen initializes
    if (storeId != null && storeId!.isNotEmpty) {
      getSpecificStoreDriver(storeId!);
    } else {
      print("❌ Driver Screen - No store ID found");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
       drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: CustomAppBar(),
      body: Padding(
        padding:  EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('23july, 2025',
                      style: TextStyle(fontSize: 12,fontFamily: 'Mulish',fontWeight: FontWeight.w800),
                    ),
                    Icon(Icons.arrow_drop_down,size: 30,)
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: (){
                        Get.to(()=>DeliveryOrder());
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration:BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Color(0xFFFCAE03),
                        ) ,
                        child: const Center(
                          child: Text('Delivery Order',style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700,fontSize: 12,fontFamily: 'Mulish',
                          ),),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8,),
                    GestureDetector(
                      onTap: (){
                        Get.to(()=>CreateDriver());
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration:BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Color(0xFF49B27A),
                        ) ,
                        child: const Center(
                          child: Text('Create Driver',style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700,fontSize: 12,fontFamily: 'Mulish',
                          ),),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Total Amount : 20',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('Total Cash : 2',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('Total Online : 2',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                const SizedBox(width: 3,),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Total Driver : 20',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('Order Delivered : 20',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('Order Pending : 20',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                const SizedBox(width: 3,),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text('Order Assigned: 20',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 10,),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('Delivery Cancelled : 10',style: TextStyle(
                      fontFamily: "Mulish",fontWeight: FontWeight.w700,fontSize: 10,color: Colors.black
                  ),),
                ),
                SizedBox(width: 3,),
              ],
            ),
            ListView.builder(
              itemCount: 3,
              padding: EdgeInsets.zero,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context,index){
              return Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          color: Colors.transparent,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Center(
                                child: Text(
                                  'Shiv Charan',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: "Mulish",
                                      height: 0),
                                ),
                              ),
                              Positioned(
                                right: -5,
                                top: -8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xff0C831F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text('ON THE WAY',style: TextStyle(
                              color: Color(0xFF49B27A),
                                fontWeight: FontWeight.w800,fontFamily: 'Mulish',fontSize: 10
                            ),),
                            SizedBox(width: 10,),
                            Container(
                              height: 32,width: 32,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SvgPicture.asset('assets/images/call.svg',),
                                  )
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Delivery  : 20',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                        Text('Delivered  : 15',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                        Text('Assigned  : 15',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0),
                      child: Center(
                        child: Text('Cancelled  : 20',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                      ),
                    ),
                    Divider(color: Colors.black,thickness: 2,),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount  : 200',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                        Text('Cash  : 100',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                        Text('Online  : 100',style: TextStyle(
                            fontFamily: "Mulish",fontWeight: FontWeight.w800,fontSize: 12,color: Colors.black
                        ),),
                      ],
                    ),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  Future<void> getSpecificStoreDriver(String storeId) async {

    setState(() {
      isLoading = true;
    });

    try{

      GetSpecificStoreDeliveryDriverResponseModel model = await CallService().getDeliveryDriver(storeId);

      setState(() {
        isLoading = false;


        print('Specific Village Consumer List value is');
      });
    }catch(e){
      setState(() {
        isLoading = false;

      });
    }

  }

}