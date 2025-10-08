// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:food_app/models/Store.dart';
// import 'package:food_app/ui/Driver/driver_screen.dart';
// import 'package:get/get.dart';
// import 'package:lottie/lottie.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../api/repository/api_repository.dart';
// import '../constants/constant.dart';
// import '../ui/LoginScreen.dart';
// import '../utils/log_util.dart';
// import '../utils/my_application.dart';
//
// class CustomDrawer extends StatefulWidget {
//   final Function(int) onSelectTab;
//
//   const CustomDrawer({Key? key, required this.onSelectTab}) : super(key: key);
//
//   @override
//   _CustomDrawerState createState() => _CustomDrawerState();
// }
//
// class _CustomDrawerState extends State<CustomDrawer> {
//   late SharedPreferences sharedPreferences;
//   String? storeName;
//   @override
//   initState() {
//     initVar();
//     super.initState();
//   }
//
//   Future<void> initVar() async {
//     sharedPreferences = await SharedPreferences.getInstance();
//     String? bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
//     if (bearerKey != null) {
//       await getStoredta(bearerKey);
//     }
//   }
//
//   Future<void> getStoredta(String bearerKey) async {
//     try {
//       String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
//       final result = await ApiRepo().getStoreData(bearerKey, storeID!);
//
//       if (result != null) {
//         Store store = result;
//         if (mounted) {
//           setState(() {
//             storeName = store.name.toString();
//             print("StoreName2 $storeName");
//           });
//         }} else {
//         showSnackbar("Error", "Failed to get store data");
//       }
//     } catch (e) {
//       Log.loga(title, "Login Api:: e >>>>> $e");
//       showSnackbar("Api Error", "An error occurred: $e");
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       width: MediaQuery.of(context).size.width * 0.75,
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 60),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 storeName == null || storeName!.isEmpty
//                     ? SizedBox(
//                   width: 30,
//                   height: 30,
//                   child: Lottie.asset(
//                     'assets/animations/burger.json', // Apni Lottie loading animation ka path do
//                     width: 30,
//                     height: 30,
//                     repeat: true,
//                   ),
//                 )
//                     : Text(
//                   storeName.toString(),
//                   style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
//                 )
//               ],
//             ),
//           ),
//
//           _drawerItem('order'.tr, onTap: () {
//             Navigator.of(context).pop(); // close drawer
//             widget.onSelectTab(0); //
//           }),
//           /*_drawerItem('customer'.tr, onTap: () {
//             Navigator.of(context).pop(); // close drawer
//             //widget.onSelectTab(1); //
//           }),*/
//           _drawerItem('reports'.tr, onTap: () {
//             Navigator.of(context).pop(); // close drawer
//             widget.onSelectTab(1); // open tab index 3 (PrinterSettingsScreen)
//           }),
//           _drawerItem('Driver', onTap: () {
//             Navigator.of(context).pop(); // First close drawer
//             // Then navigate to DriverScreen
//             Future.delayed(Duration(milliseconds: 100), () {
//               Get.to(() => DriverScreen());
//             });
//           }),
//           _drawerItem('setting'.tr, onTap: () {
//             Navigator.of(context).pop(); // close drawer
//             widget.onSelectTab(2); // open tab index 3 (PrinterSettingsScreen)
//           }),
//           const Spacer(),
//
//           Container(
//             child: _drawerItem('logout'.tr, onTap: () async {
//               var bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
//               logutAPi(bearerKey);
//             }),
//           ),
//           Padding(
//             padding:  EdgeInsets.only(left: 15.0),
//             child: Text('Version:1.3.0',style: TextStyle(
//                 fontWeight: FontWeight.w300,
//                 fontSize: 15
//             ),),
//           ),
//           SizedBox(
//             height: 60,
//           ),
//           /* Container(
//             color: Colors.grey[200],
//             child: _drawerItem("Logout", onTap: () async {
//               await sharedPreferences.remove(valueShared_BEARER_KEY);
//               Navigator.of(context).pop(); // close drawer
//               Get.to(() => LoginScreen());
//               // Add logout logic here
//             }),
//           ),*/
//         ],
//       ),
//     );
//   }
//
//   Widget _drawerItem(String title, {required VoidCallback onTap}) {
//     return ListTile(
//       title: Text(title, style: const TextStyle(fontSize: 16)),
//       onTap: onTap,
//     );
//   }
//
//   Future<void> logutAPi(String? bearerKey) async {
//     try {
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
//       print("🚪 Starting logout process...");
//
//       final result = await ApiRepo().logoutAPi(bearerKey);
//       if (result != null) {
//         print("✅ Logout API successful");
//
//         // ✅ STEP 1: Save IP data before clearing everything
//         await _preserveUserIPData();
//
//         // ✅ STEP 2: Force complete logout cleanup (without clearing IP data)
//         await _forceCompleteLogoutCleanup();
//
//         // ✅ STEP 3: Clear app controller
//         app.appController.clearOnLogout();
//
//         // ✅ STEP 4: Force background handler to clear token cache
//         await _forceBackgroundHandlerClearCache();
//
//         // ✅ STEP 5: Close drawer
//         Navigator.of(context).pop();
//
//         // ✅ STEP 6: Navigate to login with complete reset
//         Get.offAll(() => LoginScreen());
//
//         print("✅ Logout completed successfully");
//
//       } else {
//         showSnackbar("Error", "Failed to logout");
//       }
//     } catch (e) {
//       Log.loga(title, "Logout Api:: e >>>>> $e");
//       showSnackbar("Api Error", "An error occurred: $e");
//     }
//   }
//
// // ✅ NEW: Preserve IP data for the current user before logout
//   Future<void> _preserveUserIPData() async {
//     try {
//       print("💾 Preserving IP data for current user...");
//
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? currentStoreId = prefs.getString(valueShared_STORE_KEY);
//
//       if (currentStoreId != null && currentStoreId.isNotEmpty) {
//         // Save current IP data with store ID prefix
//         String userPrefix = "user_${currentStoreId}_";
//
//         // Preserve local printer IPs
//         for (int i = 0; i < 5; i++) {
//           String? currentIP = prefs.getString('printer_ip_$i');
//           if (currentIP != null && currentIP.isNotEmpty) {
//             await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
//             print("💾 Saved ${userPrefix}printer_ip_$i: $currentIP");
//           }
//         }
//
//         // Preserve remote printer IPs
//         for (int i = 0; i < 5; i++) {
//           String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
//           if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
//             await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
//             print("💾 Saved ${userPrefix}printer_ip_remote_$i: $currentRemoteIP");
//           }
//         }
//
//         // Preserve selected indices
//         int? selectedIndex = prefs.getInt('selected_ip_index');
//         if (selectedIndex != null) {
//           await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
//         }
//
//         int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
//         if (selectedRemoteIndex != null) {
//           await prefs.setInt('${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
//         }
//
//         // Preserve toggle settings
//         bool? autoOrderAccept = prefs.getBool('auto_order_accept');
//         if (autoOrderAccept != null) {
//           await prefs.setBool('${userPrefix}auto_order_accept', autoOrderAccept);
//         }
//
//         bool? autoOrderPrint = prefs.getBool('auto_order_print');
//         if (autoOrderPrint != null) {
//           await prefs.setBool('${userPrefix}auto_order_print', autoOrderPrint);
//         }
//
//         bool? autoRemoteAccept = prefs.getBool('auto_order_remote_accept');
//         if (autoRemoteAccept != null) {
//           await prefs.setBool('${userPrefix}auto_order_remote_accept', autoRemoteAccept);
//         }
//
//         bool? autoRemotePrint = prefs.getBool('auto_order_remote_print');
//         if (autoRemotePrint != null) {
//           await prefs.setBool('${userPrefix}auto_order_remote_print', autoRemotePrint);
//         }
//
//         print("✅ IP data preserved for store: $currentStoreId");
//       } else {
//         print("⚠️ No store ID found, cannot preserve IP data");
//       }
//     } catch (e) {
//       print("❌ Error preserving IP data: $e");
//     }
//   }
//
// // ✅ Complete logout cleanup WITHOUT clearing IP data
//   Future<void> _forceCompleteLogoutCleanup() async {
//     try {
//       print("🧹 Starting complete logout cleanup...");
//
//       // ✅ Multiple cleanup attempts to ensure complete removal
//       for (int attempt = 0; attempt < 3; attempt++) {
//         print("🔄 Cleanup attempt ${attempt + 1}/3");
//
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//
//         // Clear only authentication-related data (NOT IP data)
//         List<String> keysToRemove = [
//           valueShared_BEARER_KEY,
//           valueShared_STORE_KEY,
//         ];
//
//         for (String key in keysToRemove) {
//           await prefs.remove(key);
//           await Future.delayed(Duration(milliseconds: 20));
//           print("🗑️ Removed: $key");
//         }
//
//         // ✅ DON'T clear printer settings - they are preserved with user prefix
//         // The old code was clearing these, which was the problem:
//         // for (int i = 0; i < 5; i++) {
//         //   await prefs.remove('printer_ip_$i');
//         // }
//
//         // ✅ Force multiple reloads to ensure changes are committed
//         await prefs.reload();
//         await Future.delayed(Duration(milliseconds: 100));
//         await prefs.reload();
//         await Future.delayed(Duration(milliseconds: 100));
//
//         // ✅ Verify cleanup for this attempt
//         String? testToken = prefs.getString(valueShared_BEARER_KEY);
//         if (testToken == null) {
//           print("✅ Cleanup attempt ${attempt + 1}: SUCCESS");
//         } else {
//           print("⚠️ Cleanup attempt ${attempt + 1}: Token still exists, retrying...");
//         }
//       }
//
//       // ✅ Final verification
//       SharedPreferences finalPrefs = await SharedPreferences.getInstance();
//       await finalPrefs.reload();
//       String? finalToken = finalPrefs.getString(valueShared_BEARER_KEY);
//
//       if (finalToken == null) {
//         print("✅ Complete logout cleanup SUCCESS - All tokens removed");
//       } else {
//         print("❌ Logout cleanup FAILED - Token still exists: ${finalToken.substring(0, 10)}...");
//       }
//
//     } catch (e) {
//       print("❌ Error in complete logout cleanup: $e");
//     }
//   }
//
// // ✅ Force background handler to clear its token cache
//   Future<void> _forceBackgroundHandlerClearCache() async {
//     try {
//       print("🔄 Forcing background handler cache clear...");
//
//       // Additional delay to ensure background handler gets the cleared preferences
//       await Future.delayed(Duration(milliseconds: 300));
//
//       // Create a test instance to verify background handler will get null token
//       SharedPreferences testPrefs = await SharedPreferences.getInstance();
//       await testPrefs.reload();
//
//       String? testToken = testPrefs.getString(valueShared_BEARER_KEY);
//       if (testToken == null) {
//         print("✅ Background handler cache should now be cleared");
//       } else {
//         print("❌ Background handler cache clear failed - token still exists");
//       }
//
//     } catch (e) {
//       print("❌ Error clearing background handler cache: $e");
//     }
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/ui/Driver/driver_screen.dart';
import 'package:food_app/ui/PostCode/postcode.dart';
import 'package:food_app/ui/home_screen.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/Socket/socket_service.dart';
import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../ui/Discount/discount.dart';
import '../ui/LoginScreen.dart';
import '../ui/Products/Category/category.dart';
import '../ui/Products/Group Item/group_item.dart';
import '../ui/Products/Product/products.dart';
import '../ui/Products/Topping/topping_group.dart';
import '../ui/Products/Topping/toppings.dart';
import '../ui/Products/product_group/product_group.dart';
import '../ui/StoreTiming/store_timing.dart';
import '../ui/Tax MAnagement/taxmanagement.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';

class CustomDrawer extends StatefulWidget {
  final Function(int) onSelectTab;

  const CustomDrawer({Key? key, required this.onSelectTab}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late SharedPreferences sharedPreferences;
  String? storeName;
  bool isProductExpanded = false;
  @override
  initState() {
    initVar();
    super.initState();
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    if (bearerKey != null) {
      await getStoredta(bearerKey);
    }
  }

  Future<void> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      final result = await ApiRepo().getStoreData(bearerKey, storeID!);

      if (result != null) {
        Store store = result;
        if (mounted) {
          setState(() {
            storeName = store.name.toString();
            print("StoreName2 $storeName");
          });
        }} else {
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  // Helper method to check if we're currently on HomeScreen
  bool _isOnHomeScreen() {
    return Get.currentRoute == '/HomeScreen' ||
        ModalRoute.of(context)?.settings.name == '/HomeScreen' ||
        Get.previousRoute == '/LoginScreen';
  }

  // Helper method to navigate to HomeScreen with specific tab
  void _navigateToHomeScreenTab(int tabIndex) {
    Navigator.of(context).pop(); // Close drawer first

    if (_isOnHomeScreen()) {
      // If already on HomeScreen, just switch tabs
      widget.onSelectTab(tabIndex);
    } else {
      // If on different screen, navigate back to HomeScreen with specific tab
      Get.off(() => HomeScreen(), arguments: {'initialTab': tabIndex});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        children: [

          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      storeName == null || storeName!.isEmpty ?
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Lottie.asset(
                          'assets/animations/burger.json',
                          width: 30,
                          height: 30,
                          repeat: true,
                        ),
                      )
                          : Text(
                        storeName.toString(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _drawerItem('order'.tr,'assets/images/order.png', onTap: () {
                    _navigateToHomeScreenTab(0);
                  }),
                  _drawerItem('reserv'.tr,'assets/images/reserv.png', onTap: () {
                    _navigateToHomeScreenTab(1);
                  }),
                  _drawerItem('reports'.tr,'assets/images/report.png', onTap: () {
                    _navigateToHomeScreenTab(2);
                  }),
                  _drawerItem('setting'.tr,'assets/images/settings.png', onTap: () {
                    _navigateToHomeScreenTab(3);
                  }),

                  _expandableProductItem(),

                  _drawerItem('discount'.tr,'assets/images/discount.png', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => Discount());
                  }),
                  _drawerItem('store'.tr,'assets/images/store.png', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => StoreTiming());
                  }),
                  _drawerItem('manage'.tr,'assets/images/tax.png', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => Taxmanagement());
                  }),
                  _drawerItem('postcode'.tr,'assets/images/postcode.png', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const Postcode());
                  }),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: _drawerItem('logout'.tr,'assets/images/logout.png', onTap: () async {
                    var bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
                    logutAPi(bearerKey);
                  }),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Text('${'version'.tr}:1.15.0', style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 15
                  ),),
                ),
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(String title,String imagePath, {required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
        dense: true,
        leading: Image.asset(imagePath,color: Color(0xff757B8F),height: 20,width: 25,),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Add this line
        visualDensity: VisualDensity.compact
    );
  }

  Future<void> logutAPi(String? bearerKey) async {
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
      print("🚪 Starting logout process...");

      final result = await ApiRepo().logoutAPi(bearerKey);
      if (result != null) {
        print("✅ Logout API successful");
        await _disconnectSocket();
        // ✅ STEP 1: Save IP data before clearing everything
        await _preserveUserIPData();

        // ✅ STEP 2: Force complete logout cleanup (without clearing IP data)
        await _forceCompleteLogoutCleanup();

        // ✅ STEP 3: Clear app controller
        app.appController.clearOnLogout();

        // ✅ STEP 4: Force background handler to clear token cache
        await _forceBackgroundHandlerClearCache();

        // ✅ STEP 5: Close drawer
        Navigator.of(context).pop();

        // ✅ STEP 6: Navigate to login with complete reset
        Get.offAll(() => LoginScreen());

        print("✅ Logout completed successfully");

      } else {
        showSnackbar("Error", "Failed to logout");
      }
    } catch (e) {
      Log.loga(title, "Logout Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }
  Future<void> _disconnectSocket() async {
    try {
      print("🔌 Disconnecting socket...");
      // Assuming you have a socket service - adjust the class name accordingly
       SocketService().disconnect();
      await Future.delayed(Duration(milliseconds: 100));
      print("✅ Socket disconnected");
    } catch (e) {
      print("⚠️ Error disconnecting socket: $e");
    }
  }
// ✅ NEW: Preserve IP data for the current user before logout
  Future<void> _preserveUserIPData() async {
    try {
      print("💾 Preserving IP data for current user...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentStoreId = prefs.getString(valueShared_STORE_KEY);

      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        // Save current IP data with store ID prefix
        String userPrefix = "user_${currentStoreId}_";

        // Preserve local printer IPs
        for (int i = 0; i < 5; i++) {
          String? currentIP = prefs.getString('printer_ip_$i');
          if (currentIP != null && currentIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
            print("💾 Saved ${userPrefix}printer_ip_$i: $currentIP");
          }
        }

        // Preserve remote printer IPs
        for (int i = 0; i < 5; i++) {
          String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
          if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
            print("💾 Saved ${userPrefix}printer_ip_remote_$i: $currentRemoteIP");
          }
        }

        // Preserve selected indices
        int? selectedIndex = prefs.getInt('selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
        }

        // Preserve toggle settings
        bool? autoOrderAccept = prefs.getBool('auto_order_accept');
        if (autoOrderAccept != null) {
          await prefs.setBool('${userPrefix}auto_order_accept', autoOrderAccept);
        }

        bool? autoOrderPrint = prefs.getBool('auto_order_print');
        if (autoOrderPrint != null) {
          await prefs.setBool('${userPrefix}auto_order_print', autoOrderPrint);
        }

        bool? autoRemoteAccept = prefs.getBool('auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool('${userPrefix}auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint = prefs.getBool('auto_order_remote_print');
        if (autoRemotePrint != null) {
          await prefs.setBool('${userPrefix}auto_order_remote_print', autoRemotePrint);
        }

        print("✅ IP data preserved for store: $currentStoreId");
      } else {
        print("⚠️ No store ID found, cannot preserve IP data");
      }
    } catch (e) {
      print("❌ Error preserving IP data: $e");
    }
  }


// ✅ Complete logout cleanup WITHOUT clearing IP data
  Future<void> _forceCompleteLogoutCleanup() async {
    try {
      print("🧹 Starting complete logout cleanup...");

      // ✅ Multiple cleanup attempts to ensure complete removal
      for (int attempt = 0; attempt < 3; attempt++) {
        print("🔄 Cleanup attempt ${attempt + 1}/3");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Clear only authentication-related data (NOT IP data)
        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,
          // ✅ NEW: Clear backup IP keys that are created by PrinterSettingsScreen
          'printer_ip_backup',
          'printer_ip_0_backup',
          'last_save_timestamp',
          // ✅ Clear current session IP data (will be restored from user-prefixed data on next login)
          'printer_ip_0',
          'printer_ip_remote_0',
          'selected_ip_index',
          'selected_ip_remote_index',
          // ✅ Clear current session auto settings (will be restored from user-prefixed data)
          'auto_order_accept',
          'auto_order_print',
          'auto_order_remote_accept',
          'auto_order_remote_print',
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(Duration(milliseconds: 20));
          print("🗑️ Removed: $key");
        }

        // ✅ Also clear all printer IP keys (0-4) to ensure complete cleanup
        for (int i = 0; i < 5; i++) {
          await prefs.remove('printer_ip_$i');
          await prefs.remove('printer_ip_remote_$i');
        }

        // ✅ Force multiple reloads to ensure changes are committed
        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));
        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));

        // ✅ Verify cleanup for this attempt
        String? testToken = prefs.getString(valueShared_BEARER_KEY);
        String? testBackupIp = prefs.getString('printer_ip_backup');
        if (testToken == null && testBackupIp == null) {
          print("✅ Cleanup attempt ${attempt + 1}: SUCCESS");
        } else {
          print("⚠️ Cleanup attempt ${attempt + 1}: Token still exists, retrying...");
        }
      }

      // ✅ Final verification
      SharedPreferences finalPrefs = await SharedPreferences.getInstance();
      await finalPrefs.reload();
      String? finalToken = finalPrefs.getString(valueShared_BEARER_KEY);
      String? finalBackupIp = finalPrefs.getString('printer_ip_backup');

      if (finalToken == null && finalBackupIp == null) {
        print("✅ Complete logout cleanup SUCCESS - All tokens removed");
      } else {
        print("❌ Logout cleanup FAILED - Token still exists: ${finalToken!.substring(0, 10)}...");
      }

    } catch (e) {
      print("❌ Error in complete logout cleanup: $e");
    }
  }

// ✅ Force background handler to clear its token cache
  Future<void> _forceBackgroundHandlerClearCache() async {
    try {
      print("🔄 Forcing background handler cache clear...");

      // Additional delay to ensure background handler gets the cleared preferences
      await Future.delayed(Duration(milliseconds: 300));

      // Create a test instance to verify background handler will get null token
      SharedPreferences testPrefs = await SharedPreferences.getInstance();
      await testPrefs.reload();

      String? testToken = testPrefs.getString(valueShared_BEARER_KEY);
      if (testToken == null) {
        print("✅ Background handler cache should now be cleared");
      } else {
        print("❌ Background handler cache clear failed - token still exists");
      }

    } catch (e) {
      print("❌ Error clearing background handler cache: $e");
    }
  }
  // 3. Add this new method to your _CustomDrawerState class:
  Widget _expandableProductItem() {
    return Column(
      children: [
        ListTile(
          leading: Image.asset('assets/images/product.png',color: Color(0xff757B8F),height: 20,width: 25,),
          title: Row(
            children: [
              Text('product'.tr, style: const TextStyle(fontSize: 16)),
              Spacer(),
              Icon(
                isProductExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
              ),
            ],
          ),
          onTap: () {
            setState(() {
              isProductExpanded = !isProductExpanded;
            });
          },
            dense: true, // Add this line
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Add this line
            visualDensity: VisualDensity.compact,
        ),
        if (isProductExpanded) ...[
          _subDrawerItem('category'.tr, onTap: () {
            Navigator.of(context).pop();
            // Navigate to Category screen
             Get.to(() => Category());
          }),
          _subDrawerItem('product'.tr, onTap: () {
            Navigator.of(context).pop();
            // Navigate to Items screen
             Get.to(() => Products());
          }),
          _subDrawerItem('topping'.tr, onTap: () {
            Navigator.of(context).pop();
            // Navigate to Toppings screen
            Get.to(() => ToppingsScreen());
          }),
          _subDrawerItem('topping_group'.tr, onTap: () {
            Navigator.of(context).pop();
            // Navigate to Topping Group screen
            Get.to(() => ToppingGroup());
          }),
          _subDrawerItem('group'.tr, onTap: () {
            Navigator.of(context).pop();
            // Navigate to Group Item screen
             Get.to(() => GroupItem());
          }),
          _subDrawerItem('product_group'.tr, onTap: () {
            Navigator.of(context).pop();
            // Navigate to Product Groups screen
             Get.to(() => ProductGroup());
          }),
        ],
      ],
    );
  }

  Widget _subDrawerItem(String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0),
      child: ListTile(
        title: Text(
         '- ${title}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w400,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Add this line
        visualDensity: VisualDensity.compact, //
      ),
    );
  }
}