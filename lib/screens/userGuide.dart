import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../custom_widgets/customappbar.dart';
import '../custom_widgets/customsnackbar.dart';
import '../custom_widgets/elevated_button.dart';
import 'divisions_screen.dart';

class ScaffoldExample extends StatefulWidget {
  const ScaffoldExample({super.key});

  @override
  State<ScaffoldExample> createState() => _ScaffoldExampleState();
}

class _ScaffoldExampleState extends State<ScaffoldExample> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {

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
        pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Requirements',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildStep(
                    context,
                    '1. Enable Internet',
                    'Internet connection is Mandatory for the very first time when the user takes the Test.',
                    Icons.wifi,
                  ),
                  SizedBox(height: 8),
                  _buildStep(
                    context,
                    '2. Enable Bluetooth',
                    'Allow Bluetooth Permission when asked by the application for the Printing of the receipt after the test.',
                    Icons.bluetooth,
                  ),
                  SizedBox(height: 35),
                  Text(
                    'The above permission may sometimes not get asked due to version differences of Android. The user then has to manually switch on the Location and Bluetooth permissions for the app.',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomElevatedButton(
                        onPressed: () async {

                            Get.off(const DivisionsScreen());

                        },
                        text: 'Okay to proceed',
                      ),


                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildStep(BuildContext context, String title, String description, IconData icon) {
    return Row(
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
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



}
