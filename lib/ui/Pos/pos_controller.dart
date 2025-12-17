import 'package:food_app/models/get_discount_percentage_response_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../../Database/databse_helper.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/get_product_category_list_response_model.dart';
import '../../models/get_store_products_response_model.dart';

class PosController extends GetxController {
// Observable variables - Landscape Mode
  final selectedCategoryIndex = 0.obs;
  final selectedProductIndex = Rx<int?>(null);
  final orderNote = ''.obs;
  final selectedOrderType = 'Lieferzeit'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isCartExpanded = true.obs;
  final showCustomerDetails = false.obs;
  final isCustomerFormVisible = true.obs;
  final isRefreshing = false.obs;

// Cart management - Landscape
  final cartItems = <Map<String, dynamic>>[].obs;
  final customerDetails = <String, String>{}.obs;

// Portrait Mode Variables
  final isSearching = false.obs;
  final cart = <String, CartItem>{}.obs;
  final totalPrice = 0.0.obs;
  final totalItems = 0.obs;

// Lists
  final productCategoryList = <GetProductCategoryList>[].obs;
  final productList = <GetStoreProducts>[].obs;
  final filteredProducts = <GetStoreProducts>[].obs;
  final categories = <CategoryData>[].obs;
  final discountPercentage = 0.0.obs;
  final deliveryDiscount = 0.0.obs;
  final pickupDiscount = 0.0.obs;
  String? deliveryDiscountId;
  String? pickupDiscountId;
  List<GetDiscountPercentageResponseModel> currentDiscounts = [];

// Controllers
  final noteController = TextEditingController();
  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

// Scroll controllers - Portrait
  final mainScrollController = ScrollController();
  final sidebarScrollController = ScrollController();

  final visibleCategories = <int>[].obs;
  final lastScrollPosition = 0.0.obs;
  final ItemScrollController landscapeProductScrollController = ItemScrollController();
  final ItemPositionsListener landscapeProductPositionsListener = ItemPositionsListener.create();
  final landscapeCategoryScrollController = ScrollController();
  final isAutoScrolling = false.obs;

  final selectedProduct = Rx<GetStoreProducts?>(null);
  final selectedVariant = Rx<Variants?>(null);
  final selectedToppings = <String>[].obs;
  final showVariantDialog = false.obs;
  final expandedVariantId = Rx<int?>(null);
  final selectedToppingsMap = <int, List<int>>{}.obs;

  final nameFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final addressFocusNode = FocusNode();

// Other variables
  String? storeId;
  SharedPreferences? sharedPreferences;
  final isScrollingProgrammatically = false.obs;
  List<GlobalKey> categoryKeys = [];

  GlobalKey getCategoryKey(int index) {
    // grow the list with new GlobalKeys until index exists
    while (categoryKeys.length <= index) {
      categoryKeys.add(GlobalKey());
    }
    return categoryKeys[index];
  }

  final dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    _setOrientation();
    _initializeSharedPreferences();
    _setupScrollListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupLandscapeScrollListener();
    });
  }

  @override
  void onClose() {
    noteController.dispose();
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    mainScrollController.dispose();
    sidebarScrollController.dispose();
    landscapeCategoryScrollController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    addressFocusNode.dispose();
    super.onClose();
  }

  Future<void> getDiscountPercentage() async {
    if (storeId == null || storeId!.isEmpty) return;

    try {
      List<GetDiscountPercentageResponseModel> discounts =
      await CallService().getDiscountPercentage(storeId!);

      if (discounts.isNotEmpty) {
        currentDiscounts = discounts;

        for (var discount in discounts) {
          if (discount.code?.toLowerCase().contains('delivery') == true) {
            deliveryDiscount.value = (discount.value ?? 0).toDouble();
            deliveryDiscountId = discount.id?.toString();
            print('✅ Delivery discount: ${deliveryDiscount.value}%, ID: $deliveryDiscountId');
          } else if (discount.code?.toLowerCase().contains('pickup') == true) {
            pickupDiscount.value = (discount.value ?? 0).toDouble();
            pickupDiscountId = discount.id?.toString();
            print('✅ Pickup discount: ${pickupDiscount.value}%, ID: $pickupDiscountId');
          }
        }
      }
    } catch (e) {
      print('❌ Error getting discount percentage: $e');
    }
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _setupScrollListener() {
    mainScrollController.addListener(_onMainScroll);
  }

  void _onMainScroll() {
    if (isScrollingProgrammatically.value || isSearching.value) return;

    for (int i = 0; i < categoryKeys.length; i++) {
      final RenderBox? renderBox =
          categoryKeys[i].currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final height = renderBox.size.height;

        if (position.dy <= 150 && position.dy + height > 150) {
          if (selectedCategoryIndex.value != i) {
            selectedCategoryIndex.value = i;
            _scrollSidebarToCategory(i);
            break;
          }
        }
      }
    }
  }

  void _scrollSidebarToCategory(int index) {
    double itemHeight = 80.0;
    double targetPosition = index * itemHeight;

    sidebarScrollController.animateTo(
      targetPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void scrollToCategory(int index) {
    isScrollingProgrammatically.value = true;
    selectedCategoryIndex.value = index;

    final RenderBox? renderBox =
        categoryKeys[index].currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final currentScroll = mainScrollController.position.pixels;

      mainScrollController.animateTo(
        currentScroll + position.dy + 160,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        isScrollingProgrammatically.value = false;
      });
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getProductCategory();
      await getDiscountPercentage();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      isLoading.value = false;
    }
  }


  void filterProducts(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      // Reset to show all products
      filteredProducts.clear();
    } else {
      // Filter products by name or ID
      filteredProducts.value = productList.where((product) {
        final searchLower = query.toLowerCase();
        final nameLower = (product.name ?? '').toLowerCase();
        final idMatch = product.id.toString().contains(query);

        return (nameLower.contains(searchLower) || idMatch) &&
            (product.isActive ?? false);
      }).toList();
    }
  }


  void onSearchChanged(String value) {
    searchQuery.value = value;
    isSearching.value = value.isNotEmpty;
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }


  void addToCart(GetStoreProducts product) {
    int existingIndex =
        cartItems.indexWhere((item) => item['name'] == product.name);

    if (existingIndex != -1) {
      cartItems[existingIndex]['quantity']++;
    } else {
      cartItems.add({
        'name': product.name ?? '',
        'extras': '',
        'size': '',
        'quantity': 1,
        'price': double.tryParse(product.price?.toString() ?? '0') ?? 0.0,
      });
    }
    cartItems.refresh();
  }

  void addToCartWithVariant() {
    if (selectedProduct.value == null || selectedVariant.value == null) return;

    double basePrice = double.tryParse(selectedProduct.value!.price?.toString() ?? '0') ?? 0.0;
    double variantPrice = (selectedVariant.value!.price ?? 0).toDouble();

    double toppingPrice = 0.0;
    List<String> toppingDetails = [];
    List<Map<String, dynamic>> toppingDataList = [];  // ✅ Add this line

    print('🔍 Checking toppings for variant ${selectedVariant.value!.id}');
    print('🔍 Selected topping IDs: ${selectedToppingsMap[selectedVariant.value!.id]}');

    if (selectedToppingsMap.containsKey(selectedVariant.value!.id)) {
      var selectedToppingIds = selectedToppingsMap[selectedVariant.value!.id]!;

      print('🔍 Found ${selectedToppingIds.length} selected toppings');
      List<Map<String, dynamic>> toppingDataList = [];  // ✅ Store full topping data

      selectedVariant.value!.enrichedToppingGroups?.forEach((group) {
        group.toppings?.forEach((topping) {
          if (selectedToppingIds.contains(topping.id)) {
            toppingPrice += topping.price ?? 0.0;
            toppingDetails.add('${topping.name} [€${(topping.price ?? 0.0).toStringAsFixed(2)}]');

            // ✅ Store actual topping ID (not composite key)
            toppingDataList.add({
              'topping_id': topping.id,  // ✅ This should be the actual topping ID from API
              'name': topping.name,
              'price': topping.price ?? 0.0,
              'quantity': 1,
            });

            print('✅ Added topping: ${topping.name} with ID: ${topping.id}');  // Debug log
          }
        });
      });
    }

    print('✅ Total toppings added: ${toppingDetails.length}');

    double totalPrice = basePrice + variantPrice + toppingPrice;
    String variantName = selectedVariant.value!.name ?? '';
    String itemKey = '${selectedProduct.value!.name}_${variantName}_${toppingDetails.join(',')}';

    int existingIndex = cartItems.indexWhere((item) => item['key'] == itemKey);

    if (existingIndex != -1) {
      cartItems[existingIndex]['quantity']++;
    } else {
      cartItems.add({
        'key': itemKey,
        'name': selectedProduct.value!.name ?? '',
        'extras': toppingDetails.join('\n'),
        'size': variantName,
        'quantity': 1,
        'price': totalPrice,
        'variant_id': selectedVariant.value!.id,
        'product_id': selectedProduct.value!.id,
        'topping_details': toppingDetails,
        'topping_data': toppingDataList,  // ✅ Add this line
        'item_note': '',
      });
    }

    print('✅ Cart item added with ${toppingDetails.length} toppings');

    cartItems.refresh();
    showVariantDialog.value = false;
    selectedProduct.value = null;
    selectedVariant.value = null;
    selectedToppingsMap.clear();
    expandedVariantId.value = null;
  }

  // Remove cart item
  void removeCartItem(int index) {
    cartItems.removeAt(index);
    cartItems.refresh();
  }

// Show item note dialog
  void showItemNoteDialog(BuildContext context, int itemIndex) {
    TextEditingController itemNoteController = TextEditingController();
    itemNoteController.text = cartItems[itemIndex]['item_note'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Note',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xff0B1928),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: itemNoteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter note for this item...',
                      hintStyle: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xffE31E24)),
                      ),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          cartItems[itemIndex]['item_note'] = itemNoteController.text;
                          cartItems.refresh();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Item note added successfully',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Color(0xff00B10E),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffE31E24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Save Note',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void setupLandscapeScrollListener() {
    landscapeProductPositionsListener.itemPositions.addListener(() {
      if (isAutoScrolling.value) return;

      final positions = landscapeProductPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      // Get the first visible item
      final firstVisible = positions
          .where((position) => position.itemLeadingEdge >= -0.3)
          .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);

      int visibleIndex = firstVisible.index;

      // Map visible index to category index
      if (visibleIndex < visibleCategories.length) {
        int categoryIndex = visibleCategories[visibleIndex];

        if (categoryIndex != selectedCategoryIndex.value) {
          selectedCategoryIndex.value = categoryIndex;
          scrollCategoryToIndex(categoryIndex);
        }
      }
    });
  }

  void selectCategory(int index) async {
    if (isAutoScrolling.value) return;
    if (index >= productCategoryList.length) return;

    selectedCategoryIndex.value = index;
    isAutoScrolling.value = true;

    print('🎯 Selecting category $index');

    // Ensure category is visible
    if (!visibleCategories.contains(index)) {
      // Load all categories up to this index plus buffer
      for (int i = 0; i <= (index + 5).clamp(0, productCategoryList.length - 1); i++) {
        if (!visibleCategories.contains(i)) {
          visibleCategories.add(i);
        }
      }
      visibleCategories.sort();
      visibleCategories.refresh();

      await Future.delayed(Duration(milliseconds: 300));
    }

    // Find the position in visible categories list
    int visibleIndex = visibleCategories.indexOf(index);

    if (visibleIndex != -1) {
      try {
        await landscapeProductScrollController.scrollTo(
          index: visibleIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.05, // Small offset from top
        );

        await Future.delayed(Duration(milliseconds: 300));
      } catch (e) {
        print('Scroll error: $e');
      }
    }

    isAutoScrolling.value = false;
  }

  void scrollCategoryToIndex(int index) {
    if (!landscapeCategoryScrollController.hasClients) return;

    double targetPosition = index * 85.0;
    double maxScroll =
        landscapeCategoryScrollController.position.maxScrollExtent;

    if (targetPosition > maxScroll) {
      targetPosition = maxScroll;
    }

    landscapeCategoryScrollController.animateTo(
      targetPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void initializeVisibleCategories() {
    visibleCategories.clear();
    lastScrollPosition.value = 0.0;

    // Load all categories at once for ScrollablePositionedList
    // This is efficient because it only renders visible items
    for (int i = 0; i < productCategoryList.length; i++) {
      visibleCategories.add(i);
    }

    visibleCategories.refresh();

    print('📦 Initialized with all ${visibleCategories.length} categories');
  }

  void addToCartPortrait(Product product) {
    if (cart.containsKey(product.name)) {
      cart[product.name]!.quantity++;
    } else {
      cart[product.name] = CartItem(product: product, quantity: 1);
    }
    calculateTotal();
  }

  void removeFromCartPortrait(Product product) {
    if (cart.containsKey(product.name)) {
      if (cart[product.name]!.quantity > 1) {
        cart[product.name]!.quantity--;
      } else {
        cart.remove(product.name);
      }
      calculateTotal();
    }
  }

  void showProductVariantDialog(GetStoreProducts product) async {
    selectedProduct.value = product;
    selectedVariant.value = null;
    selectedToppings.clear();
    expandedVariantId.value = null;
    selectedToppingsMap.clear();
    // Load variants from database if not already loaded
    if (product.variants == null || product.variants!.isEmpty) {
      product.variants = await dbHelper.getProductVariants(product.id.toString());

      // Load topping groups for each variant
      for (var variant in product.variants!) {
        if (variant.id != null) {
          variant.enrichedToppingGroups = await dbHelper.getVariantToppingGroups(variant.id.toString());
          print('🍕 Loaded ${variant.enrichedToppingGroups?.length ?? 0} topping groups for variant ${variant.id}');
        }
      }
    }

    // Only show dialog if product has variants
    if (product.variants != null && product.variants!.isNotEmpty) {
      showVariantDialog.value = true;
    } else {
      // No variants, add directly to cart
      addToCart(product);
    }
  }

  void selectVariant(Variants variant) {
    selectedVariant.value = variant;
    // Automatically expand if variant has toppings
    if (variant.enrichedToppingGroups != null && variant.enrichedToppingGroups!.isNotEmpty) {
      expandedVariantId.value = variant.id;
    }
  }

  void toggleTopping(String topping) {
    if (selectedToppings.contains(topping)) {
      selectedToppings.remove(topping);
    } else {
      selectedToppings.add(topping);
    }
  }

  void toggleVariantExpansion(int variantId) {
    if (expandedVariantId.value == variantId) {
      expandedVariantId.value = null;
    } else {
      expandedVariantId.value = variantId;
    }
  }

  void toggleVariantTopping(int variantId, int toppingId) {
    if (variantId == null || toppingId == null) {
      print('⚠️ Null ID detected: variantId=$variantId, toppingId=$toppingId');
      return;
    }

    if (!selectedToppingsMap.containsKey(variantId)) {
      selectedToppingsMap[variantId] = [];
    }

    if (selectedToppingsMap[variantId]!.contains(toppingId)) {
      selectedToppingsMap[variantId]!.remove(toppingId);
    } else {
      selectedToppingsMap[variantId]!.add(toppingId);
    }
    selectedToppingsMap.refresh();
  }
  // Landscape Mode - Increment Quantity
  void incrementQuantity(int index) {
    cartItems[index]['quantity']++;
    cartItems.refresh();
  }

  // Landscape Mode - Decrement Quantity
  void decrementQuantity(int index) {
    if (cartItems[index]['quantity'] > 1) {
      cartItems[index]['quantity']--;
      cartItems.refresh();
    } else {
      cartItems.removeAt(index);
      cartItems.refresh();
    }
  }

  // Landscape Mode - Calculations
  double calculateSubtotal() {
    double subtotal = 0;
    for (var item in cartItems) {
      subtotal += item['price'] * item['quantity'];
    }
    return subtotal;
  }

  double calculateDiscount() {
    double subtotal = calculateSubtotal();
    double discountPercent = 0.0;

    // Apply discount based on selected order type
    if (selectedOrderType.value == 'Lieferzeit') {
      discountPercent = deliveryDiscount.value;
    } else if (selectedOrderType.value == 'Abholzeit') {
      discountPercent = pickupDiscount.value;
    }

    return subtotal * (discountPercent / 100);
  }

  double calculateGrandTotal() {
    return calculateSubtotal() - calculateDiscount();
  }

  // Portrait Mode - Calculate Total
  void calculateTotal() {
    totalPrice.value = 0.0;
    totalItems.value = 0;
    cart.forEach((key, cartItem) {
      totalPrice.value += cartItem.product.price * cartItem.quantity;
      totalItems.value += cartItem.quantity;
    });
  }

  int getProductQuantity(Product product) {
    return cart[product.name]?.quantity ?? 0;
  }

  bool isProductSelected(Product product) {
    return cart.containsKey(product.name);
  }

  // Portrait Mode - Get Filtered Categories
  List<CategoryData> getFilteredCategories() {
    if (searchQuery.value.isEmpty) {
      return categories;
    }

    List<CategoryData> filtered = [];
    for (var category in categories) {
      List<Product> filteredProducts = category.products
          .where((product) => product.name
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();

      if (filteredProducts.isNotEmpty) {
        filtered.add(CategoryData(
          name: category.name,
          image: category.image,
          products: filteredProducts,
          id: category.id,
          imageUrl: category.imageUrl,
        ));
      }
    }
    return filtered;
  }

  // Set Order Type
  void setOrderType(String type) {
    selectedOrderType.value = type;
  }

  // Save Note
  void saveNote(String note) {
    orderNote.value = note;
    Get.back();
    Get.snackbar(
      '',
      'Note added successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xff00B10E),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      messageText: Text(
        'Note added successfully',
        style: TextStyle(
          fontFamily: 'Mulish',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      titleText: SizedBox.shrink(),
    );
  }

  // Place Order - Landscape
  Future<void> placeOrder() async {
    if (cartItems.isEmpty) {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(
              'Please add items to cart',
              style: TextStyle(
                fontFamily: 'Mulish',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xffE31E24),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      List<Map<String, dynamic>> orderItems = cartItems.map((item) {
        var product = productList.firstWhere(
              (p) => p.name == item['name'],
          orElse: () => GetStoreProducts(id: 0),
        );

        List<Map<String, dynamic>>? toppings;
        if (item['topping_data'] != null && item['topping_data'] is List) {
          toppings = List<Map<String, dynamic>>.from(item['topping_data']);
        }

        return {
          'product_id': product.id ?? 0,
          'quantity': item['quantity'],
          'price': item['price'],
          'variant_id': item['variant_id'],
          'note': item['item_note'] ?? '',
          'toppings': toppings,
        };
      }).toList();

      // ✅ Get discount ID based on order type
      String? discountId;
      if (selectedOrderType.value == 'Lieferzeit') {
        discountId = deliveryDiscountId;
      } else if (selectedOrderType.value == 'Abholzeit') {
        discountId = pickupDiscountId;
      }

      int orderId = await dbHelper.saveOrder(
        storeId: storeId!,
        orderType: selectedOrderType.value == 'Lieferzeit' ? '1' : '2',
        note: orderNote.value.isEmpty ? null : orderNote.value,
        customerName: customerDetails['name'] ?? '',
        phone: customerDetails['phone'] ?? '',
        email: customerDetails['email'] ?? '',
        address: customerDetails['address'] ?? '', // ✅ Single address field
        region: '', // ✅ Empty string (not used anymore)
        items: orderItems,
        amount: calculateGrandTotal(),
        discountId: discountId,
      );

      print('✅ Order placed with ID: $orderId (POS order_type=3)');

      // Clear cart
      cartItems.clear();
      orderNote.value = '';
      noteController.clear();
      showCustomerDetails.value = false;
      isCartExpanded.value = true;
      customerDetails.clear();
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      addressController.clear();
      // regionController.clear(); // ✅ REMOVE THIS LINE

      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully! Order ID: #$orderId',
              style: TextStyle(
                fontFamily: 'Mulish',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xff00B10E),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error placing order: $e');

      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to place order. Please try again.',
              style: TextStyle(
                fontFamily: 'Mulish',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xffE31E24),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void onWeiterPressed() {
    if (!showCustomerDetails.value) {
      isCartExpanded.value = false;
      showCustomerDetails.value = true;
      isCustomerFormVisible.value = true;
    } else if (isCustomerFormVisible.value) {
      customerDetails.value = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(), // ✅ Single address
        // 'region': regionController.text.trim(), // ✅ REMOVE THIS LINE
      };
      isCustomerFormVisible.value = false;
    } else {
      placeOrder();
      showCustomerDetails.value = false;
      isCartExpanded.value = true;
      customerDetails.clear();
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      addressController.clear();
      // regionController.clear(); // ✅ REMOVE THIS LINE
    }
  }

  void onAddCustomerPressed() {
    isCartExpanded.value = false;
    showCustomerDetails.value = true;
    isCustomerFormVisible.value = true;
  }

  // Toggle Customer Details
  void toggleCustomerDetails() {
    showCustomerDetails.value = false;
    isCartExpanded.value = true;
  }

  // Edit Customer Details
  void editCustomerDetails() {
    isCustomerFormVisible.value = true;
    nameController.text = customerDetails['name'] ?? '';
    phoneController.text = customerDetails['phone'] ?? '';
    addressController.text = customerDetails['address'] ?? '';
    emailController.text = customerDetails['email'] ?? '';

  }

  // API Calls
  Future<void> getProductCategory(
      {bool showLoader = true, bool forceRefresh = false}) async
  {
    if (sharedPreferences == null) {
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      isLoading.value = false;
      return;
    }

    if (!forceRefresh) {
      bool hasData = await dbHelper.hasStoredData(storeId!);
      if (hasData) {
        await _loadFromDatabase();
        return;
      }
    }

    if (showLoader) {
      isLoading.value = true;
      isRefreshing.value = true;
      Get.dialog(
        Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
        barrierDismissible: false,
      );
    }

    try {
      print('🌐 Fetching data from API...');
      List<GetProductCategoryList> categoryList = await CallService().getProductCategory(storeId!);

      List<GetStoreProducts> products = await CallService().getProducts(storeId!);

      await dbHelper.saveCategories(categoryList, storeId!);
      await dbHelper.saveProducts(products, storeId!);

      productCategoryList.value = categoryList;
      productList.value = products;

      if (categoryList.isNotEmpty) {
        var firstCategory = categoryList[0];
        filteredProducts.value = products
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      categories.value = categoryList
          .map((apiCategory) {
        return CategoryData.fromGetProductCategory(apiCategory, products);
      })
          .where((cat) => cat.products.isNotEmpty)
          .toList();

      categoryKeys = List.generate(categories.length, (index) => GlobalKey());

      if (productCategoryList.isNotEmpty && categories.isNotEmpty) {
        var firstCategory = productCategoryList[0];
        filteredProducts.value = productList
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      print('✅ Categories loaded and saved: ${categories.length}');

      // Initialize visible categories - load all for ScrollablePositionedList
      initializeVisibleCategories();

      // Small delay to ensure UI is ready
      await Future.delayed(Duration(milliseconds: 300));

      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }

      isLoading.value = false;
      isRefreshing.value = false;

    } catch (e) {
      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }
      print('❌ Error getting Product Category: $e');
      isLoading.value = false;
      isRefreshing.value = false;

      print('📦 Attempting to load from database as fallback...');
      await _loadFromDatabase();
    }
  }

  Future<void> _loadFromDatabase() async {
    try {
      print('📦 Loading from database...');

      List<GetProductCategoryList> categoryList =
      await dbHelper.getCategories(storeId!);
      List<GetStoreProducts> products = await dbHelper.getProducts(storeId!);

      if (categoryList.isEmpty || products.isEmpty) {
        print('⚠️ No data found in database');
        isLoading.value = false;
        return;
      }

      productCategoryList.value = categoryList;
      productList.value = products;

      if (categoryList.isNotEmpty) {
        var firstCategory = categoryList[0];
        filteredProducts.value = products
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      categories.value = categoryList
          .map((apiCategory) {
        return CategoryData.fromGetProductCategory(apiCategory, products);
      })
          .where((cat) => cat.products.isNotEmpty)
          .toList();

      categoryKeys = List.generate(categories.length, (index) => GlobalKey());

      if (categoryList.isNotEmpty && categories.isNotEmpty) {
        var firstCategory = categoryList[0];
        filteredProducts.value = products
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      print('✅ Loaded ${categories.length} categories from database');

      // Initialize visible categories
      initializeVisibleCategories();

      // Small delay to ensure UI is ready
      await Future.delayed(Duration(milliseconds: 300));

      isLoading.value = false;

    } catch (e) {
      print('❌ Error loading from database: $e');
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    print('🔄 Manual refresh triggered');

    // Reset visible categories
    visibleCategories.clear();

    await getProductCategory(showLoader: true, forceRefresh: true);

    if (!isLoading.value && categories.isNotEmpty) {
      Get.showSnackbar(
        GetSnackBar(
          message: 'Data refreshed successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xff00B10E),
          messageText: Text(
            'Data refreshed successfully',
            style: TextStyle(
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(10),
          borderRadius: 8,
        ),
      );
    }
  }

  String getTrimmedImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    int queryIndex = url.indexOf('?');
    if (queryIndex != -1) {
      return url.substring(0, queryIndex);
    }
    return url;
  }

  void showAddNoteDialog(BuildContext context) {
    noteController.text = orderNote.value; // Add .value
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Note',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xff0B1928),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: noteController, // Changed from _noteController
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your note here...',
                      hintStyle: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xffE31E24)),
                      ),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          orderNote.value =
                              noteController.text; // Changed from setState
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Note added successfully',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Color(0xff00B10E),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffE31E24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Add Note',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                  width: 350,
                  padding: EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      Icons.power_settings_new,
                      color: Color(0xffE31E24),
                      size: 50,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xff0B1928),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Are you sure you want to logout?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff797878),
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Logged out successfully',
                                      style: TextStyle(
                                        fontFamily: 'Mulish',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: Color(0xff00B10E),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffE31E24),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ])
                  ])));
        });
  }
}

// Models
class CategoryData {
  final String name;
  final Image? image;
  final List<Product> products;
  final String? id;
  final String? imageUrl;

  CategoryData({
    required this.name,
    this.image,
    required this.products,
    this.id,
    this.imageUrl,
  });

  factory CategoryData.fromGetProductCategory(
      GetProductCategoryList apiCategory,
      List<GetStoreProducts> allProducts,
      ) {
    List<Product> categoryProducts = allProducts
        .where((p) => p.categoryId == apiCategory.id && (p.isActive ?? false))
        .map((p) => Product.fromGetStoreProducts(p))
        .toList();

    return CategoryData(
      name: apiCategory.name ?? '',
      products: categoryProducts,
      id: apiCategory.id.toString(),
      imageUrl: apiCategory.imageUrl,
    );
  }
}

class Product {
  final String name;
  final double price;
  final bool isSpicy;
  final bool isVeg;
  final String? id;
  final String? categoryId;
  final String? imageUrl;
  final String? description;

  Product(
      this.name,
      this.price, {
        this.isSpicy = false,
        this.isVeg = false,
        this.id,
        this.categoryId,
        this.imageUrl,
        this.description,
      });

  factory Product.fromGetStoreProducts(GetStoreProducts apiProduct) {
    return Product(
      apiProduct.name ?? '',
      double.tryParse(apiProduct.price?.toString() ?? '0') ?? 0.0,
      id: apiProduct.id.toString(),
      categoryId: apiProduct.categoryId.toString(),
      imageUrl: apiProduct.imageUrl,
      description: apiProduct.description,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}
