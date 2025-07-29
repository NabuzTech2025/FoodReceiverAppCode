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
import 'LoginScreen.dart';

class PrinterSettingsScreen extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  //getStoreSetting(bearerKey!);
  }

  // ──────────────────────────────────────────────────  PREFERENCES
  Future<void> _loadSavedSettings() async {
    try {
      print("📱 Loading saved settings...");

      sharedPreferences = await SharedPreferences.getInstance();
      final prefs = await SharedPreferences.getInstance();

      // Force reload to get latest data
      await prefs.reload();

      bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
      print("🔑 Bearer key found: ${bearerKey != null ? 'YES' : 'NO'}");

      if (bearerKey != null) {
        getStoreSetting(bearerKey!);
      }

      setState(() {
        _selectedIpIndex = prefs.getInt('selected_ip_index') ?? 0;
        _selectedRemoteIpIndex = prefs.getInt('selected_ip_remote_index') ?? 0;
        _autoOrderAccept = prefs.getBool('auto_order_accept') ?? false;
        _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
        _autoRemoteOrderrAccept = prefs.getBool('auto_order_remote_accept') ?? false;
        _autoRemoteOrderPrint = prefs.getBool('auto_order_remote_print') ?? false;
        _testEnvironment = prefs.getBool('test_environment') ?? false;

        // ✅ Load IP addresses with detailed logging
        for (int i = 0; i < 1; i++) {
          String savedIp = prefs.getString('printer_ip_$i') ?? '';
          _ipControllers[i].text = savedIp;
          print("📍 Loaded printer_ip_$i: '$savedIp'");
        }

        for (int i = 0; i < 1; i++) {
          String savedRemoteIp = prefs.getString('printer_ip_remote_$i') ?? '';
          _ipRemoteControllers[i].text = savedRemoteIp;
          print("📍 Loaded printer_ip_remote_$i: '$savedRemoteIp'");
        }

        print("✅ Settings loaded:");
        print("🔍 Selected IP Index: $_selectedIpIndex");
        print("🔍 Auto Order Accept: $_autoOrderAccept");
        print("🔍 Auto Order Print: $_autoOrderPrint");
        print("🔍 Auto Remote Accept: $_autoRemoteOrderrAccept");
        print("🔍 Auto Remote Print: $_autoRemoteOrderPrint");
      });

    } catch (e) {
      print("❌ Error loading saved settings: $e");
    }
  }
  Future<void> _saveIps() async {
    try {
      // Save to server
      await poststoreSetting(bearerKey!);

      // ✅ IMPORTANT: Sync settings back from server to ensure consistency
      await Future.delayed(Duration(seconds: 1)); // Give server time to save
      await SettingsSync.syncSettingsAfterLogin();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer auto order saved and synced')),
      );
    } catch (e) {
      print("❌ Error saving settings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings')),
      );
    }
  }

  Future<void> _saveLocalIps() async {
    try {
      print("💾 Starting to save local IP...");

      final prefs = await SharedPreferences.getInstance();
      String ipAddress = _ipControllers[0].text.trim();

      print("🔍 IP Address to save: '$ipAddress'");

      if (ipAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid IP address')),
        );
        return;
      }

      // ✅ FIRST: Save to SharedPreferences immediately
      await prefs.setString('printer_ip_0', ipAddress);
      await prefs.setInt('selected_ip_index', _selectedIpIndex);

      // ✅ Force reload to ensure it's saved
      await prefs.reload();

      // ✅ Verify it was saved
      String? savedIp = prefs.getString('printer_ip_0');
      int? savedIndex = prefs.getInt('selected_ip_index');

      print("✅ Saved to SharedPreferences:");
      print("🔍 printer_ip_0: '$savedIp'");
      print("🔍 selected_ip_index: $savedIndex");

      if (savedIp != ipAddress) {
        print("❌ Failed to save IP to SharedPreferences!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save IP locally')),
        );
        return;
      }

      // ✅ THEN: Try to save to server (don't fail if this fails)
      try {
        if (bearerKey != null && bearerKey!.isNotEmpty) {
          await poststorePrinting(bearerKey!, false, ipAddress);
          print("✅ Also saved to server successfully");
        } else {
          print("⚠️ No bearer key, skipping server save");
        }
      } catch (e) {
        print("⚠️ Server save failed but local save succeeded: $e");
        // Don't show error to user since local save worked
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer Local IP saved to device'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print("❌ Error saving local IP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save local IP: $e')),
      );
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

  // Future<void> getStoreSetting(String bearerKey) async {
  //   try {
  //     String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
  //     final result = await ApiRepo().getStoreSetting(bearerKey, storeID!);
  //
  //     if (result != null) {
  //       StoreSetting store = result;
  //       setState(() {
  //         print("RespnseStoreSetting " + result.toString()!);
  //       });
  //     } else {
  //       showSnackbar("Error", "Failed to get store data");
  //     }
  //   } catch (e) {
  //     Log.loga(title, "Login Api:: e >>>>> $e");
  //     showSnackbar("Api Error", "An error occurred: $e");
  //   }
  // }

  Future<void> getStoreSetting(String bearerKey) async {
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

      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      final result = await ApiRepo().getStoreSetting(bearerKey, storeID!);
      Get.back();

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

          print("✅ Settings loaded from API:");
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

        print("✅ Settings saved to SharedPreferences");

        // ✅ Verify saved values
        bool savedAccept = prefs.getBool('auto_order_accept') ?? false;
        bool savedPrint = prefs.getBool('auto_order_print') ?? false;
        print("🔍 Verified - Auto Accept: $savedAccept, Auto Print: $savedPrint");

      } else {
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      Get.back();
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
  // Replace your _buildIpField method with this enhanced version:

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

  // Widget _buildRemoteIpField(int index) {
  //   return Row(
  //     children: [
  //       Radio<int>(
  //         value: index,
  //         groupValue: _selectedRemoteIpIndex,
  //         onChanged: (value) => setState(() => _selectedRemoteIpIndex = value!),
  //       ),
  //       Expanded(
  //         child: TextFormField(
  //           controller: _ipRemoteControllers[index],
  //           enabled: index == _selectedRemoteIpIndex,
  //           decoration: InputDecoration(
  //             labelText: 'Remote IP Address',
  //             /*${index + 1}*/
  //             hintText: 'e.g. 192.168.0.${100 + index}',
  //           ),
  //           keyboardType: TextInputType.text,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
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
                // Text(
                //   'Remote IP',
                //   style: TextStyle(
                //       color: Colors.black, fontWeight: FontWeight.w500),
                // ),
                // _buildRemoteIpField(0),
                // Center(
                //   child: Container(
                //     margin: EdgeInsets.all(15),
                //     child: ElevatedButton(
                //       onPressed: _saveRemoteIps,
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.green[300],
                //         foregroundColor: Colors.black,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(50),
                //         ),
                //         padding: const EdgeInsets.symmetric(
                //             horizontal: 30, vertical: 14),
                //       ),
                //       child: const Text('Save Remote IP'),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 15),
                // _ToggleRow(
                //   label: 'Auto Order Accept',
                //   activeColor: Colors.green,
                //   value: _autoOrderAccept,
                //   onChanged: (val) {
                //     setState(() => _autoOrderAccept = val);
                //     _setToggle('auto_order_accept', val);
                //   },
                // ),
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
                // _ToggleRow(
                //   label: 'Auto Order Remote Print',
                //   activeColor: Colors.blue,
                //   value: _autoRemoteOrderPrint,
                //   onChanged: (val) {
                //     setState(() => _autoRemoteOrderPrint = val);
                //     _setToggle('auto_order_remote_print', val);
                //   },
                // ),
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

  @override
  void dispose() {
    for (var controller in _ipControllers) {
      controller.dispose();
    }
    super.dispose();
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
