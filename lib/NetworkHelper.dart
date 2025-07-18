import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NetworkHelper {
  static final NetworkHelper _instance = NetworkHelper._internal();

  factory NetworkHelper() {
    return _instance;
  }

  NetworkHelper._internal() {
    _initializeStreamController();
  }

  late StreamController<bool> _controller;

  void _initializeStreamController() {
    _controller = StreamController<bool>.broadcast();
  }

  Stream<bool> get isOnline => _controller.stream;

  Future<void> checkInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.none) {
        _controller.add(false); // No internet connection
        // _showToast("No internet connection");
      } else {
        final isOnline = await isInternetAvailable();
        _controller.add(isOnline);
        if (isOnline) {
          // _showToast("Internet is available");
        } else {
          _showToast("Internet is not available");
        }
      }
    } catch (e) {
      print("Error checking internet connection: $e");
      _controller.addError(e);
    }
  }

  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void dispose() {
    _controller.close();
  }
}