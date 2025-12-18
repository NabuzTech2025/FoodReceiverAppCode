
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:food_app/constants/app_color.dart';
import 'package:get/get.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_store_products_response_model.dart';
import '../home_screen.dart';
import 'pos_controller.dart';

class ResponsivePos extends StatelessWidget {
  const ResponsivePos({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (context, orientation) {
          return const PosLandscape();
        }
    );
  }
}

class PosLandscape extends StatefulWidget {
  const PosLandscape({super.key});

  @override
  State<PosLandscape> createState() => _PosLandscapeState();
}

class _PosLandscapeState extends State<PosLandscape> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PosController controller;
  @override
  void initState() {
    super.initState();
    controller = Get.put(PosController(), tag: 'pos_controller');
  }

  @override
  void dispose() {

    try {
      Get.delete<PosController>(tag: 'pos_controller', force: true);
    } catch (e) {
      print('⚠️ Error disposing PosController: $e');
    }

    // ✅ Call super.dispose() last
    super.dispose();
  }
  double _getScaleFactor(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // Base width: 1024px (standard iPad landscape)
    // Scale factor ranges from 0.7 (small) to 1.5 (very large)
    if (width < 900) return 0.75;
    if (width < 1100) return 0.9;
    if (width < 1300) return 1.0;
    if (width < 1500) return 1.15;
    if (width < 1800) return 1.3;
    return 1.5;
  }

  double _responsive(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 900) return 3;
    if (width < 1100) return 4;
    if (width < 1400) return 5;
    if (width < 1700) return 6;
    return 7;
  }
  void _openTab(int index) {

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // ✅ Navigate back to HomeScreen with specific tab
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.off(
            () => const HomeScreen(),
        arguments: {'initialTab': index},
        transition: Transition.noTransition,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return
      WillPopScope(
        onWillPop: () async {
          await Future.delayed(const Duration(milliseconds: 150));
          return true;
        },
        child: Scaffold(
          key: _scaffoldKey,
        drawer: CustomDrawer(onSelectTab: _openTab),
        backgroundColor: Color(0xffFBF9FF),
        body: Stack(
          children:[
            Padding(
            padding: EdgeInsets.only(top: _responsive(context, 12)),
            child: Row(
              children: [
               // _buildSidebar(controller, context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_responsive(context, 8)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildProductsSection(controller, context),
                        ),
                        SizedBox(width: _responsive(context, 10)),
                        Expanded(
                          flex: 3,
                          child: _buildCartSection(controller, context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
            _buildVariantDialog(controller, context),
            //_buildTimeBottomSheet(controller, context),
          ] ),
            ),
      );
  }

  Widget _buildSidebar(PosController controller, BuildContext context) {
    return Stack(
      children: [
        Container(
          width: _responsive(context, 60),
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(height: _responsive(context, 20)),
              Container(
                width: _responsive(context, 50),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_responsive(context, 12)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(_responsive(context, 5)),
                        padding: EdgeInsets.all(_responsive(context, 5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_responsive(context, 7)),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/mirch.png',
                            width: _responsive(context, 35),
                            height: _responsive(context, 35),
                          ),
                        ),
                      ),
                      SizedBox(height: _responsive(context, 50)),
                      _buildSidebarItem(Icons.shopping_bag_outlined, false, context),
                      SizedBox(height: _responsive(context, 20)),
                      _buildSidebarItem(Icons.bar_chart_outlined, false, context),
                      SizedBox(height: _responsive(context, 20)),
                      _buildSidebarItem(Icons.settings_outlined, false, context),
                      SizedBox(height: _responsive(context, 10)),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: _responsive(context, 20)),
                child: GestureDetector(
                  onTap: () {
                    controller.showLogoutDialog(Get.context!);
                  },
                  child: Container(
                    width: _responsive(context, 45),
                    height: _responsive(context, 45),
                    decoration: BoxDecoration(
                      color: Color(0xffE31E24),
                      borderRadius: BorderRadius.circular(_responsive(context, 8)),
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      color: Colors.white,
                      size: _responsive(context, 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: _responsive(context, 75),
          right: 0,
          left: 0,
          child: Container(
            height: _responsive(context, 45),
            width: _responsive(context, 49),
            margin: EdgeInsets.only(left: _responsive(context, 10)),
            padding: EdgeInsets.only(right: _responsive(context, 10)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_responsive(context, 12)),
                bottomLeft: Radius.circular(_responsive(context, 12)),
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/plus.png',
                height: _responsive(context, 20),
                width: _responsive(context, 20),
                color: Color(0xff0B1928),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, bool isActive, BuildContext context) {
    return Container(
      width: _responsive(context, 45),
      height: _responsive(context, 45),
      decoration: BoxDecoration(
        color: isActive ? Color(0xffE31E24) : Colors.transparent,
        borderRadius: BorderRadius.circular(_responsive(context, 8)),
      ),
      child: Icon(
        icon,
        color: Color(0xff0B1928),
        size: _responsive(context, 24),
      ),
    );
  }

  Widget _buildProductsSection(PosController controller, BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5),
        _buildHeader(controller, context),
        SizedBox(height: _responsive(context, 20)),
        _buildCategoryTabs(controller, context),

        Expanded(
          child: Obx(() {
            // If searching, show filtered products in a grid
            if (controller.searchQuery.value.isNotEmpty) {
              return _buildSearchResults(controller, context);
            }

            // Normal category-based view
            List<int> categoriesToShow = controller.visibleCategories.toList();

            if (categoriesToShow.isEmpty) {
              return Center(
                child: Text(
                  'No categories to show',
                  style: TextStyle(fontSize: _responsive(context, 14)),
                ),
              );
            }

            return ScrollablePositionedList.builder(
              itemScrollController: controller.landscapeProductScrollController,
              itemPositionsListener: controller.landscapeProductPositionsListener,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.1,
                top: _responsive(context, 8),
                left: _responsive(context, 4),
                right: _responsive(context, 4),
              ),
              itemCount: categoriesToShow.length,
              itemBuilder: (context, visibleIndex) {
                int categoryIndex = categoriesToShow[visibleIndex];
                if (categoryIndex >= controller.productCategoryList.length) {
                  return SizedBox.shrink();
                }

                var category = controller.productCategoryList[categoryIndex];
                var categoryProducts = controller.productList
                    .where((p) =>
                p.categoryId == category.id && (p.isActive ?? false))
                    .toList();

                if (categoryProducts.isEmpty) return SizedBox.shrink();

                return Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _responsive(context, 8),
                          vertical: _responsive(context, 12),
                        ),
                        child: Text(
                          category.name ?? '',
                          style: TextStyle(
                            fontSize: _responsive(context, 22),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          crossAxisSpacing: _responsive(context, 5),
                          mainAxisSpacing: _responsive(context, 5),
                          childAspectRatio: 0.93,
                        ),
                        itemCount: categoryProducts.length,
                        itemBuilder: (context, index) {
                          var product = categoryProducts[index];
                          return _buildProductCard(controller, product, context);
                        },
                      ),
                      SizedBox(height: _responsive(context, 20)),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchResults(PosController controller, BuildContext context) {
    return Obx(() {
      if (controller.filteredProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: _responsive(context, 60),
                color: Colors.grey.shade400,
              ),
              SizedBox(height: _responsive(context, 16)),
              Text(
                'No products found',
                style: TextStyle(
                  fontSize: _responsive(context, 18),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: _responsive(context, 8)),
              Text(
                'Try searching with different keywords',
                style: TextStyle(
                  fontSize: _responsive(context, 14),
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.all(_responsive(context, 8)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: _responsive(context, 5),
          mainAxisSpacing: _responsive(context, 5),
          childAspectRatio: 0.93,
        ),
        itemCount: controller.filteredProducts.length,
        itemBuilder: (context, index) {
          var product = controller.filteredProducts[index];
          return _buildProductCard(controller, product, context);
        },
      );
    });
  }

  Widget _buildProductCard(PosController controller, GetStoreProducts product, BuildContext context) {
    return RepaintBoundary(
      child: Obx(() {
        int cartIndex = controller.cartItems.indexWhere(
                (item) => item['name'] == product.name);
        bool isInCart = cartIndex != -1;
        int quantity = isInCart
            ? controller.cartItems[cartIndex]['quantity']
            : 0;

        return GestureDetector(
          onTap: () {
            controller.showProductVariantDialog(product);
          },
          child: Container(
            padding: EdgeInsets.all(_responsive(context, 8)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_responsive(context, 8)),
              color: Colors.white,
              border: Border.all(
                color: isInCart
                    ? AppColor.borderGreen
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(left: _responsive(context, 4)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.w600,
                      fontSize: _responsive(context, 14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: isInCart
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.end,
                    children: [
                      if (isInCart)
                        Container(
                          width: _responsive(context, 24),
                          height: _responsive(context, 24),
                          decoration: BoxDecoration(
                            color: AppColor.borderGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 15),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        '${double.tryParse(product.price?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} €',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: _responsive(context, 18),
                          color: isInCart ? AppColor.borderGreen : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(PosController controller, BuildContext context) {
    return Stack(
      children:[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: Image.asset(
                  'assets/images/mirch.png',
                  height: 25,
                  width: 25,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: _responsive(context, 12)),
                height: _responsive(context, 40),
                width: _responsive(context, 300),
                padding: EdgeInsets.symmetric(horizontal: _responsive(context, 8)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_responsive(context, 5)),
                  color: Color(0xffFBF9FF),
                ),
                child: TextField(
                  controller: controller.searchController,
                  onChanged: controller.filterProducts,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(bottom: 5),
                    hintText: 'Search Item name or ID',
                    hintStyle: TextStyle(
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.w300,
                      fontSize: _responsive(context, 14),
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(_responsive(context, 8)),
                      child: Image.asset(
                        'assets/images/search.png',
                        height: _responsive(context, 8),
                        width: _responsive(context, 8),
                        color: Colors.black,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: _responsive(context, 14),
                  ),
                ),
              ), SizedBox(width: 5,),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/images/order-icon.svg',
                    height: 20,
                    width: 20,
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Obx(() => Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xffE31E24),
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${controller.cartItems.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        )),
                  ),
                ],
              ), SizedBox(width: 50,),
              SizedBox(width: _responsive(context, 10)),
              Row(
                children: [
                  Image.asset(
                    'assets/images/german.png',
                    height: _responsive(context, 25),
                    width: _responsive(context, 25),
                  ),
                  SizedBox(width: _responsive(context, 5)),
                  Text(
                    'GER',
                    style: TextStyle(
                      fontSize: _responsive(context, 12),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: Color(0xff232121),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down)
                ],
              ),
            ]),
                  ),
            Obx(() => GestureDetector(
              onTap: controller.isRefreshing.value
                  ? null
                  : controller.refreshData,
              child: Container(
                height: 60,
                padding: EdgeInsets.all(_responsive(context, 10)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(_responsive(context, 5)),
                ),
                child: controller.isRefreshing.value
                    ? SizedBox(
                  width: _responsive(context, 20),
                  height: _responsive(context, 20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xffE31E24)),
                  ),
                )
                    : Icon(
                  Icons.refresh,
                  color: Color(0xffE31E24),
                  size: _responsive(context, 30),
                ),
              ),
            )),
            GestureDetector(
              onTap: () {
                Get.offAll(() => HomeScreen());
              },
              child: Container(
                height: 60,
                padding: EdgeInsets.all(_responsive(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_responsive(context, 9)),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: _responsive(context, 20),
                  ),
                ),
              ),
            )
          ],
        ),
        Positioned(
          right:_responsive(context, 210),
          top: 10,
          child: Container(
            height: _responsive(context, 71),
            width: _responsive(context, 55),
            margin: EdgeInsets.all(5),
           // padding: EdgeInsets.only(right: _responsive(context, 10)),
            decoration: BoxDecoration(
              color: Color(0xffFBF9FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_responsive(context, 12)),
                topRight: Radius.circular(_responsive(context, 12)),
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/plus.png',
                height: _responsive(context, 20),
                width: _responsive(context, 20),
                color: Color(0xff0B1928),
              ),
            ),
          ),
        )
    ]);
  }
  // children: [
  //   Image.asset(
  //     'assets/images/mirch.png',
  //     height: _responsive(context, 20),
  //     width: _responsive(context, 30),
  //   ),
  //   Expanded(
  //     child: Container(
  //       margin: EdgeInsets.symmetric(horizontal: _responsive(context, 12)),
  //       height: _responsive(context, 40),
  //       padding: EdgeInsets.symmetric(horizontal: _responsive(context, 8)),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(_responsive(context, 5)),
  //         color: Colors.white,
  //       ),
  //       child: TextField(
  //         controller: controller.searchController,
  //         onChanged: controller.filterProducts,
  //         decoration: InputDecoration(
  //           hintText: 'Search Item name or ID',
  //           hintStyle: TextStyle(
  //             fontFamily: 'Mulish',
  //             fontWeight: FontWeight.w300,
  //             fontSize: _responsive(context, 14),
  //             fontStyle: FontStyle.italic,
  //           ),
  //           border: InputBorder.none,
  //           suffixIcon: Padding(
  //             padding: EdgeInsets.all(_responsive(context, 8)),
  //             child: Image.asset(
  //               'assets/images/search.png',
  //               height: _responsive(context, 10),
  //               width: _responsive(context, 10),
  //               color: Colors.black,
  //             ),
  //           ),
  //         ),
  //         style: TextStyle(
  //           fontFamily: 'Mulish',
  //           fontSize: _responsive(context, 14),
  //         ),
  //       ),
  //     ),
  //   ),

  // ],
  Widget _buildCategoryTabs(PosController controller, BuildContext context) {
    return Container(
      height: _responsive(context, 115),
      child: Obx(() => ListView.builder(
        controller: controller.landscapeCategoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: controller.productCategoryList.length,
        itemBuilder: (context, index) {
          var category = controller.productCategoryList[index];
          return Obx(() {
            bool isSelected = controller.selectedCategoryIndex.value == index;

            return GestureDetector(
              onTap: () {
                controller.selectCategory(index);
              },
              child: Container(
                width: _responsive(context, 116),
                height: _responsive(context, 80),
                margin: EdgeInsets.only(right: _responsive(context, 5)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_responsive(context, 8)),
                  border: Border.all(
                    color: isSelected ? AppColor.borderGreen : Color(0xffCFC1ED),
                    width: 1,
                  ),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: controller.getTrimmedImageUrl(category.imageUrl),
                          height: _responsive(context, 55),
                          width: _responsive(context, 55),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => Icon(Icons.restaurant, size: _responsive(context, 20)),
                        ),
                      ),
                    ),
                    SizedBox(height: _responsive(context, 8)),
                    Container(
                      width: MediaQuery.of(context).size.width*0.5,
                      child: Text(
                        category.name ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: _responsive(context, 14),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        },
      )),
    );
  }

  Widget _buildCartSection(PosController controller, BuildContext context) {
    // bool _shouldShowSaveButtons(PosController controller) {
    //   return controller.cartItems.isNotEmpty || controller.customerDetails.isNotEmpty;
    // }
    return Stack(
      children: [
        Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_responsive(context, 5)),
        ),
        child: Column(
          children: [
            SizedBox(height: 5,),
            //
            // Padding(
            //   padding: EdgeInsets.only(left: 8.0,right: 8),
            //   child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text('OPEN ORDERS [10]',
            //         style: TextStyle(
            //         fontFamily: 'Mulish',
            //           fontSize: 14,
            //           fontWeight: FontWeight.w600,
            //           decoration: TextDecoration.underline
            //       ),),
            //       Obx(() => Row(
            //         children: [
            //           Text('Invoice no : ',
            //             style: TextStyle(
            //                 fontFamily: 'Mulish',
            //                 fontSize: 12,
            //                 fontWeight: FontWeight.w400
            //             ),),
            //           Text('${controller.invoiceNumber.value}',
            //             style: TextStyle(
            //                 fontFamily: 'Mulish',
            //                 fontSize: 13,
            //                 fontWeight: FontWeight.w800
            //             ),),
            //         ],
            //       )),
            //     ],
            //   ),
            // ),
            Padding(
              padding: EdgeInsets.all(_responsive(context, 8)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _responsive(context, 10),
                  vertical: _responsive(context, 6),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xffEDE4FF), width: 1),
                  borderRadius: BorderRadius.circular(_responsive(context, 5)),
                  color: Color(0xffFBF9FF),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phone Number / Name',
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w500,
                        fontSize: _responsive(context, 14),
                        color: Color(0xff797878),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.onAddCustomerPressed(),
                      child: Container(
                        padding: EdgeInsets.all(_responsive(context, 8)),
                        decoration: BoxDecoration(
                          color: Color(0xffB8ABD1),
                          borderRadius: BorderRadius.circular(_responsive(context, 6)),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/add-user.svg',
                          height: _responsive(context, 18),
                          width: _responsive(context, 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(_responsive(context, 4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildOrderTypeButton(controller, 'Lieferzeit',
                              'assets/images/delivery-icon.svg', context),
                          SizedBox(width: _responsive(context, 8)),
                          _buildOrderTypeButton(controller, 'Abholzeit',
                              'assets/images/pickup-icon.svg', context),
                        ],
                      ),
                      SizedBox(height: _responsive(context, 8)),
                      GestureDetector(
                        onTap: () => controller.showAddNoteDialog(context),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/note.png',
                              height: 14,
                              width: 14,
                            ),
                            SizedBox(width: _responsive(context, 5)),
                            Obx(
                              () => Text(
                                controller.orderNote.value.isEmpty
                                    ? 'Note'
                                    : 'Note: ${controller.orderNote.value}',
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.cartItems.isEmpty && !controller.showCustomerDetails.value) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'No items in cart',
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w500,
                              fontSize: _responsive(context, 20),
                              color: Color(0xff797878),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _responsive(context, 12),
                          vertical: _responsive(context, 15),
                        ),
                        child: _buildSummarySection(controller, context),
                      ),
                    ],
                  );
                }

                if (controller.showCustomerDetails.value) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _responsive(context, 8),
                          vertical: _responsive(context, 12),
                        ),
                        child: _buildSummarySection(controller, context),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (controller.isCustomerFormVisible.value)
                                _buildCustomerDetailsSection(controller, context),

                              if (controller.customerDetails.isNotEmpty &&
                                  !controller.isCustomerFormVisible.value)
                                _buildCustomerDetailsDisplay(controller, context),

                              if (controller.customerDetails.isNotEmpty &&
                                  !controller.isCustomerFormVisible.value)
                                _buildTodaySection(context),

                              SizedBox(height: _responsive(context, 20)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCartItems(controller, context),
                            SizedBox(height: _responsive(context, 20)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _responsive(context, 8),
                        vertical: _responsive(context, 12),
                      ),
                      child: _buildSummarySection(controller, context),
                    ),
                  ],
                );
              }),
            ),

            // Obx(() {
            //   if (!_shouldShowSaveButtons(controller)) {
            //     return SizedBox.shrink();
            //   }
            //
            //   bool showBothButtons = controller.cartItems.isNotEmpty;
            //
            //   return Padding(
            //     padding: EdgeInsets.symmetric(
            //       horizontal: _responsive(context, 8),
            //       vertical: _responsive(context, 8),
            //     ),
            //     child: Row(
            //       children: [
            //         // Save Button
            //         Expanded(
            //           child: GestureDetector(
            //             onTap: () {
            //               controller.selectedSaveOption.value = 'save';  // ✅ Set selection
            //               print('Save clicked');
            //             },
            //             child: Container(
            //               padding: EdgeInsets.symmetric(
            //                 vertical: _responsive(context, 14),
            //               ),
            //               decoration: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(_responsive(context, 8)),
            //                 color: controller.selectedSaveOption.value == 'save'  // ✅ Check selection
            //                     ? Color(0xff1A1F2E)  // Dark color when selected
            //                     : Color(0xffFBF9FF),
            //               ),
            //               child: Center(
            //                 child: Text(
            //                   'Save',
            //                   style: TextStyle(
            //                     fontWeight: FontWeight.w700,
            //                     fontSize: _responsive(context, 15),
            //                     fontFamily: 'Mulish',
            //                     color: controller.selectedSaveOption.value == 'save'  // ✅ Text color change
            //                         ? Colors.white
            //                         : Color(0xff0B1928),
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //
            //         // Show Save & Print only if cart has items
            //         if (showBothButtons) ...[
            //           SizedBox(width: _responsive(context, 8)),
            //           Expanded(
            //             child: GestureDetector(
            //               onTap: () {
            //                 controller.selectedSaveOption.value = 'save_print';  // ✅ Set selection
            //                 print('Save & Print clicked');
            //               },
            //               child: Container(
            //                 padding: EdgeInsets.symmetric(
            //                   vertical: _responsive(context, 14),
            //                 ),
            //                 decoration: BoxDecoration(
            //                   borderRadius: BorderRadius.circular(_responsive(context, 8)),
            //                   color: controller.selectedSaveOption.value == 'save_print'  // ✅ Check selection
            //                       ? Color(0xff1A1F2E)  // Dark when selected
            //                       : Color(0xffFBF9FF),   // Keep dark (default state)
            //                 ),
            //                 child: Center(
            //                   child: Text(
            //                     'Save & Print',
            //                     style: TextStyle(
            //                       fontWeight: FontWeight.w700,
            //                       fontSize: _responsive(context, 15),
            //                       fontFamily: 'Mulish',
            //                       color: controller.selectedSaveOption.value == 'save_print'
            //                           ? Colors.white
            //                           : Color(0xff0B1928),
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ],
            //     ),
            //   );
            // }),

            _buildWeiterButton(controller, context),
          ],
        ),
      ),
        _buildTimeBottomSheet(controller, context),
        _buildCalendarBottomSheet(controller, context),
      ]);
  }

  Widget _buildVariantDialog(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showVariantDialog.value ||
          controller.selectedProduct.value == null) {
        return SizedBox.shrink();
      }

      var product = controller.selectedProduct.value!;
      var variants = product.variants ?? [];

      return Stack(
        children: [
          GestureDetector(
            onTap: () => controller.showVariantDialog.value = false,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Positioned(
            left: _responsive(context, 60),
            // Sidebar width
            right: MediaQuery.of(context).size.width * 0.375,
            // Cart section width (3/8)
            top: 0,
            bottom: 0,
            child: Center(
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_responsive(context, 12)),),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(_responsive(context, 16)),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xffEDE4FF))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name ?? '',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 22),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(_responsive(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (variants.isNotEmpty) ...[
                                SizedBox(height: _responsive(context, 8)),
                                ...variants
                                    .map((variant) => Obx(() {
                                          bool isSelected = controller
                                                  .selectedVariant.value?.id ==
                                              variant.id;
                                          bool isExpanded = controller
                                                  .expandedVariantId.value ==
                                              variant.id;

                                          return Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  controller
                                                      .selectVariant(variant);
                                                },
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: _responsive(
                                                          context, 5)),
                                                  padding: EdgeInsets.all(
                                                      _responsive(context, 14)),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            _responsive(
                                                                context, 8)),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Color(0xff0C831F)
                                                          : Color(0xffEDE4FF),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: _responsive(
                                                            context, 20),
                                                        height: _responsive(
                                                            context, 20),
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? Color(
                                                                    0xff0C831F)
                                                                : Colors.grey,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: isSelected
                                                            ? Center(
                                                                child:
                                                                    Container(
                                                                  width:
                                                                      _responsive(
                                                                          context,
                                                                          10),
                                                                  height:
                                                                      _responsive(
                                                                          context,
                                                                          10),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: Color(
                                                                        0xff0C831F),
                                                                  ),
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      SizedBox(
                                                          width: _responsive(
                                                              context, 12)),
                                                      Expanded(
                                                        child: Text(
                                                          variant.name ?? '',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Mulish',
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize:
                                                                _responsive(
                                                                    context,
                                                                    18),
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '€${((variant.price ?? 0) / 100).toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontFamily: 'Mulish',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: _responsive(
                                                              context, 18),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Expandable toppings section
                                              if (isExpanded &&
                                                  variant.enrichedToppingGroups !=
                                                      null &&
                                                  variant.enrichedToppingGroups!
                                                      .isNotEmpty)
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    left: _responsive(
                                                        context, 25),
                                                    bottom:
                                                        _responsive(context, 8),
                                                  ),
                                                  padding: EdgeInsets.all(
                                                      _responsive(context, 12)),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xffFBF9FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            _responsive(
                                                                context, 8)),
                                                    border: Border.all(
                                                        color:
                                                            Color(0xffEDE4FF)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: variant
                                                        .enrichedToppingGroups!
                                                        .map((group) {
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (group.toppings !=
                                                                  null &&
                                                              group.toppings!
                                                                  .isNotEmpty) ...[
                                                            ...group.toppings!
                                                                .map(
                                                                    (topping) =>
                                                                        Obx(() {
                                                                          bool
                                                                              isToppingSelected =
                                                                              controller.selectedToppingsMap[variant.id]?.contains(topping.id) ?? false;

                                                                          return GestureDetector(
                                                                            onTap: () {
                                                                              if (variant.id != null && topping.id != null) {
                                                                                controller.toggleVariantTopping(variant.id!, topping.id!);
                                                                              }
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              margin: EdgeInsets.only(bottom: _responsive(context, 8)),
                                                                              child: Row(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Container(
                                                                                    width: _responsive(context, 25),
                                                                                    height: _responsive(context, 25),
                                                                                    decoration: BoxDecoration(
                                                                                      border: Border.all(
                                                                                        color: isToppingSelected ? Color(0xff0C831F) : Colors.grey,
                                                                                        width: 2,
                                                                                      ),
                                                                                      borderRadius: BorderRadius.circular(4),
                                                                                      color: isToppingSelected ? Color(0xff0C831F) : Colors.transparent,
                                                                                    ),
                                                                                    child: isToppingSelected ? Icon(Icons.check, size: _responsive(context, 18), color: Colors.white) : null,
                                                                                  ),
                                                                                  SizedBox(width: _responsive(context, 8)),
                                                                                  Expanded(
                                                                                    child: Text(
                                                                                      topping.name ?? '',
                                                                                      style: TextStyle(
                                                                                        fontFamily: 'Mulish',
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: _responsive(context, 15),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  Text(
                                                                                    '€${(topping.price ?? 0).toStringAsFixed(2)}',
                                                                                    style: TextStyle(
                                                                                      fontFamily: 'Mulish',
                                                                                      fontWeight: FontWeight.w600,
                                                                                      fontSize: _responsive(context, 16),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }))
                                                                .toList(),
                                                            SizedBox(
                                                                height:
                                                                    _responsive(
                                                                        context,
                                                                        8)),
                                                          ],
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                            ],
                                          );
                                        }))
                                    .toList(),
                              ],
                              SizedBox(height: _responsive(context, 16)),
                            ],
                          ),
                        ),
                      ),

                      // Footer button
                      GestureDetector(
                        onTap: () => controller.addToCartWithVariant(),
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(_responsive(context, 12)),
                          decoration: BoxDecoration(
                            color: Color(0xff0C831F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Weiter €${_calculateDialogTotal(controller)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w700,
                              fontSize: _responsive(context, 22),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -12,
                  right: -12,
                  child: GestureDetector(
                    onTap: () => controller.showVariantDialog.value = false,
                    child: Container(
                      width: _responsive(context, 40),
                      height: _responsive(context, 40),
                      decoration: BoxDecoration(
                        color: Color(0xffE31E24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          color: Colors.white, size: _responsive(context, 20)),
                    ),
                  ),
                )
              ]),
            ),
          ),
        ],
      );
    });
  }

  String _calculateDialogTotal(PosController controller) {
    if (controller.selectedProduct.value == null) return '0.00';

    double basePrice = double.tryParse(controller.selectedProduct.value!.price?.toString() ?? '0') ?? 0.0;
    double variantPrice = 0.0;
    double toppingPrice = 0.0;

    if (controller.selectedVariant.value != null) {
      variantPrice = (controller.selectedVariant.value!.price ?? 0).toDouble();

      // Calculate topping prices
      if (controller.selectedToppingsMap.containsKey(controller.selectedVariant.value!.id)) {
        var selectedToppingIds = controller.selectedToppingsMap[controller.selectedVariant.value!.id]!;

        controller.selectedVariant.value!.enrichedToppingGroups?.forEach((group) {
          group.toppings?.forEach((topping) {
            if (selectedToppingIds.contains(topping.id)) {
              toppingPrice += topping.price ?? 0.0;
            }
          });
        });
      }
    }

    return (basePrice + variantPrice + toppingPrice).toStringAsFixed(2);
  }

  Widget _buildOrderTypeButton(
      PosController controller, String type, String iconPath, BuildContext context) {
    return Obx(() {
      bool isSelected = controller.selectedOrderType.value == type;
      return GestureDetector(
        onTap: () => controller.setOrderType(type),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_responsive(context, 5)),
            color: isSelected ? Color(0xff0C831F) : Color(0xffFBF9FF),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                color: isSelected ? Colors.white : Colors.black,
                height: 13,
                width: 13,
              ),
              SizedBox(width: _responsive(context, 3)),
              Text(
                type,
                style: TextStyle(
                  fontSize:14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: isSelected ? Colors.white : Color(0xff0B1928),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCartItems(PosController controller, BuildContext context) {
    return Obx(() {
      if (controller.isCartExpanded.value) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: _responsive(context, 4)),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.cartItems.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Color(0xffE6E1EE)),
            itemBuilder: (context, index) {
              final item = controller.cartItems[index];
              List<String> toppingsList = [];

              // Parse toppings from extras string
              if (item['extras'] != null && item['extras'].toString().isNotEmpty) {
                toppingsList = item['extras'].toString().split('\n');
              }

              return Container(
                margin: EdgeInsets.all(_responsive(context, 2)),
                padding: EdgeInsets.all(_responsive(context, 8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name with quantity controls and price
                    // Product name with quantity controls and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cross button to remove item
                        GestureDetector(
                          onTap: () => controller.removeCartItem(index),
                          child: Icon(
                            Icons.close,
                            size: _responsive(context, 20),
                            color: Color(0xffE31E24),
                          ),
                        ),
                        // Product name
                        Container(
                          width: MediaQuery.of(context).size.width*0.15,
                          child: Text(
                            item['name'],
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w700,
                              fontSize: _responsive(context, 12),
                            ),
                          ),
                        ),

                        // Note icon button
                        GestureDetector(
                          onTap: () => controller.showItemNoteDialog(context, index),
                          child: Image.asset(
                            'assets/images/note.png',
                            height: _responsive(context, 14),
                            width: _responsive(context, 14),
                            color: item['item_note'] != null && item['item_note'].toString().isNotEmpty
                                ? Color(0xff0C831F)
                                : Color(0xff797878),
                          ),
                        ),

                        SizedBox(width: _responsive(context, 8)),

                        // Quantity controls
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => controller.decrementQuantity(index),
                              child: Container(
                                width: _responsive(context, 25),
                                height: _responsive(context, 25),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xffB8ABD1), width: 1),
                                  borderRadius: BorderRadius.circular(_responsive(context, 4)),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: _responsive(context, 20),
                                  color: Color(0xff0B1928),
                                ),
                              ),
                            ),
                            SizedBox(width: _responsive(context, 5)),
                            Text(
                              '${item['quantity']}',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 16),
                                color: Color(0xff0B1928),
                              ),
                            ),
                            SizedBox(width: _responsive(context, 5)),
                            GestureDetector(
                              onTap: () => controller.incrementQuantity(index),
                              child: Container(
                                width: _responsive(context, 25),
                                height: _responsive(context, 25),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xffB8ABD1), width: 1),
                                  borderRadius: BorderRadius.circular(_responsive(context, 4)),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: _responsive(context, 20),
                                  color: Color(0xff0B1928),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: _responsive(context, 8)),

                        // Price
                        Text(
                          '€ ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: _responsive(context, 15),
                            color: Color(0xff0B1928),
                          ),
                        ),
                      ],
                    ),

                    // Toppings list (without variant name)
                    if (toppingsList.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: _responsive(context, 6), left: _responsive(context, 12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: toppingsList.map((topping) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: _responsive(context, 2)),
                              child: Text(
                                '1× $topping',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w500,
                                  fontSize: _responsive(context, 12),
                                  color: Color(0xff797878),
                                ),
                              ),
                            );
                          }).toList(),

                        ),
                      ),
                    // Item note (if exists)
                    if (item['item_note'] != null && item['item_note'].toString().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: _responsive(context, 4), left: _responsive(context, 12)),
                        child: Row(
                          children: [
                            Text(
                              'Note: ',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item['item_note'],
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  fontSize: _responsive(context, 11),
                                  color: Color(0xff797878),

                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }
      return SizedBox.shrink();
    });
  }

  Widget _buildSummarySection(PosController controller, BuildContext context) {
    double discountPercent = 0.0;
    if (controller.selectedOrderType.value == 'Lieferzeit') {
      discountPercent = controller.deliveryDiscount.value;
    } else if (controller.selectedOrderType.value == 'Abholzeit') {
      discountPercent = controller.pickupDiscount.value;
    }

    return Obx(() => Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(_responsive(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_responsive(context, 12)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 7)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SubTotal',
                    style: TextStyle(
                      fontSize: _responsive(context, 16),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  Text(
                    '${controller.calculateSubtotal().toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: _responsive(context, 16),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Discount (${discountPercent.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: _responsive(context, 16),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: Color(0xff00B10E),
                    ),
                  ),
                  Text(
                    '${controller.calculateDiscount().toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: _responsive(context, 16),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
              Divider(color: Color(0xffB8ABD1), thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total',
                    style: TextStyle(
                      fontSize: _responsive(context, 20),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: Color(0xff00B10E),
                    ),
                  ),
                  Text(
                    '${controller.calculateGrandTotal().toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: _responsive(context, 20),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (controller.showCustomerDetails.value)
          Positioned(
            bottom: _responsive(context, -12),
            right: 0,
            child: InkWell(
              onTap: () {
                controller.toggleCustomerDetails();
              },
              child: Container(
                padding: EdgeInsets.all(_responsive(context, 10)),
                decoration: BoxDecoration(
                  color: Color(0xff0B1928),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  controller.isCartExpanded.value
                      ? 'assets/images/drop.svg'
                      : 'assets/images/dropdown.svg',
                  color: Colors.white,
                  width: _responsive(context, 8),
                  height: _responsive(context, 8),
                ),
              ),
            ),
          ),
      ],
    ));
  }

  Widget _buildCustomerDetailsSection(PosController controller, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _responsive(context, 8)),
      padding: EdgeInsets.all(_responsive(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsive(context, 8)),
        border: Border.all(color: Color(0xffE6E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/user.svg',
                height: _responsive(context, 14),
                width: _responsive(context, 14),
              ),
              SizedBox(width: _responsive(context, 5)),
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: _responsive(context, 15),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          SizedBox(height: _responsive(context, 12)),

          // Name Field
          _buildTextField(
            'Ihre Name *',
            controller.nameController,
            context,
            focusNode: controller.nameFocusNode,
            nextFocusNode: controller.phoneFocusNode,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _responsive(context, 8)),

          // Phone Field
          _buildTextField(
            'Ihre Telefonnummer *',
            controller.phoneController,
            context,
            focusNode: controller.phoneFocusNode,
            nextFocusNode: controller.addressFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _responsive(context, 8)),
        // ✅ Single Address Field
          _buildTextField(
            'Adresse *',
            controller.addressController,
            context,
            focusNode: controller.addressFocusNode,
            nextFocusNode: controller.regionFocusNode,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _responsive(context, 8)),
          _buildTextField(
            'Wählen Sie Ihre Region *',
            controller.regionController,
            context,
            focusNode: controller.regionFocusNode,
            nextFocusNode: controller.emailFocusNode,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _responsive(context, 8)),
          // Email Field
          _buildTextField(
            'Ihre E-Mail',
            controller.emailController,
            context,
            focusNode: controller.emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),


        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      BuildContext context,
      {FocusNode? focusNode,
        FocusNode? nextFocusNode,
        TextInputType? keyboardType,
        TextInputAction? textInputAction}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _responsive(context, 12),
            fontWeight: FontWeight.w600,
            fontFamily: 'Mulish',
          ),
        ),
        SizedBox(height: _responsive(context, 4)),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType ?? TextInputType.text,
          textInputAction: textInputAction ?? TextInputAction.next,
          onSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              FocusScope.of(context).unfocus(); // Close keyboard on last field
            }
          },
          style: TextStyle(
            fontSize: _responsive(context, 11),
            fontFamily: 'Mulish',
          ),
          decoration: InputDecoration(
            hintText: label.split('*')[0].trim(),
            hintStyle: TextStyle(
              fontSize: _responsive(context, 11),
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _responsive(context, 8),
              vertical: _responsive(context, 8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_responsive(context, 4)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_responsive(context, 4)),
              borderSide: BorderSide(color: Color(0xffE31E24)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsDisplay(PosController controller, BuildContext context) {
    return Obx(() => Container(
      margin: EdgeInsets.symmetric(
        horizontal: _responsive(context, 8),
        vertical: _responsive(context, 8),
      ),
      padding: EdgeInsets.all(_responsive(context, 12)),
      decoration: BoxDecoration(
        color: Color(0xffFBF9FF),
        borderRadius: BorderRadius.circular(_responsive(context, 8)),
        border: Border.all(color: Color(0xffE6E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/user.svg',
                    height: _responsive(context, 14),
                    width: _responsive(context, 14),
                  ),
                  SizedBox(width: _responsive(context, 5)),
                  Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: _responsive(context, 14),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: controller.editCustomerDetails,
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 4)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_responsive(context, 4)),
                  ),
                  child: Image.asset(
                    'assets/images/note.png',
                    height: _responsive(context, 20),
                    width: _responsive(context, 20),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _responsive(context, 8)),
          Divider(color: Color(0xffE6E1EE), thickness: 1),
          SizedBox(height: _responsive(context, 8)),
          _buildDetailRow('Ihre Name', controller.customerDetails['name'] ?? '', context),
          SizedBox(height: _responsive(context, 4)),
          _buildDetailRow('Ihre Telefonnummer', controller.customerDetails['phone'] ?? '', context),
          SizedBox(height: _responsive(context, 4)),
          _buildDetailRow('Address', controller.customerDetails['address'] ?? '', context),
          SizedBox(height: _responsive(context, 4)),
          _buildDetailRow('Region', controller.customerDetails['region'] ?? '', context),
          SizedBox(height: _responsive(context, 4)),
          if (controller.customerDetails['email']?.isNotEmpty ?? false)
            _buildDetailRow('Ihre E-Mail', controller.customerDetails['email'] ?? '', context),


        ],
      ),
    ));
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: _responsive(context, 11),
            fontWeight: FontWeight.w700,
            fontFamily: 'Mulish',
            color: Color(0xff797878),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: _responsive(context, 11),
              fontWeight: FontWeight.w600,
              fontFamily: 'Mulish',
              color: Color(0xff0B1928),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildTodaySection(BuildContext context) {
  //   return Container(
  //     margin: EdgeInsets.symmetric(
  //       horizontal: _responsive(context, 8),
  //       vertical: _responsive(context, 8),
  //     ),
  //     padding: EdgeInsets.all(_responsive(context, 12)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(_responsive(context, 8)),
  //       border: Border.all(color: Color(0xffE6E1EE)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               width: _responsive(context, 18),
  //               height: _responsive(context, 18),
  //               decoration: BoxDecoration(
  //                 color: Color(0xffE31E24),
  //                 borderRadius: BorderRadius.circular(_responsive(context, 3)),
  //                 border: Border.all(color: Color(0xffE31E24), width: 2),
  //               ),
  //               child: Icon(
  //                 Icons.check,
  //                 color: Colors.white,
  //                 size: _responsive(context, 12),
  //               ),
  //             ),
  //             SizedBox(width: _responsive(context, 8)),
  //             Text(
  //               'Heute',
  //               style: TextStyle(
  //                 fontSize: _responsive(context, 13),
  //                 fontWeight: FontWeight.w700,
  //                 fontFamily: 'Mulish',
  //                 color: Color(0xff0B1928),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: _responsive(context, 12)),
  //
  //         GestureDetector(
  //           onTap: () => controller.openTimeBottomSheet(),
  //           child: Container(
  //             padding: EdgeInsets.symmetric(
  //               horizontal: _responsive(context, 12),
  //               vertical: _responsive(context, 10),
  //             ),
  //             decoration: BoxDecoration(
  //               color: Color(0xffFBF9FF),
  //               borderRadius: BorderRadius.circular(_responsive(context, 6)),
  //               border: Border.all(color: Color(0xffE6E1EE)),
  //             ),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Obx(() => Text(
  //                   controller.selectedTimeSlot.value,
  //                   style: TextStyle(
  //                     fontSize: _responsive(context, 12),
  //                     fontWeight: FontWeight.w500,
  //                     fontFamily: 'Mulish',
  //                     color: Color(0xff0B1928),
  //                   ),
  //                 )),
  //                 Icon(
  //                   Icons.access_time,
  //                   size: _responsive(context, 16),
  //                   color: Color(0xff0B1928),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //         SizedBox(height: _responsive(context, 12)),
  //         Row(
  //           children: [
  //             Container(
  //               width: _responsive(context, 18),
  //               height: _responsive(context, 18),
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(_responsive(context, 3)),
  //                 border: Border.all(color: Color(0xffB8ABD1), width: 2),
  //               ),
  //             ),
  //             SizedBox(width: _responsive(context, 8)),
  //             Text(
  //               'Vorbestellen',
  //               style: TextStyle(
  //                 fontSize: _responsive(context, 13),
  //                 fontWeight: FontWeight.w700,
  //                 fontFamily: 'Mulish',
  //                 color: Color(0xff0B1928),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: _responsive(context, 12)),
  //         Container(
  //           padding: EdgeInsets.symmetric(
  //             horizontal: _responsive(context, 12),
  //             vertical: _responsive(context, 10),
  //           ),
  //           decoration: BoxDecoration(
  //             color: Color(0xffFBF9FF),
  //             borderRadius: BorderRadius.circular(_responsive(context, 6)),
  //             border: Border.all(color: Color(0xffE6E1EE)),
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Select Date',
  //                 style: TextStyle(
  //                   fontSize: _responsive(context, 12),
  //                   fontWeight: FontWeight.w500,
  //                   fontFamily: 'Mulish',
  //                   color: Color(0xff797878),
  //                 ),
  //               ),
  //               Container(
  //                 padding: EdgeInsets.all(_responsive(context, 6)),
  //                 decoration: BoxDecoration(
  //                   color: Color(0xffE31E24),
  //                   borderRadius: BorderRadius.circular(_responsive(context, 4)),
  //                 ),
  //                 child: Icon(
  //                   Icons.calendar_today,
  //                   color: Colors.white,
  //                   size: _responsive(context, 12),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         SizedBox(height: _responsive(context, 16)),
  //         Divider(color: Color(0xffE6E1EE), thickness: 1),
  //         SizedBox(height: _responsive(context, 12)),
  //         Text(
  //           'Zahlungsmethode auswählen',
  //           style: TextStyle(
  //             fontSize: _responsive(context, 13),
  //             fontWeight: FontWeight.w700,
  //             fontFamily: 'Mulish',
  //             color: Color(0xff0B1928),
  //           ),
  //         ),
  //         SizedBox(height: _responsive(context, 12)),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Container(
  //                 padding: EdgeInsets.symmetric(
  //                   vertical: _responsive(context, 10),
  //                   horizontal: _responsive(context, 4),
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(_responsive(context, 6)),
  //                   border: Border.all(color: Color(0xffE31E24), width: 2),
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Icon(
  //                       Icons.credit_card,
  //                       color: Color(0xffE31E24),
  //                       size: _responsive(context, 16),
  //                     ),
  //                     SizedBox(width: _responsive(context, 3)),
  //                     Text(
  //                       'Online-Zahlung',
  //                       style: TextStyle(
  //                         fontSize: _responsive(context, 11),
  //                         fontWeight: FontWeight.w700,
  //                         fontFamily: 'Mulish',
  //                         color: Color(0xffE31E24),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: _responsive(context, 10)),
  //             Expanded(
  //               child: Container(
  //                 padding: EdgeInsets.symmetric(
  //                   vertical: _responsive(context, 10),
  //                   horizontal: _responsive(context, 12),
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Color(0xff232D3F),
  //                   borderRadius: BorderRadius.circular(_responsive(context, 6)),
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Icon(
  //                       Icons.payments_outlined,
  //                       color: Colors.white,
  //                       size: _responsive(context, 16),
  //                     ),
  //                     SizedBox(width: _responsive(context, 6)),
  //                     Text(
  //                       'Bar',
  //                       style: TextStyle(
  //                         fontSize: _responsive(context, 11),
  //                         fontWeight: FontWeight.w700,
  //                         fontFamily: 'Mulish',
  //                         color: Colors.white,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildTodaySection(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(
          horizontal: _responsive(context, 8),
          vertical: _responsive(context, 8),
        ),
        padding: EdgeInsets.all(_responsive(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_responsive(context, 8)),
          border: Border.all(color: Color(0xffE6E1EE)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => GestureDetector(
                onTap: () => controller.selectHeute(),
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 12)),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(_responsive(context, 8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _responsive(context, 24),
                        height: _responsive(context, 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff0B1928),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(_responsive(context, 4)),
                        ),
                        child: controller.isHeuteSelected.value?
                            Container(
                              margin: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: controller.isHeuteSelected.value
                                    ? Color(0xff0C831F)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(_responsive(context, 4)),
                              ),
                            )
                            : null,
                      ),
                      SizedBox(width: _responsive(context, 12)),
                      Text(
                        'Heute',
                        style: TextStyle(
                          fontSize: _responsive(context, 14),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: Color(0xff0B1928),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          SizedBox(height: _responsive(context, 12)),

          Obx(() => controller.isHeuteSelected.value
              ? GestureDetector(
                  onTap: () => controller.openTimeBottomSheet(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _responsive(context, 12),
                      vertical: _responsive(context, 10),
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffFBF9FF),
                      borderRadius:
                          BorderRadius.circular(_responsive(context, 6)),
                      border: Border.all(color: Color(0xffE6E1EE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.selectedTimeSlot.value,
                          style: TextStyle(
                            fontSize: _responsive(context, 12),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Mulish',
                            color: Color(0xff0B1928),
                          ),
                        ),
                        Icon(
                          Icons.access_time,
                          size: _responsive(context, 16),
                          color: Color(0xff0B1928),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox.shrink()),

          SizedBox(height: _responsive(context, 12)),

          Obx(() => GestureDetector(
                onTap: () => controller.selectVorbestellen(),
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 12)),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(_responsive(context, 8)),

                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _responsive(context, 24),
                        height: _responsive(context, 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff0B1928),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(_responsive(context, 4)),
                        ),
                        child: controller.isVorbestellenSelected.value
                            ?  Container(
                          margin: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: controller.isVorbestellenSelected.value
                                ? Color(0xff0C831F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(_responsive(context, 4)),
                          ),
                        )
                            : null,
                      ),
                      SizedBox(width: _responsive(context, 12)),
                      Text(
                        'Vorbestellen',
                        style: TextStyle(
                          fontSize: _responsive(context, 14),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: Color(0xff0B1928),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          SizedBox(height: _responsive(context, 12)),

          Obx(() => controller.isVorbestellenSelected.value
              ? Column(
                  children: [
                    GestureDetector(
                      onTap: () => controller.openCalendar(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _responsive(context, 12),
                          vertical: _responsive(context, 10),
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffFBF9FF),
                          borderRadius:
                              BorderRadius.circular(_responsive(context, 6)),
                          border: Border.all(color: Color(0xffE6E1EE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.getFormattedSelectedDateTime(),
                              style: TextStyle(
                                fontSize: _responsive(context, 12),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Mulish',
                                color: Color(0xff797878),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(_responsive(context, 6)),
                              decoration: BoxDecoration(
                                color: Color(0xffE31E24),
                                borderRadius: BorderRadius.circular(
                                    _responsive(context, 4)),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: _responsive(context, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Select Time (only visible after date is selected)
                    if (controller.showTimeSelector.value &&
                        controller.selectedDate.value != null)
                      Padding(
                        padding: EdgeInsets.only(top: _responsive(context, 12)),
                        child: GestureDetector(
                          onTap: () => controller.openTimeSelector(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _responsive(context, 12),
                              vertical: _responsive(context, 10),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xffFBF9FF),
                              borderRadius: BorderRadius.circular(
                                  _responsive(context, 6)),
                              border: Border.all(color: Color(0xffE6E1EE)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select Time',
                                  style: TextStyle(
                                    fontSize: _responsive(context, 12),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Mulish',
                                    color: Color(0xff797878),
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  size: _responsive(context, 16),
                                  color: Color(0xff0B1928),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : SizedBox.shrink()),

          SizedBox(height: _responsive(context, 16)),
          Divider(color: Color(0xffE6E1EE), thickness: 1),
          SizedBox(height: _responsive(context, 12)),

          Text(
            'Zahlungsmethode auswählen',
            style: TextStyle(
              fontSize: _responsive(context, 13),
              fontWeight: FontWeight.w700,
              fontFamily: 'Mulish',
              color: Color(0xff0B1928),
            ),
          ),
          SizedBox(height: _responsive(context, 12)),
          Row(children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _responsive(context, 10),
                  horizontal: _responsive(context, 4),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_responsive(context, 6)),
                  border: Border.all(color: Color(0xffE31E24), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: Color(0xffE31E24),
                      size: _responsive(context, 16),
                    ),
                    SizedBox(width: _responsive(context, 3)),
                    Text(
                      'Online-Zahlung',
                      style: TextStyle(
                        fontSize: _responsive(context, 11),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                        color: Color(0xffE31E24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: _responsive(context, 10)),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _responsive(context, 10),
                  horizontal: _responsive(context, 12),
                ),
                decoration: BoxDecoration(
                  color: Color(0xff232D3F),
                  borderRadius: BorderRadius.circular(_responsive(context, 6)),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    Icons.payments_outlined,
                    color: Colors.white,
                    size: _responsive(context, 16),
                  ),
                  SizedBox(width: _responsive(context, 6)),
                  Text(
                    'Bar',
                    style: TextStyle(
                      fontSize: _responsive(context, 11),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildWeiterButton(PosController controller, BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: controller.onWeiterPressed,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          _responsive(context, 8),
          _responsive(context, 12),
          _responsive(context, 8),
          _responsive(context, 12),
        ),
        decoration: BoxDecoration(
          color: Color(0xff0C831F),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(_responsive(context, 5)),
            bottomRight: Radius.circular(_responsive(context, 5)),
          ),
        ),
        child: Center(
          child: Text(
            controller.customerDetails.isEmpty ? 'Weiter' : 'Place Order',
            style: TextStyle(
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w700,
              fontSize: _responsive(context, 14),
              color: Colors.white,
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildTimeBottomSheet(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showTimeBottomSheet.value) {
        return SizedBox.shrink();
      }

      return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.375,
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Stack(clipBehavior: Clip.none,
                children: [
                  Container(
                  padding: EdgeInsets.all(_responsive(context, 16)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xffE6E1EE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _responsive(context, 35),
                        height: _responsive(context, 35),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff0B1928),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(_responsive(context, 6)),
                        ),
                        child: Container(
                          margin: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Color(0xff0C831F),
                            borderRadius: BorderRadius.circular(_responsive(context, 4)),
                          ),
                        )
                      ),
                      SizedBox(width: _responsive(context, 12)),
                      Text(
                        'Heute',
                        style: TextStyle(
                          fontSize: _responsive(context, 18),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ),
                  Positioned(
                    top: -18,right: 15,
                    child: GestureDetector(
                    onTap: () => controller.closeTimeBottomSheet(),
                    child: Container(
                      width: _responsive(context, 45),
                      height: _responsive(context, 45),
                      decoration: BoxDecoration(
                        color: Color(0xffE31E24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: _responsive(context, 30),
                      ),
                    ),
                  ),)
              ]),

              // sofort option
              Padding(
                padding: EdgeInsets.all(_responsive(context, 12)),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: _responsive(context, 8),
                  ),
                  decoration: BoxDecoration(
                    color:  Color(0xffFBF9FF),
                    borderRadius: BorderRadius.circular(_responsive(context, 5)),
                    border: Border.all(
                      color: Color(0xff0C831F),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'sofort',
                      style: TextStyle(
                        fontSize: _responsive(context, 18),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                        color:  Color(0xff0B1928),
                      ),
                    ),
                  ),
                ),
              ),

              // Time slots grid
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: _responsive(context, 16)),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: _responsive(context, 5),
                      mainAxisSpacing: _responsive(context, 5),
                      childAspectRatio: 2.3,
                    ),
                    itemCount: controller.getTimeSlots().length,
                    itemBuilder: (context, index) {
                      String timeSlot = controller.getTimeSlots()[index];
                      bool isSelected = controller.selectedTimeSlot.value == timeSlot;

                      return GestureDetector(
                        onTap: () => controller.selectTimeSlot(timeSlot),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xff0C831F) : Color(0xffE9F6EF),
                            borderRadius: BorderRadius.circular(_responsive(context, 4)),
                            border: Border.all(
                              color: isSelected ? Color(0xff0C831F) : Color(0xff0C831F),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              timeSlot,
                              style: TextStyle(
                                fontSize: _responsive(context, 16),
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                                color: isSelected ? Colors.white : Color(0xff0B1928),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCalendarBottomSheet(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showCalendar.value) {
        return SizedBox.shrink();
      }

      return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.375,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Stack(clipBehavior: Clip.none,
                children:[
                  Container(
                  padding: EdgeInsets.all(_responsive(context, 16)),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xffE6E1EE))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'March,',
                            style: TextStyle(
                              fontSize: _responsive(context, 20),
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            '2025',
                            style: TextStyle(
                              fontSize: _responsive(context, 18),
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Mulish',
                              color: Color(0xff0C831F),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Color(0xff0C831F)),
                        ],
                      ),
                    ],
                  ),
                ),
                  Positioned(
                    top: -18,right: 15,
                    child:  GestureDetector(
                    onTap: () => controller.closeCalendar(),
                    child: Container(
                      width: _responsive(context, 45),
                      height: _responsive(context, 45),
                      decoration: BoxDecoration(
                        color: Color(0xffE31E24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: _responsive(context, 30),
                      ),
                    ),
                  ),)
             ] ),

              // Calendar Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_responsive(context, 16)),
                  child: Column(
                    children: [
                      // Week days header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) =>
                            Container(
                              padding: EdgeInsets.all(2),
                          width: _responsive(context, 50),
                          decoration: BoxDecoration(
                            color: Color(0xff0B1928),
                          ),
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: _responsive(context, 14),
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                      SizedBox(height: _responsive(context, 10)),
                      // Calendar dates (simplified - you'll need to implement full calendar logic)
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: _responsive(context, 4),
                            crossAxisSpacing: _responsive(context, 4),
                          ),
                          itemCount: 35,
                          itemBuilder: (context, index) {
                            int day = index + 1;
                            bool isSelected = controller.selectedDate.value?.day == day;

                            return GestureDetector(
                              onTap: () {
                                DateTime now = DateTime.now();
                                controller.selectDate(DateTime(now.year, now.month, day));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(0xff0C831F) : Colors.transparent,
                                  border: Border.all(color: Color(0xffEEF5FF),width: 1)
                                ),
                                child: Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: _responsive(context, 14),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Mulish',
                                      color: isSelected ? Colors.white : Color(0xff0B1928),
                                    ),
                                  ),
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
            ],
          ),
        ),
      );
    });
  }
}

