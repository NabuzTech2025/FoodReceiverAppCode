import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/models/add_new_product_category_response_model.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../customView/CustomAppBar.dart';
import '../../../customView/CustomDrawer.dart';
import '../../../models/edit_existing_product_category_response_model.dart';
import '../../../models/get_added_tax_response_model.dart';
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
  TextEditingController categoryNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? selectedTaxId; // To store selected tax ID
  String? selectedTaxName;
  File? selectedImage; // Add this for image selection
  final ImagePicker _picker = ImagePicker(); // Add this for image picker

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
      getStoreTaxes();
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
  List<getAddedtaxResponseModel> storeTaxesList = [];
  bool isResetting = false;
  bool isEditMode = false;
  GetProductCategoryList? editingCategory;
  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    super.initState();
  }
  Future<void> _pickImage(StateSetter setModalState) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mulish',
              ),
            ),
            SizedBox(height: 20),
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
                      }
                    } catch (e) {
                      print('Error picking image from camera: $e');
                      Get.snackbar('Error', 'Failed to capture image');
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Color(0xFFFCAE03),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Camera',
                        style: TextStyle(
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
                      }
                    } catch (e) {
                      print('Error picking image from gallery: $e');
                      Get.snackbar('Error', 'Failed to pick image');
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Color(0xFFFCAE03),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Gallery',
                        style: TextStyle(
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
            SizedBox(height: 20),
            // Cancel Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    'Cancel',
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
  @override
  void dispose() {
    _pageController.dispose();
    categoryNameController.dispose();
    descriptionController.dispose();
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
                      Text('category'.tr, style: TextStyle(
                          fontFamily: 'Mulish', fontSize: 18, fontWeight: FontWeight.bold
                      )),
                      GestureDetector(
                        onTap: () {
                          _showAddCategoryBottomSheet(context);
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
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECF8FF),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 40),
                          child: Row(
                           // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.43,
                                child: Text('name'.tr,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      fontFamily: 'Mulish'
                                  ),
                                ),
                              ),
                              Container(
                                //width: MediaQuery.of(context).size.width * 0.2,
                                child: Text('taxe'.tr,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        fontFamily: 'Mulish'
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Center(
                            child: Text('status'.tr,
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
                      child: Text(
                        'no'.tr,
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
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(product.name.toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  fontFamily: 'Mulish'
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(product.description.toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 10,
                                                  fontFamily: 'Mulish'
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                          ],
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
                                      (product.isActive == true) ? 'active'.tr : 'inactive'.tr,
                                      style: TextStyle(
                                          fontSize: 12,fontFamily: 'Mulish',fontWeight: FontWeight.w700,
                                          color: Colors.white
                                      ),),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    _showAddCategoryBottomSheet(context, categoryToEdit: product);
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
                                    _showDeleteTaxConfirmation(context, product.name.toString(), product.id!);
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

      List<GetProductCategoryList> category = await CallService().getProductCategory(storeId!);

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
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
      }

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Product Category: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showAddCategoryBottomSheet(BuildContext context, {GetProductCategoryList? categoryToEdit}) {
    // Set edit mode and prefill data if editing
    if (categoryToEdit != null) {
      isEditMode = true;
      editingCategory = categoryToEdit;
      categoryNameController.text = categoryToEdit.name ?? '';
      descriptionController.text = categoryToEdit.description ?? '';
      selectedTaxId = categoryToEdit.tax?.id?.toString();
      selectedTaxName = '${categoryToEdit.tax?.name} (${categoryToEdit.tax?.percentage}%)';
      // Handle image URL if needed
      selectedImage = null; // Reset for now, you can implement image loading if needed
    } else {
      isEditMode = false;
      editingCategory = null;
      // Clear fields for add mode
      categoryNameController.clear();
      descriptionController.clear();
      selectedTaxId = null;
      selectedTaxName = null;
      selectedImage = null;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Centered Title
                    Center(
                      child: Text(
                        isEditMode ? 'edit'.tr : 'new'.tr,
                        style: TextStyle(
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
                          _pickImage(setModalState);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedImage != null ? Colors.transparent : Color(0xFFFCAE03),
                            border: selectedImage != null ? Border.all(color: Colors.grey.shade300, width: 2) : null,
                          ),
                          child: selectedImage != null
                              ? Stack(
                            children: [
                              // Selected Image
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
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                              : Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'category_name'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryNameController,
                  decoration: InputDecoration(
                    hintText: 'add_category'.tr,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontFamily: 'Mulish',
                    ),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Tax Dropdown
                Text(
                  'select'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedTaxId,
                    hint: Text(
                      'select'.tr,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                    items: storeTaxesList.map<DropdownMenuItem<String>>((tax) {
                      return DropdownMenuItem<String>(
                        value: tax.id.toString(),
                        child: Text(
                          '${tax.name} (${tax.percentage}%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Mulish',
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setModalState(() {
                        selectedTaxId = newValue;
                        // Find selected tax name for display
                        var selectedTax = storeTaxesList.firstWhere((tax) => tax.id.toString() == newValue);
                        selectedTaxName = '${selectedTax.name} (${selectedTax.percentage}%)';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Description Field
                Text(
                  'desc'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'description'.tr,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontFamily: 'Mulish',
                    ),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          categoryNameController.clear();
                          descriptionController.clear();
                          selectedTaxId = null;
                          selectedTaxName = null;
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
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
                    // Save Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isEditMode) {
                            _updateProductCategory(editingCategory!.id.toString());
                          } else {
                            _saveProductCategory();
                          }
                          String categoryName = categoryNameController.text.trim();
                          String description = descriptionController.text.trim();

                          if (categoryName.isEmpty) {
                            Get.snackbar('Error', 'Please enter category name');
                            return;
                          }

                          if (selectedTaxId == null) {
                            Get.snackbar('Error', 'Please select tax');
                            return;
                          }

                          print('Category Name: $categoryName');
                          print('Selected Tax ID: $selectedTaxId');
                          print('Description: $description');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFCAE03),
                          ),
                          child: Center(
                            child: Text(
                              isEditMode ? 'update'.tr : 'saved'.tr,
                              style: TextStyle(
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
      ),
    );
  }

  Future<void> getStoreTaxes({bool showLoader = true}) async {
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

      List<getAddedtaxResponseModel> storeTax = await CallService().getStoreTax(storeId!);

      if (showLoader) {
        Get.back();
      }

      setState(() {
        storeTaxesList=storeTax;
        isLoading = false;
      });

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Store taxes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProductCategory() async {
    if (sharedPreferences == null) {
      Get.snackbar('Error', 'SharedPreferences not initialized');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('Error', 'Store ID not found');
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

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

      var map = {
        "name": categoryNameController.text.trim(),
        "store_id": storeId,
        "tax_id": selectedTaxId,
        "image_url": selectedImage,
        "description": descriptionController.text??''
      };

      print("Add product Map: $map");

      AddNewProductCategoryResponseModel model = await CallService().addNewProductCategory(map);

      await Future.delayed(Duration(seconds: 2));

      print("Product Category added successfully");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      Get.back(); // Close loading dialog

      // Clear form fields
      categoryNameController.clear();
      descriptionController.clear();
      selectedTaxId = null;
      selectedTaxName = null;
      selectedImage = null;

      Navigator.pop(context);
      await getProductCategory(showLoader: false);

      Get.snackbar('Success', 'Product category added successfully');

    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      Get.back(); // Close loading dialog
      print('Adding error: $e');
      Get.snackbar('Error', 'Failed to add product category: ${e.toString()}');
    }
  }

  void _showDeleteTaxConfirmation(BuildContext context, String productName, int productId) {
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
                              _deleteProductCategory(productId);
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

  Future<void> _deleteProductCategory(int productId) async {
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
      print('API call ProductId: $productId ke liye');

      await CallService().deleteProductCategory(productId);

      Get.back();
      Get.snackbar('Success', 'Product Category deleted successfully');

      await getProductCategory(showLoader: false);

    } catch (e) {
      Get.back();
      print('Error deleting product: $e');
      Get.snackbar('Error', 'Failed to delete product');
    }
  }

  Future<void> _updateProductCategory(String productId) async {
    if (sharedPreferences == null) {
      Get.snackbar('Error', 'SharedPreferences not initialized');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('Error', 'Store ID not found');
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
      var map = {
        "name": categoryNameController.text.trim(),
        "store_id": storeId,
        "tax_id": selectedTaxId,
        "image_url": "", // You may want to handle image upload here
        "description": descriptionController.text.trim()
      };

      print("Edit Product Category Map: $map");

      EditExistingProductCategoryResponseModel model = await CallService().editProductCategory(map,productId);

      await Future.delayed(Duration(seconds: 2));

      print("Product updated successfully");

      setState(() {
        isLoading = false;
      });

      Get.back(); // Close loading dialog
      Navigator.pop(context);
      // Clear form fields
      categoryNameController.clear();
      descriptionController.clear();
      selectedTaxId = null;
      selectedTaxName = null;
      selectedImage = null;

// Refresh the list
      await getProductCategory(showLoader: false);// Close bottom sheet
      Get.snackbar('Success', 'Product category updated successfully');


    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.back();
      print('Edit error: $e');
      Get.snackbar('Error', 'Failed to update product: ${e.toString()}');
    }
  }
}
