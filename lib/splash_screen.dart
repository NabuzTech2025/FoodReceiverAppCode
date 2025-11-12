import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/ui/LoginScreen.dart';
import 'package:food_app/ui/home_screen.dart';
import 'package:lottie/lottie.dart';
/*import 'package:hive/hive.dart';
import 'package:raxar_project/ui/home_screen.dart';*/
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import 'api/api.dart';

/*import '../database/database_source.dart';
import 'login_register/login_screen.dart';*/
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SharedPreferences _prefs;
  final supportedLocales = ['en', 'de', 'hi', 'ch'];

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    _prefs = await SharedPreferences.getInstance();
    final sessionID = _prefs.getString(valueShared_BEARER_KEY);
    await Api.init();
    String? savedLangCode = _prefs.getString(valueShared_LANGUAGE);
    if (savedLangCode != null && supportedLocales.contains(savedLangCode)) {
      changeLanguage(savedLangCode);
    }

    Timer(const Duration(seconds: 4), () {
      if (sessionID != null) {
        // Check if we have a stored tab preference from notification
        String? notificationTab = _prefs.getString('notification_initial_tab');

        if (notificationTab != null) {
          // Clear the stored preference
          _prefs.remove('notification_initial_tab');
          // Navigate with the tab preference
          Get.off(() => const HomeScreen(), arguments: {'initialTab': int.parse(notificationTab)});
        } else {
          // Check if we have navigation arguments from Get.arguments
          final arguments = Get.arguments;
          if (arguments != null && arguments['initialTab'] != null) {
            Get.off(() => const HomeScreen(), arguments: arguments);
          } else {
            // Normal navigation to default tab
            Get.off(() => const HomeScreen());
          }
        }
      } else {
        Get.off(() => const LoginScreen());
      }
    });
  }

  Future<void> changeLanguage(String langCode) async {
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:  
        Lottie.asset(
            'assets/animations/burger.json',
            width: 350,
            height: 350,
            repeat: true, )
      ),
    );
  }
}
