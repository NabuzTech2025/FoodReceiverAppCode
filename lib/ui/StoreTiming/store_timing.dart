// import 'package:flutter/material.dart';
// import 'package:food_app/ui/StoreTiming/store_hour_bottomsheet.dart';
// import 'package:get/get.dart';
// import 'package:lottie/lottie.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../api/repository/api_repository.dart';
// import '../../constants/constant.dart';
// import '../../customView/CustomAppBar.dart';
// import '../../customView/CustomDrawer.dart';
// import '../../models/add_new_store_timing_response_model.dart';
// import '../../models/get_store_timing_response_model.dart';
//
// class StoreTiming extends StatefulWidget {
//   const StoreTiming({super.key});
//
//   @override
//   State<StoreTiming> createState() => _StoreTimingState();
// }
//
// class _StoreTimingState extends State<StoreTiming> {
//   late PageController _pageController;
//   bool isLoading=false;
//   String? storeId;
//   SharedPreferences? sharedPreferences;
//   List<DayModel> days = [
//     DayModel(day: 'M', isSelected: true),
//     DayModel(day: 'T', isSelected: false),
//     DayModel(day: 'W', isSelected: true),
//     DayModel(day: 'T', isSelected: true),
//     DayModel(day: 'F', isSelected: true),
//     DayModel(day: 'S', isSelected: true),
//     DayModel(day: 'S', isSelected: true),
//   ];
//
//   void _openTab(int index) {
//     if (_pageController.hasClients &&
//         _pageController.page == index.toDouble()) {
//       print("Already on tab $index. Skipping.");
//       return;
//     }
//   }
//
//   Future<void> _initializeSharedPreferences() async {
//     try {
//       sharedPreferences = await SharedPreferences.getInstance();
//       await getStoreTiming();
//     } catch (e) {
//       print('Error initializing SharedPreferences: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//   @override
//   void initState() {
//     _pageController = PageController(initialPage: 0);
//     _initializeSharedPreferences();
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       drawer: CustomDrawer(onSelectTab: _openTab),
//       appBar: CustomAppBar(),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Store Hours', style: TextStyle(
//                       fontFamily: 'Mulish', fontSize: 18, fontWeight: FontWeight.bold
//                   )),
//                   GestureDetector(
//                     onTap: (){
//                       showAddStoreHoursBottomSheet(context);
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(3),
//                         color: const Color(0xFFFCAE03),
//                       ),
//                       child: const Center(
//                         child: Text('Add New', style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 12,
//                           fontFamily: 'Mulish',
//                         )),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 10),
//               Container(
//                 padding: EdgeInsets.all(15),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFECF8FF),
//                 ),
//                 child: Row(
//                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       width: MediaQuery.of(context).size.width * 0.6,
//                       child:  Text('Morning', style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: 13,
//                           fontFamily: 'Mulish'
//                       )),
//                     ),
//                     const Row(
//                       children: [
//                         Text('Start', style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 13,
//                             fontFamily: 'Mulish'
//                         )),
//                         SizedBox(width: 20),
//                         Text('End', style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 13,
//                             fontFamily: 'Mulish'
//                         )),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//               SizedBox(height: 10,),
//               Container(
//                 padding: EdgeInsets.all(10),
//                 child: Row(
//                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Days circles
//                     Container(
//                       width: MediaQuery.of(context).size.width*0.6,
//                       child: Row(
//                         children: days.asMap().entries.map((entry) {
//                           int index = entry.key;
//                           DayModel day = entry.value;
//
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 2),
//                             child: GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   days[index].isSelected = !days[index].isSelected;
//                                 });
//                               },
//                               child: Container(
//                                 width: 28,
//                                 height: 28,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: day.isSelected
//                                       ? Colors.green
//                                       : Colors.white,
//                                   border: Border.all(
//                                     color: day.isSelected
//                                         ? Colors.green
//                                         : Colors.black,
//                                     width: 1,
//                                   ),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     day.day,
//                                     style: TextStyle(
//                                       color: day.isSelected
//                                           ? Colors.white
//                                           : Colors.black,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 10,
//                                       fontFamily: 'Mulish',
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//
//                     // Time display
//                     const Row(
//                       children: [
//                         Text('08:00', style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                             fontFamily: 'Mulish'
//                         )),
//                         SizedBox(width: 20),
//                         Text('12:00', style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                             fontFamily: 'Mulish'
//                         )),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(color: Color(0xFFAEC2DF),),
//               Container(
//                 padding: EdgeInsets.all(15),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFECF8FF),
//                 ),
//                 child: Row(
//                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       width: MediaQuery.of(context).size.width * 0.6,
//                       child: const Text('Morning', style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: 13,
//                           fontFamily: 'Mulish'
//                       )),
//                     ),
//                     const Row(
//                       children: [
//                         Text('Start', style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 13,
//                             fontFamily: 'Mulish'
//                         )),
//                         SizedBox(width: 30),
//                         Text('End', style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 13,
//                             fontFamily: 'Mulish'
//                         )),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//               SizedBox(height: 10,),
//               Container(
//                 padding: EdgeInsets.all(10),
//                 child: Row(
//                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Days circles
//                     Container(
//                       width: MediaQuery.of(context).size.width*0.6,
//                       child: Row(
//                         children: days.asMap().entries.map((entry) {
//                           int index = entry.key;
//                           DayModel day = entry.value;
//
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 2),
//                             child: GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   days[index].isSelected = !days[index].isSelected;
//                                 });
//                               },
//                               child: Container(
//                                 width: 28,
//                                 height: 28,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: day.isSelected
//                                       ? Colors.green
//                                       : Colors.white,
//                                   border: Border.all(
//                                     color: day.isSelected
//                                         ? Colors.green
//                                         : Colors.black,
//                                     width: 1,
//                                   ),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     day.day,
//                                     style: TextStyle(
//                                       color: day.isSelected
//                                           ? Colors.white
//                                           : Colors.black,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 10,
//                                       fontFamily: 'Mulish',
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//
//                     // Time display
//                     const Row(
//                       children: [
//                         Text('08:00', style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                             fontFamily: 'Mulish'
//                         )),
//                         SizedBox(width: 20),
//                         Text('12:00', style: TextStyle(
//                             fontWeight: FontWeight.w700,
//                             fontSize: 14,
//                             fontFamily: 'Mulish'
//                         )),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(color: Color(0xFFAEC2DF),),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   // Function to show the bottom sheet
//   void showAddStoreHoursBottomSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//         ),
//         child: const AddStoreHoursBottomSheet(),
//       ),
//     );
//   }
//
//   Future<void> getStoreTiming() async {
//
//     if (sharedPreferences == null) {
//       print('SharedPreferences not initialized yet');
//       return;
//     }
//
//     storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
//
//     if (storeId == null) {
//       print('Store ID not found in SharedPreferences');
//       setState(() {
//         isLoading = false;
//       });
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       Get.dialog(
//         Center(
//             child: Lottie.asset(
//               'assets/animations/burger.json',
//               width: 150,
//               height: 150,
//               repeat: true,
//             )
//         ),
//         barrierDismissible: false,
//       );
//       List<GetStoreTimingResponseModel> storeTiming = await CallService().getStoreTiming(storeId!);
//       Get.back();
//       setState(() {
//         isLoading = false;
//       });
//
//     } catch (e) {
//       Get.back();
//       print('Error getting Store Timing: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
// }
//
// // Model class for day data
// class DayModel {
//   final String day;
//   bool isSelected;
//
//   DayModel({
//     required this.day,
//     this.isSelected = false,
//   });
// }
import 'package:flutter/material.dart';
import 'package:food_app/ui/StoreTiming/store_hour_bottomsheet.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/add_new_store_timing_response_model.dart';
import '../../models/get_store_timing_response_model.dart';

class StoreTiming extends StatefulWidget {
  const StoreTiming({super.key});

  @override
  State<StoreTiming> createState() => _StoreTimingState();
}

class _StoreTimingState extends State<StoreTiming> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;

  // Store timing data from API
  List<GetStoreTimingResponseModel> storeTimingList = [];

  // Days array for mapping day numbers to names
  List<String> dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getStoreTiming();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Text('store_hour'.tr, style: TextStyle(
                      fontFamily: 'Mulish', fontSize: 18, fontWeight: FontWeight.bold
                  )),
                  GestureDetector(
                    onTap: () {
                      showAddStoreHoursBottomSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: const Color(0xFFFCAE03),
                      ),
                      child:  Center(
                        child: Text('add'.tr, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Mulish',
                        )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Display store timing data
              buildTimingCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTimingCards() {
    if (storeTimingList.isEmpty) {
      if (isLoading) {
        return  Center(child:Container());
      } else {
        return const Center(child: Text('No store timing data available'));
      }
    }

    // Group timings by name
    Map<String, List<GetStoreTimingResponseModel>> groupedTimings = {};
    for (var timing in storeTimingList) {
      String name = timing.name ?? 'Timing';
      if (!groupedTimings.containsKey(name)) {
        groupedTimings[name] = [];
      }
      groupedTimings[name]!.add(timing);
    }

    // Build cards for each group
    return Column(
      children: groupedTimings.entries.map((entry) {
        String timingName = entry.key;
        List<GetStoreTimingResponseModel> timings = entry.value;

        // Get all days for this timing group
        List<int> selectedDays = timings.map((t) => t.dayOfWeek ?? -1).where((day) => day >= 0 && day <= 6).toList();

        // Get opening and closing time (assuming same for all days in group)
        String openingTime = timings.isNotEmpty ? (timings.first.openingTime ?? '00:00') : '00:00';
        String closingTime = timings.isNotEmpty ? (timings.first.closingTime ?? '00:00') : '00:00';
        int? timingId = timings.isNotEmpty ? timings.first.id : null;
         print('timing id is $timingId');
        return buildTimingCard(timingName, selectedDays, openingTime, closingTime,timingId);
      }).toList(),
    );
  }

  // buildTimingCard method में edit button ke tap event को update करें
  Widget buildTimingCard(String timingName, List<int> selectedDays, String openingTime, String closingTime,int? timingId) {
    return Column(
      children: [
        // Header with timing name
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: Color(0xFFECF8FF),
          ),
          child: Row(
            children: [
              Expanded(  // Changed from Container with fixed width
                child: Text(
                  timingName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'Mulish'
                  ),
                ),
              ),
             Row(
                children: [
                  Text('open'.tr, style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'Mulish'
                  )),
                  SizedBox(width: 20),
                  Text('close'.tr, style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamily: 'Mulish'
                  )),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Row(
                  children: List.generate(7, (index) {
                    bool isSelected = selectedDays.contains(index);

                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.green : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Row(
                  children: [
                    Text(
                      openingTime.substring(0, 5),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Mulish'
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      closingTime.substring(0, 5),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Mulish'
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Edit button
                    GestureDetector(
                      onTap: () {
                        showEditStoreHoursBottomSheet(
                            context,
                            timingName,
                            selectedDays,
                            openingTime,
                            closingTime
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff0C831F)
                        ),
                        child: const Center(
                          child: Icon(Icons.mode_edit_outline_outlined, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Delete button
                    GestureDetector(
                      onTap: () {
                        if (timingId != null) {
                          _showDeleteConfirmation(context, timingName, timingId);
                        } else {
                          Get.snackbar('Error', 'Invalid timing ID');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffE25454)
                        ),
                        child: const Center(
                          child: Icon(Icons.delete_outline, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFFAEC2DF)),
      ],
    );
  }

// Delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String timingName, int timingId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
           // margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(15),
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
                SizedBox(height: 20,),
                Text(
                  '${"are".tr} "$timingName"',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    fontFamily: 'Mulish'
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 35,
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E9AAF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child:  Text(
                          'cancel'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),
                    Container(
                      height: 35,
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE25454),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                          _deleteStoreTiming(timingId);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child:  Text(
                          'delete'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
              top: -20,
              child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFED4C5C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),)
        ]
        ),
      ),
    );
  }
  Future<void> _deleteStoreTiming(int timingId) async {
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

    try {
      await CallService().deleteStoreTiming(timingId);

      Get.back();
      Get.snackbar('Success', 'Tax deleted successfully');

      await getStoreTiming(showLoader: false);

    } catch (e) {
      Get.back();
      print('Error deleting timing: $e');
      Get.snackbar('Error', 'Failed to delete timing');
    }
  }

// New method to show edit bottom sheet
  void showEditStoreHoursBottomSheet(
      BuildContext context,
      String timingName,
      List<int> selectedDays,
      String openingTime,
      String closingTime
      )
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddStoreHoursBottomSheet(
          isEditMode: true,
          editTimingName: timingName,
          editSelectedDays: selectedDays,
          editOpeningTime: openingTime,
          editClosingTime: closingTime,
          onDataAdded: () {
            getStoreTiming(showLoader: false); // Refresh data without loader
          },
        ),
      ),
    );
  }
  Future<void> getStoreTiming({bool showLoader = true}) async {
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

    if (showLoader) {
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
            )
        ),
        barrierDismissible: false,
      );
    }

      try {

      List<GetStoreTimingResponseModel> storeTiming = await CallService().getStoreTiming(storeId!);

      if (showLoader) {
        Get.back();
      }

      setState(() {
        storeTimingList = storeTiming; // Store the API response
        isLoading = false;
      });

    } catch (e) {
        if (showLoader) {
          Get.back();
        }
      print('Error getting Store Timing: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
}

class DayModel {
  final String day;
  bool isSelected;

  DayModel({
    required this.day,
    this.isSelected = false,
  });
}