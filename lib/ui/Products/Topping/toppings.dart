import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../customView/CustomAppBar.dart';
import '../../../customView/CustomDrawer.dart';
import '../../../models/get_toppings_response_model.dart';

class ToppingsScreen extends StatefulWidget {
  const ToppingsScreen({super.key});

  @override
  State<ToppingsScreen> createState() => _ToppingsScreenState();
}

class _ToppingsScreenState extends State<ToppingsScreen> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;

  int currentPage = 1;
  int itemsPerPage = 8;
  int totalPages = 0;

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }
  void _updatePagination() {
    // totalPages = (productList.length / itemsPerPage).ceil();
    // if (totalPages == 0) totalPages = 1;
    //
    // // Ensure current page is valid
    // if (currentPage > totalPages) currentPage = totalPages;
    // if (currentPage < 1) currentPage = 1;
    //
    // // Get items for current page
    // int startIndex = (currentPage - 1) * itemsPerPage;
    // int endIndex = startIndex + itemsPerPage;
    // if (endIndex > productList.length) endIndex = productList.length;
    //
    // currentPageItems = productList.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
        _updatePagination();
      });
    }
  }

  List<int> _getPageNumbers() {
    List<int> pages = [];

    if (totalPages <= 5) {
      // Show all pages if total is 5 or less
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      // Show current page with 2 pages on each side
      int start = currentPage - 2;
      int end = currentPage + 2;

      if (start < 1) {
        start = 1;
        end = 5;
      }

      if (end > totalPages) {
        end = totalPages;
        start = totalPages - 4;
      }

      for (int i = start; i <= end; i++) {
        pages.add(i);
      }
    }

    return pages;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('topping'.tr,
                            style: TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                           // _showAddProductBottomSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: const Color(0xFFFCAE03),
                            ),
                            child: Center(
                              child: Text('add'.tr,
                                  style: TextStyle(
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
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('',
                        // 'Showing ${(currentPage - 1) * itemsPerPage +
                        //     1} to ${(currentPage - 1) * itemsPerPage +
                        //     currentPageItems.length} of ${productList
                        //     .length} entries',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Mulish',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECF8FF),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.44,
                          child: Text('topping_name'.tr,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Mulish'),
                          ),
                        ),
                        Container(
                          child: Text('desc'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish')),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.2,
                          child: Center(
                            child: Text('Price'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish'),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                     // itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        return Slidable(
                          key: ValueKey(index),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.502,
                            children: [
                              Container(
                                width: 60,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xffE25454),
                                ),
                                child: Icon(
                                  Icons.airplanemode_active,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              GestureDetector(
                                //onTap: () => _editProduct(index),
                                child: Container(
                                  width: 60,
                                  height: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xff0C831F),
                                  ),
                                  child: const Icon(
                                    Icons.mode_edit_outline_outlined,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                //onTap: () => _deleteProduct(index),
                                child: Container(
                                  width: 60,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffE25454),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 5),
                                Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Container(
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width * 0.4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              //currentPageItems[index].name ??
                                                'N/A',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  fontFamily: 'Mulish'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              //currentPageItems[index].itemCode ??
                                                  'N/A',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 10,
                                                  fontFamily: 'Mulish'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width * 0.32,
                                        child: Text(
                                          //currentPageItems[index].category?.name ??
                                              'N/A',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              fontFamily: 'Mulish'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  child: Center(
                                    child: Text(
                                      '€${
                                          //currentPageItems[index].price?.toStringAsFixed(2) ??
                                          '0.00'}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Mulish',
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // if (productList.isNotEmpty && totalPages > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    GestureDetector(
                      // onTap: currentPage > 1
                      //     ? () => _goToPage(currentPage - 1)
                      //     : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentPage > 1 ? Colors.white : Colors.grey
                              .shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage > 1 ? Colors.black87 : Colors
                                .grey,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Page Numbers
                    ...(_getPageNumbers().map((pageNum) {
                      bool isActive = pageNum == currentPage;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          //onTap: () => _goToPage(pageNum),
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isActive ? Color(0xFF0EA5E9) : Colors
                                  .white,
                              border: Border.all(
                                color: isActive ? Color(0xFF0EA5E9) : Colors
                                    .grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '$pageNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : Colors
                                      .black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList()),

                    SizedBox(width: 8),

                    // Next Button
                    GestureDetector(
                      // onTap: currentPage < totalPages ? () =>
                      //     _goToPage(currentPage + 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentPage < totalPages
                              ? Colors.white
                              : Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage < totalPages
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> getToppings({bool showLoader = true}) async {
    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (showLoader && mounted) {
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
      List<GetToppingsResponseModel> toppings = await CallService().getToppings(storeId!);
      print('product list length is ${toppings.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          //productList = product;
          currentPage = 1;
          _updatePagination();
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Product: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

}
