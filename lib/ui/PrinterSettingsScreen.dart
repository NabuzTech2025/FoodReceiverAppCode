import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../models/StoreSetting.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';
import 'LoginScreen.dart';

class PrinterSettingsScreen extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  // ✅ Keep the widget alive but detect tab changes
  @override
  bool get wantKeepAlive => true;

  // ──────────────────────────────────────────────────  PRINTER IPs
  final List<TextEditingController> _ipControllers =
  List.generate(1, (_) => TextEditingController());
  final List<TextEditingController> _ipRemoteControllers =
  List.generate(1, (_) => TextEditingController());
  final List<FocusNode> _ipFocusNodes = List.generate(1, (_) => FocusNode());
  final List<FocusNode> _ipRemoteFocusNodes = List.generate(1, (_) => FocusNode());

  int _selectedIpIndex = 0;
  int _selectedRemoteIpIndex = 0;

  // ──────────────────────────────────────────────────  NEW TOGGLES
  bool _autoOrderAccept = false;
  bool _autoOrderPrint = false;
  bool _autoRemoteOrderrAccept = false;
  bool _autoRemoteOrderPrint = false;
  String? bearerKey;
  late SharedPreferences sharedPreferences;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  // ✅ Tab tracking variables
  int? _lastTabIndex;
  bool _isCurrentTab = false;

  // ✅ Add worker reference for proper disposal
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharedPrefsAndLoadSettings();
    _setupTabListener();
  }

  // ✅ Setup tab change listener using GetX controller
  void _setupTabListener() {
    // Use the reactive getter from AppController and store the worker reference
    _tabWorker = ever(app.appController.selectedTabIndexRx, (int tabIndex) {
      // ✅ Check if widget is still mounted before handling tab change
      if (mounted) {
        _handleTabChange(tabIndex);
      }
    });
  }

  // ✅ Handle tab change logic
  void _handleTabChange(int tabIndex) {
    print("📱 Tab changed to: $tabIndex");

    // Check if this is the printer settings tab (index 2)
    bool isNowCurrentTab = tabIndex == 2;

    if (isNowCurrentTab && (!_isCurrentTab || _lastTabIndex != tabIndex)) {
      print("🔄 Printer Settings tab became active, refreshing...");
      _isCurrentTab = true;
      _lastTabIndex = tabIndex;
      _unfocusAllTextFields();
      // ✅ FIX: Remove delay and call immediately
      _refreshSettings();
    } else {
      _isCurrentTab = isNowCurrentTab;
      if (!isNowCurrentTab) {
        _unfocusAllTextFields();
      }
    }
  }

  @override
  void dispose() {
    // ✅ Dispose the worker first to prevent further callbacks
    _tabWorker?.dispose();

    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _ipControllers) {
      controller.dispose();
    }
    for (var controller in _ipRemoteControllers) {
      controller.dispose();
    }
    // ✅ Dispose focus nodes
    for (var focusNode in _ipFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _ipRemoteFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _unfocusAllTextFields() {
    // ✅ Check if widget is still mounted before accessing context
    if (!mounted) {
      print("⚠️ Widget not mounted, skipping unfocus");
      return;
    }

    try {
      for (var focusNode in _ipFocusNodes) {
        if (focusNode.hasFocus) {
          focusNode.unfocus();
        }
      }
      for (var focusNode in _ipRemoteFocusNodes) {
        if (focusNode.hasFocus) {
          focusNode.unfocus();
        }
      }
      // Also unfocus any currently focused element
      FocusScope.of(context).unfocus();
    } catch (e) {
      print("⚠️ Error unfocusing text fields: $e");
      // Continue execution even if unfocus fails
    }
  }

  // ✅ App lifecycle detection (for app foreground/background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isCurrentTab && mounted) {
      print("📱 App resumed and on printer settings tab, refreshing...");
      _unfocusAllTextFields();
      // ✅ FIX: Remove delay and call immediately
      _refreshSettings();
    }
  }

  // ✅ Refresh settings method
  Future<void> _refreshSettings() async {
    if (!mounted) return; // ✅ Check mounted state

    if (bearerKey != null && bearerKey!.isNotEmpty) {
      print("🔄 Refreshing settings from server...");
      getStoreSetting(bearerKey!);
    } else {
      print("⚠️ No bearer key available for refresh");
    }
  }

  Future<void> _initSharedPrefsAndLoadSettings() async {
    if (!mounted) return; // ✅ Check mounted state

    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    print("🔑 Bearer Key found: ${bearerKey != null}");

    await _loadSavedSettings();

    if (bearerKey != null && mounted) {
      await getStoreSetting(bearerKey!);
    }
  }

  // ──────────────────────────────────────────────────  PREFERENCES
  Future<void> _loadSavedSettings() async {
    if (!mounted) return; // ✅ Check mounted state

    try {
      final prefs = sharedPreferences;

      _selectedIpIndex = prefs.getInt('selected_ip_index') ?? 0;
      _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
      _autoRemoteOrderrAccept =
          prefs.getBool('auto_order_remote_accept') ?? false;
      _autoRemoteOrderPrint =
          prefs.getBool('auto_order_remote_print') ?? false;
      _autoOrderAccept = prefs.getBool('auto_order_accept') ?? false;

      _ipControllers[0].text = prefs.getString('printer_ip_0') ?? '';
      _ipRemoteControllers[0].text =
          prefs.getString('printer_ip_remote_0') ?? '';

      if (mounted) {
        setState(() {}); // trigger rebuild with loaded values
      }

      print("✅ Local settings loaded from SharedPreferences");
    } catch (e) {
      print("❌ Error loading settings: $e");
    }
  }

  Future<void> _saveIps() async {
    if (!mounted) return; // ✅ Check mounted state

    try {
      setState(() {
        _isSaving = true; // ✅ NEW: Set saving state
      });
      // ✅ IMPORTANT: Unfocus all text fields BEFORE API call
      _unfocusAllTextFields();

      // ✅ Show loading dialog
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

      // ✅ FIXED: Call poststoreSetting with showDialog: true to let it handle dialogs
      await poststoreSetting(bearerKey!, showDialog: false);
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });

      // ✅ Close loading dialog first
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 300)); // Wait for dialog to close
      }

      // ✅ Sync settings after successful API call
      await SettingsSync.syncSettingsAfterLogin();

      // ✅ Show success animation
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/Success.json',
              width: 150,
              height: 150,
              repeat: false,
            )
        ),
        barrierDismissible: false,
      );

      // ✅ Wait for success animation, then close
      await Future.delayed(Duration(seconds: 2));

      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200)); // Wait for dialog to close
      }

      _unfocusAllTextFields();

      Get.snackbar(
        'Success',
        'Settings synced successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      print("❌ Error in _saveIps: $e");
      setState(() {
        _isSaving = false;
      });
      // ✅ Close any open dialog
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200));
      }

      // ✅ IMPORTANT: Unfocus on error as well
      _unfocusAllTextFields();

      Get.snackbar(
        'Error',
        'Failed to save settings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> _saveLocalIps() async {
    if (!mounted) return; // ✅ Check mounted state

    try {
      // ✅ IMPORTANT: Unfocus before validation and saving
      _unfocusAllTextFields();

      final prefs = sharedPreferences;
      String ip = _ipControllers[0].text.trim();

      if (ip.isEmpty || _validateIP(ip) != null) {
        // Using Get.snackbar instead of ScaffoldMessenger
        Get.snackbar(
          'Invalid IP',
          'Enter valid Local IP',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await prefs.setString('printer_ip_0', ip);
      await prefs.setInt('selected_ip_index', _selectedIpIndex);

      // ✅ Make sure focus is removed
      if (_ipFocusNodes[0].hasFocus) {
        _ipFocusNodes[0].unfocus();
      }

      // Using Get.snackbar for success message
      Get.snackbar(
        'Success',
        'Local IP saved',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("❌ Save Local IP error: $e");

      // ✅ Unfocus on error
      _unfocusAllTextFields();

      // Show error snackbar
      Get.snackbar(
        'Error',
        'Failed to save Local IP',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> poststoreSetting(String bearerKey, {bool showDialog = true}) async {
    if (!mounted) return; // ✅ Check mounted state

    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    Map<String, dynamic> jsonData = {
      "auto_accept_orders_remote": _autoRemoteOrderrAccept,
      "auto_print_orders_remote": _autoRemoteOrderPrint,
      "auto_accept_orders_local": _autoOrderAccept,
      "auto_print_orders_local": _autoOrderPrint,
      "store_id": storeID
    };

    try {
      // ✅ Show loading dialog only if requested
      if (showDialog) {
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

      // ✅ NEW: Add timeout wrapper around API call
      final result = await Future.any([
        ApiRepo().storeSettingPost(bearerKey, jsonData),
        Future.delayed(Duration(seconds: 10)).then((_) => null) // 10 second timeout
      ]);

      // ✅ NEW: Check if result is null due to timeout
      if (result == null) {
        // ✅ Close loading dialog if timeout occurred
        if (showDialog && Get.isDialogOpen == true) {
          Get.back();
          await Future.delayed(Duration(milliseconds: 300));
        }

        // ✅ IMPORTANT: Unfocus on timeout
        _unfocusAllTextFields();

        if (showDialog) {
          Get.snackbar(
            'Timeout',
            'Request timed out. Please try again.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
        }

        throw Exception('Request timeout after 10 seconds');
      }
      if (showDialog && Get.isDialogOpen == true) {
        Get.back();
        // ✅ Wait for dialog to close completely before showing next one
        await Future.delayed(Duration(milliseconds: 300));
      }

      if (mounted) {
        setState(() {
          print("StoreSettigData " + result.toString());
        });
      }

      // ✅ Show success animation dialog only if requested
      if (showDialog) {
        Get.dialog(
          Center(
              child: Lottie.asset(
                'assets/animations/Success.json',
                width: 150,
                height: 150,
                repeat: false, // Don't repeat success animation
              )
          ),
          barrierDismissible: false,
        );

        // ✅ Wait for success animation to complete, then close and show snackbar
        await Future.delayed(Duration(seconds: 2));

        if (Get.isDialogOpen == true) {
          Get.back();
        }

        // ✅ Wait for success dialog to close before proceeding
        await Future.delayed(Duration(milliseconds: 200));

        // ✅ IMPORTANT: Ensure focus is removed after success dialog
        _unfocusAllTextFields();

        // ✅ Show success snackbar
        Get.snackbar(
          'Success',
          'Settings updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }

      return; // ✅ Return on success

    } catch (e) {
      // ✅ Close loading dialog (only if we showed it) with proper delay
      if (showDialog && Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200)); // ✅ Wait for dialog to close
      }

      // ✅ IMPORTANT: Unfocus on any exception
      _unfocusAllTextFields();

      Log.loga(title, "Login Api:: e >>>>> $e");

      if (showDialog) {
        // ✅ NEW: Different error message for timeout vs other errors
        String errorMessage = e.toString().contains('timeout')
            ? 'Request timed out. Please check your connection and try again.'
            : 'An error occurred: $e';

        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }

      rethrow; // ✅ Rethrow to handle in _saveIps
    }
  }

  Future<void> getStoreSetting(String bearerKey) async {
    if (!mounted) return; // ✅ Check mounted state

    try {
      print("🌐 Calling getStoreSetting API... (Tab active: $_isCurrentTab)");

      // ✅ IMPORTANT: Unfocus before API call
      _unfocusAllTextFields();

      // ✅ FIX: Show loading dialog IMMEDIATELY if this is the current active tab
      if (_isCurrentTab) {
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

      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      final result = await ApiRepo().getStoreSetting(bearerKey, storeID!);

      if (_isCurrentTab && Get.isDialogOpen == true) {
        Get.back();
      }

      if (result != null && mounted) {
        StoreSetting store = result;

        // ✅ Get SharedPreferences instance
        final prefs = await SharedPreferences.getInstance();

        setState(() {
          // API response se toggle values set karo
          _autoOrderPrint = store.auto_print_orders_local ?? false;
          _autoRemoteOrderrAccept = store.auto_accept_orders_remote ?? false;
          _autoOrderAccept = store.auto_accept_orders_local ?? false;
          _autoRemoteOrderPrint = store.auto_print_orders_remote ?? false;
          _hasUnsavedChanges = false;
          print("✅ Settings loaded from API (Tab: $_isCurrentTab):");
          print("🔍 Auto Accept Local: $_autoOrderAccept");
          print("🔍 Auto Print Local: $_autoOrderPrint");
          print("🔍 Auto Accept Remote: $_autoRemoteOrderrAccept");
          print("🔍 Auto Print Remote: $_autoRemoteOrderPrint");
        });

        // ✅ SharedPreferences me save karo - IMPORTANT: Use correct keys
        await prefs.setBool('auto_order_accept', _autoOrderAccept);
        await prefs.setBool('auto_order_print', _autoOrderPrint);
        await prefs.setBool('auto_order_remote_accept', _autoRemoteOrderrAccept);
        await prefs.setBool('auto_order_remote_print', _autoRemoteOrderPrint);

        print("✅ Settings saved to SharedPreferences after API call");

        // ✅ Verify saved values
        bool savedAccept = prefs.getBool('auto_order_accept') ?? false;
        bool savedPrint = prefs.getBool('auto_order_print') ?? false;
        print("🔍 Verified - Auto Accept: $savedAccept, Auto Print: $savedPrint");

        // ✅ IMPORTANT: Ensure focus remains removed after API success
        Future.delayed(Duration(milliseconds: 100), () {
          _unfocusAllTextFields();
        });

      } else {
        _unfocusAllTextFields();
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      if (_isCurrentTab && Get.isDialogOpen == true) {
        Get.back();
      }

      // ✅ IMPORTANT: Unfocus on error
      _unfocusAllTextFields();

      Log.loga(title, "getStoreSetting Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> _setToggle(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);

      // Verify it was saved
      bool saved = prefs.getBool(key) ?? false;
      print("✅ Setting '$key' set to $value, verified: $saved");
    } catch (e) {
      print("❌ Failed to save setting '$key': $e");
    }
  }

  // ──────────────────────────────────────────────────  UI HELPERS
  Widget _buildIpField(int index) {
    return Column(
      children: [
        Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _selectedIpIndex,
              onChanged: (value) => setState(() => _selectedIpIndex = value!),
            ),
            Expanded(
              child: TextFormField(
                controller: _ipControllers[index],
                focusNode: _ipFocusNodes[index], // ✅ Assign focus node
                enabled: index == _selectedIpIndex,
                decoration: InputDecoration(
                  labelText: 'Local IP Address',
                  hintText: 'e.g. 192.168.1.100',
                  border: OutlineInputBorder(),
                  errorText: _validateIP(_ipControllers[index].text),
                ),
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  if (mounted) {
                    setState(() {}); // Trigger rebuild to show validation
                  }
                },
                // ✅ IMPORTANT: Handle form submission
                onFieldSubmitted: (value) {
                  _ipFocusNodes[index].unfocus();
                },
                // ✅ IMPORTANT: Handle tap outside
                onTapOutside: (event) {
                  _ipFocusNodes[index].unfocus();
                },
              ),
            ),
          ],
        ),
        // Show current saved IP
        if (_ipControllers[index].text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 4),
            child: Row(
              children: [
                Icon(
                  _validateIP(_ipControllers[index].text) == null
                      ? Icons.check_circle
                      : Icons.error,
                  color: _validateIP(_ipControllers[index].text) == null
                      ? Colors.green
                      : Colors.red,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  _validateIP(_ipControllers[index].text) == null
                      ? 'Valid IP format'
                      : 'Invalid IP format',
                  style: TextStyle(
                    fontSize: 12,
                    color: _validateIP(_ipControllers[index].text) == null
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Add this validation method to your class:
  String? _validateIP(String ip) {
    if (ip.isEmpty) return null;

    // Basic IP validation
    final parts = ip.split('.');
    if (parts.length != 4) return 'IP must have 4 parts';

    for (String part in parts) {
      if (part.isEmpty) return 'Empty part in IP';

      int? num = int.tryParse(part);
      if (num == null) return 'Invalid number in IP';
      if (num < 0 || num > 255) return 'Number must be 0-255';
    }

    return null; // Valid IP
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      onTap: () {
        // ✅ IMPORTANT: Unfocus when tapping outside
        _unfocusAllTextFields();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                const Text(
                  'Local IP',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w500),
                ),
                _buildIpField(0),
                Center(
                  child: Container(
                    margin: EdgeInsets.all(15),
                    child: ElevatedButton(
                      onPressed: _saveLocalIps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[300],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                      ),
                      child: const Text('Save Local IP'),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _ToggleRow(
                  label: 'Auto Order Print',
                  activeColor: Colors.blue,
                  value: _autoOrderPrint,
                  onChanged: (val) async {
                    _unfocusAllTextFields();

                    if (mounted) {
                      setState(() {
                        _autoOrderPrint = val;
                        _hasUnsavedChanges = true;
                      });
                    }

                    // ✅ CRITICAL: Use multiple approaches to ensure saving
                    try {
                      // Method 1: Use existing instance
                      await sharedPreferences.setBool('auto_order_print', val);
                      await sharedPreferences.reload();

                      // Method 2: Create fresh instance and verify
                      final freshPrefs = await SharedPreferences.getInstance();
                      await freshPrefs.setBool('auto_order_print', val);
                      await freshPrefs.reload();

                      // Method 3: Verify the save worked
                      bool savedValue = freshPrefs.getBool('auto_order_print') ?? false;

                      if (savedValue == val) {
                        print("✅ Auto Order Print toggled to: $val and VERIFIED in SharedPreferences");
                      } else {
                        print("❌ Auto Order Print save verification FAILED! Expected: $val, Got: $savedValue");
                        // Try again with delay
                        await Future.delayed(Duration(milliseconds: 200));
                        await freshPrefs.setBool('auto_order_print', val);
                        await freshPrefs.reload();
                      }

                      // ✅ ADDITIONAL: Force background handler to refresh its cache
                      await _triggerBackgroundSettingsRefresh();

                    } catch (e) {
                      print("❌ Error saving Auto Order Print: $e");
                    }
                  },
                ),

                _ToggleRow(
                  label: 'Auto Order Remote Accept',
                  activeColor: Colors.green,
                  value: _autoRemoteOrderrAccept,
                  onChanged: (val) async {
                    _unfocusAllTextFields();

                    if (mounted) {
                      setState(() {
                        _autoRemoteOrderrAccept = val;
                        _hasUnsavedChanges = true;
                      });
                    }

                    // ✅ CRITICAL: Use multiple approaches to ensure saving
                    try {
                      // Method 1: Use existing instance
                      await sharedPreferences.setBool('auto_order_remote_accept', val);
                      await sharedPreferences.reload();

                      // Method 2: Create fresh instance and verify
                      final freshPrefs = await SharedPreferences.getInstance();
                      await freshPrefs.setBool('auto_order_remote_accept', val);
                      await freshPrefs.reload();

                      // Method 3: Verify the save worked
                      bool savedValue = freshPrefs.getBool('auto_order_remote_accept') ?? false;

                      if (savedValue == val) {
                        print("✅ Auto Order Remote Accept toggled to: $val and VERIFIED in SharedPreferences");
                      } else {
                        print("❌ Auto Order Remote Accept save verification FAILED! Expected: $val, Got: $savedValue");
                        // Try again with delay
                        await Future.delayed(Duration(milliseconds: 200));
                        await freshPrefs.setBool('auto_order_remote_accept', val);
                        await freshPrefs.reload();
                      }

                      // ✅ ADDITIONAL: Force background handler to refresh its cache
                      await _triggerBackgroundSettingsRefresh();

                    } catch (e) {
                      print("❌ Error saving Auto Order Remote Accept: $e");
                    }
                  },
                ),

                _ToggleRow(
                  label: 'Auto Order Remote Print',
                  activeColor: Colors.blue.shade400,
                  value: _autoRemoteOrderPrint,
                  onChanged: (val) async {
                    _unfocusAllTextFields();
                    if (mounted) {
                      setState(() {
                        _autoRemoteOrderPrint = val;
                        _hasUnsavedChanges = true;
                      });
                    }

                    // ✅ CRITICAL: Use multiple approaches to ensure saving
                    try {
                      await sharedPreferences.setBool('auto_order_remote_print', val);
                      await sharedPreferences.reload();

                      // Method 2: Create fresh instance and verify
                      final freshPrefs = await SharedPreferences.getInstance();
                      await freshPrefs.setBool('auto_order_remote_print', val);
                      await freshPrefs.reload();

                      // Method 3: Verify the save worked
                      bool savedValue = freshPrefs.getBool('auto_order_remote_print') ?? false;

                      if (savedValue == val) {
                        print("✅ Auto Order Remote Print toggled to: $val and VERIFIED in SharedPreferences");
                      } else {
                        print("❌ Auto Order Remote Print save verification FAILED! Expected: $val, Got: $savedValue");
                        // Try again with delay
                        await Future.delayed(Duration(milliseconds: 200));
                        await freshPrefs.setBool('auto_order_remote_print', val);
                        await freshPrefs.reload();
                      }

                      // ✅ ADDITIONAL: Force background handler to refresh its cache
                      await _triggerBackgroundSettingsRefresh();

                    } catch (e) {
                      print("❌ Error saving Auto Order Remote Print: $e");
                    }
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: (_hasUnsavedChanges && !_isSaving) ? _saveIps : null, // ✅ NEW: Conditional
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_hasUnsavedChanges && !_isSaving)
                          ? Colors.green[300]
                          : Colors.grey[300], // ✅ NEW: Visual feedback
                      foregroundColor: (_hasUnsavedChanges && !_isSaving)
                          ? Colors.black
                          : Colors.grey[600], // ✅ NEW: Visual feedback
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Save IPs'), // ✅ NEW: Dynamic text
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ✅ ADD THIS METHOD TO YOUR PrinterSettingsScreen class
  Future<void> _triggerBackgroundSettingsRefresh() async {
    try {
      // Create multiple fresh instances to ensure background handler will see the changes
      for (int i = 0; i < 3; i++) {
        final testPrefs = await SharedPreferences.getInstance();
        await testPrefs.reload();
        await Future.delayed(Duration(milliseconds: 100));
      }

      print("🔄 Background settings refresh triggered");
    } catch (e) {
      print("❌ Error triggering background settings refresh: $e");
    }
  }

}

// ──────────────────────────────────────────────────  TOGGLE ROW WIDGET
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}