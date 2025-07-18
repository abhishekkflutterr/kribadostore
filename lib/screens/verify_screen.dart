import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/custom_widgets/text_field.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../DataSingleton.dart';
import '../constants/urls.dart';
import '../controllers/login_controller.dart';
import '../models/user_login_response.dart';
import 'divisions_screen.dart';

class VerifyScreen extends StatefulWidget {
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late String divisionId;
  final LoginController loginController = Get.find<LoginController>();
  final TextEditingController _subCodeController = TextEditingController();

  Future<void> verify() async {
    divisionId = Get.arguments?['divisionId'] ?? '';
    var subscriptionCode = _subCodeController.text;

    if (subscriptionCode.isEmpty) {
      // Show a dialog indicating that the subscription code is empty
      CustomSnackbar.showErrorSnackbar(title: 'Oops', message: "Please fill in the Subscription Code.");
      return; // Exit the method early
    }


    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };



    print('urlverify ${Uri.parse('$baseurl/sub_code_verification/$divisionId')}');

    http.Response response = await http.post(
      Uri.parse('$baseurl/sub_code_verification/$divisionId'),
      body: {'subscription_code': subscriptionCode.toString()},
      headers: headers,
    );

    if (response.statusCode == 200) {



      autoLoginapi();



      Get.offAll(DivisionsScreen());

      CustomSnackbar.showErrorSnackbar(
        title: 'Verified Done',
        message: 'Verified successfully.',
      );


      print('success verify');
    } else {
      CustomSnackbar.showErrorSnackbar(title: "Error", message: "Something Went Wrong");
      print('res verify code ${response.statusCode}');
    }
  }


  Future<void> autoLoginapi() async {

    // Check if a token is present in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    print('username splash $username');
    final user_id = prefs.getString('user_id');
    print('userid splash $user_id');

    print('token spalsh $token');

    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };



    http.Response response = await http.post(
      Uri.parse('$baseurl/auto_login'),
      body: {'username': username, 'user_id': user_id},
      headers: headers,
    );

    if (response.statusCode == 200) {

      print('response in splasf ${response.body}');
      // Parse the response body into your model
      LoginResponse userLoginResponse =
      LoginResponse.fromJson(json.decode(response.body));

      Get.find<LoginController>().setUserLoginResponse(userLoginResponse);
      Get.find<LoginController>().updateUserLoginResponse(userLoginResponse);

      DataSingleton().userLoginOffline = response.body.toString();


    }



  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      // Handle back button pressDataSingleton().division_id
      // For example, navigate to a specific screen

      Get.to(DivisionsScreen());
      return false;
    },
    child: Scaffold(
      appBar: CustomAppBar(title: "Verify", showKebabMenu: true, showBackButton: false,pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(controller: _subCodeController, hintText: 'Subscription Code', errorText: '',),
            SizedBox(height: 20),
            CustomElevatedButton(
              text: 'Submit',
              onPressed: () {
                verify();
              },
            ),
          ],
        ),
      ),),
    );
  }
}
