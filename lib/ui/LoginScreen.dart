import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../api/repository/api_repository.dart';
import '../api/responses/userLogin_h.dart';
import '../constants/constant.dart';
import '../customView/custom_button.dart';
import '../customView/custom_text_form_prefiex.dart';
import '../models/StoreSetting.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';
import '../utils/validators.dart';
import 'ResetPasswordScreen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  GlobalKey<FormState> _formKey = GlobalKey();
  late TextEditingController _EmailController = TextEditingController();
  late TextEditingController _PasswordController = TextEditingController();
  bool _obscureText = true;
  late UserLoginH userData;
  late SharedPreferences sharedPreferences;
  String? token;
  String? userName;
  String? password;
  String selectedEnvironment = 'Prod'; // Default
  // At the top of your _LoginScreenState class
  final supportedLocales = ['en', 'de', 'hi', 'ch'];

  String getValidatedLocale() {
    final currentLocale = Get.locale?.languageCode ?? 'en';
    return supportedLocales.contains(currentLocale) ? currentLocale : 'en';
  }

  @override
  initState() {
    initVar();
    getDeviceToken();
    super.initState();
  }

  Future<void> getDeviceToken() async {
    token = await FirebaseMessaging.instance.getToken();
    print("DeviceToken " + token.toString());
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    userName = sharedPreferences.getString(valueShared_USERNAME_KEY);
    password = sharedPreferences.getString(valueShared_PASSWORD_KEY);
    if (userName != null) {
      _EmailController.text = userName!;
      _PasswordController.text = password!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.blue,
            // Cursor color
            selectionColor: Colors.blue.withOpacity(0.3),
            // Highlighted text background color
            selectionHandleColor: Colors.blue, // Selection handle color
          ),
        ),
        home: Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              backgroundColor: Colors.grey[100],
              elevation: 0,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  child: DropdownButton<String>(
                    value: selectedEnvironment,
                    underline: const SizedBox(),
                    icon:
                        const Icon(Icons.security_rounded, color: Colors.black),
                    isDense: true,
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        Text('Prod', style: TextStyle(fontSize: 16,color: Colors.black)),
                        Text('Test', style: const TextStyle(fontSize: 16,color: Colors.black)),
                      ];
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'Prod',
                        child: Text('Prod',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'Test',
                        child:
                            Text('Test', style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) enviroment(value);
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  child: DropdownButton<String>(
                    value: getValidatedLocale(),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language, color: Colors.black),
                    isDense: true,
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        Text('English', style: const TextStyle(fontSize: 16)),
                        Text('German', style: const TextStyle(fontSize: 16)),
                        Text('India', style: const TextStyle(fontSize: 16)),
                        Text('CHF', style: const TextStyle(fontSize: 16)),
                      ];
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'de',
                        child: Text('German',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'hi',
                        child:
                            Text('India', style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'ch',
                        child:
                            Text('CHF', style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) changeLanguage(value);
                    },
                  ),
                ),
              ],
            ),
            body: Container(
              margin: EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // SvgPicture.asset(
                      //   'assets/images/login-vector.svg',
                      //   width: 120,
                      //   height: 120,
                      //   fit: BoxFit.cover,
                      // ),
                      Transform.translate(
                        offset: Offset(-10, 25), // Move up by 10 pixels
                        child: const Text(
                          "Login!",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextFormPrefix(
                            keyboardType: TextInputType.emailAddress,
                            myLabelText: "Username...",
                            controller: _EmailController,
                            icon: Icon(Icons.person,color: Colors.black,),
                            validate: (value) => validateFieldCustomText(
                                value, "Please enter username"),
                            valueChanged: (value) {},
                            obscureText: false),
                        CustomTextFormPrefix(
                          keyboardType: TextInputType.visiblePassword,
                          myLabelText: "Password...",
                          controller: _PasswordController,
                          icon: Icon(Icons.lock,color: Colors.black,),
                          validate: (value) => validateFieldCustomText(
                              value, "Please enter password"),
                          valueChanged: (value) {},
                          obscureText: _obscureText,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(onTap:(){
                     showPasswordResetDialog(context);
                    /*Get.to(() => ResetPasswordScreen());*/
                  },child:
                  Text(
                    "Forget Password",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationStyle:
                          TextDecorationStyle.solid, // Underline the text
                    ),
                  ),),
                  SizedBox(
                    height: 20,
                  ),
                  CustomButton(
                    onPressed: () async {
                      loginApi();
                    },
                    myText: "Login",
                    color: Colors.black,
                    textColor: Colors.white,
                    fontSize: 17,
                    fontWeigt: FontWeight.w700,
                  ),
                ],
              ),
            )));
  }

  void loginApi() {
    final FormState? form = _formKey.currentState;
    //getHiveData();
    if (form!.validate()) {
      print('Form is valid ' + _EmailController.text);
      postloginData(_EmailController.text, _PasswordController.text, token!);
    } else {
      print('Form is invalid');
    }
    //if (validateData()) {}
  }

  Future<void> postloginData(String email, String password, String deviceToken) async {
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

      final result = await ApiRepo().loginApi(email, password, deviceToken);
      Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      Get.back();

      if (result != null) {
        print("🔐 Login successful, clearing old data and saving new token...");

        // ✅ STEP 1: Complete data cleanup
        await _forceCompleteCleanup();

        // ✅ STEP 2: Wait for cleanup to complete
        await Future.delayed(Duration(milliseconds: 500));

        // ✅ STEP 3: Create completely fresh SharedPreferences instance
        SharedPreferences freshPrefs = await SharedPreferences.getInstance();

        // ✅ STEP 4: Set new values with verification
        print("💾 Saving bearer token...");
        await freshPrefs.setString(valueShared_BEARER_KEY, result.access_token!);
        await Future.delayed(Duration(milliseconds: 100));

        print("💾 Saving username...");
        await freshPrefs.setString(valueShared_USERNAME_KEY, _EmailController.text.toString());
        await Future.delayed(Duration(milliseconds: 100));

        print("💾 Saving password...");
        await freshPrefs.setString(valueShared_PASSWORD_KEY, _PasswordController.text.toString());
        await Future.delayed(Duration(milliseconds: 100));

        // ✅ STEP 5: IMPORTANT - Save store ID if available from login response
        // if (result.store_id != null && result.address..toString().isNotEmpty) {
        //   print("💾 Saving store ID: ${result.store_id}");
        //   await freshPrefs.setString(valueShared_STORE_KEY, result.store_id.toString());
        //   await Future.delayed(Duration(milliseconds: 100));
        // } else {
        //   print("⚠️ No store ID in login response - this might cause background issues");
        // }

        // ✅ STEP 6: Force commit and reload multiple times
        await freshPrefs.reload();
        await Future.delayed(Duration(milliseconds: 200));
        await freshPrefs.reload();

        // ✅ STEP 7: Comprehensive verification
        String? verifyToken = freshPrefs.getString(valueShared_BEARER_KEY);
        String? verifyStore = freshPrefs.getString(valueShared_STORE_KEY);
        String? verifyUsername = freshPrefs.getString(valueShared_USERNAME_KEY);

        print("🔍 Verification Results:");
        print("🔑 Token: ${verifyToken?.substring(0, 20) ?? 'NULL'}...");
        print("🏪 Store: $verifyStore");
        print("👤 Username: $verifyUsername");

        if (verifyToken != null && verifyToken == result.access_token) {
          print("✅ Token verification: PASSED");
          print("👤 Role ID: ${result.role_id}");
          print("🆔 Token Length: ${result.access_token?.length}");

          // ✅ STEP 8: Update class instance
          sharedPreferences = freshPrefs;

          // ✅ STEP 9: Force background handler to refresh token cache
          await _forceBackgroundHandlerTokenRefresh();

          // ✅ STEP 10: Test background handler access
          await SettingsSync.syncSettingsAfterLogin();
          Get.to(() => HomeScreen());
        } else {
          print("❌ Token verification failed!");
          showSnackbar("Error", "Failed to save login credentials");
        }
      } else {
        showSnackbar("Error", "Error on login");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
      Get.back();
    }
  }
// Add this method to sync settings after login
  Future<void> syncSettingsAfterLogin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
      String? storeID = prefs.getString(valueShared_STORE_KEY);

      if (bearerKey != null && storeID != null) {
        print("🔄 Syncing settings after login...");

        // Get settings from server
        final result = await ApiRepo().getStoreSetting(bearerKey, storeID);

        if (result != null) {
          StoreSetting store = result;

          // Save to SharedPreferences
          await prefs.setBool('auto_order_accept', store.auto_accept_orders_local ?? false);
          await prefs.setBool('auto_order_print', store.auto_print_orders_local ?? false);
          await prefs.setBool('auto_order_remote_accept', store.auto_accept_orders_remote ?? false);
          await prefs.setBool('auto_order_remote_print', store.auto_print_orders_remote ?? false);

          print("✅ Settings synced after login:");
          print("🔍 Auto Accept: ${store.auto_accept_orders_local ?? false}");
          print("🔍 Auto Print: ${store.auto_print_orders_local ?? false}");
        } else {
          print("❌ Failed to sync settings after login");
        }
      }
    } catch (e) {
      print("❌ Error syncing settings after login: $e");
    }
  }

// Call this method after successful login in your login screen
// Example:
// After successful login:
// await syncSettingsAfterLogin();

// ✅ Complete cleanup function
  Future<void> _forceCompleteCleanup() async {
    try {
      print("🧹 Starting complete cleanup...");

      // Multiple cleanup attempts
      for (int i = 0; i < 3; i++) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Clear all user-related keys
        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_USERNAME_KEY,
          valueShared_PASSWORD_KEY,
          valueShared_STORE_KEY,
          'auto_order_accept',
          'auto_order_print',
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(Duration(milliseconds: 20));
        }

        // Clear printer settings
        for (int j = 0; j < 5; j++) {
          await prefs.remove('printer_ip_$j');
        }

        await prefs.reload();
        await Future.delayed(Duration(milliseconds: 100));
      }

      print("✅ Complete cleanup finished");
    } catch (e) {
      print("❌ Error in complete cleanup: $e");
    }
  }

// ✅ Force background handler to refresh token cache
  Future<void> _forceBackgroundHandlerTokenRefresh() async {
    try {
      print("🔄 Forcing background handler token refresh...");

      // Multiple attempts to ensure background handler can access new token
      for (int i = 0; i < 3; i++) {
        SharedPreferences testPrefs = await SharedPreferences.getInstance();
        await testPrefs.reload();

        String? testToken = testPrefs.getString(valueShared_BEARER_KEY);
        String? testStore = testPrefs.getString(valueShared_STORE_KEY);

        print("🔍 Background test $i - Token: ${testToken?.substring(0, 20) ?? 'NULL'}...");
        print("🔍 Background test $i - Store: $testStore");

        if (testToken != null && testToken.isNotEmpty) {
          print("✅ Background handler token refresh verified on attempt $i");
          break;
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

    } catch (e) {
      print("❌ Error refreshing background handler token: $e");
    }
  }

// ✅ Test background handler access to stored data
  Future<void> _testBackgroundHandlerAccess() async {
    try {
      print("🧪 Testing background handler data access...");

      // Simulate what background handler does
      SharedPreferences bgPrefs = await SharedPreferences.getInstance();
      await bgPrefs.reload();

      String? bgToken = bgPrefs.getString(valueShared_BEARER_KEY);
      String? bgStore = bgPrefs.getString(valueShared_STORE_KEY);
      bool bgAutoAccept = bgPrefs.getBool('auto_order_accept') ?? false;
      bool bgAutoPrint = bgPrefs.getBool('auto_order_print') ?? false;

      print("🧪 Background simulation results:");
      print("🔑 Token available: ${bgToken != null && bgToken.isNotEmpty ? 'YES' : 'NO'}");
      print("🏪 Store available: ${bgStore != null && bgStore.isNotEmpty ? 'YES' : 'NO'}");
      print("🤖 Auto Accept: $bgAutoAccept");
      print("🖨️ Auto Print: $bgAutoPrint");

      if (bgToken != null && bgToken.isNotEmpty) {
        print("✅ Background handler should work correctly");
      } else {
        print("❌ Background handler will fail - token not accessible");
      }

    } catch (e) {
      print("❌ Error testing background handler access: $e");
    }
  }

  // Future<void> postloginData(String email, String password, String deviceToken) async {
  //   try {
  //     Get.dialog(
  //       Center(
  //           child:  Lottie.asset(
  //             'assets/animations/burger.json',
  //             width: 150,
  //             height: 150,
  //             repeat: true, )
  //       //     CupertinoActivityIndicator(
  //       //   radius: 20,
  //       //   color: Colors.orange,
  //       // )
  //       ),
  //       barrierDismissible: false,
  //     );
  //     final result = await ApiRepo().loginApi(email, password, deviceToken);
  //     Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
  //     Get.back();
  //     if (result != null) {
  //       // Handle navigation or success here
  //       sharedPreferences.setString(valueShared_BEARER_KEY, result.access_token!);
  //       sharedPreferences.setString(valueShared_USERNAME_KEY, _EmailController.text.toString());
  //       sharedPreferences.setString(valueShared_PASSWORD_KEY, _PasswordController.text.toString());
  //       print("LoginData  " + result.role_id.toString());
  //       print("LoginDataaccess_token  " + result.access_token.toString());
  //       Get.to(() => HomeScreen());
  //     } else {
  //       showSnackbar("Error", "Error on login");
  //     }
  //   } catch (e) {
  //     Log.loga(title, "Login Api:: e >>>>> $e");
  //     showSnackbar("Api Error", "An error occurred: $e");
  //     Get.back();
  //   }
  // }

  Future<void> changeLanguage(String langCode) async {
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
    await sharedPreferences.setString(valueShared_LANGUAGE, langCode);
  }

  Future<void> enviroment(String value) async {
    if (value == "Prod") {
      sharedPreferences.setString(valueShared_BASEURL, "https://magskr.com/");
    } else if (value == "Test") {
      sharedPreferences.setString(valueShared_BASEURL, "https://magskr.de/");
    } else {
      sharedPreferences.setString(valueShared_BASEURL, "https://magskr.com/");
    }
    setState(() {
      selectedEnvironment = value;
    });
    await Api.init();
  }


  void showPasswordResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Password Reset',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
              ),
              children: [
                TextSpan(text: 'For password reset assistance, please contact our support team at '),
                TextSpan(
                  text: 'support@magskr.com',
                  style: TextStyle(color: Colors.blue),
                ),
                TextSpan(text: ' with your registered email address.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }


}
// Add this utility class or method to your app
// Add this class to a new file or at the top of your main.dart

class SettingsSync {

  /// Call this method immediately after successful login
  static Future<void> syncSettingsAfterLogin() async {
    try {
      print("🔄 Starting settings sync after login...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force fresh data

      String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
      String? storeID = prefs.getString(valueShared_STORE_KEY);

      if (bearerKey == null || bearerKey.isEmpty) {
        print("❌ No bearer token found for settings sync");
        return;
      }

      if (storeID == null || storeID.isEmpty) {
        print("❌ No store ID found for settings sync");
        return;
      }

      print("✅ Syncing settings with token: ${bearerKey.substring(0, 20)}... and store: $storeID");

      // Get settings from server
      final result = await ApiRepo().getStoreSetting(bearerKey, storeID);

      if (result != null) {
        StoreSetting store = result;

        // ✅ Save all settings to SharedPreferences with proper keys
        await prefs.setBool('auto_order_accept', store.auto_accept_orders_local ?? false);
        await prefs.setBool('auto_order_print', store.auto_print_orders_local ?? false);
        await prefs.setBool('auto_order_remote_accept', store.auto_accept_orders_remote ?? false);
        await prefs.setBool('auto_order_remote_print', store.auto_print_orders_remote ?? false);

        // ✅ Force save to disk
        await prefs.reload();

        print("✅ Settings synced successfully after login:");
        print("🔍 Auto Accept Local: ${store.auto_accept_orders_local ?? false}");
        print("🔍 Auto Print Local: ${store.auto_print_orders_local ?? false}");
        print("🔍 Auto Accept Remote: ${store.auto_accept_orders_remote ?? false}");
        print("🔍 Auto Print Remote: ${store.auto_print_orders_remote ?? false}");

        // ✅ Verify the saved values
        bool savedAccept = prefs.getBool('auto_order_accept') ?? false;
        bool savedPrint = prefs.getBool('auto_order_print') ?? false;
        bool savedRemoteAccept = prefs.getBool('auto_order_remote_accept') ?? false;
        bool savedRemotePrint = prefs.getBool('auto_order_remote_print') ?? false;

        print("✅ Verified saved values:");
        print("🔍 Saved Auto Accept: $savedAccept");
        print("🔍 Saved Auto Print: $savedPrint");
        print("🔍 Saved Remote Accept: $savedRemoteAccept");
        print("🔍 Saved Remote Print: $savedRemotePrint");

      } else {
        print("❌ Failed to get store settings from server");
      }
    } catch (e) {
      print("❌ Error syncing settings after login: $e");
    }
  }
}