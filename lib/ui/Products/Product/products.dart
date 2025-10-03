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

  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> variants = [];

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  void _updatePagination() {
    totalPages = (productList.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    // Ensure current page is valid
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    // Get items for current page
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > productList.length) endIndex = productList.length;

    currentPageItems = productList.sublist(startIndex, endIndex);
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

  void _addVariant() {
    setState(() {
      variants.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  void _removeVariant(int index) {
    setState(() {
      // Dispose controllers before removing
      variants[index]['name'].dispose();
      variants[index]['price'].dispose();
      variants[index]['description'].dispose();
      variants.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    getProduct();
    getStoreTaxes();
    getProductCategory();
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
                        Text('Products'.tr,
                            style: TextStyle(
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

                  // Showing entries info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${(currentPage - 1) * itemsPerPage + 1} to ${(currentPage - 1) * itemsPerPage + currentPageItems.length} of ${productList.length} entries',
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
                          width: MediaQuery.of(context).size.width * 0.44,
                          child: Text('Product Name'.tr,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Mulish'),
                          ),
                        ),
                        Container(
                          child: Text('Category'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish')),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.2,
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
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        return Slidable(
                          key: ValueKey(index),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.335,
                            children: [
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.4,
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
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.32,
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
                                const SizedBox(width: 5),
                                Container(
                                  child: Center(
                                    child: Text('€${currentPageItems[index].price?.toStringAsFixed(2) ?? '0.00'}',
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

          if (productList.isNotEmpty && totalPages > 1)
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
                      offset: Offset(0, -2),
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
                          'Previous',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage > 1 ? Colors.black87 : Colors.grey,
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
                          onTap: () => _goToPage(pageNum),
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isActive ? Color(0xFF0EA5E9) : Colors.white,
                              border: Border.all(
                                color: isActive ? Color(0xFF0EA5E9) : Colors.grey.shade300,
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

                    SizedBox(width: 8),

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
                          'Next',
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
    TextEditingController descriptionController = TextEditingController();
    String? selectedCategory;
    String? selectedTax;
    String? selectedProductType = 'Simple';
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
            child: Stack(
                clipBehavior: Clip.none,
              children: [
                Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [

                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add New Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Show options to pick from gallery or camera
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return SafeArea(
                                          child: Wrap(
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.photo_library),
                                                title: Text('Choose from Gallery'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _pickImage(ImageSource.gallery);
                                                  setModalState(() {});
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.photo_camera),
                                                title: Text('Take a Photo'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _pickImage(ImageSource.camera);
                                                  setModalState(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: selectedImage != null
                                        ? ClipOval(
                                      child: Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (selectedImage != null)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _removeImage();
                                        setModalState(() {});
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
            SizedBox(height: 16),
            Text(
            'Loading product details...',
            style: TextStyle(
            fontSize: 14,
            fontFamily: 'Mulish',
            color: Colors.grey[600],
            ),
            ),
            ],
            ),
            )
                :
             SingleChildScrollView(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Product Name *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter product name',
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
                                  borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Product Code *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: codeController,
                              decoration: InputDecoration(
                                hintText: 'Enter code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tax *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedTaxId,
                              hint: Text('Select Tax'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            SizedBox(height: 10),
                            Text(
                              'Category *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              hint: Text('Select Category'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
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
                            SizedBox(height: 10),
                            Text(
                              'Product Type *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedProductType,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: ['Simple','Variable',].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  selectedProductType = newValue;
                                  // Clear variants when switching to Simple
                                  if (newValue == 'Simple') {
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
                            SizedBox(height: 10),
                            if (selectedProductType == 'Simple') ...[
                              Text(
                                'Price *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: priceController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Enter price',
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
                                    borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                            if (selectedProductType == 'Variable') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Variants',
                                    style: TextStyle(
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
                                    icon: Icon(Icons.add, size: 18),
                                    label: Text('Add Variant'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xff0C831F),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              // Display all variants
                              ...List.generate(variants.length, (index) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  padding: EdgeInsets.all(12),
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
                                            borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      TextField(
                                        controller: variants[index]['price'],
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: 'Price',
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
                                            borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      TextField(
                                        controller: variants[index]['description'],
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'Description',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      SizedBox(height: 10),
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
                                            backgroundColor: Color(0xffE25454),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Remove Variant',
                                            style: TextStyle(
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

                              // Add Variant button at bottom
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
                                    icon: Icon(Icons.add, size: 18),
                                    label: Text('Add Variant'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xff0C831F),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                            ],

                            SizedBox(height: 16),

                            // Description
                            Text(
                              'Description *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter description...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 20),

                            Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(0.2),
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Mulish',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15,),
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Validation
                                      if (nameController.text.isEmpty) {
                                        Get.snackbar('Error', 'Please enter product name',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (codeController.text.isEmpty) {
                                        Get.snackbar('Error', 'Please enter product code',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (selectedTaxId == null) {
                                        Get.snackbar('Error', 'Please select tax',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (selectedCategoryId == null) {
                                        Get.snackbar('Error', 'Please select category',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (descriptionController.text.isEmpty) {
                                        Get.snackbar('Error', 'Please enter description',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }

                                      if (selectedProductType == 'Simple') {
                                        if (priceController.text.isEmpty) {
                                          Get.snackbar('Error', 'Please enter price',
                                              snackPosition: SnackPosition.BOTTOM);
                                          return;
                                        }
                                      } else if (selectedProductType == 'Variable') {
                                        if (variants.isEmpty) {
                                          Get.snackbar('Error', 'Please add at least one variant',
                                              snackPosition: SnackPosition.BOTTOM);
                                          return;
                                        }
                                        for (var variant in variants) {
                                          if (variant['name'].text.isEmpty || variant['price'].text.isEmpty) {
                                            Get.snackbar('Error', 'Please fill all variant fields',
                                                snackPosition: SnackPosition.BOTTOM);
                                            return;
                                          }
                                        }
                                      }

                                      // Prepare variants for variable products
                                      List<Map<String, dynamic>>? productVariants;
                                      if (selectedProductType == 'Variable') {
                                        productVariants = variants.map((v) => {
                                          "name": v['name'].text,
                                          "price": int.parse(v['price'].text),
                                          "item_code": codeController.text + "-" + v['name'].text.replaceAll(' ', '').toUpperCase(),
                                          "image_url": "",
                                          "description": v['description'].text,
                                        }).toList();
                                      }

                                      bool success = await addProduct(
                                        name: nameController.text,
                                        itemCode: codeController.text,
                                        categoryId: selectedCategoryId!,
                                        taxId: selectedTaxId!,
                                        productType: selectedProductType!,
                                        description: descriptionController.text,
                                        price: selectedProductType == 'Simple' ? priceController.text : null,
                                        productVariants: productVariants,
                                        imageUrl: selectedImage?.path,
                                      );

                                      // Only close bottom sheet if API was successful
                                      if (success && mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFCAE03),
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Add Product',
                                      style: TextStyle(
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
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                Positioned(
                  top: -70,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                        child: const Icon(Icons.close, size: 25, color: Colors.black),
                      ),
                    ),
                  ),
                ),
            ]),
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
    TextEditingController descriptionController = TextEditingController(text: product.description);

    String? selectedProductType = product.type != null
        ? product.type!.substring(0, 1).toUpperCase() + product.type!.substring(1).toLowerCase()
        : 'Simple';
    String? selectedCategoryId = product.categoryId?.toString();
    String? selectedTaxId = product.taxId?.toString();

    // Pre-fill variants if Variable type
    variants.clear();
    if (product.type == 'Variable' && product.variants != null) {
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

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return SafeArea(
                                          child: Wrap(
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.photo_library),
                                                title: Text('Choose from Gallery'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _pickImage(ImageSource.gallery);
                                                  setModalState(() {});
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.photo_camera),
                                                title: Text('Take a Photo'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _pickImage(ImageSource.camera);
                                                  setModalState(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: selectedImage != null
                                        ? ClipOval(
                                      child: Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                                        ? ClipOval(
                                      child: Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          );
                                        },
                                      ),
                                    )
                                        : Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (selectedImage != null)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _removeImage();
                                        setModalState(() {});
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                            SizedBox(height: 16),
                            Text(
                              'Loading product details...',
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
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Product Name *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter product name',
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
                                  borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Product Code *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: codeController,
                              decoration: InputDecoration(
                                hintText: 'Enter code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tax *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedTaxId,
                              hint: Text('Select Tax'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            SizedBox(height: 10),
                            Text(
                              'Category *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              hint: Text('Select Category'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            SizedBox(height: 10),
                            Text(
                              'Product Type *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedProductType,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: ['Simple', 'Variable'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  selectedProductType = newValue;
                                  if (newValue == 'Simple') {
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
                            SizedBox(height: 10),
                            if (selectedProductType == 'Simple') ...[
                              Text(
                                'Price *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: priceController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Enter price',
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
                                    borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                            if (selectedProductType == 'Variable') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Variants',
                                    style: TextStyle(
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
                                      icon: Icon(Icons.add, size: 18),
                                      label: Text('Add Variant'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xff0C831F),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 10),
                              ...List.generate(variants.length, (index) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  padding: EdgeInsets.all(12),
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
                                            borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      TextField(
                                        controller: variants[index]['price'],
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: 'Price',
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
                                            borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      TextField(
                                        controller: variants[index]['description'],
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'Description',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      SizedBox(height: 10),
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
                                            backgroundColor: Color(0xffE25454),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Remove Variant',
                                            style: TextStyle(
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
                                    icon: Icon(Icons.add, size: 18),
                                    label: Text('Add Variant'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xff0C831F),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            SizedBox(height: 16),
                            Text(
                              'Description *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter description...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color(0xFFFCAE03)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 20),
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
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Mulish',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (nameController.text.isEmpty) {
                                        Get.snackbar('Error', 'Please enter product name',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (codeController.text.isEmpty) {
                                        Get.snackbar('Error', 'Please enter product code',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (selectedTaxId == null) {
                                        Get.snackbar('Error', 'Please select tax',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (selectedCategoryId == null) {
                                        Get.snackbar('Error', 'Please select category',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      if (descriptionController.text.isEmpty) {
                                        Get.snackbar('Error', 'Please enter description',
                                            snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }

                                      if (selectedProductType == 'Simple') {
                                        if (priceController.text.isEmpty) {
                                          Get.snackbar('Error', 'Please enter price',
                                              snackPosition: SnackPosition.BOTTOM);
                                          return;
                                        }
                                      } else if (selectedProductType == 'Variable') {
                                        if (variants.isEmpty) {
                                          Get.snackbar('Error', 'Please add at least one variant',
                                              snackPosition: SnackPosition.BOTTOM);
                                          return;
                                        }
                                        for (var variant in variants) {
                                          if (variant['name'].text.isEmpty || variant['price'].text.isEmpty) {
                                            Get.snackbar('Error', 'Please fill all variant fields',
                                                snackPosition: SnackPosition.BOTTOM);
                                            return;
                                          }
                                        }
                                      }

                                      List<Map<String, dynamic>>? productVariants;
                                      if (selectedProductType == 'Variable') {
                                        productVariants = variants.map((v) {
                                          Map<String, dynamic> variantMap = {
                                            "name": v['name'].text,
                                            "price": int.parse(v['price'].text),
                                            "item_code": codeController.text + "-" + v['name'].text.replaceAll(' ', '').toUpperCase(),
                                            "image_url": "",
                                            "description": v['description'].text,
                                          };
                                          if (v['id'] != null) {
                                            variantMap['id'] = v['id'];
                                          }
                                          return variantMap;
                                        }).toList();
                                      }

                                      bool success = await editProductDetail(
                                        productId: product.id!,
                                        name: nameController.text,
                                        itemCode: codeController.text,
                                        categoryId: selectedCategoryId!,
                                        taxId: selectedTaxId!,
                                        productType: selectedProductType!,
                                        description: descriptionController.text,
                                        price: selectedProductType == 'Simple' ? priceController.text : null,
                                        productVariants: productVariants,
                                        imageUrl: selectedImage?.path ?? product.imageUrl,
                                      );

                                      if (success && mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFCAE03),
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Update Product',
                                      style: TextStyle(
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
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -70,
                right: 0,
                left: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                      child: const Icon(Icons.close, size: 25, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
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
    List<Map<String, dynamic>>? productVariants,
    String? imageUrl,
  })
  async {
    if (sharedPreferences == null) {
      Get.snackbar('Error', 'SharedPreferences not initialized',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('Error', 'Store ID not found',
          snackPosition: SnackPosition.BOTTOM);
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
      var map = {
        "name": name,
        "category_id": int.parse(categoryId),
        "image_url": imageUrl ?? "",
        "type": productType.toLowerCase(),
        "store_id": int.parse(storeId!),
        "tax_id": int.parse(taxId),
        "description": description,
      };

      if (productType == "Simple") {
        map["price"] = int.parse(price!);
        map["item_code"] = itemCode;
      }

      if (productType == "Variable" && productVariants != null) {
        map["variants"] = productVariants;
      }

      print("Add Product Map: $map");
      AddNewProductResponseModel model = await CallService().addNewProduct(map);

      // Close loader
      Get.back();

      // Refresh product list
      await getProduct(showLoader: false);

      // Show success snackbar using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return true;

    } catch (e) {
      Get.back();

      print('Create Product error: $e');

      // Show error snackbar using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create product: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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
    List<Map<String, dynamic>>? productVariants,
    String? imageUrl,
  })
  async {

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "name": name,
        "item_code": itemCode,
        "category_id": int.parse(categoryId),
        "image_url": imageUrl ?? "",
        "type": productType.toLowerCase(),
        "store_id": int.parse(storeId!),
        "tax_id": int.parse(taxId),
        "description": description,
        "isActive": true,
        "display_order": 0,
      };

      if (productType == "Simple") {
        map["price"] = int.parse(price!);
      }

      if (productType == "Variable" && productVariants != null) {
        map["variants"] = productVariants;
      }

      print("Edit Product Map: $map");
      EditStoreProductResponseModel model = await CallService().editProducts(map,productId.toString());

      Get.back();
      await getProduct(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
        );
      }

      return true;
    } catch (e) {
      Get.back();
      print('Edit Product error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
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
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      Get.back();
      print('Error deleting product: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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
                    SizedBox(height: 20,),
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


}
