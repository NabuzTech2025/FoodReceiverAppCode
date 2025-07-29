import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../api/api.dart';
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
  int _selectedIpIndex = 0;
  int _selectedRemoteIpIndex = 0;

  // ──────────────────────────────────────────────────  NEW TOGGLES
  bool _autoOrderAccept = false;
  bool _autoOrderPrint = false;
  bool _autoRemoteOrderrAccept = false;
  bool _autoRemoteOrderPrint = false;
  bool _testEnvironment = false;
  String? bearerKey;
  late SharedPreferences sharedPreferences;

  // ✅ Tab tracking variables
  int? _lastTabIndex;
  bool _isCurrentTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharedPrefsAndLoadSettings();
    _setupTabListener();
  }

  // ✅ Setup tab change listener using GetX controller
  void _setupTabListener() {
    // Use the reactive getter from AppController
    ever(app.appController.selectedTabIndexRx, (int tabIndex) {
      _handleTabChange(tabIndex);
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

      // Add a small delay to ensure UI is ready
      Future.delayed(Duration(milliseconds: 300), () {
        _refreshSettings();
      });
    } else {
      _isCurrentTab = isNowCurrentTab;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _ipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ✅ App lifecycle detection (for app foreground/background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isCurrentTab) {
      print("📱 App resumed and on printer settings tab, refreshing...");
      Future.delayed(Duration(milliseconds: 500), () {
        _refreshSettings();
      });
    }
  }

  // ✅ Refresh settings method
  Future<void> _refreshSettings() async {
    if (bearerKey != null && bearerKey!.isNotEmpty) {
      print("🔄 Refreshing settings from server...");
      await getStoreSetting(bearerKey!);
    } else {
      print("⚠️ No bearer key available for refresh");
    }
  }

  Future<void> _initSharedPrefsAndLoadSettings() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    print("🔑 Bearer Key found: ${bearerKey != null}");

    await _loadSavedSettings();

    if (bearerKey != null) {
      await getStoreSetting(bearerKey!);
    }
  }

  // ──────────────────────────────────────────────────  PREFERENCES
  Future<void> _loadSavedSettings() async {
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

      setState(() {}); // trigger rebuild with loaded values

      print("✅ Local settings loaded from SharedPreferences");
    } catch (e) {
      print("❌ Error loading settings: $e");
    }
  }

  Future<void> _saveIps() async {
    try {
      await poststoreSetting(bearerKey!);
      await Future.delayed(Duration(seconds: 1));
      await SettingsSync.syncSettingsAfterLogin();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings synced')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings')),
      );
    }
  }

  Future<void> _saveLocalIps() async {
    try {
      final prefs = sharedPreferences;
      String ip = _ipControllers[0].text.trim();

      if (ip.isEmpty || _validateIP(ip) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid Local IP')),
        );
        return;
      }

      await prefs.setString('printer_ip_0', ip);
      await prefs.setInt('selected_ip_index', _selectedIpIndex);

      if (bearerKey != null && bearerKey!.isNotEmpty) {
        await poststorePrinting(bearerKey!, false, ip);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local IP saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Save Local IP error: $e");
    }
  }


  Future<void> _saveRemoteIps() async {
    final prefs = await SharedPreferences.getInstance();
    var idAddress;
    for (int i = 0; i < 1; i++) {
      await prefs.setString(
          'printer_ip_remote_$i', _ipRemoteControllers[i].text);
      idAddress = _ipRemoteControllers[i].text;
    }
    await prefs.setInt('selected_ip_remote_index', _selectedRemoteIpIndex);

    poststorePrinting(bearerKey!, true, idAddress);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer Remote IPs saved')),
    );
  }

  Future<void> poststoreSetting(String bearerKey) async {
    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    Map<String, dynamic> jsonData = {
      "auto_accept_orders_remote": _autoRemoteOrderrAccept,
      "auto_print_orders_remote": _autoRemoteOrderPrint,
      "auto_accept_orders_local": _autoOrderAccept,
      "auto_print_orders_local": _autoOrderPrint,
      "store_id": storeID
    };

    try {
      final result = await ApiRepo().storeSettingPost(bearerKey, jsonData);

      if (result != null) {
        setState(() {
          print("StoreSettigData " + result.toString());
        });
      } else {
        showSnackbar("Error", "Failed to update order status");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> poststorePrinting(String bearerKey, bool remote, String ipAddress) async {
    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
    Map<String, dynamic> jsonData = {
      "name": "",
      "ip_address": ipAddress,
      "store_id": storeID,
      "isActive": true,
      "type": 0,
      "category_id": 0,
      "isRemote": remote,
    };

    try {
      final result = await ApiRepo().printerSettingPost(bearerKey, jsonData);

      if (result != null) {
        setState(() {
          print("StoreSettigData " + result.toString());
        });
      } else {
        showSnackbar("Error", "Failed to update order status");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  // ✅ Enhanced getStoreSetting with better logging
  Future<void> getStoreSetting(String bearerKey) async {
    try {
      print("🌐 Calling getStoreSetting API... (Tab active: $_isCurrentTab)");

      // Only show loading if this is the current active tab
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

      if (result != null) {
        StoreSetting store = result;

        // ✅ Get SharedPreferences instance
        final prefs = await SharedPreferences.getInstance();

        setState(() {
          // API response se toggle values set karo
          _autoOrderPrint = store.auto_print_orders_local ?? false;
          _autoRemoteOrderrAccept = store.auto_accept_orders_remote ?? false;
          _autoOrderAccept = store.auto_accept_orders_local ?? false;
          _autoRemoteOrderPrint = store.auto_print_orders_remote ?? false;

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

      } else {
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      if (_isCurrentTab && Get.isDialogOpen == true) {
        Get.back();
      }
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
                enabled: index == _selectedIpIndex,
                decoration: InputDecoration(
                  labelText: 'Local IP Address',
                  hintText: 'e.g. 192.168.1.100',
                  border: OutlineInputBorder(),
                  errorText: _validateIP(_ipControllers[index].text),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to show validation
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
      onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header with refresh button and tab indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Tab Active: ${_isCurrentTab ? "Yes" : "No"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isCurrentTab ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        print("🔄 Manual refresh triggered");
                        _refreshSettings();
                      },
                      icon: Icon(Icons.refresh, color: Colors.blue),
                      tooltip: 'Refresh Settings',
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
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
                    setState(() => _autoOrderPrint = val);

                    // ✅ Immediately save to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('auto_order_print', val);

                    print("✅ Auto Order Print toggled to: $val and saved to SharedPreferences");
                  },
                ),

                _ToggleRow(
                  label: 'Auto Order Remote Accept',
                  activeColor: Colors.green,
                  value: _autoRemoteOrderrAccept,
                  onChanged: (val) async {
                    setState(() => _autoRemoteOrderrAccept = val);

                    // ✅ Immediately save to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('auto_order_remote_accept', val);

                    print("✅ Auto Order Remote Accept toggled to: $val and saved to SharedPreferences");
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveIps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[300],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                    ),
                    child: const Text('Save IPs'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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