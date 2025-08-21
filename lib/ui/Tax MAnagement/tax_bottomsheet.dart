import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/add_tax_response_mode.dart';
import '../../models/edit_tax_response_model.dart';

class AddTaxBottomSheet extends StatefulWidget {
  final VoidCallback? onDataAdded;
  final String? editTaxName;
  final String? editTaxPercentage;
  final int? editTaxId; // Add this line
  final bool isEditMode;

  const AddTaxBottomSheet({
    super.key,
    this.onDataAdded,
    this.editTaxName,
    this.editTaxPercentage,
    this.editTaxId, // Add this line
    this.isEditMode = false,
  });

  @override
  State<AddTaxBottomSheet> createState() => _AddTaxBottomSheetState();
}


class _AddTaxBottomSheetState extends State<AddTaxBottomSheet> {
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _taxPercentageController = TextEditingController();

  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
    if (widget.isEditMode) {
      _prefillEditData();
    }
  }

  // Initialize SharedPreferences
  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  // Pre-fill data for edit mode
  void _prefillEditData() {
    setState(() {
      if (widget.editTaxName != null) {
        _taxNameController.text = widget.editTaxName!;
      }
      if (widget.editTaxPercentage != null) {
        _taxPercentageController.text = widget.editTaxPercentage!;
      }
    });
  }

  void _onSave() {
    // Validate inputs
    if (_taxNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter tax name');
      return;
    }

    if (_taxPercentageController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter tax percentage');
      return;
    }

    // Validate percentage
    double? percentage = double.tryParse(_taxPercentageController.text.trim());
    if (percentage == null) {
      Get.snackbar('Error', 'Please enter a valid percentage');
      return;
    }

    if (percentage < 0 || percentage > 100) {
      Get.snackbar('Error', 'Tax percentage must be between 0 and 100');
      return;
    }

    // Call appropriate method based on edit mode
    if (widget.isEditMode) {
      _editSavedTax();
    } else {
      _saveTax();
    }
  }

  Future<void> _saveTax() async {
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
        "name": _taxNameController.text.trim(),
        "percentage": double.parse(_taxPercentageController.text.trim()),
        "store_id": storeId
      };

      print("Add Tax Map: $map");

      AddTaxResponseModel model = await CallService().addStoreTaxes(map);

      await Future.delayed(Duration(seconds: 2));

      print("Tax added successfully");

      setState(() {
        isLoading = false;
      });

      Get.back(); // Close loading dialog
      Navigator.pop(context); // Close bottom sheet
      Get.snackbar('Success', widget.isEditMode ? 'Tax updated successfully' : 'Tax added successfully');

      if (widget.onDataAdded != null) {
        widget.onDataAdded!();
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.back();
      print('Adding error: $e');
      Get.snackbar('Error', 'Failed to ${widget.isEditMode ? 'update' : 'add'} tax: ${e.toString()}');
    }
  }

  Future<void> _editSavedTax() async {
    if (sharedPreferences == null) {
      Get.snackbar('Error', 'SharedPreferences not initialized');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('Error', 'Store ID not found');
      return;
    }

    if (widget.editTaxId == null) {
      Get.snackbar('Error', 'Tax ID not found');
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
        "name": _taxNameController.text.trim(),
        "percentage": double.parse(_taxPercentageController.text.trim()),
        "store_id": storeId
      };

      print("Edit Tax Map: $map");

      editTaxResponseModel model = await CallService().editStoreTaxes(map,widget.editTaxId.toString(),);

      await Future.delayed(Duration(seconds: 2));

      print("Tax updated successfully");

      setState(() {
        isLoading = false;
      });

      Get.back(); // Close loading dialog
      Navigator.pop(context); // Close bottom sheet
      Get.snackbar('Success', 'Tax updated successfully');

      if (widget.onDataAdded != null) {
        widget.onDataAdded!();
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.back();
      print('Edit error: $e');
      Get.snackbar('Error', 'Failed to update tax: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _taxNameController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isEditMode ? 'Edit Tax' : 'Add Tax',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Tax Name Field
                    const Text(
                      'Tax Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taxNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter tax name (e.g., GST, VAT)',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Mulish',
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tax Percentage Field
                    const Text(
                      'Tax Percentage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taxPercentageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter percentage (e.g., 18.5)',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Mulish',
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            '%',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff757B8F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ),
          Positioned(
            top: -90,
            right: 0,
            left: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(15),
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
                  child: const Icon(Icons.close, size: 30, color: Colors.black),
                ),
              ),
            ),
          ),
        ]
    );
  }
}

void showAddTaxBottomSheet(
    BuildContext context, {
      VoidCallback? onDataAdded,
      String? editTaxName,
      String? editTaxPercentage,
      int? editTaxId, // Add this line
      bool isEditMode = false,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddTaxBottomSheet(
        onDataAdded: onDataAdded,
        editTaxName: editTaxName,
        editTaxPercentage: editTaxPercentage,
        editTaxId: editTaxId, // Add this line
        isEditMode: isEditMode,
      ),
    ),
  );
}
