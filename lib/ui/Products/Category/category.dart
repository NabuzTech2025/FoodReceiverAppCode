import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../customView/CustomAppBar.dart';
import '../../../customView/CustomDrawer.dart';
import '../../../models/get_product_category_list_response_model.dart';
class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;

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
       await getProductCategory();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  List<ScrollController> scrollControllers = [];
  int? currentScrolledIndex;
  List<GetProductCategoryList> productCategoryList = [];
  bool isResetting = false;
  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    // scrollControllers = List.generate(productCategoryList.length, (index) {
    //   ScrollController controller = ScrollController();
    //
    //   // Add listener to each controller
    //   controller.addListener(() {
    //     if (controller.offset > 0 && currentScrolledIndex != index) {
    //       _handleScroll(index);
    //     }
    //   });
    //
    //   return controller;
    // });
    super.initState();
  }

  void _handleScroll(int currentIndex) {
    // Reset ONLY the previous scrolled container
    if (currentScrolledIndex != null && currentScrolledIndex != currentIndex) {
      if (currentScrolledIndex! < scrollControllers.length &&
          scrollControllers[currentScrolledIndex!].hasClients) {
        scrollControllers[currentScrolledIndex!].animateTo(
          0.0,
          duration: Duration(milliseconds: 80),
          curve: Curves.easeInOut,
        );
      }
    }

    // Set new current index
    currentScrolledIndex = currentIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (ScrollController controller in scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        drawer: CustomDrawer(onSelectTab: _openTab),
        appBar: CustomAppBar(),
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Category'.tr, style: TextStyle(
                          fontFamily: 'Mulish', fontSize: 18, fontWeight: FontWeight.bold
                      )),
                      GestureDetector(
                        onTap: () {
                          //showTaxManagementBottomSheet(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: const Color(0xFFFCAE03),
                          ),
                          child: const Center(
                            child: Text('Add New', style: TextStyle(
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
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECF8FF),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 40),
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    fontFamily: 'Mulish'
                                ),
                              ),
                              Text('Tax',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      fontFamily: 'Mulish'
                                  )
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Center(
                            child: Text('Status',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish'
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (isLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(),
                    )
                  else if (productCategoryList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        'No Products found',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Mulish',
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: productCategoryList.length,
                      itemBuilder: (context, index) {
                         final product = productCategoryList[index];
                         var productId=product.id.toString();
                         print('Product Id IS$productId');
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            controller: scrollControllers[index], // Add this line
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                            Image.network(product.imageUrl.toString(),height: 40,width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/food.png',height: 40,width: 40,),),
                                SizedBox(width: 5,),
                                Container(
                                  // width: MediaQuery.of(context).size.width * 0.6,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        child: Text(product.name.toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              fontFamily: 'Mulish'
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        child: Center(
                                          child: Text(
                                           " ${product.tax!.percentage.toString()}%",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                fontFamily: 'Mulish'
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  height: 25,
                                  width: 60,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: (product.isActive == true) ? Color(0xff49B27A) : Color(0xffE25454)
                                  ),
                                  child: Center(
                                    child: Text(
                                      (product.isActive == true) ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                          fontSize: 12,fontFamily: 'Mulish',fontWeight: FontWeight.w700,
                                          color: Colors.white
                                      ),),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    // print('Delete button click - Tax ID: ${tax.id}');
                                    // print('Tax object details: Name=${tax.name}, Percentage=${tax.percentage}');
                                    //
                                    // if (tax.id != null) {
                                    //   print('Passing taxId to confirmation dialog: ${tax.id}');
                                    //  // _showDeleteTaxConfirmation(context, tax.name ?? 'Tax', tax.id!);
                                    // } else {
                                    //   print('Tax ID is null!');
                                    //   Get.snackbar('Error', 'Invalid tax ID');
                                    // }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xff0C831F)
                                    ),
                                    child: const Center(
                                      child: Icon(
                                          Icons.mode_edit_outline_outlined,
                                          color: Colors.white,
                                          size: 16
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    // if (tax.id != null) {
                                    //  // _showDeleteTaxConfirmation(context, tax.name ?? 'Tax', tax.id!);
                                    // } else {
                                    //   Get.snackbar('Error', 'Invalid tax ID');
                                    // }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xffE25454)
                                    ),
                                    child: const Center(
                                      child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 16
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            )
        )
    );
  }

  Future<void> getProductCategory({bool showLoader = true}) async {
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

      List<GetProductCategoryList> category = await CallService().getProductCategory(storeId!);

      if (showLoader) {
        Get.back();
      }

      setState(() {
        productCategoryList = category;
        // Initialize scroll controllers after getting data
        scrollControllers = List.generate(category.length, (index) {
          ScrollController controller = ScrollController();
          controller.addListener(() {
            // Skip if we're programmatically resetting
            if (isResetting) return;

            // When this container is scrolled left
            if (controller.offset > 10) {
              // Reset previous container if different
              if (currentScrolledIndex != null && currentScrolledIndex != index) {
                isResetting = true; // Set flag before animating

                if (scrollControllers[currentScrolledIndex!].hasClients) {
                  scrollControllers[currentScrolledIndex!].animateTo(
                    0.0,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  ).then((_) {
                    isResetting = false; // Reset flag after animation
                  });
                } else {
                  isResetting = false;
                }
              }
              // Set this as current
              currentScrolledIndex = index;
            }
          });
          return controller;
        });
        isLoading = false;
      });

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Product Category: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
}
