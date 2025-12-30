import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../customView/CustomAppBar.dart';
import '../../../customView/CustomDrawer.dart';
import '../../../models/add_new_product_response_model.dart';
import '../../../models/edit_store_product_response_model.dart';
import '../../../models/get_added_tax_response_model.dart';
import '../../../models/get_product_category_list_response_model.dart';
import '../../../models/get_store_products_response_model.dart';
import '../../../models/iamge_upload_response_model.dart';
import '../../../utils/my_application.dart';
import '../../home_screen.dart';


class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<GetStoreProducts> productList = [];
  List<getAddedtaxResponseModel> storeTaxesList = [];
  List<GetProductCategoryList> productCategoryList = [];

  int currentPage = 1;
  int itemsPerPage = 8;
  int totalPages = 0;
  List<GetStoreProducts> currentPageItems = [];

  List<GetStoreProducts> filteredProductList = [];
  String currentSearchQuery = '';

  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> variants = [];

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

  void _updatePagination() {
    totalPages = (filteredProductList.length / itemsPerPage).ceil(); // ✅ CHANGED
    if (totalPages == 0) totalPages = 1;

    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredProductList.length) endIndex = filteredProductList.length; // ✅ CHANGED

    currentPageItems = filteredProductList.sublist(startIndex, endIndex); // ✅ CHANGED
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

  // Edit function
  void _editProduct(int index) {
    GetStoreProducts product = currentPageItems[index];
    _showEditProductBottomSheet(product);
  }

  void _deleteProduct(int index) {
    GetStoreProducts product = currentPageItems[index];
    showDeleteProduct(context, product.name ?? 'this product', product.id!);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      selectedImage = null;
    });
  }

  Future<void> _pickImageModal(StateSetter setModalState) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_image'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mulish',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Option
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 500,
                        maxHeight: 500,
                        imageQuality: 80,
                      );

                      if (image != null) {
                        setModalState(() {
                          selectedImage = File(image.path);
                        });
                        setState(() {});
                      }
                    } catch (e) {
                      print('Error picking image from camera: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('failed_capture'.tr),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCAE03),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'camera'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ),
                // Gallery Option
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 500,
                        maxHeight: 500,
                        imageQuality: 80,
                      );

                      if (image != null) {
                        setModalState(() {
                          selectedImage = File(image.path);
                        });
                        setState(() {});
                      }
                    } catch (e) {
                      print('Error picking image from gallery: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to pick image'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCAE03),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'gallery'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Cancel Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTrimmedImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Remove query parameters (everything after '?')
    int queryIndex = url.indexOf('?');
    if (queryIndex != -1) {
      return url.substring(0, queryIndex);
    }
    return url;
  }


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    getProduct();
    getStoreTaxes();
    getProductCategory();

    app.appController.registerProductsFilter(_filterProducts);
  }

  void _filterProducts(String query) {
    setState(() {
      currentSearchQuery = query.toLowerCase();
      if (currentSearchQuery.isEmpty) {
        filteredProductList = productList;
      } else {
        filteredProductList = productList.where((product) {
          final name = product.name?.toLowerCase() ?? '';
          final code = product.itemCode?.toLowerCase() ?? '';
          final category = product.category?.name?.toLowerCase() ?? '';

          return name.contains(currentSearchQuery) ||
              code.contains(currentSearchQuery) ||
              category.contains(currentSearchQuery);
        }).toList();
      }
      currentPage = 1;
      _updatePagination();
    });

    print("🔍 Products filtered: ${filteredProductList.length} results");
  }

  @override
  void dispose() {
    // ✅ Clear callback
    app.appController.productsFilterCallback = null;
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getProduct();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
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
                        Text('product'.tr,
                            style: const TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            _showAddProductBottomSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: const Color(0xFFFCAE03),
                            ),
                            child: Center(
                              child: Text('add'.tr,
                                  style: const TextStyle(
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
                  const SizedBox(height: 15),

                  // Showing entries info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${'showing'.tr} ${(currentPage - 1) * itemsPerPage + 1} to ${(currentPage - 1) * itemsPerPage + currentPageItems.length}'
                            ' of ${filteredProductList.length} ${'entries'.tr}', // ✅ CHANGED from productList.length
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Mulish',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
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
                          width: 50,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.35,
                          child: Text('product_name'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Mulish'),
                          ),
                        ),
                        Container(
                          child: Text('category'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish')),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Center(
                            child: Text('price'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish'),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (filteredProductList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentSearchQuery.isEmpty
                                ? 'no_product'.tr
                                : '${'no_match'.tr} "$currentSearchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Mulish',
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (currentSearchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'try'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Mulish',
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                  SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        print('Image Url Is ${currentPageItems[index].imageUrl.toString()}');
                        return Slidable(
                          key: ValueKey(index),
                          endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.502,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _showProductStatusChangeDialog(
                                        context,
                                        currentPageItems[index].name ?? 'Product',
                                        currentPageItems[index].id ?? 0,
                                        currentPageItems[index].isActive ?? false);
                                  },
                                  child: Container(
                                    width: 60,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      // ✅ Active → Green, Inactive → Grey
                                      color: (currentPageItems[index].isActive ?? false)
                                          ? Colors.green           // Active product
                                          : Colors.grey.shade600,  // Inactive product
                                    ),
                                    child: Icon(
                                      // ✅ Active → Active icon, Inactive → Inactive icon
                                      (currentPageItems[index].isActive ?? false)
                                          ? Icons.airplanemode_active      // Active icon
                                          : Icons.airplanemode_inactive,   // Inactive icon
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                onTap: () => _editProduct(index),
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
                                onTap: () => _deleteProduct(index),
                                child: Container(
                                  width: 60,
                                  height: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffE25454),
                                  ),
                                  child: const Icon(
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
                                const SizedBox(width: 5),
                                Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade300, width: 1),
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _getTrimmedImageUrl(currentPageItems[index].imageUrl),
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            errorWidget: (context, url, error) => const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3,),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(currentPageItems[index].name ?? 'N/A',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  fontFamily: 'Mulish'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(currentPageItems[index].itemCode ?? 'N/A',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 10,
                                                  fontFamily: 'Mulish'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.3,
                                        child: Text(currentPageItems[index].category?.name ?? 'N/A',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              fontFamily: 'Mulish'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  child: Center(
                                    child: Text('€${currentPageItems[index].price?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
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

          if (filteredProductList.isNotEmpty && totalPages > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    GestureDetector(
                      onTap: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentPage > 1 ? Colors.white : Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'previous'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage > 1 ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Page Numbers
                    ...(_getPageNumbers().map((pageNum) {
                      bool isActive = pageNum == currentPage;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _goToPage(pageNum),
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF0EA5E9) : Colors.white,
                              border: Border.all(
                                color: isActive ? const Color(0xFF0EA5E9) : Colors.grey.shade300,
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
                                  color: isActive ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList()),

                    const SizedBox(width: 8),

                    // Next Button
                    GestureDetector(
                      onTap: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentPage < totalPages ? Colors.white : Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'next'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage < totalPages ? Colors.black87 : Colors.grey,
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

  Future<void> getProduct({bool showLoader = true}) async {
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
      List<GetStoreProducts> product = await CallService().getProducts(storeId!);
      print('product list length is ${product.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          productList = product;
          filteredProductList = product;

          for (var p in product) {
            print('Product: ${p.name}, isActive: ${p.isActive}');
          }


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

  void _showAddProductBottomSheet() {

    selectedImage = null;
    getStoreTaxes();
    getProductCategory();
    // Controllers
    TextEditingController nameController = TextEditingController();
    TextEditingController codeController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController discountPriceController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String? selectedCategory;
    String? selectedTax;
    String? selectedProductType = 'simple'.tr;
    String? selectedCategoryId;
    String? selectedTaxId;

    bool isLoadingData = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {

          if (isLoadingData) {
            Future.wait([
              getStoreTaxes(),
              getProductCategory(),
            ]).then((_) {
              setModalState(() {
                isLoadingData = false;
              });
            }).catchError((error) {
              print('Error loading data: $error');
              setModalState(() {
                isLoadingData = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header with Title and Image Button
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Centered Title
                        Center(
                          child: Text(
                            'add_new_product'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                        // Image Button in Top Right
                        Positioned(
                          right: 0,
                          top: -5,
                          child: GestureDetector(
                            onTap: () {
                              _pickImageModal(setModalState);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedImage != null
                                    ? Colors.transparent
                                    : const Color(0xFFFCAE03),
                                border: selectedImage != null
                                    ? Border.all(color: Colors.grey.shade300, width: 2)
                                    : null,
                              ),
                              child: selectedImage != null
                                  ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22.5),
                                    child: Image.file(
                                      selectedImage!,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Close Icon
                                  Positioned(
                                    top: 0,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedImage = null;
                                        });
                                        setState(() {});
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: isLoadingData
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/burger.json',
                            width: 150,
                            height: 150,
                            repeat: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'loading'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Mulish',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                        : SingleChildScrollView(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            'product_name'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'enter_product'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Product Code
                          Text(
                            'product_code'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: codeController,
                            decoration: InputDecoration(
                              hintText: 'enter_code'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tax Dropdown
                          Text(
                            'taxe'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedTaxId,
                              hint: Text('select'.tr),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                              items: storeTaxesList.map((tax) {
                                return DropdownMenuItem<String>(
                                  value: tax.id.toString(),
                                  child: Text('${tax.name} (${tax.percentage}%)'),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  selectedTaxId = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category Dropdown
                          Text(
                            'category'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategoryId,
                              hint: Text('select_category'.tr),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                              items: productCategoryList.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id.toString(),
                                  child: Text(category.name ?? 'N/A'),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  selectedCategoryId = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Product Type
                          Text(
                            'product_type'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedProductType,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                              items: ['simple'.tr, 'variable'.tr].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  selectedProductType = newValue;
                                  if (newValue == 'simple'.tr) {
                                    for (var variant in variants) {
                                      variant['name'].dispose();
                                      variant['price'].dispose();
                                      variant['description'].dispose();
                                    }
                                    variants.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Simple Product Fields
                          if (selectedProductType == 'simple'.tr) ...[
                            Text(
                              '${'price'.tr} *',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'enter_price'.tr,
                                prefixText: '€ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'dis_price'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: discountPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'opt'.tr,
                                prefixText: '€ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Variable Product Fields
                          if (selectedProductType == 'variable'.tr) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'variant'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                                if (variants.isEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setModalState(() {
                                        variants.add({
                                          'name': TextEditingController(),
                                          'price': TextEditingController(),
                                          'description': TextEditingController(),
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text('add_variant'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff0C831F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(variants.length, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: variants[index]['name'],
                                      decoration: InputDecoration(
                                        hintText: 'Variant Name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: variants[index]['price'],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        hintText: 'price'.tr,
                                        prefixText: '€ ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: variants[index]['description'],
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'desc'.tr,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setModalState(() {
                                            variants[index]['name'].dispose();
                                            variants[index]['price'].dispose();
                                            variants[index]['description'].dispose();
                                            variants.removeAt(index);
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xffE25454),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'remove'.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Mulish',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (variants.isNotEmpty)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      variants.add({
                                        'name': TextEditingController(),
                                        'price': TextEditingController(),
                                        'description': TextEditingController(),
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text('add_variant'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff0C831F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],

                          // Description
                          Text(
                            '${'desc'.tr} *',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'enter_desc'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'cancel'.tr,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Mulish',
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    // Validation
                                    if (nameController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter product name'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (codeController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter product code'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (selectedTaxId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select tax'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (selectedCategoryId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select category'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (descriptionController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter description'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    if (selectedProductType == 'simple'.tr) {
                                      if (priceController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter price'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                    } else if (selectedProductType == 'variable'.tr) {
                                      if (variants.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please add at least one variant'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                      for (var variant in variants) {
                                        if (variant['name'].text.isEmpty ||
                                            variant['price'].text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please fill all variant fields'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }
                                      }
                                    }

                                    // Prepare variants for variable products
                                    List<Map<String, dynamic>>? productVariants;
                                    if (selectedProductType == 'Variable') {
                                      productVariants = variants
                                          .map((v) => {
                                        "name": v['name'].text,
                                        "price": double.parse(v['price'].text).toInt(),
                                        "item_code":
                                        "${codeController.text}-${v['name'].text.replaceAll(' ', '').toUpperCase()}",
                                        "image_url": "",
                                        "description": v['description'].text,
                                      })
                                          .toList();
                                    }

                                    String? uploadedImageUrl;
                                    if (selectedImage != null) {
                                      uploadedImageUrl = await uploadProductImage(selectedImage!);
                                      if (uploadedImageUrl == null) {
                                        return;
                                      }
                                    }

                                    bool success = await addProduct(
                                      name: nameController.text,
                                      itemCode: codeController.text,
                                      categoryId: selectedCategoryId!,
                                      taxId: selectedTaxId!,
                                      productType: selectedProductType!,
                                      description: descriptionController.text,
                                      price: selectedProductType == 'simple'.tr ? priceController.text : null,
                                      discount: selectedProductType == 'simple'.tr
                                          ? discountPriceController.text
                                          : null,
                                      productVariants: productVariants,
                                      imageUrl: uploadedImageUrl,
                                    );

                                    if (success && mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: const Color(0xFFFCAE03),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'add_produc'.tr,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Mulish',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditProductBottomSheet(GetStoreProducts product) {
    selectedImage = null;
    TextEditingController nameController = TextEditingController(text: product.name);
    TextEditingController codeController = TextEditingController(text: product.itemCode);
    TextEditingController priceController = TextEditingController(
        text: product.price != null ? product.price.toString() : '');
    TextEditingController discountPriceController = TextEditingController(
        text: product.discountPrice != null && product.discountPrice! > 0
            ? product.discountPrice.toString()
            : '');
        TextEditingController descriptionController = TextEditingController(text: product.description);

    String? selectedProductType = product.type != null
        ? (product.type!.toLowerCase() == 'simple' ? 'simple'.tr : 'variable'.tr)
        : 'simple'.tr;
    String? selectedCategoryId = product.categoryId?.toString();
    String? selectedTaxId = product.taxId?.toString();

    // Pre-fill variants if Variable type
    variants.clear();
    if (product.type?.toLowerCase() == 'variable' && product.variants != null) {
      for (var variant in product.variants!) {
        variants.add({
          'id': variant.id,
          'name': TextEditingController(text: variant.name),
          'price': TextEditingController(text: variant.price?.toString() ?? ''),
          'description': TextEditingController(text: variant.description),
        });
      }
    }

    bool isLoadingData = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isLoadingData) {
            Future.wait([
              getStoreTaxes(),
              getProductCategory(),
            ]).then((_) {
              setModalState(() {
                isLoadingData = false;
              });
            }).catchError((error) {
              print('Error loading data: $error');
              setModalState(() {
                isLoadingData = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Centered Title
                        Center(
                          child: Text(
                            'edit_produc'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                        // Image Button in Top Right
                        Positioned(
                          right: 0,
                          top: -5,
                          child: GestureDetector(
                            onTap: () {
                              _pickImageModal(setModalState);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (selectedImage != null ||
                                    (product.imageUrl != null && product.imageUrl!.isNotEmpty))
                                    ? Colors.transparent
                                    : const Color(0xFFFCAE03),
                                border: (selectedImage != null ||
                                    (product.imageUrl != null && product.imageUrl!.isNotEmpty))
                                    ? Border.all(color: Colors.grey.shade300, width: 2)
                                    : null,
                              ),
                              child: selectedImage != null
                                  ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22.5),
                                    child: Image.file(
                                      selectedImage!,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Close Icon
                                  Positioned(
                                    top: 0,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedImage = null;
                                        });
                                        setState(() {});
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                                  ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22.5),
                                    child: CachedNetworkImage(
                                      imageUrl: _getTrimmedImageUrl(product.imageUrl),
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  // Close Icon for existing image
                                  Positioned(
                                    top: 0,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          product.imageUrl = null;
                                        });
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoadingData
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/burger.json',
                            width: 150,
                            height: 150,
                            repeat: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'loading'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Mulish',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                        : SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            '${'product_name'.tr} *',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'enter_product'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'product_code'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: codeController,
                            decoration: InputDecoration(
                              hintText: 'enter_code'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${'taxe'.tr} *',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedTaxId,
                            hint: Text('select'.tr),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: storeTaxesList.map((tax) {
                              return DropdownMenuItem<String>(
                                value: tax.id.toString(),
                                child: Text('${tax.name} (${tax.percentage}%)'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setModalState(() {
                                selectedTaxId = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${'category'.tr} *',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategoryId,
                            hint: Text('select_category'.tr),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: productCategoryList.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id.toString(),
                                child: Text(category.name ?? 'N/A'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setModalState(() {
                                selectedCategoryId = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'product_type'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedProductType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: ['simple'.tr, 'variable'.tr].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setModalState(() {
                                selectedProductType = newValue;
                                if (newValue == 'simple'.tr) {
                                  for (var variant in variants) {
                                    variant['name'].dispose();
                                    variant['price'].dispose();
                                    variant['description'].dispose();
                                  }
                                  variants.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          if (selectedProductType == 'simple'.tr) ...[
                            Text(
                              '${'price'.tr} *',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'enter_price'.tr,
                                prefixText: '€ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'dis_price'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: discountPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'opt'.tr,
                                prefixText: '€ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                          if (selectedProductType == 'variable'.tr) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'variant'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                                if (variants.isEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setModalState(() {
                                        variants.add({
                                          'name': TextEditingController(),
                                          'price': TextEditingController(),
                                          'description': TextEditingController(),
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text('add_variant'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff0C831F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(variants.length, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: variants[index]['name'],
                                      decoration: InputDecoration(
                                        hintText: 'variant_name'.tr,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: variants[index]['price'],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        hintText: 'price'.tr,
                                        prefixText: '€ ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: variants[index]['description'],
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'desc'.tr,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setModalState(() {
                                            variants[index]['name'].dispose();
                                            variants[index]['price'].dispose();
                                            variants[index]['description'].dispose();
                                            variants.removeAt(index);
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xffE25454),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'remove'.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Mulish',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (variants.isNotEmpty)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      variants.add({
                                        'name': TextEditingController(),
                                        'price': TextEditingController(),
                                        'description': TextEditingController(),
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text('add_variant'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff0C831F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            '${'desc'.tr} *',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'enter_desc'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(0.2),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'cancel'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              SizedBox(
                                width: 160,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (nameController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter product name'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (codeController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter product code'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (selectedTaxId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select tax'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (selectedCategoryId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select category'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (descriptionController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter description'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    if (selectedProductType == 'simple'.tr) {
                                      if (priceController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter price'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                    } else if (selectedProductType == 'variable'.tr) {
                                      if (variants.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please add at least one variant'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }
                                      for (var variant in variants) {
                                        if (variant['name'].text.isEmpty || variant['price'].text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please fill all variant fields'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }
                                      }
                                    }

                                    List<Map<String, dynamic>>? productVariants;
                                    if (selectedProductType == 'variable'.tr) {
                                      productVariants = variants.map((v) {
                                        Map<String, dynamic> variantMap = {
                                          "name": v['name'].text,
                                          "price": double.parse(v['price'].text).toInt(),
                                          "item_code": "${codeController.text}-" + v['name'].text.replaceAll(' ', '').toUpperCase(),
                                          "image_url": "",
                                          "description": v['description'].text,
                                        };
                                        if (v['id'] != null) {
                                          variantMap['id'] = v['id'];
                                        }
                                        return variantMap;
                                      }).toList();
                                    }
                                    String? finalImageUrl = product.imageUrl;

                                    if (selectedImage != null) {
                                      String? uploadedImageUrl = await uploadProductImage(selectedImage!);
                                      if (uploadedImageUrl == null) {
                                        return;
                                      }
                                      finalImageUrl = uploadedImageUrl;
                                    }
                                    bool success = await editProductDetail(
                                      productId: product.id!,
                                      name: nameController.text,
                                      itemCode: codeController.text,
                                      categoryId: selectedCategoryId!,
                                      taxId: selectedTaxId!,
                                      productType: selectedProductType!,
                                      description: descriptionController.text,
                                      price: selectedProductType == 'simple'.tr ? priceController.text : null,
                                      discountPrice: selectedProductType == 'simple'.tr ? discountPriceController.text : null,
                                      productVariants: productVariants,
                                      imageUrl: finalImageUrl,
                                    );

                                    if (success && mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFCAE03),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'upd_product'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getStoreTaxes() async {
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
    try {

      List<getAddedtaxResponseModel> storeTax = await CallService().getStoreTax(storeId!);

      if (mounted) {
        setState(() {
          storeTaxesList=storeTax;
          isLoading = false;
        });
      }

    } catch (e) {

      print('Error getting Store taxes: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getProductCategory() async {
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
    try {
      List<GetProductCategoryList> category = await CallService().getProductCategory(storeId!);
      if (mounted) {
        setState(() {
          productCategoryList = category;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting Product Category: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> addProduct({
    required String name,
    required String itemCode,
    required String categoryId,
    required String taxId,
    required String productType,
    required String description,
    String? price,
    String? discount,
    List<Map<String, dynamic>>? productVariants,
    String? imageUrl,
  }) async
  {
    if (sharedPreferences == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SharedPreferences not initialized'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store ID not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    // Show loader
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
      // Convert translated product type to English for API
      String apiProductType = productType == 'simple'.tr ? 'simple' : 'variable';

      var map = {
        "name": name,
        "category_id": int.parse(categoryId),
        "image_url": imageUrl ?? "",
        "type": apiProductType,  // Use converted English value
        "store_id": int.parse(storeId!),
        "tax_id": int.parse(taxId),
        "description": description,
      };

      if (productType == 'simple'.tr) {
        map["price"] = double.parse(price!).toInt();
        map["discount_price"] = discount != null && discount.isNotEmpty
            ? double.parse(discount).toInt()
            : 0;
        map["item_code"] = itemCode;
      }
      if (productType == 'variable'.tr && productVariants != null) {
        map["variants"] = productVariants;
      }

      print("Add Product Map: $map");
      AddNewProductResponseModel model = await CallService().addNewProduct(map);

      await getProduct(showLoader: false);

      // Close loader AFTER API completes
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show success snackbar using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product_created'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;

    } catch (e) {
      // Close loader on error
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      print('Create Product error: $e');

      // Show error snackbar using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_create'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return false;
    }
  }

  Future<bool> editProductDetail({
    required int productId,
    required String name,
    required String itemCode,
    required String categoryId,
    required String taxId,
    required String productType,
    required String description,
    String? price,
    String? discountPrice,
    List<Map<String, dynamic>>? productVariants,
    String? imageUrl,
  }) async
  {

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      // Convert translated product type to English for API
      String apiProductType = productType == 'simple'.tr ? 'simple' : 'variable';

      var map = {
        "name": name,
        "item_code": itemCode,
        "category_id": int.parse(categoryId),
        "image_url": imageUrl ?? "",
        "type": apiProductType,  // Use converted English value
        "store_id": int.parse(storeId!),
        "tax_id": int.parse(taxId),
        "description": description,
        "isActive": true,
        "display_order": 0,
      };

      if (productType == 'simple'.tr) {
        map["price"] = double.parse(price!).toInt();
        map["discount_price"] = discountPrice != null && discountPrice.isNotEmpty
            ? double.parse(discountPrice).toInt()
            : 0;
        map["item_code"] = itemCode;
      }

      if (productType == 'variable'.tr && productVariants != null) {
        map["variants"] = productVariants;
      }

      print("Edit Product Map: $map");
      EditStoreProductResponseModel model = await CallService().editProducts(map, productId.toString());

      await getProduct(showLoader: false);

      // Close loader AFTER API completes
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('product_upd'.tr), backgroundColor: Colors.green),
        );
      }

      return true;
    } catch (e) {
      // Close loader on error
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      print('Edit Product error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_upd'.tr}: $e'), backgroundColor: Colors.red),
        );
      }

      return false;
    }
  }

  Future<void> deleteProduct(int productId) async {
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
      print('Deleting ProductId: $productId');

      await CallService().deleteProduct(productId);

      Get.back();

      // Refresh product list after deletion
      await getProduct(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('produc_delete'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      Get.back();
      print('Error deleting product: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_delete_product'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void showDeleteProduct(BuildContext context, String productName, int productId) {
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
                    const SizedBox(height: 20,),
                    Text(
                      '${'are'.tr}"$productName"?',
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
                              style: const TextStyle(
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
                              deleteProduct(productId);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child:  Text(
                              'delete'.tr,
                              style: const TextStyle(
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

  Future<String?> uploadProductImage(File imageFile) async {
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

      image_upload_response_model response = await CallService().uploadImage(imageFile);

      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close loader
      }

      if (response.url != null && response.url!.isNotEmpty) {
        print("Image uploaded successfully: ${response.url}");
        return response.url;
      } else {
        throw Exception('Image URL is empty');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close loader
      }
      print('Image upload error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _showProductStatusChangeDialog(BuildContext context, String productName, int productId, bool currentStatus) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                    const SizedBox(height: 20),
                    Text(
                      currentStatus
                          ? '${'deactivate_cat'.tr} "$productName"?'
                          : '${'reactivate_cat'.tr} "$productName"?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          fontFamily: 'Mulish'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            child: Text('cancel'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          height: 35,
                          width: 70,
                          decoration: BoxDecoration(
                            color: currentStatus ? const Color(0xFFE25454) : const Color(0xff49B27A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Get.back();
                              _toggleProductStatus(productId, !currentStatus);
                            },
                            child: Text('yes'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0, right: 0, top: -20,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFED4C5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              )
            ]
        ),
      ),
    );
  }

  Future<void> _toggleProductStatus(int productId, bool newStatus) async {
    if (sharedPreferences == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SharedPreferences not initialized'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } Get.snackbar('Error', 'Store ID not found');
      return;
    }

    // Find the product
    GetStoreProducts? product = productList.firstWhere(
          (p) => p.id == productId,
      orElse: () => GetStoreProducts(),
    );

    if (product.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      String apiProductType = product.type == 'simple'.tr ? 'simple' : 'variable';

      var map = {
        "name": product.name ?? '',
        "item_code": product.itemCode ?? '',
        "category_id": product.categoryId ?? 0,
        "image_url": product.imageUrl ?? '',
        "type": apiProductType,
        "store_id": int.parse(storeId!),
        "tax_id": product.taxId ?? 0,
        "description": product.description ?? '',
        "isActive": newStatus,  // ✅ Updated status
        "display_order": 0,
      };

      if (product.type == 'simple'.tr) {
        map["price"] = product.price ?? 0;
        map["discount_price"] = product.discountPrice ?? 0;
      }
      if (product.type == 'variable'.tr && product.variants != null) {
        map["variants"] = product.variants!.map((v) => {
          "id": v.id,
          "name": v.name ?? '',
          "price": v.price ?? 0,
          "item_code": v.itemCode ?? '',
          "image_url": v.imageUrl ?? '',
          "description": v.description ?? '',
        }).toList();
      }

      print("Toggle Product Status Map: $map");

      EditStoreProductResponseModel model = await CallService().editProducts(map, productId.toString());

      await getProduct(showLoader: false);
      Get.back();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'product_activated'.tr : 'product_deactivated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      Get.back();
      print('Error toggling product status: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_status_change'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


}
