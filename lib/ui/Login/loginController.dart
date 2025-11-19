import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/StoreSetting.dart';
import '../../utils/log_util.dart';
import '../home_screen.dart';

class LoginController extends GetxController {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Observables
  final selectedEnvironment = 'Prod'.obs;
  final selectedLanguage = 'en'.obs;
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  // Variables
  String? deviceToken;
  Timer? loginTimer;
  late SharedPreferences prefs;

  final supportedLocales = ['en', 'de', 'hi', 'ch'];

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _cancelTimer();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> _initialize() async {
    await _initSharedPreferences();
    await _getDeviceToken();
    _loadSavedCredentials();
    _loadSavedLanguage();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _getDeviceToken() async {
    try {
      deviceToken = await FirebaseMessaging.instance.getToken();
      print("Device Token: $deviceToken");
    } catch (e) {
      print("Error getting device token: $e");
      deviceToken = "default_token";
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void _loadSavedCredentials() {
    final savedUsername = prefs.getString(valueShared_USERNAME_KEY);
    final savedPassword = prefs.getString(valueShared_PASSWORD_KEY);

    if (savedUsername != null && savedPassword != null) {
      emailController.text = savedUsername;
      passwordController.text = savedPassword;
    }
  }

  void _loadSavedLanguage() {
    final savedLang = prefs.getString(valueShared_LANGUAGE);
    if (savedLang != null && supportedLocales.contains(savedLang)) {
      selectedLanguage.value = savedLang;
      Get.updateLocale(Locale(savedLang));
    }
  }

  String getValidatedLocale() {
    final currentLocale = Get.locale?.languageCode ?? 'en';
    return supportedLocales.contains(currentLocale) ? currentLocale : 'en';
  }

  // Login Logic
  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      _showSnackbar("Validation Error", "Please fill in all fields correctly");
      return;
    }

    if (deviceToken == null) {
      _showSnackbar("Error", "Device token not available. Please restart the app.");
      return;
    }

    await _performLogin();
  }

  Future<void> _performLogin() async {
    _showLoadingDialog();
    _startLoginTimer();

    try {
      final result = await ApiRepo().loginApi(
        emailController.text.trim(),
        passwordController.text.trim(),
        deviceToken!,
      );

      _cancelTimer();

      Log.loga("LoginController", "Login result: ${result.toJson()}");

      await _handleLoginSuccess(result);
    } catch (e) {
      _cancelTimer();
      _closeLoadingDialog();

      // Wait for dialog to fully close
      await Future.delayed(const Duration(milliseconds: 500));

      Log.loga("LoginController", "Login error: $e");

      final errorMessage = _parseErrorMessage(e.toString());
      _showErrorDialog("Login Error", errorMessage);
    }
  }

  void _showLoadingDialog() {
    if (!isLoading.value) {
      isLoading.value = true;
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  void _closeLoadingDialog() {
    if (isLoading.value) {
      isLoading.value = false;
      if (Get.isDialogOpen == true) {
        try {
          Get.back();
        } catch (e) {
          print("⚠️ Error closing dialog: $e");
        }
      }
    }
  }

  void _startLoginTimer() {
    _cancelTimer();
    loginTimer = Timer(const Duration(seconds: 7), () {
      _closeLoadingDialog();
      Future.delayed(const Duration(milliseconds: 500), () {
        _showErrorDialog("Timeout", "Login request timed out. Please try again.");
      });
    });
  }

  void _cancelTimer() {
    loginTimer?.cancel();
    loginTimer = null;
  }

  Future<void> _handleLoginSuccess(dynamic result) async {
    // Check if login was actually successful
    if (result.access_token == null || result.access_token!.isEmpty) {
      _closeLoadingDialog();

      // Wait for dialog to fully close before showing message
      await Future.delayed(const Duration(milliseconds: 500));

      // Use a simple dialog instead of snackbar to avoid overlay issues
      _showErrorDialog("Login Failed", "Invalid email or password");
      return;
    }

    await _saveCredentials(result);
    await _syncSettings();

    _closeLoadingDialog();

    // Wait a bit before navigation
    await Future.delayed(const Duration(milliseconds: 300));

    _navigateToHome(result.role_id);
  }

  Future<void> _saveCredentials(dynamic result) async {
    await prefs.setString(valueShared_BEARER_KEY, result.access_token!);
    await prefs.setString(valueShared_STORE_TYPE, result.storeType?.toString() ?? '');
    await prefs.setString(valueShared_USERNAME_KEY, emailController.text.trim());
    await prefs.setString(valueShared_PASSWORD_KEY, passwordController.text.trim());
    //await prefs.setInt(valueShared_ROLE_ID, result.role_id ?? 0);
    await prefs.reload();

    print("✅ Credentials saved successfully");
  }

  Future<void> _syncSettings() async {
    try {
      final bearerKey = prefs.getString(valueShared_BEARER_KEY);
      final storeID = prefs.getString(valueShared_STORE_KEY);

      if (bearerKey != null && storeID != null) {
        final result = await ApiRepo().getStoreSetting(bearerKey, storeID);
        StoreSetting store = result;

        await prefs.setBool('auto_order_accept', store.auto_accept_orders_local ?? false);
        await prefs.setBool('auto_order_print', store.auto_print_orders_local ?? false);
        await prefs.setBool('auto_order_remote_accept', store.auto_accept_orders_remote ?? false);
        await prefs.setBool('auto_order_remote_print', store.auto_print_orders_remote ?? false);
        await prefs.reload();

        print("✅ Settings synced successfully");
      }
    } catch (e) {
      print("⚠️ Error syncing settings: $e");
    }
  }

  void _navigateToHome(int? roleId) {
    if (roleId == 1) {
      //Get.offAll(() => const SuperAdmin());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  String _parseErrorMessage(String errorString) {
    final error = errorString.toLowerCase();

    if (error.contains("401") || error.contains("unauthorized")) {
      return "Invalid email or password";
    }

    if (error.contains("socketexception") ||
        error.contains("network") ||
        error.contains("failed host lookup") ||
        error.contains("connection timed out") ||
        error.contains("connection refused") ||
        error.contains("timeout")) {
      return "No internet connection";
    }

    if (error.contains("400")) return "Invalid email";
    if (error.contains("404")) return "User not found";
    if (error.contains("500")) return "Server error. Please try again later";

    return "Unable to connect. Please check your internet connection";
  }

  // Language Change
  Future<void> changeLanguage(String langCode) async {
    if (!supportedLocales.contains(langCode)) return;

    selectedLanguage.value = langCode;
    Get.updateLocale(Locale(langCode));
    await prefs.setString(valueShared_LANGUAGE, langCode);
  }

  // Environment Change
  Future<void> changeEnvironment(String value) async {
    final newBaseUrl = value == "Prod"
        ? "https://magskr.com/"
        : "https://magskr.de/";

    await prefs.setString(valueShared_BASEURL, newBaseUrl);
    await Future.delayed(const Duration(milliseconds: 100));
    await prefs.reload();

    selectedEnvironment.value = value;

    await Api.init();

    print("🌐 Environment changed to: $value");
    print("✅ New base URL: $newBaseUrl");
  }

  // Password Reset Dialog
  void showPasswordResetDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Password Reset',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(text: 'For password reset assistance, please contact our support team at '),
              TextSpan(
                text: 'support@magskr.com',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' with your registered email address.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // Show error dialog instead of snackbar to avoid overlay issues
  void _showErrorDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _showSnackbar(String title, String message) {
    final context = Get.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        ),
      );
    } else {
      print("⚠️ Snackbar: $title - $message");
    }
  }
}