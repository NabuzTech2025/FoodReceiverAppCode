import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_app/ui/Pos/pos_controller.dart';
import 'package:get/get.dart';

import '../home_screen.dart';


// Portrait Mode
class PosPortrait extends StatelessWidget {
  const PosPortrait({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PosController());

    return Scaffold(
      backgroundColor: const Color(0xffFAFCFF),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.offAll(() => const HomeScreen());
          },
          child: const Icon(Icons.arrow_back_ios, size: 32),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
              _buildPortraitHeader(controller),
              Expanded(
                child: Row(
                  children: [
                    Obx(() {
                      if (!controller.isSearching.value) {
                        return _buildPortraitSidebar(controller);
                      }
                      return const SizedBox.shrink();
                    }),
                    Expanded(
                      child: _buildPortraitContent(controller, context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.totalItems.value > 0) {
              return _buildCartBar(controller);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildPortraitHeader(PosController controller) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/drawer.png', height: 25, width: 25),
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffDDEAFF), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 15, color: Colors.black),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Mulish',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search item',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Mulish',
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return GestureDetector(
                      onTap: controller.clearSearch,
                      child: const Icon(Icons.clear, size: 15, color: Colors.grey),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          Obx(() => GestureDetector(
            onTap: controller.isRefreshing.value ? null : controller.refreshData,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xffDDEAFF), width: 1),
              ),
              child: controller.isRefreshing.value
                  ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xffE31E24)),
                ),
              )
                  : const Icon(
                Icons.refresh,
                color: Color(0xffE31E24),
                size: 15,
              ),
            ),
          )),
          Row(
            children: [
              Image.asset('assets/images/german.png', height: 20, width: 20),
              const Text(
                'GER',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Mulish',
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitSidebar(PosController controller) {
    return Obx(() => Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          ListView.builder(
            padding: EdgeInsets.zero,
            controller: controller.sidebarScrollController,
            itemCount: controller.productCategoryList.length,
            itemBuilder: (context, index) {
              bool isSelected =
                  controller.selectedCategoryIndex.value == index;
              var category = controller.productCategoryList[index];
              return GestureDetector(
                onTap: () => controller.scrollToCategory(index),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color:
                    isSelected ? const Color(0xffFFF5F5) : Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: controller.getTrimmedImageUrl(category.imageUrl),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                            const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          category.name.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mulish',
                            color: isSelected
                                ? const Color(0xffE7292D)
                                : const Color(0xff232121),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: 0,
            top: controller.selectedCategoryIndex.value * 80.0,
            child: Container(
              width: 3,
              height: 80,
              color: const Color(0xffE7292D),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildPortraitContent(
      PosController controller, BuildContext context) {
    return Obx(() {
      // Show filtered products when searching
      if (controller.isSearching.value) {
        final displayCategories = controller.getFilteredCategories();

        if (displayCategories.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Search results - show all matching products grouped by category
        return ListView.builder(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).size.width * 1.35,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, categoryIndex) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    displayCategories[categoryIndex].name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: displayCategories[categoryIndex].products.length,
                  itemBuilder: (context, index) {
                    var product = displayCategories[categoryIndex].products[index];
                    return ProductCard(
                      product: product,
                      controller: controller,
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        );
      }

      // Normal mode - show only selected category's products
      if (controller.categories.isEmpty) {
        return const Center(
          child: Text(
            'No products available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Mulish',
              color: Colors.grey,
            ),
          ),
        );
      }

      final selectedCategory = controller.categories[controller.selectedCategoryIndex.value];

      if (selectedCategory.products.isEmpty) {
        return const Center(
          child: Text(
            'No products in this category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Mulish',
              color: Colors.grey,
            ),
          ),
        );
      }

      return ListView(
        controller: controller.mainScrollController,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).size.width * 1.35,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              selectedCategory.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: selectedCategory.products.length,
            itemBuilder: (context, index) {
              var product = selectedCategory.products[index];
              return ProductCard(
                product: product,
                controller: controller,
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildCartBar(PosController controller) {
    return Positioned(
      bottom: 15,
      left: 15,
      right: 15,
      child: Obx(() => Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xff4CAF50),
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset('assets/images/cart.png'),
                      if (controller.totalItems.value > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xffE7292D),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                '${controller.totalItems.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${controller.totalPrice.value.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Text(
                        'Items : ${controller.totalItems.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Row(
                children: [
                  Text(
                    'View Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final PosController controller;

  const ProductCard({super.key, 
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isSelected = controller.isProductSelected(product);
      int quantity = controller.getProductQuantity(product);

      return GestureDetector(
        onTap: () => controller.addToCartPortrait(product),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xff4CAF50) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: Color(0xff232121),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty)
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CachedNetworkImage(
                          imageUrl:
                          controller.getTrimmedImageUrl(product.imageUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                            size: 25,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xff4CAF50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      controller.removeFromCartPortrait(product),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: Icon(Icons.remove,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Mulish',
                                    color: Colors.white,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      controller.addToCartPortrait(product),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: Icon(Icons.add,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Text(
                          '${product.price.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (product.isSpicy)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/images/non-veg.png',
                        height: 12, width: 12),
                  ),
                ),
              if (product.isVeg)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/images/veg.png',
                        height: 12, width: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:food_app/constants/app_color.dart';
// import 'package:get/get.dart';
// import '../home_screen.dart';
// import 'pos_controller.dart';
//
// class ResponsivePos extends StatelessWidget {
//   const ResponsivePos({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return OrientationBuilder(
//       builder: (context, orientation) {
//       //   if (orientation == Orientation.landscape) {
//       //     return const PosLandscape();
//       //   } else {
//       //     return const PosPortrait();
//       //   }
//       // },
//         return const PosLandscape();
//       }
//     );
//   }
// }
//
// class PosLandscape extends StatefulWidget {
//   const PosLandscape({super.key});
//
//   @override
//   State<PosLandscape> createState() => _PosLandscapeState();
// }
//
// class _PosLandscapeState extends State<PosLandscape> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(PosController());
//
//     return Scaffold(
//       backgroundColor: Color(0xffFBF9FF),
//       body: Padding(
//         padding: const EdgeInsets.only(top: 12),
//         child: Row(
//           children: [
//             _buildSidebar(controller),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       flex: 5,
//                       child: _buildProductsSection(controller, context),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       flex: 3,
//                       child: _buildCartSection(controller, context),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSidebar(PosController controller) {
//     return Stack(
//       children: [
//         Container(
//           width: 60,
//           color: Colors.white,
//           child: Column(
//             children: [
//               SizedBox(height: 20),
//               Container(
//                 width: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       Container(
//                         margin: EdgeInsets.all(5),
//                         padding: EdgeInsets.all(5),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(7),
//                         ),
//                         child: Center(
//                           child: Image.asset('assets/images/mirch.png'),
//                         ),
//                       ),
//                       SizedBox(height: 50),
//                       _buildSidebarItem(Icons.shopping_bag_outlined, false),
//                       SizedBox(height: 20),
//                       _buildSidebarItem(Icons.bar_chart_outlined, false),
//                       SizedBox(height: 20),
//                       _buildSidebarItem(Icons.settings_outlined, false),
//                       SizedBox(height: 10),
//                     ],
//                   ),
//                 ),
//               ),
//               Spacer(),
//               Padding(
//                 padding: EdgeInsets.only(bottom: 20),
//                 child:GestureDetector(
//                   onTap: () {
//                     controller.showLogoutDialog(Get.context!);
//                   },
//                   child: Container(
//                     width: 45,
//                     height: 45,
//                     decoration: BoxDecoration(
//                       color: Color(0xffE31E24),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       Icons.power_settings_new,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           top: 60,
//           right: 0,
//           left: 0,
//           child: Container(
//             height: 45,
//             width: 49,
//             margin: EdgeInsets.only(left: 10, top: 15),
//             padding: EdgeInsets.only(right: 10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 bottomLeft: Radius.circular(12),
//               ),
//             ),
//             child: Center(
//               child: Image.asset(
//                 'assets/images/plus.png',
//                 height: 20,
//                 width: 20,
//                 color: Color(0xff0B1928),
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }
//
//   Widget _buildSidebarItem(IconData icon, bool isActive) {
//     return Container(
//       width: 45,
//       height: 45,
//       decoration: BoxDecoration(
//         color: isActive ? Color(0xffE31E24) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Icon(
//         icon,
//         color: Color(0xff0B1928),
//         size: 24,
//       ),
//     );
//   }
//
//   Widget _buildProductsSection(PosController controller, BuildContext context) {
//     return Column(
//       children: [
//         _buildHeader(controller),
//         SizedBox(height: 20),
//         _buildCategoryTabs(controller),
//         Expanded(
//           child: Obx(() {
//             print('🔄 Rebuilding product list. Visible categories: ${controller.visibleCategories}');
//
//             List<int> categoriesToShow = controller.visibleCategories.toList();
//
//             if (categoriesToShow.isEmpty) {
//               return Center(child: Text('No categories to show'));
//             }
//
//             return ListView.builder(
//               controller: controller.landscapeProductScrollController,
//               padding: EdgeInsets.only(bottom:200),
//               itemCount: categoriesToShow.length,
//               itemBuilder: (context, visibleIndex) {
//                 int categoryIndex = categoriesToShow[visibleIndex];
//                 if (categoryIndex >= controller.productCategoryList.length) {
//                   return SizedBox.shrink();
//                 }
//                 var category = controller.productCategoryList[categoryIndex];
//                 var categoryProducts = controller.productList
//                     .where((p) => p.categoryId == category.id && (p.isActive ?? false))
//                     .toList();
//                 if (categoryProducts.isEmpty) return SizedBox.shrink();
//                 return Container(
//                   key: ValueKey('category_$categoryIndex'),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Position marker widget
//                       _CategoryPositionMarker(
//                         categoryIndex: categoryIndex,
//                         controller: controller,
//                       ),
//                       Padding(
//                         padding: EdgeInsets.only(left: 8, top: 12, bottom: 8),
//                         child: Text(
//                           category.name ?? '',
//                           style: TextStyle(
//                             fontFamily: 'Mulish',
//                             fontWeight: FontWeight.w700,
//                             fontSize: 20,
//                           ),
//                         ),
//                       ),
//                       GridView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         padding: EdgeInsets.zero,
//                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 5,
//                           crossAxisSpacing: 5,
//                           mainAxisSpacing: 5,
//                           childAspectRatio: 0.93,
//                         ),
//                         itemCount: categoryProducts.length,
//                         itemBuilder: (context, index) {
//                           var product = categoryProducts[index];
//
//                           return RepaintBoundary(
//                               child: Obx(() {
//                               int cartIndex = controller.cartItems.indexWhere(
//                                       (item) => item['name'] == product.name
//                               );
//                               bool isInCart = cartIndex != -1;
//                               int quantity = isInCart ? controller.cartItems[cartIndex]['quantity'] : 0;
//
//                               bool isSelected = controller.selectedProductIndex.value == index;
//                               return GestureDetector(
//                                 onTap: () {
//                                   //controller.selectedProductIndex.value = index;
//                                   controller.addToCart(product);
//                                 },
//                                 child: Container(
//                                   padding: EdgeInsets.all(3),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8),
//                                     color: Colors.white,
//                                     border: Border.all(
//                                       color:isInCart ? AppColor.borderGreen : Colors.transparent,
//                                       width: 1,
//                                     ),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.grey.withOpacity(0.1),
//                                         blurRadius: 4,
//                                         offset: Offset(0, 2),
//                                       )
//                                     ],
//                                   ),
//                                   child:  Padding(
//                                     padding: const EdgeInsets.only(left: 4.0),
//                                     child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           product.name ?? '',
//                                           style: TextStyle(
//                                             fontFamily: 'Mulish',
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 12,
//                                           ),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         Row(
//                                           mainAxisAlignment: isInCart
//                                               ? MainAxisAlignment.spaceBetween
//                                               : MainAxisAlignment.end,
//                                           children: [
//                                             if (isInCart)
//                                               Container(
//                                                 width: 24,
//                                                 height: 24,
//                                                 decoration: BoxDecoration(
//                                                   color: AppColor.borderGreen,
//                                                   shape: BoxShape.circle,
//                                                 ),
//                                                 child: Center(
//                                                   child: Text(
//                                                     '$quantity',
//                                                     style: TextStyle(
//                                                       fontFamily: 'Mulish',
//                                                       fontWeight: FontWeight.w700,
//                                                       fontSize: 12,
//                                                       color: Colors.white,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             Text(
//                                               '${double.tryParse(product.price?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} €',
//                                               style: TextStyle(
//                                                 fontFamily: 'Mulish',
//                                                 fontWeight: FontWeight.w700,
//                                                 fontSize: 12,
//                                                 color: AppColor.borderGreen,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               );
//                                                         }),
//                             );
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               },);
//           }
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildHeader(PosController controller) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Image.asset(
//           'assets/images/drawer.png',
//           height: 20,
//           width: 30,
//         ),
//         Expanded(
//           child: Container(
//             margin: EdgeInsets.symmetric(horizontal: 12),
//             height: 40,
//             padding: EdgeInsets.symmetric(horizontal: 8),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(5),
//               color: Colors.white,
//             ),
//             child: TextField(
//               controller: controller.searchController,
//               onChanged: controller.filterProducts,
//               decoration: InputDecoration(
//                 hintText: 'Search Item name or ID',
//                 hintStyle: TextStyle(
//                   fontFamily: 'Mulish',
//                   fontWeight: FontWeight.w300,
//                   fontSize: 14,
//                   fontStyle: FontStyle.italic,
//                 ),
//                 border: InputBorder.none,
//                 suffixIcon: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Image.asset(
//                     'assets/images/search.png',
//                     height: 10,
//                     width: 10,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               style: TextStyle(
//                 fontFamily: 'Mulish',
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ),
//         Obx(() => GestureDetector(
//           onTap: controller.isRefreshing.value ? null : controller.refreshData,
//           child: Container(
//             padding: EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(5),
//             ),
//             child: controller.isRefreshing.value
//                 ? SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xffE31E24)),
//               ),
//             )
//                 : Icon(
//               Icons.refresh,
//               color: Color(0xffE31E24),
//               size: 20,
//             ),
//           ),
//         )),
//         SizedBox(width: 5),
//         Row(
//           children: [
//             Image.asset(
//               'assets/images/german.png',
//               height: 25,
//               width: 25,
//             ),
//             SizedBox(width: 5),
//             Text(
//               'GER',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'Mulish',
//                 color: Color(0xff232121),
//               ),
//             )
//           ],
//         ),
//         SizedBox(width: 3),
//         GestureDetector(
//           onTap: () {
//             Get.offAll(() => HomeScreen());
//           },
//           child: Container(
//             padding: EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(5),
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.arrow_back_ios,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }
//
//   Widget _buildCategoryTabs(PosController controller) {
//     return Container(
//       height: 80,
//       child: Obx(() => ListView.builder(
//         controller: controller.landscapeCategoryScrollController,
//         scrollDirection: Axis.horizontal,
//         itemCount: controller.productCategoryList.length,
//         itemBuilder: (context, index) {
//           var category = controller.productCategoryList[index];
//           return Obx(() {
//             bool isSelected = controller.selectedCategoryIndex.value == index;
//
//             return GestureDetector(
//               onTap: () {
//                 controller.selectCategory(index);
//               },
//               child: Container(
//                 padding: EdgeInsets.all(5),
//                 width: 80,
//                 height: 40,
//                 margin: EdgeInsets.only(right: 5),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isSelected ? AppColor.borderGreen : Color(
//                         0xffCFC1ED),
//                     width: 1,
//                   ),
//                   color: Colors.white,
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       child: Center(
//                         child: CachedNetworkImage(
//                           imageUrl: controller.getTrimmedImageUrl(
//                               category.imageUrl),
//                           height: 30,
//                           width: 30,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) =>
//                               CircularProgressIndicator(strokeWidth: 2),
//                           errorWidget: (context, url, error) =>
//                               Icon(Icons.restaurant, size: 20),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       category.name ?? '',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontFamily: 'Mulish',
//                         fontWeight: FontWeight.w700,
//                         fontSize: 10,
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             );
//           });
//         },
//           )
//           ),
//     );
//   }
//
//   Widget _buildCartSection(PosController controller, BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(5),
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(8),
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Color(0xffEDE4FF),width: 1),
//                 borderRadius: BorderRadius.circular(5),
//                 color: Color(0xffFBF9FF),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Phone Number / Name',
//                     style: TextStyle(
//                       fontFamily: 'Mulish',
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                       color: Color(0xff797878),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => controller.onAddCustomerPressed(),
//                     child: Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Color(0xffB8ABD1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child:SvgPicture.asset('assets/images/add-user.svg',
//                         height: 18,width: 18,)
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Order type buttons - always at top
//           Padding(
//             padding: EdgeInsets.all(8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         _buildOrderTypeButton(controller, 'Lieferzeit',
//                             'assets/images/delivery-icon.svg'),
//                         SizedBox(width: 10),
//                         _buildOrderTypeButton(controller, 'Abholzeit',
//                             'assets/images/pickup-icon.svg'),
//                       ],
//                     ),
//                     GestureDetector(
//                       onTap: () => controller.showAddNoteDialog(context),
//                       child: Row(
//                         children: [
//                           Image.asset('assets/images/note.png',
//                               height: 10, width: 10),
//                           SizedBox(width: 5),
//                           Text(
//                             'Add Note',
//                             style: TextStyle(
//                               fontFamily: 'Mulish',
//                               fontWeight: FontWeight.w800,
//                               fontSize: 10,
//                               decoration: TextDecoration.underline,
//                               color: Color(0xff0B1928),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           // Main content area
//           Expanded(
//             child: Obx(() {
//               // When cart is empty and customer details not shown
//               if (controller.cartItems.isEmpty && !controller.showCustomerDetails.value) {
//                 return Column(
//                   children: [
//                     Expanded(
//                       child: Center(
//                         child: Text(
//                           'No items in cart',
//                           style: TextStyle(
//                             fontFamily: 'Mulish',
//                             fontWeight: FontWeight.w500,
//                             fontSize: 14,
//                             color: Color(0xff797878),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                       child: _buildSummarySection(controller),
//                     ),
//                   ],
//                 );
//               }
//
//               // When customer details are being shown (after Weiter tap)
//               if (controller.showCustomerDetails.value) {
//                 return Column(
//                   children: [
//                     // Summary box fixed at top (after order type buttons)
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                       child: _buildSummarySection(controller),
//                     ),
//                     // Scrollable customer details section
//                     Expanded(
//                       child: SingleChildScrollView(
//                         child: Column(
//                           children: [
//                             if (controller.isCustomerFormVisible.value)
//                               _buildCustomerDetailsSection(controller),
//
//                             if (controller.customerDetails.isNotEmpty &&
//                                 !controller.isCustomerFormVisible.value)
//                               _buildCustomerDetailsDisplay(controller),
//
//                             if (controller.customerDetails.isNotEmpty &&
//                                 !controller.isCustomerFormVisible.value)
//                               _buildTodaySection(),
//
//                             SizedBox(height: 20),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }
//
//               // When cart has items but customer details not shown yet
//               return Column(
//                 children: [
//                   // Scrollable cart items
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           _buildCartItems(controller, context),
//                           SizedBox(height: 20),
//                         ],
//                       ),
//                     ),
//                   ),
//                   // Summary box fixed at bottom
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                     child: _buildSummarySection(controller),
//                   ),
//                 ],
//               );
//             }),
//           ),
//
//           _buildWeiterButton(controller),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderTypeButton(
//       PosController controller, String type, String iconPath) {
//     return Obx(() {
//       bool isSelected = controller.selectedOrderType.value == type;
//       return GestureDetector(
//         onTap: () => controller.setOrderType(type),
//         child: Container(
//           padding: EdgeInsets.all(5),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(5),
//             color: isSelected ? Color(0xff0C831F) : Color(0xffFBF9FF),
//           ),
//           child: Row(
//             children: [
//               SvgPicture.asset(
//                 iconPath,
//                 color: isSelected ? Colors.white : Colors.black,
//                 height: 12,
//                 width: 12,
//               ),
//               SizedBox(width: 3),
//               Text(
//                 type,
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   fontFamily: 'Mulish',
//                   color: isSelected ? Colors.white : Color(0xff0B1928),
//                 ),
//               )
//             ],
//           ),
//         ),
//       );
//     });
//   }
//
//   Widget _buildCartItems(PosController controller, BuildContext context) {
//     return Obx(() {
//       if (controller.isCartExpanded.value) {
//         return Padding(
//           padding: EdgeInsets.symmetric(horizontal: 4),
//           child: ListView.separated(
//             shrinkWrap: true,
//             padding: EdgeInsets.zero,
//             physics: NeverScrollableScrollPhysics(),
//             itemCount: controller.cartItems.length,
//             separatorBuilder: (context, index) =>
//                 Divider(height: 1, color: Color(0xffE6E1EE)),
//             itemBuilder: (context, index) {
//               final item = controller.cartItems[index];
//               return Container(
//                 margin: EdgeInsets.all(2),
//                 padding: EdgeInsets.all(2),
//                 child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       width: MediaQuery.of(context).size.width * 0.16,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             item['name'],
//                             style: TextStyle(
//                               fontFamily: 'Mulish',
//                               fontWeight: FontWeight.w700,
//                               fontSize: 12,
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             item['extras'],
//                             style: TextStyle(
//                               fontFamily: 'Mulish',
//                               fontWeight: FontWeight.w500,
//                               fontSize: 10,
//                               color: Color(0xff797878),
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             item['size'],
//                             style: TextStyle(
//                               fontFamily: 'Mulish',
//                               fontWeight: FontWeight.w500,
//                               fontSize: 10,
//                               color: Color(0xff797878),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Row(
//                       children: [
//                         GestureDetector(
//                           onTap: () => controller.decrementQuantity(index),
//                           child: Container(
//                             width: 18,
//                             height: 18,
//                             decoration: BoxDecoration(
//                               border:
//                               Border.all(color: Color(0xffB8ABD1), width: 1),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Icon(Icons.remove,
//                                 size: 14, color: Color(0xff0B1928)),
//                           ),
//                         ),
//                         SizedBox(width: 5),
//                         Text(
//                           '${item['quantity']}',
//                           style: TextStyle(
//                             fontFamily: 'Mulish',
//                             fontWeight: FontWeight.w700,
//                             fontSize: 12,
//                             color: Color(0xff0B1928),
//                           ),
//                         ),
//                         SizedBox(width: 5),
//                         GestureDetector(
//                           onTap: () => controller.incrementQuantity(index),
//                           child: Container(
//                             width: 18,
//                             height: 18,
//                             decoration: BoxDecoration(
//                               border:
//                               Border.all(color: Color(0xffB8ABD1), width: 1),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Icon(Icons.add,
//                                 size: 14, color: Color(0xff0B1928)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(width: 5),
//                     Text(
//                       '€ ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
//                       style: TextStyle(
//                         fontFamily: 'Mulish',
//                         fontWeight: FontWeight.w700,
//                         fontSize: 11,
//                         color: Color(0xff0B1928),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         );
//       }
//       return SizedBox.shrink();
//     });
//   }
//
//   Widget _buildSummarySection(PosController controller) {
//     return Obx(() => Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 7)],
//           ),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'SubTotal',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                     ),
//                   ),
//                   Text(
//                     '${controller.calculateSubtotal().toStringAsFixed(2)} €',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Total Discount (10%)',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                       color: Color(0xff00B10E),
//                     ),
//                   ),
//                   Text(
//                     '${controller.calculateDiscount().toStringAsFixed(2)} €',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                     ),
//                   ),
//                 ],
//               ),
//               Divider(color: Color(0xffB8ABD1), thickness: 1),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Grand Total',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                       color: Color(0xff00B10E),
//                     ),
//                   ),
//                   Text(
//                     '${controller.calculateGrandTotal().toStringAsFixed(2)} €',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'Mulish',
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         // Show dropdown only when customer details are visible
//         if (controller.showCustomerDetails.value)
//           Positioned(
//             bottom: -10,
//             right: 0,
//             child: InkWell(
//               onTap: () {
//                 // This will hide customer details and bring back to cart view
//                 controller.toggleCustomerDetails();
//               },
//               child: Container(
//                 padding: EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Color(0xff0B1928),
//                   shape: BoxShape.circle,
//                 ),
//                 child: SvgPicture.asset(
//                   controller.isCartExpanded.value
//                       ? 'assets/images/drop.svg'
//                       : 'assets/images/dropdown.svg',
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     ));
//   }
//
//   Widget _buildCustomerDetailsSection(PosController controller) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 8),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Color(0xffE6E1EE)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               SvgPicture.asset('assets/images/user.svg',
//                   height: 14, width: 14),
//               SizedBox(width: 5),
//               Text(
//                 'Customer Details',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w800,
//                   fontFamily: 'Mulish',
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           _buildTextField('Ihre Name *', controller.nameController),
//           SizedBox(height: 8),
//           _buildTextField(
//               'Ihre Telefonnummer *', controller.phoneController),
//           SizedBox(height: 8),
//           _buildTextField('Ihre E-Mail', controller.emailController),
//           SizedBox(height: 8),
//           _buildTextField(
//               'Straße und Hausnummer *', controller.addressController),
//           SizedBox(height: 8),
//           _buildTextField(
//               'Wählen Sie Ihre Region *', controller.regionController),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             fontFamily: 'Mulish',
//           ),
//         ),
//         SizedBox(height: 4),
//         TextField(
//           controller: controller,
//           style: TextStyle(fontSize: 11, fontFamily: 'Mulish'),
//           decoration: InputDecoration(
//             hintText: label.split('*')[0].trim(),
//             hintStyle: TextStyle(
//               fontSize: 11,
//               fontFamily: 'Mulish',
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade400,
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(4),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(4),
//               borderSide: BorderSide(color: Color(0xffE31E24)),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCustomerDetailsDisplay(PosController controller) {
//     return Obx(() => Container(
//       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Color(0xffFBF9FF),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Color(0xffE6E1EE)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   SvgPicture.asset('assets/images/user.svg',
//                       height: 14, width: 14),
//                   SizedBox(width: 5),
//                   Text(
//                     'Customer Details',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w800,
//                       fontFamily: 'Mulish',
//                     ),
//                   ),
//                 ],
//               ),
//               GestureDetector(
//                 onTap: controller.editCustomerDetails,
//                 child: Container(
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Image.asset(
//                     'assets/images/note.png',
//                     height: 20,
//                     width: 20,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Divider(color: Color(0xffE6E1EE), thickness: 1),
//           SizedBox(height: 8),
//           _buildDetailRow('Ihre Name',
//               controller.customerDetails['name'] ?? ''),
//           SizedBox(height: 4),
//           _buildDetailRow('Ihre Telefonnummer',
//               controller.customerDetails['phone'] ?? ''),
//           SizedBox(height: 4),
//           if (controller.customerDetails['email']?.isNotEmpty ?? false)
//             _buildDetailRow('Ihre E-Mail',
//                 controller.customerDetails['email'] ?? ''),
//           SizedBox(height: 4),
//           _buildDetailRow(
//               'Address', controller.customerDetails['address'] ?? ''),
//           SizedBox(height: 4),
//           _buildDetailRow(
//               'Region', controller.customerDetails['region'] ?? ''),
//         ],
//       ),
//     ));
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '$label: ',
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             fontFamily: 'Mulish',
//             color: Color(0xff797878),
//           ),
//         ),
//         Expanded(
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               fontFamily: 'Mulish',
//               color: Color(0xff0B1928),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTodaySection() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Color(0xffE6E1EE)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 18,
//                 height: 18,
//                 decoration: BoxDecoration(
//                   color: Color(0xffE31E24),
//                   borderRadius: BorderRadius.circular(3),
//                   border: Border.all(color: Color(0xffE31E24), width: 2),
//                 ),
//                 child: Icon(Icons.check, color: Colors.white, size: 12),
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Heute',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   fontFamily: 'Mulish',
//                   color: Color(0xff0B1928),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             decoration: BoxDecoration(
//               color: Color(0xffFBF9FF),
//               borderRadius: BorderRadius.circular(6),
//               border: Border.all(color: Color(0xffE6E1EE)),
//             ),
//             child: Text(
//               'sofort',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 fontFamily: 'Mulish',
//                 color: Color(0xff0B1928),
//               ),
//             ),
//           ),
//           SizedBox(height: 12),
//           Row(
//             children: [
//               Container(
//                 width: 18,
//                 height: 18,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(3),
//                   border: Border.all(color: Color(0xffB8ABD1), width: 2),
//                 ),
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Vorbestellen',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   fontFamily: 'Mulish',
//                   color: Color(0xff0B1928),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             decoration: BoxDecoration(
//               color: Color(0xffFBF9FF),
//               borderRadius: BorderRadius.circular(6),
//               border: Border.all(color: Color(0xffE6E1EE)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Select Date',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: 'Mulish',
//                     color: Color(0xff797878),
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Color(0xffE31E24),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child:
//                   Icon(Icons.calendar_today, color: Colors.white, size: 12),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 16),
//           Divider(color: Color(0xffE6E1EE), thickness: 1),
//           SizedBox(height: 12),
//           Text(
//             'Zahlungsmethode auswählen',
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               fontFamily: 'Mulish',
//               color: Color(0xff0B1928),
//             ),
//           ),
//           SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(color: Color(0xffE31E24), width: 2),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.credit_card,
//                           color: Color(0xffE31E24), size: 16),
//                       SizedBox(width: 3),
//                       Text(
//                         'Online-Zahlung',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           fontFamily: 'Mulish',
//                           color: Color(0xffE31E24),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(width: 10),
//               Expanded(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: Color(0xff232D3F),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.payments_outlined,
//                           color: Colors.white, size: 16),
//                       SizedBox(width: 6),
//                       Text(
//                         'Bar',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           fontFamily: 'Mulish',
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWeiterButton(PosController controller) {
//     return Obx(() => GestureDetector(
//       onTap: controller.onWeiterPressed,
//       child: Container(
//         padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
//         decoration: BoxDecoration(
//           color: Color(0xff0C831F),
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(5),
//             bottomRight: Radius.circular(5),
//           ),
//         ),
//         child: Center(
//           child: Text(
//             controller.customerDetails.isEmpty
//                 ? 'Weiter'
//                 : 'Place Order',
//             style: TextStyle(
//               fontFamily: 'Mulish',
//               fontWeight: FontWeight.w700,
//               fontSize: 14,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     ));
//   }
// }
//
// class _CategoryPositionMarker extends StatefulWidget {
//   final int categoryIndex;
//   final PosController controller;
//
//   const _CategoryPositionMarker({
//     required this.categoryIndex,
//     required this.controller,
//   });
//
//   @override
//   State<_CategoryPositionMarker> createState() => _CategoryPositionMarkerState();
// }
//
// class _CategoryPositionMarkerState extends State<_CategoryPositionMarker> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Calculate only once when dependencies change
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _calculatePosition();
//     });
//   }
//
//   void _calculatePosition() {
//     try {
//       final RenderBox? box = context.findRenderObject() as RenderBox?;
//       if (box != null &&
//           box.hasSize &&
//           widget.controller.landscapeProductScrollController.hasClients) {
//         final position = box.localToGlobal(Offset.zero);
//         final scrollOffset = widget.controller.landscapeProductScrollController.offset;
//         widget.controller.storeCategoryPosition(
//             widget.categoryIndex,
//             position.dy + scrollOffset
//         );
//       }
//     } catch (e) {
//       // Silently ignore errors
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox.shrink();
//   }
// }