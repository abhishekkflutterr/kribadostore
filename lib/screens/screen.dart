import 'package:flutter/services.dart';

class ScreenUtils {
  static const platform = MethodChannel('com.indigitalit.kribadostore/screen');

  static Future<void> setDisplayMode(String mode) async {
    try {
      await platform.invokeMethod('setDisplayMode', {"mode": mode});
    } on PlatformException catch (e) {
      print("Failed to set display mode: ${e.message}");
    }
  }
}
