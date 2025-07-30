import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../custom_widgets/customappbar.dart';
import '../custom_widgets/elevated_button.dart';
import 'divisions_screen.dart';

class ScaffoldExample extends StatefulWidget {
  const ScaffoldExample({super.key});

  @override
  State<ScaffoldExample> createState() => _ScaffoldExampleState();
}

class _ScaffoldExampleState extends State<ScaffoldExample> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Steps",
        showKebabMenu: false,
        pageNavigationTime:
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Requirements',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              _buildStep(
                '1. Enable Internet',
                'Internet connection is mandatory for the first-time test.',
                Icons.wifi,
              ),
              SizedBox(height: 12),
              _buildStep(
                '2. Enable Bluetooth',
                'Allow Bluetooth permission for printing after the test.',
                Icons.bluetooth,
              ),
              SizedBox(height: 35),
              Text(
                'Note: Due to Android version differences, permissions might not prompt automatically. In such cases, manually enable Location and Bluetooth permissions.',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              if (!_isConnected)
                Text(
                  '⚠ No internet connection detected.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SizedBox(height: 10),
              CustomElevatedButton(
                onPressed: () {
                  if (_isConnected) {
                    Get.off(const DivisionsScreen());
                  } else {
                    Get.snackbar(
                      'No Internet',
                      'Please connect to the internet to proceed.',
                      backgroundColor: Colors.red.withOpacity(0.8),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                text: 'Okay to proceed',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
