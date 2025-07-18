import 'package:flutter/services.dart';

class AppSettingsHelper {
  static const MethodChannel _channel = MethodChannel('app_settings');

  static Future<void> openAppInfo() async {
    try {
      await _channel.invokeMethod('openAppInfo');
    } catch (e) {
      print("Error opening App Info: $e");
    }
  }
}
