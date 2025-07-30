import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:kribadostore/NetworkHelper.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/screens/divisions_screen.dart';
import 'package:kribadostore/screens/login_screen.dart';
import 'package:kribadostore/screens/print.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/login_controller.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../constants/ColorConstants.dart';

class CustomAppBar1 extends StatefulWidget implements PreferredSizeWidget {
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
  final bool status;
  final S3Upload s3Upload = S3Upload();

  CustomAppBar1({
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
    this.status = false,
    this.showHome = false,
    this.showSwitchPrinter = false,
    this.onSwitchPrinter,
    this.showLogout = false,
  }) : super(key: key) {
    _databaseHelper = DatabaseHelper.instance;
  }

  @override
  State<CustomAppBar1> createState() => _CustomAppBar1State();



  Future<void> statusSync() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? status = prefs.getString('status');
    String? message = prefs.getString('message');
    if (status == "error") {
      await performLogout();
      await prefs.clear();

      final prefs1 = await SharedPreferences.getInstance();
      prefs1.setString("device_serial_number",DataSingleton().device_serial_number.toString());

      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text('$message',style: TextStyle(color: Colors.black),),
            actions: [
              TextButton(
                onPressed: () {
                  DataSingleton().status = false;
                  Navigator.of(context).pop();
                  Get.off(LoginScreen());
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );

    } else {
      print('@@@###ELSE BLOCKOF SP');
    }
  }

  Future<void> autoSync(String currentDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastLogin = prefs.getString('lastLogin');
    if (currentDate != lastLogin) {
      await s3Upload.initializeAndFetchDivisionDetails();
      await s3Upload.uploadJsonToS3ButOnlySync();
    } else {
      print('@@@###ELSE BLOCKOF SP');
    }
  }

  Future<void> performLogout() async {
    NetworkHelper networkHelper = NetworkHelper();
    bool isOnline = await networkHelper.isInternetAvailable();

    if (isOnline) {
      await s3Upload.initializeAndFetchDivisionDetails();
      await s3Upload.uploadJsonToS3();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      DataSingleton().bottom_logo = null;
      DataSingleton().top_logo = null;
      DataSingleton().Disclaimer = null;
      DataSingleton().font_size = 16.0;
    } else {
      CustomSnackbar.showErrorSnackbar(
        title: 'No Internet',
        message: 'Please check your internet connection.',
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);
}

class _CustomAppBar1State extends State<CustomAppBar1> {
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
    widget.autoSync(widget.pageNavigationTime!);
    // widget.autoSync("16-11-2024");
    if(DataSingleton().status == true) {
      widget.statusSync();
      print('checkbuilddtimes');
    }
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: widget.showBackButton,
      leading: widget.showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () {
          if (widget.destinationScreen != null) {
            Get.off(widget.destinationScreen);
          } else {
            Get.back();
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
