import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/params_args.dart';
import '../controller/AppController.dart';
import '../controller/MapController.dart';
import '../controller/WidgetController.dart';

MyApplication app = MyApplication();

class MyApplication {
  static final MyApplication _myApplication = MyApplication._i();
  AppController _appController = Get.find(tag: ParamsArgus.APP);
  MapController _mapController = Get.find(tag: ParamsArgus.APP);
  WidgetController _widgetController = Get.find(tag: ParamsArgus.WIDGET);

  factory MyApplication() {
    return _myApplication;
  }

  MyApplication._i() {}

  AppController get appController {
    return _appController;
  }
  MapController get mapController {
    return _mapController;
  }
  WidgetController get widgetController {
    return _widgetController;
  }
}
