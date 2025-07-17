import 'dart:math';

import 'package:flutter/material.dart';

AppColor appColor = AppColor();

class AppColor {
  static final AppColor _appColor = AppColor._i();

  factory AppColor() {
    return _appColor;
  }

  AppColor._i();

  final Color main = Color(0xFF5297F4);
  final Color primaryColor = Color(0xFF5297F4);
  final Color primaryDarkColor = Color(0xFF5297F4);
  final Color primaryLightColor = Color(0xFF5297F4);
  final Color primaryLight = Color(0xFF5297F4);
  final Color accentColor = Color(0xff39446F);

  final Color bgColor = Color(0xFFEAF1FF);

  final Color white = Colors.white;
  final Color black = Colors.black;
  final Color transparent = Colors.transparent;

  final Color grey = Color(0xff898989);
  final Color greyDark = Color(0xFF424242);
  final Color greyLight = Color(0x23898989);
  final Color pink = Color(0xFFFF4081);
  final Color loginRightColor = Color(0xFF41a0e4);
  final  loginLeftColor = Color(0xFF40b4e5);
  final  backgroundBlueDarkColor = Color(0xFF4086e5);
  final  backgroundBlueLightColor = Color(0xFF3face5);



  final Color notWhite = Color(0xFFEDF0F2);
  final Color notWhite2 = Color(0xFFF7F3F3);
  final Color nearlyWhite = Color(0x8EE2E1E1);

   Color colorBG2 = Color(0xffBAE3F7);


  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  Color generateRandomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];

    Random random = new Random();
    return Color.fromARGB(
        255, random.nextInt(255), random.nextInt(255), random.nextInt(255));
  }
}
