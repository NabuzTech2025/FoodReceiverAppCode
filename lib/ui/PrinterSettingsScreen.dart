
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../controller/AppController.dart';
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
      int? syncTimeSeconds = int.tryParse(savedSyncTime);
      if (syncTimeSeconds != null) {
        int syncTimeMinutes = (syncTimeSeconds / 60).round();
        _syncTimeController.text = syncTimeMinutes.toString();
        print('✅ Loaded sync time: $syncTimeMinutes minutes ($syncTimeSeconds seconds)');
      }
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
        final messenger = ScaffoldMessenger.of(context); // ✅ Cache messenger first
        messenger.showSnackBar(
          SnackBar(
            content: Text('please_enter_sync'.tr),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
      return;
    }

    // ✅ Validate if it's a number
    int? syncTimeMinutes = int.tryParse(syncTime);
    if (syncTimeMinutes == null || syncTimeMinutes < 1) { // ✅ Minimum 1 minute
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context); // ✅ Cache messenger first
        messenger.showSnackBar(
          SnackBar(
            content: Text('Sync time must be at least 1 minute'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
      return;
    }

    try {
      // ✅ Convert minutes to seconds before saving
      int syncTimeSeconds = syncTimeMinutes * 60;

      await sharedPreferences.setString('sync_time', syncTimeSeconds.toString());

      // ✅ Unfocus before showing snackbar
      if (mounted) {
        _syncTimeFocusNode.unfocus();
      }

      // ✅ Cache messenger before async gap
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${'sync_time_saved'.tr}: $syncTimeMinutes minutes'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving sync time: $e');
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context); // ✅ Cache messenger first
        messenger.showSnackBar(
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
                              suffixText: 'minutes'.tr,
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
