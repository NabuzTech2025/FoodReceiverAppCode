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
    sharedPreferences = await SharedPreferences.getInstance();
    final prefs = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
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

      for (int i = 0; i < 1; i++) {
        _ipControllers[i].text = prefs.getString('printer_ip_$i') ?? '';
      }
      for (int i = 0; i < 1; i++) {
        _ipRemoteControllers[i].text = prefs.getString('printer_ip_remote_$i') ?? '';
      }
    });
  }

  Future<void> _saveIps() async {
/*
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < 3; i++) {
      await prefs.setString('printer_ip_$i', _ipControllers[i].text);
    }
    await prefs.setInt('selected_ip_index', _selectedIpIndex);
*/

    poststoreSetting(bearerKey!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer auto order saved')),
    );
  }

  Future<void> _saveLocalIps() async {
    final prefs = await SharedPreferences.getInstance();

    var idAddress;
    for (int i = 0; i < 1; i++) {
      await prefs.setString('printer_ip_$i', _ipControllers[i].text);
      idAddress = _ipControllers[i].text;
    }
    await prefs.setInt('selected_ip_index', _selectedIpIndex);

    poststorePrinting(bearerKey!, false, idAddress);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer Local IPs saved')),
    );
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
        setState(() {
          // API response se toggle values set karo
          _autoOrderPrint = store.auto_print_orders_local ?? false;
          _autoRemoteOrderrAccept = store.auto_accept_orders_remote ?? false;
          _autoOrderAccept = store.auto_accept_orders_local ?? false;
          _autoRemoteOrderPrint = store.auto_print_orders_remote ?? false;

          print("RespnseStoreSetting " + result.toString()!);
        });

        // SharedPreferences me bhi save karo
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auto_order_print', _autoOrderPrint);
        await prefs.setBool('auto_order_remote_accept', _autoRemoteOrderrAccept);
        await prefs.setBool('auto_order_accept', _autoOrderAccept);
        await prefs.setBool('auto_order_remote_print', _autoRemoteOrderPrint);

      } else {
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      Get.back();
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> _setToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ──────────────────────────────────────────────────  UI HELPERS
  Widget _buildIpField(int index) {
    return Row(
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
              /* ${index + 1}*/
              hintText: 'e.g. 192.168.0.${100 + index}',
            ),
            keyboardType: TextInputType.text,
          ),
        ),
      ],
    );
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
                  onChanged: (val) {
                    setState(() => _autoOrderPrint = val);
                    _setToggle('auto_order_print', val);
                  },
                ),
                _ToggleRow(
                  label: 'Auto Order Remote Accept',
                  activeColor: Colors.green,
                  value: _autoRemoteOrderrAccept,
                  onChanged: (val) {
                    setState(() => _autoRemoteOrderrAccept = val);
                    _setToggle('auto_order_remote_accept', val);
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
