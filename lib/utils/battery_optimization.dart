import 'package:flutter/services.dart';

Future<bool> isIgnoringBatteryOptimizations() async {
  const platform = MethodChannel('com.food.mandeep.food_app/battery');
  try {
    final bool result = await platform.invokeMethod('isIgnoringBatteryOptimizations');
    return result;
  } on PlatformException {
    return false;
  }
}
