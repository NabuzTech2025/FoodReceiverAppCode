
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../models/get_printer_ip_response_model.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>  with AutomaticKeepAliveClientMixin, WidgetsBindingObserver{
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _newIpController = TextEditingController();
  final FocusNode _ipFocusNode = FocusNode();
  final TextEditingController _syncTimeController = TextEditingController();
  final FocusNode _syncTimeFocusNode = FocusNode();
  bool isLoading =false;
  bool _autoRemoteOrderrAccept = false;
  List<IpAddressItem> _ipAddresses = [];
  late SharedPreferences sharedPreferences;
  List<GetPrinterIpResponseModel> ip = [];
  String? storeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharedPrefs();
  }

  Future<void> _initSharedPrefs() async {
    sharedPreferences = await SharedPreferences.getInstance();
    await getPrinterIp();
    await _loadSettings();
    String? savedSyncTime = sharedPreferences.getString('sync_time');
    if (savedSyncTime != null && savedSyncTime.isNotEmpty) {
      _syncTimeController.text = savedSyncTime;
    }
  }
    @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      print("📱 App resumed on Printer Settings, refreshing...");
      _refreshData();
    }
  }

  // ✅ Add this method - detect when screen becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if this screen just became visible
    if (ModalRoute.of(context)?.isCurrent == true) {
      print("🔄 Printer Settings became visible, refreshing...");
      _refreshData();
    }
  }

  // ✅ Add this refresh method
  Future<void> _refreshData() async {
    if (!mounted) return;

    print("🔄 Refreshing printer settings data...");
    await getPrinterIp(showLoader: false);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // First load local cache
    setState(() {
      _autoRemoteOrderrAccept = sharedPreferences.getBool('auto_order_remote_accept') ?? false;

      if (ip.isNotEmpty) {
        _ipAddresses = ip.map((item) => IpAddressItem(
          ip: item.ipAddress ?? '',
          isActive: item.isActive ?? false,
        )).toList();
      }
    });

    // Then fetch from server
    String? bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    if (bearerKey != null && bearerKey.isNotEmpty) {
      await getStoreSetting(bearerKey);
    }
  }

  Future<void> _saveSettings() async {
    await sharedPreferences.setBool('auto_accept', _autoRemoteOrderrAccept);

    List<String> ips = _ipAddresses.map((e) => e.ip).toList();
    List<String> statuses = _ipAddresses.map((e) => e.isActive.toString()).toList();

    await sharedPreferences.setStringList('ip_addresses', ips);
    await sharedPreferences.setStringList('ip_statuses', statuses);
  }

  void _toggleIpStatus(int index) {
    setState(() {
      _ipAddresses[index].isActive = !_ipAddresses[index].isActive;
    });
    _saveSettings();
  }

  void _editIpAddress(int index) {
    TextEditingController editController = TextEditingController(
        text: _ipAddresses[index].ip
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Edit IP Address'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'IP Address',
            hintText: 'e.g. 192.168.1.100',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {  // ✅ Make it async
              String newIp = editController.text.trim();
              String? validation = _validateIP(newIp);

              if (validation != null) {
                Get.snackbar(
                  'Invalid IP',
                  validation,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();  // ✅ Close dialog first

              // ✅ Get printer ID and call API
              if (ip.isNotEmpty && index < ip.length) {
                String printerId = ip[index].id.toString();
                bool success = await editPrinterIp(printerId, newIp);

                // ✅ Only update local state if API succeeds
                // The getPrinterIp call inside editPrinterIp will refresh the list
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to edit. Please refresh and try again.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[300],
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _validateIP(String ip) {
    if (ip.isEmpty) return 'IP address cannot be empty';

    final parts = ip.split('.');
    if (parts.length != 4) return 'IP must have 4 parts separated by dots';

    for (String part in parts) {
      if (part.isEmpty) return 'IP parts cannot be empty';

      int? num = int.tryParse(part);
      if (num == null) return 'Each part must be a number';
      if (num < 0 || num > 255) return 'Each part must be between 0-255';
    }

    return null;
  }

  @override
  void dispose() {
    _newIpController.dispose();
    _ipFocusNode.dispose();
    _syncTimeController.dispose();
    _syncTimeFocusNode.dispose();
    super.dispose();
  }
  Future<void> _saveSyncTime() async {
    String syncTime = _syncTimeController.text.trim();

    if (syncTime.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_enter_sync'.tr),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
      return;
    }

    // Validate if it's a number
    int? syncTimeValue = int.tryParse(syncTime);
    if (syncTimeValue == null || syncTimeValue <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_enter_valid'.tr),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
      return;
    }

    try {
      await sharedPreferences.setString('sync_time', syncTime);
      _syncTimeFocusNode.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('sync_time_saved'.tr),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      print('Error saving sync time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_save_sync'.tr),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () => _ipFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Auto Accept Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                     Expanded(
                      child: Text(
                        'auto_order'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Switch(
                      value: _autoRemoteOrderrAccept,
                      activeThumbColor: Colors.green,
                      onChanged: (val) async {
                        setState(() {
                          _autoRemoteOrderrAccept = val;
                        });
                        await poststoreSetting(val, showDialog: true);
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sync_time'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _syncTimeController,
                            focusNode: _syncTimeFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 30',
                              suffixText: 'seconds'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onFieldSubmitted: (value) => _saveSyncTime(),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveSyncTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[300],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'saved'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // IP Address List Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child:  Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'ip'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'status'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'action'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // IP Address List
              Expanded(
                child: _ipAddresses.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_ip'.tr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _ipAddresses.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // IP Address
                            Expanded(
                              flex: 4,
                              child: Text(
                                _ipAddresses[index].ip,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            // Status Toggle
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => _toggleIpStatus(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _ipAddresses[index].isActive
                                          ? Colors.green[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _ipAddresses[index].isActive
                                          ? 'active'.tr
                                          : 'inactive'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _ipAddresses[index].isActive
                                            ? Colors.green[800]
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Actions
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.blue,
                                    onPressed: () => _editIpAddress(index),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: Colors.red,

                                    onPressed: () {

                                      if (ip.isNotEmpty && index < ip.length) {
                                        String printerId = ip[index].id.toString();
                                        String ipAddress = _ipAddresses[index].ip;
                                        showDeleteDialog(context, ipAddress, printerId);
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                             SnackBar(
                                              content: Text('unable_to'.tr),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Add New IP Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'enter_new'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newIpController,
                      focusNode: _ipFocusNode,
                      decoration: InputDecoration(
                        hintText: 'e.g. 192.168.1.100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      //onFieldSubmitted: (value) => _addIpAddress(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        String newIp = _newIpController.text.trim();

                        if (newIp.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('please_enter_ip'.tr),
                                backgroundColor: Colors.red,
                                duration: Duration(milliseconds: 100),
                              ),
                            );
                          }
                          return;
                        }

                        String? validation = _validateIP(newIp);
                        if (validation != null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(validation),
                                backgroundColor: Colors.red,
                                duration: Duration(milliseconds: 100),
                              ),
                            );
                          }
                          return;
                        }

                        // API call
                        bool success = await addNewIp();

                        if (success) {
                          _newIpController.clear();
                          _ipFocusNode.unfocus();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[300],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:  Text(
                        'saved'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getPrinterIp({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });

      Get.dialog(
        Center(child: Lottie.asset('assets/animations/burger.json',
            width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );
    }

    try {
      // ✅ 6 second timeout wrapper
      final result = await Future.any([CallService().getIpAddress(),
        Future.delayed(Duration(seconds: 6)).then((_) => <GetPrinterIpResponseModel>[])
      ]);

      // ✅ Always close dialog after 6 seconds max
      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          ip = result;
          isLoading = false;
        });
      }
    } catch (e) {
      // ✅ Close dialog on error bhi
      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> addNewIp() async {
    storeId = sharedPreferences.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('storeId'.tr), backgroundColor: Colors.red),
        );
      }
      return false;
    }

    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(Duration(milliseconds: 100));
    }

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json',
          width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "name": "",
        "ip_address": _newIpController.text.trim(),
        "store_id": storeId,
        "isActive": true,
        "type": 0,
        "category_id": 0,
        "isRemote": true
      };

      final result = await Future.any([
        CallService().addNewIp(map),
        Future.delayed(Duration(seconds: 6)).then((_) => null)
      ]);

      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200)); // ✅ Delay add karo
      }

      if (result != null) {
        await getPrinterIp(showLoader: false);
        _loadSettings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ip_added'.tr),
                backgroundColor: Colors.green,
              duration: Duration(milliseconds: 100),
            ),
          );
        }
        return true;
      } else {
        throw Exception('timeout_null'.tr);
      }

    } catch (e) {
      // ✅ Dialog close with delay
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200)); // ✅ Ye bhi add karo
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_ip'.tr}: $e'.tr),
              backgroundColor: Colors.red,
            duration: Duration(milliseconds: 100),
          ),
        );
      }
      return false;
    }
  }

  Future<void> poststoreSetting(bool autoAcceptValue, {bool showDialog = true}) async {
    if (!mounted) return;

    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

    Map<String, dynamic> jsonData = {
      "auto_accept_orders_remote": autoAcceptValue,  // ✅ Use the parameter
      "auto_print_orders_remote": false,
      "auto_accept_orders_local": false,
      "auto_print_orders_local": false,
      "store_id": storeID
    };
    try {
      // ✅ Dialog open karne se pehle check
      if (showDialog) {
        if (Get.isDialogOpen == true) {
          Get.back();
          await Future.delayed(Duration(milliseconds: 100));
        }

        Get.dialog(
          Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
          barrierDismissible: false,
        );
      }

      // ✅ Bearer token properly get karo
      String? bearerToken = sharedPreferences.getString(valueShared_BEARER_KEY);

      if (bearerToken == null || bearerToken.isEmpty) {
        if (showDialog && Get.isDialogOpen == true) {
          Get.back();
          await Future.delayed(Duration(milliseconds: 200));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth'.tr),
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 100),
            ),
          );
        }
        return;
      }

      // ✅ 6 second timeout
      final result = await Future.any([
        ApiRepo().storeSettingPost(bearerToken, jsonData),
        Future.delayed(Duration(seconds: 6)).then((_) => null)
      ]);

      // ✅ Dialog close with delay
      if (showDialog && Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Inside poststoreSetting, after successful API call:
      if (result != null && mounted) {
        // ✅ Save to SharedPreferences
        await sharedPreferences.setBool('auto_order_remote_accept', autoAcceptValue);

        if (showDialog && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('setting_update'.tr),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 100),
            ),
          );
        }
      } else {
        // ✅ Timeout case
        if (showDialog && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('request'.tr),
              backgroundColor: Colors.orange,
              duration: Duration(milliseconds: 100),
            ),
          );
        }
      }

    } catch (e) {
      // ✅ Dialog close on error
      if (showDialog && Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200));
      }

      print("Error: $e");

      if (showDialog && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_update'.tr}: $e'),
            backgroundColor: Colors.red,
              duration: Duration(milliseconds: 100)
          ),
        );
      }
    }
  }

  Future<void> deletePrinterIp(String printerId) async {
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


      await CallService().deleteExistingIp(printerId);

      Get.back();
      await getPrinterIp(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ip_delete'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      Get.back();
        print('${'error_delete'.tr}: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_delete_ip'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void showDeleteDialog(BuildContext context, String ip, String printerId) {
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
                      '${'are'.tr} "$ip"  ?',
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
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(
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
                              deletePrinterIp(printerId);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(
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
                ),
              )
            ]
        ),
      ),
    );
  }

  Future<bool> editPrinterIp(String printerId, String newIpAddress) async {
    storeId = sharedPreferences.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('storeId'.tr),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 100),
          ),
        );
      }
      return false;
    }

    // ✅ Dialog open check
    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(Duration(milliseconds: 100));
    }

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "name": "",
        "ip_address": newIpAddress,  // ✅ Use the passed IP address
        "store_id": storeId,
        "isActive": true,
        "type": 0,
        "category_id": 0,
        "isRemote": true
      };

      // ✅ 6 second timeout
      final result = await Future.any([
        CallService().editIpAddress(map, printerId),
        Future.delayed(Duration(seconds: 6)).then((_) => null)
      ]);

      // ✅ Close dialog with delay
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200));
      }

      if (result != null) {
        await getPrinterIp(showLoader: false);
        _loadSettings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('update_ip'.tr),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 100),
            ),
          );
        }
        return true;
      } else {
        throw Exception('timeout_null'.tr);
      }

    } catch (e) {
      // ✅ Close dialog on error
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(Duration(milliseconds: 200));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_update_ip'.tr}: $e'.tr),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 100),
          ),
        );
      }
      return false;
    }
  }

  Future<void> getStoreSetting(String bearerKey) async {
    if (!mounted) return;

    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID == null) {
        print("❌ Store ID not found");
        return;
      }

      // ✅ 6 second timeout
      final result = await Future.any([
        ApiRepo().getStoreSetting(bearerKey, storeID),
        Future.delayed(Duration(seconds: 6)).then((_) => null)
      ]);

      if (result != null && mounted) {
        setState(() {
          // ✅ Update from server response
          _autoRemoteOrderrAccept = result.auto_accept_orders_remote ?? false;
          // Store in SharedPreferences
          sharedPreferences.setBool('auto_order_remote_accept', _autoRemoteOrderrAccept);
        });

        print("✅ Settings loaded from server: Remote Accept = $_autoRemoteOrderrAccept");
      }
    } catch (e) {
      print("❌ getStoreSetting error: $e");
    }
  }
}


class IpAddressItem {
  String ip;
  bool isActive;

  IpAddressItem({
    required this.ip,
    required this.isActive,
  });
}
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:lottie/lottie.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api/repository/api_repository.dart';
// import '../constants/constant.dart';
// import '../models/StoreSetting.dart';
// import '../utils/log_util.dart';
// import '../utils/my_application.dart';
// import 'LoginScreen.dart';
//
// class PrinterSettingsScreen extends StatefulWidget {
//   @override
//   _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
// }
//
// class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>
//     with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
//
//   // ✅ Keep the widget alive but detect tab changes
//   @override
//   bool get wantKeepAlive => true;
//
//   // ──────────────────────────────────────────────────  PRINTER IPs
//   final List<TextEditingController> _ipControllers = List.generate(1, (_) => TextEditingController());
//   final List<TextEditingController> _ipRemoteControllers =
//   List.generate(1, (_) => TextEditingController());
//   final List<FocusNode> _ipFocusNodes = List.generate(1, (_) => FocusNode());
//   final List<FocusNode> _ipRemoteFocusNodes = List.generate(1, (_) => FocusNode());
//
//   int _selectedIpIndex = 0;
//   int _selectedRemoteIpIndex = 0;
//
//   // ──────────────────────────────────────────────────  NEW TOGGLES
//   bool _autoOrderAccept = false;
//   bool _autoOrderPrint = false;
//   bool _autoRemoteOrderrAccept = false;
//   bool _autoRemoteOrderPrint = false;
//   String? bearerKey;
//   late SharedPreferences sharedPreferences;
//   bool _hasUnsavedChanges = false;
//   bool _isSaving = false;
//   // ✅ Tab tracking variables
//   int? _lastTabIndex;
//   bool _isCurrentTab = false;
//   Worker? _tabWorker;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _debugSharedPreferences().then((_) {
//       _initSharedPrefsAndLoadSettings();
//     });
//
//     _setupTabListener();
//   }
//
//   void _setupTabListener() {
//     _tabWorker = ever(app.appController.selectedTabIndexRx, (int tabIndex) {
//       if (mounted) {
//         _handleTabChange(tabIndex);
//       }
//     });
//   }
//
//   void _handleTabChange(int tabIndex) {
//     print("📱 Tab changed to: $tabIndex");
//
//     // Check if this is the printer settings tab (index 2)
//     bool isNowCurrentTab = tabIndex == 2;
//
//     if (isNowCurrentTab && (!_isCurrentTab || _lastTabIndex != tabIndex)) {
//       print("🔄 Printer Settings tab became active, refreshing...");
//       _isCurrentTab = true;
//       _lastTabIndex = tabIndex;
//       _unfocusAllTextFields();
//       // ✅ FIX: Remove delay and call immediately
//       _refreshOnlyServerSettings();
//     } else {
//       _isCurrentTab = isNowCurrentTab;
//       if (!isNowCurrentTab) {
//         _unfocusAllTextFields();
//       }
//
//     }
//   }
//
//   Future<void> _refreshOnlyServerSettings() async {
//     if (!mounted) return;
//
//     if (bearerKey != null && bearerKey!.isNotEmpty) {
//       print("🔄 Refreshing only server settings...");
//       // This will call getStoreSetting but won't overwrite local IPs
//       await getStoreSetting(bearerKey!);
//     }
//   }
//
//   @override
//   void dispose() {
//     // ✅ Dispose the worker first to prevent further callbacks
//     _tabWorker?.dispose();
//
//     WidgetsBinding.instance.removeObserver(this);
//     for (var controller in _ipControllers) {
//       controller.dispose();
//     }
//     for (var controller in _ipRemoteControllers) {
//       controller.dispose();
//     }
//     // ✅ Dispose focus nodes
//     for (var focusNode in _ipFocusNodes) {
//       focusNode.dispose();
//     }
//     for (var focusNode in _ipRemoteFocusNodes) {
//       focusNode.dispose();
//     }
//     super.dispose();
//   }
//
//   void _unfocusAllTextFields() {
//     // ✅ Check if widget is still mounted before accessing context
//     if (!mounted) {
//       print("⚠️ Widget not mounted, skipping unfocus");
//       return;
//     }
//
//     try {
//       for (var focusNode in _ipFocusNodes) {
//         if (focusNode.hasFocus) {
//           focusNode.unfocus();
//         }
//       }
//       for (var focusNode in _ipRemoteFocusNodes) {
//         if (focusNode.hasFocus) {
//           focusNode.unfocus();
//         }
//       }
//       // Also unfocus any currently focused element
//       FocusScope.of(context).unfocus();
//     } catch (e) {
//       print("⚠️ Error unfocusing text fields: $e");
//       // Continue execution even if unfocus fails
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed && _isCurrentTab && mounted) {
//       print("📱 App resumed and on printer settings tab, refreshing...");
//       _unfocusAllTextFields();
//       // ✅ FIX: Remove delay and call immediately
//       _refreshSettings();
//     }
//   }
//
//   Future<void> _refreshSettings() async {
//     if (!mounted) return; // ✅ Check mounted state
//
//     if (bearerKey != null && bearerKey!.isNotEmpty) {
//       print("🔄 Refreshing settings from server...");
//       getStoreSetting(bearerKey!);
//     } else {
//       print("⚠️ No bearer key available for refresh");
//     }
//   }
//
//   Future<void> _initSharedPrefsAndLoadSettings() async {
//     if (!mounted) return;
//
//     print("🔍 INIT ENHANCED - Starting...");
//
//     sharedPreferences = await SharedPreferences.getInstance();
//
//     // 🔥 IMMEDIATE DIAGNOSTICS
//     await _logAllSharedPreferences();
//
//     bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
//     print("🔑 Bearer Key found: ${bearerKey != null}");
//
//     // 🔥 USE ENHANCED LOAD METHOD
//     await _loadOnlyLocalSettings();
//
//     if (bearerKey != null && mounted) {
//       await getStoreSetting(bearerKey!);
//     }
//
//     print("🔍 INIT ENHANCED - Complete");
//   }
//
//   Future<void> _saveIps() async {
//     if (!mounted) return;
//     try {
//       setState(() {
//         _isSaving = true;
//       });
//       if (Get.isDialogOpen == true) {
//         Get.back();
//         await Future.delayed(Duration(milliseconds: 50));
//       }
//
//       _unfocusAllTextFields();
//       Get.dialog(
//         Center(
//             child: Lottie.asset(
//               'assets/animations/burger.json',
//               width: 150,
//               height: 150,
//               repeat: true,
//             )
//         ),
//         barrierDismissible: false,
//       );
//       await poststoreSetting(bearerKey!, showDialog: false);
//
//       setState(() {
//         _hasUnsavedChanges = false;
//         _isSaving = false;
//       });
//       if (Get.isDialogOpen == true) {
//         Get.back();
//         await Future.delayed(Duration(milliseconds: 50)); // Wait for dialog to close
//       }
//       await SettingsSync.syncSettingsAfterLogin();
//
//       // ✅ Show success animation
//       Get.dialog(
//         Center(
//             child: Lottie.asset(
//               'assets/animations/Success.json',
//               width: 150,
//               height: 150,
//               repeat: false,
//             )
//         ),
//         barrierDismissible: false,
//       );
//
//       await Future.delayed(Duration(seconds: 1));
//
//       if (Get.isDialogOpen == true) {
//         Get.back();
//         await Future.delayed(Duration(milliseconds: 50));
//       }
//
//       _unfocusAllTextFields();
//
//       Get.snackbar(
//         'success'.tr,
//         'settings'.tr,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 3),
//       );
//     } catch (e) {
//       print("❌ Error in _saveIps: $e");
//       setState(() {
//         _isSaving = false;
//       });
//       if (Get.isDialogOpen == true) {
//         Get.back();
//         await Future.delayed(Duration(milliseconds: 50));
//       }
//       _unfocusAllTextFields();
//       Get.snackbar(
//         'error'.tr,
//         '${'failed_save'.tr}: $e',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: 3),
//       );
//     }
//   }
//   Future<void> _saveLocalIps() async {
//     if (!mounted) return;
//
//     try {
//       _unfocusAllTextFields();
//
//       String ip = _ipControllers[0].text.trim();
//       print("🔍 SAVING IP ENHANCED - Input: '$ip'");
//
//       if (_validateIP(ip) != null) {
//         print("❌ IP validation failed, not saving");
//         Get.snackbar(
//             'invalid'.tr,
//             'valid_local'.tr,
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//             snackPosition: SnackPosition.BOTTOM,
//             duration: Duration(seconds: 1)
//         );
//         return;
//       }
//
//       if (ip.isNotEmpty) {
//         print("🔍 SAVING IP ENHANCED - About to save: '$ip'");
//
//         // 🔥 STRATEGY 1: Multiple save attempts with verification
//         bool saveSuccessful = false;
//
//         for (int attempt = 1; attempt <= 3; attempt++) {
//           try {
//             print("🔄 Save attempt $attempt/3");
//
//             // Method A: Use existing instance
//             await sharedPreferences.setString('printer_ip_0', ip);
//             await sharedPreferences.setInt('selected_ip_index', _selectedIpIndex);
//
//             // Method B: Create fresh instance
//             final freshPrefs = await SharedPreferences.getInstance();
//             await freshPrefs.setString('printer_ip_0', ip);
//             await freshPrefs.setInt('selected_ip_index', _selectedIpIndex);
//
//             // 🔥 STRATEGY 2: Force commit and reload
//             await freshPrefs.reload();
//             await Future.delayed(Duration(milliseconds: 200));
//
//             // 🔥 STRATEGY 3: Immediate verification
//             String? savedIp = freshPrefs.getString('printer_ip_0');
//             print("🔍 VERIFICATION attempt $attempt - Saved IP: '$savedIp'");
//
//             if (savedIp == ip) {
//               print("✅ SAVE SUCCESSFUL on attempt $attempt");
//               saveSuccessful = true;
//
//               // 🔥 STRATEGY 4: Additional backup keys
//               await freshPrefs.setString('printer_ip_backup', ip);
//               await freshPrefs.setString('printer_ip_0_backup', ip);
//               await freshPrefs.setInt('last_save_timestamp', DateTime.now().millisecondsSinceEpoch);
//
//               break;
//             } else {
//               print("⚠️ Save verification failed on attempt $attempt. Expected: '$ip', Got: '$savedIp'");
//               if (attempt < 3) {
//                 await Future.delayed(Duration(milliseconds: 500 * attempt));
//               }
//             }
//
//           } catch (e) {
//             print("❌ Error on save attempt $attempt: $e");
//             if (attempt < 3) {
//               await Future.delayed(Duration(milliseconds: 500 * attempt));
//             }
//           }
//         }
//
//         if (saveSuccessful) {
//           Get.snackbar(
//               'success'.tr,
//               'Local IP Saved Successfully',
//               backgroundColor: Colors.green,
//               colorText: Colors.white,
//               snackPosition: SnackPosition.BOTTOM,
//               duration: Duration(seconds: 2)
//           );
//
//           // 🔥 STRATEGY 5: Log all keys after successful save
//           await _logAllSharedPreferences();
//
//         } else {
//           print("❌ ALL SAVE ATTEMPTS FAILED");
//           Get.snackbar(
//               'Error',
//               'Failed to save IP address. Please try again.',
//               backgroundColor: Colors.red,
//               colorText: Colors.white,
//               snackPosition: SnackPosition.BOTTOM,
//               duration: Duration(seconds: 2)
//           );
//         }
//
//       } else {
//         print("❌ IP field is empty, not saving");
//       }
//     } catch (e) {
//       print("❌ Save Local IP Enhanced error: $e");
//     }
//   }
//
//   Future<void> poststoreSetting(String bearerKey, {bool showDialog = true}) async {
//     if (!mounted) return;
//
//     String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//     Map<String, dynamic> jsonData = {
//       "auto_accept_orders_remote": _autoRemoteOrderrAccept,
//       "auto_print_orders_remote": _autoRemoteOrderPrint,
//       "auto_accept_orders_local": _autoOrderAccept,
//       "auto_print_orders_local": _autoOrderPrint,
//       "store_id": storeID
//     };
//
//     try {
//       if (showDialog) {
//         // Close any existing dialog first
//         if (Get.isDialogOpen == true) {
//           Get.back();
//           await Future.delayed(Duration(milliseconds: 300));
//         }
//
//         Get.dialog(
//           Center(
//               child: Lottie.asset(
//                 'assets/animations/burger.json',
//                 width: 150,
//                 height: 150,
//                 repeat: true,
//               )
//           ),
//           barrierDismissible: false,
//         );
//       }
//
//
//       // ✅ NEW: Add timeout wrapper around API call
//       final result = await Future.any([
//         ApiRepo().storeSettingPost(bearerKey, jsonData),
//         Future.delayed(Duration(seconds: 10)).then((_) => null) // 10 second timeout
//       ]);
//
//       // ✅ NEW: Check if result is null due to timeout
//       if (result == null) {
//         // ✅ Close loading dialog if timeout occurred
//         if (showDialog && Get.isDialogOpen == true) {
//           Get.back();
//           await Future.delayed(Duration(milliseconds: 300));
//         }
//
//         // ✅ IMPORTANT: Unfocus on timeout
//         _unfocusAllTextFields();
//
//         if (showDialog) {
//           Get.snackbar(
//             'Timeout',
//             'Request timed out. Please try again.',
//             backgroundColor: Colors.orange,
//             colorText: Colors.white,
//             snackPosition: SnackPosition.BOTTOM,
//             duration: Duration(seconds: 1),
//           );
//         }
//
//         throw Exception('Request timeout after 10 seconds');
//       }
//       if (showDialog && Get.isDialogOpen == true) {
//         Get.back();
//         // ✅ Wait for dialog to close completely before showing next one
//         await Future.delayed(Duration(milliseconds: 300));
//       }
//
//       if (mounted) {
//         setState(() {
//           print("StoreSettigData " + result.toString());
//         });
//       }
//
//       // ✅ Show success animation dialog only if requested
//       if (showDialog) {
//         Get.dialog(
//           Center(
//               child: Lottie.asset(
//                 'assets/animations/Success.json',
//                 width: 150,
//                 height: 150,
//                 repeat: false, // Don't repeat success animation
//               )
//           ),
//           barrierDismissible: false,
//         );
//
//         // ✅ Wait for success animation to complete, then close and show snackbar
//         await Future.delayed(Duration(seconds: 2));
//
//         if (Get.isDialogOpen == true) {
//           Get.back();
//         }
//
//         // ✅ Wait for success dialog to close before proceeding
//         await Future.delayed(Duration(milliseconds: 200));
//
//         // ✅ IMPORTANT: Ensure focus is removed after success dialog
//         _unfocusAllTextFields();
//
//         // ✅ Show success snackbar
//         Get.snackbar(
//           'Success',
//           'Settings updated successfully',
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//           duration: Duration(seconds: 1),
//         );
//       }
//
//       return; // ✅ Return on success
//
//     } catch (e) {
//       // ✅ Close loading dialog (only if we showed it) with proper delay
//       if (showDialog && Get.isDialogOpen == true) {
//         Get.back();
//         await Future.delayed(Duration(milliseconds: 200)); // ✅ Wait for dialog to close
//       }
//
//       // ✅ IMPORTANT: Unfocus on any exception
//       _unfocusAllTextFields();
//
//       Log.loga(title, "Login Api:: e >>>>> $e");
//
//       if (showDialog) {
//         // ✅ NEW: Different error message for timeout vs other errors
//         String errorMessage = e.toString().contains('timeout')
//             ? 'Request timed out. Please check your connection and try again.'
//             : 'An error occurred: $e';
//
//         Get.snackbar(
//           'Error',
//           errorMessage,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//           duration: Duration(seconds: 3),
//         );
//       }
//
//       rethrow; // ✅ Rethrow to handle in _saveIps
//     }
//   }
//
//   Future<void> getStoreSetting(String bearerKey) async {
//     if (!mounted) return;
//
//     try {
//       print("🌐 Calling getStoreSetting API... (Tab active: $_isCurrentTab)");
//
//       _unfocusAllTextFields();
//
//       // ✅ Store current IP values BEFORE API call
//       String currentLocalIp = _ipControllers[0].text;
//       String currentRemoteIp = _ipRemoteControllers[0].text;
//
//       // ✅ FIX: Show loading dialog IMMEDIATELY if this is the current active tab
//       if (_isCurrentTab) {
//         Get.dialog(
//           Center(
//               child: Lottie.asset(
//                 'assets/animations/burger.json',
//                 width: 150,
//                 height: 150,
//                 repeat: true,
//               )
//           ),
//           barrierDismissible: false,
//         );
//       }
//
//       String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//       final result = await ApiRepo().getStoreSetting(bearerKey, storeID!);
//
//       if (_isCurrentTab && Get.isDialogOpen == true) {
//         Get.back();
//       }
//
//       if (result != null && mounted) {
//         StoreSetting store = result;
//
//         setState(() {
//           // ✅ ONLY update server settings, NOT local IPs
//           _autoOrderPrint = store.auto_print_orders_local ?? false;
//           _autoRemoteOrderrAccept = store.auto_accept_orders_remote ?? false;
//           _autoOrderAccept = store.auto_accept_orders_local ?? false;
//           _autoRemoteOrderPrint = store.auto_print_orders_remote ?? false;
//           _hasUnsavedChanges = false;
//
//           // ✅ PRESERVE local IP values
//           // _ipControllers[0].text = currentLocalIp;
//           _ipRemoteControllers[0].text = currentRemoteIp;
//
//           print("✅ Settings loaded from API (Tab: $_isCurrentTab):");
//           print("🔍 Auto Accept Local: $_autoOrderAccept");
//           print("🔍 Auto Print Local: $_autoOrderPrint");
//           print("🔍 Auto Accept Remote: $_autoRemoteOrderrAccept");
//           print("🔍 Auto Print Remote: $_autoRemoteOrderPrint");
//           print("🔍 Preserved Local IP: '${_ipControllers[0].text}'");
//         });
//
//         // ✅ Save server settings to SharedPreferences
//         await sharedPreferences.setBool('auto_order_accept', _autoOrderAccept);
//         await sharedPreferences.setBool('auto_order_print', _autoOrderPrint);
//         await sharedPreferences.setBool('auto_order_remote_accept', _autoRemoteOrderrAccept);
//         await sharedPreferences.setBool('auto_order_remote_print', _autoRemoteOrderPrint);
//
//         print("✅ Server settings saved to SharedPreferences after API call");
//
//         // ✅ IMPORTANT: Ensure focus remains removed after API success
//         Future.delayed(Duration(milliseconds: 100), () {
//           _unfocusAllTextFields();
//         });
//
//       } else {
//         _unfocusAllTextFields();
//         showSnackbar("Error", "Failed to get store data");
//       }
//     } catch (e) {
//       if (_isCurrentTab && Get.isDialogOpen == true) {
//         Get.back();
//       }
//
//       // ✅ IMPORTANT: Unfocus on error
//       _unfocusAllTextFields();
//
//       Log.loga(title, "getStoreSetting Api:: e >>>>> $e");
//       showSnackbar("Api Error", "An error occurred: $e");
//     }
//   }
//   Future<void> _loadOnlyLocalSettings() async {
//     print("🔍 LOADING ENHANCED - Starting load process");
//
//     try {
//       // 🔥 STRATEGY 1: Multiple reload attempts
//       for (int attempt = 1; attempt <= 3; attempt++) {
//         print("🔄 Load attempt $attempt/3");
//
//         await sharedPreferences.reload();
//         await Future.delayed(Duration(milliseconds: 100 * attempt));
//
//         String? savedIp = sharedPreferences.getString('printer_ip_0');
//         print("🔍 Load attempt $attempt - Found IP: '$savedIp'");
//         String? savedRemoteIp = sharedPreferences.getString('printer_ip_remote_0');
//         if (savedRemoteIp != null && savedRemoteIp.isNotEmpty) {
//           _ipRemoteControllers[0].text = savedRemoteIp;
//         }
//         _selectedRemoteIpIndex = sharedPreferences.getInt('selected_ip_remote_index') ?? 0;
//
// // Also load auto settings from SharedPreferences:
//         _autoOrderAccept = sharedPreferences.getBool('auto_order_accept') ?? false;
//         _autoOrderPrint = sharedPreferences.getBool('auto_order_print') ?? false;
//         _autoRemoteOrderrAccept = sharedPreferences.getBool('auto_order_remote_accept') ?? false;
//         _autoRemoteOrderPrint = sharedPreferences.getBool('auto_order_remote_print') ?? false;
//         if (savedIp != null && savedIp.isNotEmpty) {
//           _ipControllers[0].text = savedIp;
//           _selectedIpIndex = sharedPreferences.getInt('selected_ip_index') ?? 0;
//           print("✅ LOAD SUCCESSFUL on attempt $attempt - Set controller to: '${_ipControllers[0].text}'");
//           return;
//         }
//       }
//
//       // 🔥 STRATEGY 2: Try backup keys
//       print("🔍 Primary key failed, trying backup keys...");
//       String? backupIp = sharedPreferences.getString('printer_ip_backup') ??
//           sharedPreferences.getString('printer_ip_0_backup');
//
//       if (backupIp != null && backupIp.isNotEmpty) {
//         print("✅ RECOVERED from backup - IP: '$backupIp'");
//         _ipControllers[0].text = backupIp;
//         _selectedIpIndex = sharedPreferences.getInt('selected_ip_index') ?? 0;
//
//         // Restore primary key
//         await sharedPreferences.setString('printer_ip_0', backupIp);
//         return;
//       }
//
//       // 🔥 STRATEGY 3: Try fresh SharedPreferences instance
//       print("🔍 Trying fresh SharedPreferences instance...");
//       final freshPrefs = await SharedPreferences.getInstance();
//       await freshPrefs.reload();
//
//       String? freshIp = freshPrefs.getString('printer_ip_0');
//       if (freshIp != null && freshIp.isNotEmpty) {
//         print("✅ RECOVERED from fresh instance - IP: '$freshIp'");
//         _ipControllers[0].text = freshIp;
//         _selectedIpIndex = freshPrefs.getInt('selected_ip_index') ?? 0;
//         return;
//       }
//
//       print("❌ ALL LOAD STRATEGIES FAILED - No IP found");
//       _ipControllers[0].text = '';
//       _selectedIpIndex = 0;
//
//     } catch (e) {
//       print("❌ Error in enhanced load: $e");
//       _ipControllers[0].text = '';
//       _selectedIpIndex = 0;
//     }
//
//     // Log final state
//     await _logAllSharedPreferences();
//   }
//   Future<void> _logAllSharedPreferences() async {
//     try {
//       await sharedPreferences.reload();
//       print("🔍 === CURRENT SHAREDPREFERENCES STATE ===");
//       print("🔍 Total keys: ${sharedPreferences.getKeys().length}");
//
//       for (String key in sharedPreferences.getKeys().toList()..sort()) {
//         dynamic value = sharedPreferences.get(key);
//         if (key.contains('printer') || key.contains('ip') || key.contains('selected')) {
//           print("🔍 *** $key: $value");
//         } else {
//           print("🔍     $key: $value");
//         }
//       }
//       print("🔍 ========================================");
//
//       // Also check timestamp
//       int? lastSave = sharedPreferences.getInt('last_save_timestamp');
//       if (lastSave != null) {
//         DateTime saveTime = DateTime.fromMillisecondsSinceEpoch(lastSave);
//         print("🔍 Last save time: $saveTime");
//       }
//
//     } catch (e) {
//       print("❌ Error logging SharedPreferences: $e");
//     }
//   }
//
//   Future<void> _debugSharedPreferences() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.reload();
//
//       print("🔍 DEBUG - All SharedPreferences contents:");
//       for (String key in prefs.getKeys()) {
//         dynamic value = prefs.get(key);
//         print("   $key: $value (${value.runtimeType})");
//       }
//
//       // ✅ Specifically check our IP key
//       String? ip = prefs.getString('printer_ip_0');
//       print("🔍 DEBUG - printer_ip_0 specifically: '$ip'");
//
//     } catch (e) {
//       print("❌ Debug SharedPreferences error: $e");
//     }
//   }
//
//   Widget _buildIpField(int index) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: _ipControllers[index],
//                 focusNode: _ipFocusNodes[index], // ✅ Assign focus node
//                 enabled: index == _selectedIpIndex,
//                 decoration: InputDecoration(
//                   labelText: 'ip'.tr,
//                   hintText: 'e.g. 192.168.1.100',
//                   border: OutlineInputBorder(),
//                   errorText: _validateIP(_ipControllers[index].text),
//                 ),
//                 keyboardType: TextInputType.text,
//                 onChanged: (value) {
//                   if (mounted) {
//                     setState(() {}); // Trigger rebuild to show validation
//                   }
//                 },
//                 onFieldSubmitted: (value) {
//                   _ipFocusNodes[index].unfocus();
//                 },
//                 onTapOutside: (event) {
//                   _ipFocusNodes[index].unfocus();
//                 },
//               ),
//             ),
//           ],
//         ),
//         // Show current saved IP
//         if (_ipControllers[index].text.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(left: 8, top: 4),
//             child: Row(
//               children: [
//                 Icon(
//                   _validateIP(_ipControllers[index].text) == null
//                       ? Icons.check_circle
//                       : Icons.error,
//                   color: _validateIP(_ipControllers[index].text) == null
//                       ? Colors.green
//                       : Colors.red,
//                   size: 16,
//                 ),
//                 SizedBox(width: 4),
//                 Text(
//                   _validateIP(_ipControllers[index].text) == null
//                       ? 'valid'.tr
//                       : 'invalid'.tr,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _validateIP(_ipControllers[index].text) == null
//                         ? Colors.green
//                         : Colors.red,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
//   String? _validateIP(String ip) {
//     if (ip.isEmpty) return null;
//
//     // Basic IP validation
//     final parts = ip.split('.');
//     if (parts.length != 4) return 'ip_must'.tr;
//
//     for (String part in parts) {
//       if (part.isEmpty) return 'empty'.tr;
//
//       int? num = int.tryParse(part);
//       if (num == null) return 'invalid_number'.tr;
//       if (num < 0 || num > 255) return 'number'.tr;
//     }
//
//     return null; // Valid IP
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//
//     return GestureDetector(
//       onTap: () {
//         _unfocusAllTextFields();
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 16),
//                  Text(
//                   'local'.tr,
//                   style: TextStyle(
//                       color: Colors.black, fontWeight: FontWeight.w500),
//                 ),
//                 SizedBox(height: 8),
//                 _buildIpField(0),
//                 Center(
//                   child: Container(
//                     margin: EdgeInsets.all(15),
//                     child: ElevatedButton(
//                       onPressed: () {
//                         print("🔍 BUTTON PRESSED - IP Controller text: '${_ipControllers[0].text}'");
//                         print("🔍 BUTTON PRESSED - IP Controller text length: ${_ipControllers[0].text.length}");
//                         _saveLocalIps();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green[300],
//                         foregroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(50),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 30, vertical: 14),
//                       ),
//                       child:  Text('save'.tr),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 _ToggleRow(
//                   label: 'auto'.tr,
//                   activeColor: Colors.blue,
//                   value: _autoOrderPrint,
//                   onChanged: (val) async {
//                     _unfocusAllTextFields();
//
//                     if (mounted) {
//                       setState(() {
//                         _autoOrderPrint = val;
//                         _hasUnsavedChanges = true;
//                       });
//                     }
//
//                     // ✅ CRITICAL: Use multiple approaches to ensure saving
//                     try {
//                       // Method 1: Use existing instance
//                       await sharedPreferences.setBool('auto_order_print', val);
//                       await sharedPreferences.reload();
//
//                       // Method 2: Create fresh instance and verify
//                       final freshPrefs = await SharedPreferences.getInstance();
//                       await freshPrefs.setBool('auto_order_print', val);
//                       await freshPrefs.reload();
//
//                       // Method 3: Verify the save worked
//                       bool savedValue = freshPrefs.getBool('auto_order_print') ?? false;
//
//                       if (savedValue == val) {
//                         print("✅ Auto Order Print toggled to: $val and VERIFIED in SharedPreferences");
//                       } else {
//                         print("❌ Auto Order Print save verification FAILED! Expected: $val, Got: $savedValue");
//                         // Try again with delay
//                         await Future.delayed(Duration(milliseconds: 200));
//                         await freshPrefs.setBool('auto_order_print', val);
//                         await freshPrefs.reload();
//                       }
//
//                       // ✅ ADDITIONAL: Force background handler to refresh its cache
//                       await _triggerBackgroundSettingsRefresh();
//
//                     } catch (e) {
//                       print("❌ Error saving Auto Order Print: $e");
//                     }
//                   },
//                 ),
//
//                 _ToggleRow(
//                   label: 'auto_order'.tr,
//                   activeColor: Colors.green,
//                   value: _autoRemoteOrderrAccept,
//                   onChanged: (val) async {
//                     _unfocusAllTextFields();
//
//                     if (mounted) {
//                       setState(() {
//                         _autoRemoteOrderrAccept = val;
//                         _hasUnsavedChanges = true;
//                       });
//                     }
//
//                     // ✅ CRITICAL: Use multiple approaches to ensure saving
//                     try {
//                       // Method 1: Use existing instance
//                       await sharedPreferences.setBool('auto_order_remote_accept', val);
//                       await sharedPreferences.reload();
//
//                       // Method 2: Create fresh instance and verify
//                       final freshPrefs = await SharedPreferences.getInstance();
//                       await freshPrefs.setBool('auto_order_remote_accept', val);
//                       await freshPrefs.reload();
//
//                       // Method 3: Verify the save worked
//                       bool savedValue = freshPrefs.getBool('auto_order_remote_accept') ?? false;
//
//                       if (savedValue == val) {
//                         print("✅ Auto Order Remote Accept toggled to: $val and VERIFIED in SharedPreferences");
//                       } else {
//                         print("❌ Auto Order Remote Accept save verification FAILED! Expected: $val, Got: $savedValue");
//                         // Try again with delay
//                         await Future.delayed(Duration(milliseconds: 200));
//                         await freshPrefs.setBool('auto_order_remote_accept', val);
//                         await freshPrefs.reload();
//                       }
//
//                       // ✅ ADDITIONAL: Force background handler to refresh its cache
//                       await _triggerBackgroundSettingsRefresh();
//
//                     } catch (e) {
//                       print("❌ Error saving Auto Order Remote Accept: $e");
//                     }
//                   },
//                 ),
//
//                 // _ToggleRow(
//                 //   label: 'Auto Order Remote Print',
//                 //   activeColor: Colors.blue.shade400,
//                 //   value: _autoRemoteOrderPrint,
//                 //   onChanged: (val) async {
//                 //     _unfocusAllTextFields();
//                 //     if (mounted) {
//                 //       setState(() {
//                 //         _autoRemoteOrderPrint = val;
//                 //         _hasUnsavedChanges = true;
//                 //       });
//                 //     }
//                 //
//                 //     // ✅ CRITICAL: Use multiple approaches to ensure saving
//                 //     try {
//                 //       await sharedPreferences.setBool('auto_order_remote_print', val);
//                 //       await sharedPreferences.reload();
//                 //
//                 //       // Method 2: Create fresh instance and verify
//                 //       final freshPrefs = await SharedPreferences.getInstance();
//                 //       await freshPrefs.setBool('auto_order_remote_print', val);
//                 //       await freshPrefs.reload();
//                 //
//                 //       // Method 3: Verify the save worked
//                 //       bool savedValue = freshPrefs.getBool('auto_order_remote_print') ?? false;
//                 //
//                 //       if (savedValue == val) {
//                 //         print("✅ Auto Order Remote Print toggled to: $val and VERIFIED in SharedPreferences");
//                 //       } else {
//                 //         print("❌ Auto Order Remote Print save verification FAILED! Expected: $val, Got: $savedValue");
//                 //         // Try again with delay
//                 //         await Future.delayed(Duration(milliseconds: 200));
//                 //         await freshPrefs.setBool('auto_order_remote_print', val);
//                 //         await freshPrefs.reload();
//                 //       }
//                 //
//                 //       // ✅ ADDITIONAL: Force background handler to refresh its cache
//                 //       await _triggerBackgroundSettingsRefresh();
//                 //
//                 //     } catch (e) {
//                 //       print("❌ Error saving Auto Order Remote Print: $e");
//                 //     }
//                 //   },
//                 // ),
//                 const SizedBox(height: 40),
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: (_hasUnsavedChanges && !_isSaving) ? _saveIps : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: (_hasUnsavedChanges && !_isSaving)
//                           ? Colors.green[300]
//                           : Colors.grey[300],
//                       foregroundColor: (_hasUnsavedChanges && !_isSaving)
//                           ? Colors.black
//                           : Colors.grey[600],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
//                     ),
//                     child: Text(_isSaving ? 'Saving...' : 'save_ip'.tr),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Future<void> _triggerBackgroundSettingsRefresh() async {
//     try {
//       // Create multiple fresh instances to ensure background handler will see the changes
//       for (int i = 0; i < 3; i++) {
//         final testPrefs = await SharedPreferences.getInstance();
//         await testPrefs.reload();
//         await Future.delayed(Duration(milliseconds: 100));
//       }
//
//       print("🔄 Background settings refresh triggered");
//     } catch (e) {
//       print("❌ Error triggering background settings refresh: $e");
//     }
//   }
//
// }
//
// class _ToggleRow extends StatelessWidget {
//   const _ToggleRow({
//     required this.label,
//     required this.value,
//     required this.onChanged,
//     required this.activeColor,
//   });
//
//   final String label;
//   final bool value;
//   final ValueChanged<bool> onChanged;
//   final Color activeColor;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               label,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//           ),
//           Switch(
//             value: value,
//             activeColor: activeColor,
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }
// }