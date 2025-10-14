import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../utils/validators.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  GlobalKey<FormState> _formKey = GlobalKey();
  late TextEditingController _EmailController = TextEditingController();
  late TextEditingController _PasswordController = TextEditingController();
  bool _obscureText = true;
  late UserLoginH userData;
  late SharedPreferences sharedPreferences;
  String? token;
  String? userName;
  String? password;
  String selectedEnvironment = 'Prod';
  // At the top of your _LoginScreenState class
  final supportedLocales = ['en', 'de', 'hi', 'ch'];
  Timer? _loginTimer;
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
  void dispose() {
    _loginTimer?.cancel();
    super.dispose();
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
              margin: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(-10, 25),
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
                    height: 20,
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

      _loginTimer = Timer(Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("Login Timeout", "Login request timed out. Please try again.");
        }
      });

      final result = await ApiRepo().loginApi(email, password, deviceToken);
      _loginTimer?.cancel();

      Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");

      if (result != null && result.access_token != null && result.access_token!.isNotEmpty) {
        print("🔐 Login successful, clearing old data and saving new token...");
        await _forceCompleteCleanup();
        await Future.delayed(Duration(milliseconds: 50));
        SharedPreferences freshPrefs = await SharedPreferences.getInstance();
        print("💾 Saving bearer token...");
        await freshPrefs.setString(valueShared_BEARER_KEY, result.access_token!);
        await Future.delayed(Duration(milliseconds: 50));
        print("💾 Saving StoreType...");
        await freshPrefs.setString(valueShared_STORE_TYPE, result.storeType!.toString());
        print("💾 Saving username...");
        await freshPrefs.setString(valueShared_USERNAME_KEY, _EmailController.text.toString());
        await Future.delayed(Duration(milliseconds: 50));
        print("💾 Saving password...");
        await freshPrefs.setString(valueShared_PASSWORD_KEY, _PasswordController.text.toString());
        await Future.delayed(Duration(milliseconds: 50));
        await freshPrefs.reload();
        await Future.delayed(Duration(milliseconds: 100));
        await freshPrefs.reload();
        String? verifyToken = freshPrefs.getString(valueShared_BEARER_KEY);
        String? verifyStore = freshPrefs.getString(valueShared_STORE_KEY);
        String? verifyUsername = freshPrefs.getString(valueShared_USERNAME_KEY);
        String? verifyStoreType = freshPrefs.getString(valueShared_STORE_TYPE);
        print("🔍 Verification Results:");
        print("🔑 Token: ${verifyToken?.substring(0, 20) ?? 'NULL'}...");
        print("🏪 Store: $verifyStore");
        print("👤 Username: $verifyUsername");
        print("🏪 Store Type: $verifyStoreType");

        if (verifyToken != null && verifyToken == result.access_token) {
          print("✅ Token verification: PASSED");
          print("👤 Role ID: ${result.role_id}");
          print("🆔 Token Length: ${result.access_token?.length}");
          sharedPreferences = freshPrefs;
          await _forceBackgroundHandlerTokenRefresh();
          await SettingsSync.syncSettingsAfterLogin();
          Get.back();
          Get.to(() => HomeScreen());
        } else {
          print("❌ Token verification failed!");
          Get.back(); // Close loader on verification failure
          showSnackbar("Error", "Failed to save login credentials");
        }
      } else {
        Get.back();
        showSnackbar("Login Failed", "Invalid email or password");
      }
    } catch (e)
    {
      _loginTimer?.cancel();

      Log.loga(title, "Login Api:: e >>>>> $e");
      Get.back();

      String errorMessage = "";
      String errorString = e.toString().toLowerCase();
      if (errorString.contains("dioexception") && errorString.contains("401")) {
        if (errorString.contains("invalid username or password") ||
            errorString.contains("invalid credentials")) {
          errorMessage = "Invalid email or password";
        } else if (errorString.contains("email")) {
          errorMessage = "Invalid email";
        } else if (errorString.contains("password")) {
          errorMessage = "Invalid password";
        } else {
          errorMessage = "Invalid email or password";
        }
      }

      else if (errorString.contains("socketexception") ||
          errorString.contains("network is unreachable") ||
          errorString.contains("failed host lookup") ||
          errorString.contains("no internet") ||
          errorString.contains("connection timed out") ||
          errorString.contains("connection refused") ||
          errorString.contains("no route to host") ||
          errorString.contains("network error")) {
        errorMessage = "No internet connection";
      }
      else if (errorString.contains("dioexception") || errorString.contains("dioerror")) {
        if (errorString.contains("400")) {
          // Bad request - usually email format issues
          errorMessage = "Invalid email";
        } else if (errorString.contains("404")) {
          errorMessage = "Invalid email";
        } else if (errorString.contains("500")) {
          errorMessage = "Server error. Please try again later";
        } else if (errorString.contains("timeout")) {
          errorMessage = "No internet connection";
        } else {
          errorMessage = "No internet connection";
        }
      } else {
        errorMessage = "No internet connection";
      }

      showSnackbar("Login Error", errorMessage);
    }
  }

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

  Future<void> _forceCompleteCleanup() async {
    try {
      print("🧹 Starting complete cleanup...");

      // Multiple cleanup attempts
      for (int i = 0; i < 3; i++) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Clear all user-related keys
        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,
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
        await Future.delayed(Duration(milliseconds: 50));
      }

      print("✅ Complete cleanup finished");
    } catch (e) {
      print("❌ Error in complete cleanup: $e");
    }
  }

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

  Future<void> changeLanguage(String langCode) async {
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
    await sharedPreferences.setString(valueShared_LANGUAGE, langCode);
  }

  Future<void> enviroment(String value) async {
    String newBaseUrl;

    if (value == "Prod") {
      newBaseUrl = "https://magskr.com/";
    } else if (value == "Test") {
      newBaseUrl = "https://magskr.de/";
    } else {
      newBaseUrl = "https://magskr.com/";
    }

    // ✅ Save to SharedPreferences with multiple verification
    await sharedPreferences.setString(valueShared_BASEURL, newBaseUrl);
    await Future.delayed(Duration(milliseconds: 100));
    await sharedPreferences.reload();

    // ✅ Verify it was saved correctly
    String? savedUrl = sharedPreferences.getString(valueShared_BASEURL);
    print("🔧 Environment changed to: $value");
    print("🌐 New base URL set: $newBaseUrl");
    print("🔍 Verified saved URL: $savedUrl");

    if (savedUrl != newBaseUrl) {
      print("⚠️ URL save verification failed, retrying...");
      await sharedPreferences.setString(valueShared_BASEURL, newBaseUrl);
      await sharedPreferences.reload();
    }

    setState(() {
      selectedEnvironment = value;
    });

    // ✅ Reinitialize API with new base URL
    await Api.init();

    // ✅ Additional verification that Api class picked up the new URL
    print("✅ API reinitialized with environment: $value");
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