import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/add_new_store_timing_response_model.dart';

class AddStoreHoursBottomSheet extends StatefulWidget {
  final VoidCallback? onDataAdded;
  final String? editTimingName;
  final List<int>? editSelectedDays;
  final String? editOpeningTime;
  final String? editClosingTime;
  final bool isEditMode;
  const AddStoreHoursBottomSheet({
    super.key, this.onDataAdded,
    this.editTimingName,
    this.editSelectedDays,
    this.editOpeningTime,
    this.editClosingTime,
    this.isEditMode = false,
  });

  @override
  State<AddStoreHoursBottomSheet> createState() => _AddStoreHoursBottomSheetState();
}
class _AddStoreHoursBottomSheetState extends State<AddStoreHoursBottomSheet> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();

  TimeOfDay? _selectedOpeningTime;
  TimeOfDay? _selectedClosingTime;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;

  // Days data with selection state - Updated with proper day names and indices
  List<DayModel> days = [
    DayModel(day: 'M', dayIndex: 0, isSelected: false), // Monday
    DayModel(day: 'T', dayIndex: 1, isSelected: false), // Tuesday
    DayModel(day: 'W', dayIndex: 2, isSelected: false), // Wednesday
    DayModel(day: 'T', dayIndex: 3, isSelected: false), // Thursday
    DayModel(day: 'F', dayIndex: 4, isSelected: false), // Friday
    DayModel(day: 'S', dayIndex: 5, isSelected: false), // Saturday
    DayModel(day: 'S', dayIndex: 6, isSelected: false), // Sunday
  ];

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
  // Pre-fill data method - FIXED VERSION
  void _prefillEditData() {
    setState(() {
      // Pre-fill store name
      if (widget.editTimingName != null) {
        _storeNameController.text = widget.editTimingName!;
      }

      // Pre-fill selected days
      if (widget.editSelectedDays != null) {
        for (int i = 0; i < days.length; i++) {
          days[i].isSelected = widget.editSelectedDays!.contains(i);
        }
      }

      // Pre-fill opening time
      if (widget.editOpeningTime != null) {
        try {
          // Handle both "HH:mm:ss" and "HH:mm" formats
          String timeStr = widget.editOpeningTime!;
          List<String> timeParts = timeStr.split(':');

          if (timeParts.length >= 2) {
            int hour = int.parse(timeParts[0]);
            int minute = int.parse(timeParts[1]);

            _selectedOpeningTime = TimeOfDay(hour: hour, minute: minute);
            _openingTimeController.text = _formatTimeForDisplay(_selectedOpeningTime!);
          }
        } catch (e) {
          print('Error parsing opening time: $e');
        }
      }

      // Pre-fill closing time
      if (widget.editClosingTime != null) {
        try {
          // Handle both "HH:mm:ss" and "HH:mm" formats
          String timeStr = widget.editClosingTime!;
          List<String> timeParts = timeStr.split(':');

          if (timeParts.length >= 2) {
            int hour = int.parse(timeParts[0]);
            int minute = int.parse(timeParts[1]);

            _selectedClosingTime = TimeOfDay(hour: hour, minute: minute);
            _closingTimeController.text = _formatTimeForDisplay(_selectedClosingTime!);
          }
        } catch (e) {
          print('Error parsing closing time: $e');
        }
      }
    });
  }
  bool get isAllSelected => days.every((day) => day.isSelected);

  void _toggleSelectAll() {
    setState(() {
      bool newSelectionState = !isAllSelected;
      for (var day in days) {
        day.isSelected = newSelectionState;
      }
    });
  }

  Future<void> _selectOpeningTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedOpeningTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedOpeningTime) {
      setState(() {
        _selectedOpeningTime = picked;
        _openingTimeController.text = _formatTimeForDisplay(picked);
      });
    }
  }

  Future<void> _selectClosingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedClosingTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedClosingTime) {
      setState(() {
        _selectedClosingTime = picked;
        _closingTimeController.text = _formatTimeForDisplay(picked);
      });
    }
  }

  // Format time for display (12-hour format)
  String _formatTimeForDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Format time for API (24-hour format HH:mm)
  String _formatTimeForAPI(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get selected day indices
  List<int> _getSelectedDayIndices() {
    return days.where((day) => day.isSelected).map((day) => day.dayIndex).toList();
  }

  void _onSave() {
    // Validate inputs
    if (_storeNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter store hours name');
      return;
    }

    if (_selectedOpeningTime == null) {
      Get.snackbar('Error', 'Please select opening time');
      return;
    }

    if (_selectedClosingTime == null) {
      Get.snackbar('Error', 'Please select closing time');
      return;
    }

    List<int> selectedDays = _getSelectedDayIndices();
    if (selectedDays.isEmpty) {
      Get.snackbar('Error', 'Please select at least one day');
      return;
    }

    // Save store hours for each selected day
    _saveStoreHours(selectedDays);
  }

  Future<void> _saveStoreHours(List<int> selectedDays) async {
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

      // Save store hours for each selected day
      for (int dayIndex in selectedDays) {
        var map = {
          "name": _storeNameController.text.trim(),
          "day_of_week": dayIndex,
          "opening_time": _formatTimeForAPI(_selectedOpeningTime!),
          "closing_time": _formatTimeForAPI(_selectedClosingTime!),
          "store_id": storeId
        };

        print("add Store Time Map: $map");

        AddNewStoreTimingResponseModel model = await CallService().addStoreTiming(map, storeId!);
        print("Store timing added for day $dayIndex: ${model.toString()}");
      }

      setState(() {
        isLoading = false;
      });

      Get.back(); // Close loading dialog
      Navigator.pop(context); // Close bottom sheet
      Get.snackbar('Success', 'Store hours added successfully');
      if (widget.onDataAdded != null) {
        widget.onDataAdded!();
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.back(); // Close loading dialog
      print('Adding error: $e');
      Get.snackbar('Error', 'Failed to add store hours: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
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
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isEditMode ? 'Edit Store Hours' : 'Add Store Hours',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),)
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Store Hours Name
                    const Text(
                      'Store Hours Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _storeNameController,
                      decoration: InputDecoration(
                        hintText: 'Add Title..',
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

                    // Time Fields Row
                    Row(
                      children: [
                        // Opening Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Opening Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _openingTimeController,
                                readOnly: true,
                                onTap: _selectOpeningTime,
                                decoration: InputDecoration(
                                  hintText: '--:--',
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
                                  suffixIcon: const Icon(
                                    Icons.access_time,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Closing Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Closing Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _closingTimeController,
                                readOnly: true,
                                onTap: _selectClosingTime,
                                decoration: InputDecoration(
                                  hintText: '--:--',
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
                                  suffixIcon: const Icon(
                                    Icons.access_time,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Select Days Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Mulish',
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: isAllSelected,
                              onChanged: (value) => _toggleSelectAll(),
                              activeColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Text(
                              'Select All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Mulish',
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Days Selection Circles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: days.asMap().entries.map((entry) {
                        int index = entry.key;
                        DayModel day = entry.value;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              days[index].isSelected = !days[index].isSelected;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: day.isSelected ? Colors.green : Colors.white,
                              border: Border.all(
                                color: day.isSelected ? Colors.green : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day.day,
                                style: TextStyle(
                                  color: day.isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    Row(mainAxisAlignment: MainAxisAlignment.center,
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
                              onPressed: (){
                                Navigator.pop(context);
                              },
                              child: Text('Cancel',style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Mulish',
                              ),)),
                        ),
                        SizedBox(width: 20,),
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
        ]);
  }

}

// Updated Model class for day data with dayIndex
class DayModel {
  final String day;
  final int dayIndex; // 0=Sunday, 1=Monday, 2=Tuesday, etc.
  bool isSelected;

  DayModel({
    required this.day,
    required this.dayIndex,
    this.isSelected = false,
  });
}

// Function to show the bottom sheet
void showAddStoreHoursBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const AddStoreHoursBottomSheet(),
    ),
  );
}