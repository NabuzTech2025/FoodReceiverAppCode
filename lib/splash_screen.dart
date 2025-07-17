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
    // After 3 s decide where to go
    // Load and apply stored language
    String? savedLangCode = _prefs.getString(valueShared_LANGUAGE);
    if (savedLangCode != null && supportedLocales.contains(savedLangCode)) {
      changeLanguage(savedLangCode);
    }
    Timer(const Duration(seconds: 4), () {
      Get.off(() => sessionID != null ? HomeScreen() : LoginScreen());
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
        child: Lottie.asset(
            'assets/animations/burger.json',
            width: 350,
            height: 350,
            repeat: true, )
        // Image.asset(
        //   'assets/images/bg.gif',
        //   fit: BoxFit.contain, // 🔑 show the whole GIF, no cropping
        //   gaplessPlayback: true,
        //   width: double.infinity, // let it expand while preserving ratio
        //   height: double.infinity,
        // ),
      ),
    );
  }
}
