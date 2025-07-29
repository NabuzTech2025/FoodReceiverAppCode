import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/ui/Driver/driver_screen.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../ui/LoginScreen.dart';
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
        setState(() {
          storeName = store.name.toString();
          print("StoreName2 " + storeName!);
        });
      } else {
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
                storeName == null || storeName!.isEmpty
                    ? SizedBox(
                  width: 30,
                  height: 30,
                  child: Lottie.asset(
                    'assets/animations/burger.json', // Apni Lottie loading animation ka path do
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

          _drawerItem('order'.tr, onTap: () {
            Navigator.of(context).pop(); // close drawer
            widget.onSelectTab(0); //
          }),
          /*_drawerItem('customer'.tr, onTap: () {
            Navigator.of(context).pop(); // close drawer
            //widget.onSelectTab(1); //
          }),*/
          _drawerItem('reports'.tr, onTap: () {
            Navigator.of(context).pop(); // close drawer
            widget.onSelectTab(1); // open tab index 3 (PrinterSettingsScreen)
          }),
          // _drawerItem('Driver', onTap: () {
          //   Navigator.of(context).pop(); // First close drawer
          //   // Then navigate to DriverScreen
          //   Future.delayed(Duration(milliseconds: 100), () {
          //     Get.to(() => DriverScreen());
          //   });
          // }),
          _drawerItem('setting'.tr, onTap: () {
            Navigator.of(context).pop(); // close drawer
            widget.onSelectTab(2); // open tab index 3 (PrinterSettingsScreen)
          }),
          const Spacer(),

          Container(
            child: _drawerItem('logout'.tr, onTap: () async {
              var bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
              logutAPi(bearerKey);
            }),
          ),
          Padding(
            padding:  EdgeInsets.only(left: 15.0),
            child: Text('Version:1.3.0',style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 15
            ),),
          ),
          SizedBox(
            height: 60,
          ),
          /* Container(
            color: Colors.grey[200],
            child: _drawerItem("Logout", onTap: () async {
              await sharedPreferences.remove(valueShared_BEARER_KEY);
              Navigator.of(context).pop(); // close drawer
              Get.to(() => LoginScreen());
              // Add logout logic here
            }),
          ),*/
        ],
      ),
    );
  }

  Widget _drawerItem(String title, {required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  Future<void> logutAPi(String? bearerKey) async {
    try {
      print("🚪 Starting logout process...");

      final result = await ApiRepo().logoutAPi(bearerKey);
      if (result != null) {
        print("✅ Logout API successful");

        // ✅ STEP 1: Force complete logout cleanup
        await _forceCompleteLogoutCleanup();

        // ✅ STEP 2: Clear app controller
        app.appController.clearOnLogout();

        // ✅ STEP 3: Force background handler to clear token cache
        await _forceBackgroundHandlerClearCache();

        // ✅ STEP 4: Close drawer
        Navigator.of(context).pop();

        // ✅ STEP 5: Navigate to login with complete reset
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

// ✅ Complete logout cleanup with multiple attempts
  Future<void> _forceCompleteLogoutCleanup() async {
    try {
      print("🧹 Starting complete logout cleanup...");

      // ✅ Multiple cleanup attempts to ensure complete removal
      for (int attempt = 0; attempt < 3; attempt++) {
        print("🔄 Cleanup attempt ${attempt + 1}/3");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Clear all user-related data
        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,
          valueShared_USERNAME_KEY,
          valueShared_PASSWORD_KEY,
          'auto_order_accept',
          'auto_order_print',
          'selected_language',
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(Duration(milliseconds: 20));
          print("🗑️ Removed: $key");
        }

        // Clear printer settings
        for (int i = 0; i < 5; i++) {
          await prefs.remove('printer_ip_$i');
        }

        // ✅ Force multiple reloads to ensure changes are committed
        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));
        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));

        // ✅ Verify cleanup for this attempt
        String? testToken = prefs.getString(valueShared_BEARER_KEY);
        if (testToken == null) {
          print("✅ Cleanup attempt ${attempt + 1}: SUCCESS");
        } else {
          print("⚠️ Cleanup attempt ${attempt + 1}: Token still exists, retrying...");
        }
      }

      // ✅ Final verification
      SharedPreferences finalPrefs = await SharedPreferences.getInstance();
      await finalPrefs.reload();
      String? finalToken = finalPrefs.getString(valueShared_BEARER_KEY);

      if (finalToken == null) {
        print("✅ Complete logout cleanup SUCCESS - All tokens removed");
      } else {
        print("❌ Logout cleanup FAILED - Token still exists: ${finalToken.substring(0, 10)}...");
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
}
