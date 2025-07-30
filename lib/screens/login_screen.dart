import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/screens/register_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/login_controller.dart';
import '../custom_widgets/elevated_button.dart';
import '../custom_widgets/text_field.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final LoginController controller = Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    print('Datasingleton subscriber id: ${DataSingleton().subscriber_id}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildContent(),
          _buildLoader(),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Main content of the login screen
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogo(),
            const SizedBox(height: 10),
            _buildUsernameField(),
            const SizedBox(height: 20),
            Obx(() => _buildErrorMessage()),
            const SizedBox(height: 20),
            _buildLoginButton(),
            /*   const SizedBox(height: 10),
            InkWell(
              onTap: (){
                Get.to(RegisterScreen());
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8,0,8,0),
                child: Center(child: Text('Register',style: TextStyle(color: Colors.black),)),
              ),
            )*/

          ],
        ),
      ),
    );
  }

  /// Logo widget
  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/toplogologin.png',
        height: 250,
        width: 300,
      ),
    );
  }

  /// Username text field
  Widget _buildUsernameField() {
    return CustomTextField(
      controller: controller.emailText,
      hintText: 'Username',
      keyboardType: TextInputType.text,
      prefixIcon: Icons.person,
    );
  }

  /// Error message displayed below input field
  Widget _buildErrorMessage() {
    return controller.loginErrorMessage.isNotEmpty
        ? Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        controller.loginErrorMessage,
        style: const TextStyle(color: Colors.red),
      ),
    )
        : const SizedBox.shrink();
  }

  /// Login button
  Widget _buildLoginButton() {
    return CustomElevatedButton(
      onPressed: () {
        if (controller.emailText.text.isNotEmpty) {
          controller.CheckDeviceOrPOS(
            Get.context!,
            controller.emailText.text.trim(),
            "1234",
          );
        } else {
          CustomSnackbar.showErrorSnackbar(
            title: 'Error',
            message: 'Please fill Employee Id.',
          );
        }
      },
      text: 'Login',
    );
  }

  /// Loader widget
  Widget _buildLoader() {
    return Obx(() {
      return controller.isLoading
          ? Center(
        child: Image.asset('assets/loader.gif'),
      )
          : const SizedBox.shrink();
    });
  }

  /// Footer widget
  Widget _buildFooter() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _callSupport,
              child: const Text(
                'Kribado support: 1800 1212 606',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  color: Color(0xFF0E5670),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2024-25 Indigital Technologies LLP',
              style: TextStyle(
                fontFamily: 'Quicksand',
                color: Color(0xFF0E5670),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Launches support call
  void _callSupport() async {
    final Uri telLaunchUri = Uri(scheme: 'tel', path: '18001212606');
    if (await canLaunchUrl(telLaunchUri)) {
      await launchUrl(telLaunchUri);
    } else {
      throw 'Could not launch $telLaunchUri';
    }
  }
}
