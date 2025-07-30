import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aws_client/cloud_front_2016_11_25.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kribadostore/NetworkHelper.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/screens/camp_list_screen.dart';
import 'package:kribadostore/screens/divisions_screen.dart';
import 'package:kribadostore/screens/login_screen.dart';
import 'package:kribadostore/screens/print.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/login_controller.dart';
import 'package:aws_client/network_firewall_2020_11_12.dart';
import 'package:aws_client/s3_2006_03_01.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../constants/ColorConstants.dart';
import '../models/ExecuteCamp.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showKebabMenu; // Add showKebabMenu parameter
  final VoidCallback? onLogout;
  final VoidCallback? onSwitch;
  final VoidCallback? onDivision;
  String? pageNavigationTime;
  final Widget? destinationScreen; // Add this line
//added for home & printer
  final bool showHome; // Add flag to control "Home" option
  final VoidCallback? onHome;
  final bool showSwitchPrinter; // Add flag to control "Switch Printer" option
  final VoidCallback? onSwitchPrinter;
  final bool showLogout;
  late DatabaseHelper _databaseHelper;

  CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.showKebabMenu = false,
    this.onLogout,
    this.onSwitch,
    this.onDivision,
    this.pageNavigationTime,
    this.destinationScreen, // Make it optional
    //
    this.onHome,
    this.showHome = false,
    this.showSwitchPrinter = false,
    this.onSwitchPrinter,
    this.showLogout = false,
  }) : super(key: key) {
    _databaseHelper = DatabaseHelper.instance;
  }

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();



  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);
}

class _CustomAppBarState extends State<CustomAppBar> {
  List<Map<String, dynamic>> campsData = [];
  var mrCodedb;
  late String answersdb;
  late DatabaseHelper _databaseHelper;
  Map<String, dynamic> resultData = {};
  bool showSyncedSnackbar = false;
  // Add this variable
  final LoginController loginController = Get.find<LoginController>();
  final Connectivity _connectivity = Connectivity();

  final NetworkHelper networkHelper = NetworkHelper();
  late StreamSubscription<bool> subscription;
  final S3Upload s3Upload = S3Upload();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: widget.showBackButton,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                if (widget.destinationScreen != null) {
                  Get.off(widget.destinationScreen);
                } else   if (widget.destinationScreen == CampListScreen()) {
                  Get.to(widget.destinationScreen);
                }
                else {
                //  Get.back();
                  Navigator.pop(context);
                }
              },
              color: ColorConstants.colorR13,
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
        child: Text(
          widget.title,
          textAlign: TextAlign.center,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: 'Quicksand-Bold',
            fontWeight: FontWeight.bold,
            fontSize: 16, // Adjust font size based on character count
            color: Theme.of(context).primaryColor, // Updated line
            //color: Theme.of(context).textTheme.bodyMedium?.color, // Updated line
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        if (widget.showKebabMenu) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.black, // Customize color as needed
              ),
              onSelected: (String value) {
                handleDropdownOption(value);
              },
              itemBuilder: (BuildContext context) => [
                if (widget.showLogout)
                  const PopupMenuItem<String>(
                    value: 'Logout',
                    child: Text('Log Out'),
                  ),
                if (widget.showHome)
                  const PopupMenuItem<String>(
                    value: 'Home',
                    child: Text('Home'),
                  ),
                if (widget.showSwitchPrinter)
                  const PopupMenuItem<String>(
                    value: 'Switchprinter',
                    child: Text('Switch Printer'),
                  ),
              ],
            ),
          ),
        ],
        // Include other actions using the spread operator
        ...(widget.actions != null
            ? widget.actions!.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: action,
                );
              }).toList()
            : []),
      ],
    );
  }

  Future<void> handleDropdownOption(String? value) async {
    if (value == 'Logout') {
      try {
        DataSingleton().clearSubscriberId();
        DataSingleton().EndCampBtn = "";
        DataSingleton().brands?.clear();
        DataSingleton().displayAddDoctorbtn = true;
        DataSingleton().CampWithSeniorDropDown = "false";
        DataSingleton().print_btn = "";
        DataSingleton().download_btn = "";
        DataSingleton().download_print_btn = "";
        print('@@objectcreation');
        DataSingleton().drConsentText = "";
        //DataSingleton().ptConsentText = "";
        bool isOnline = await networkHelper.isInternetAvailable();

        if (isOnline) {
          performLogout();
        } else {
          CustomSnackbar.showErrorSnackbar(
            title: 'No Internet',
            message: 'Please check your internet connection.',
          );
        }
      } catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    } else if (value == 'Home') {
      DataSingleton().EndCampBtn = "";
      DataSingleton().brands?.clear();
      DataSingleton().displayAddDoctorbtn = true;
      DataSingleton().print_btn = "";
      DataSingleton().download_btn = "";
      DataSingleton().download_print_btn = "";
      Get.to(DivisionsScreen());
    } else if (value == 'Switchprinter') {
      Get.to(PrintScreen(
        automaticprint: false,
      ));
    }
  }


  Future<void> performLogout() async {
    bool isOnline = await networkHelper.isInternetAvailable();

    if (isOnline) {

      await s3Upload.initializeAndFetchDivisionDetails();
      await s3Upload.uploadJsonToS3();

      // Clear all data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final prefs1 = await SharedPreferences.getInstance();
      prefs1.setString("device_serial_number",DataSingleton().device_serial_number.toString());

      DataSingleton().bottom_logo = null;
      DataSingleton().top_logo = null;
      DataSingleton().Disclaimer = null;
      DataSingleton().font_size = 16.0;
      Get.offAll(LoginScreen());

    } else {
      CustomSnackbar.showErrorSnackbar(
        title: 'No Internet',
        message: 'Please check your internet connection.',
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 50);
}
