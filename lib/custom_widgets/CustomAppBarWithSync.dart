import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../controllers/login_controller.dart';
import '../screens/divisions_screen.dart';
import '../screens/login_screen.dart';
import 'customsnackbar.dart';

class CustomAppBarWithSync extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onSync;
  final bool showKebabMenu;
  final VoidCallback? onLogout;
  final VoidCallback? onSwitch;
  final VoidCallback? onDivision;
  final Widget? destinationScreen;
  late  DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  CustomAppBarWithSync({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onSync,
    this.showKebabMenu = false,
    this.onLogout,
    this.onSwitch,
    this.onDivision,
    this.destinationScreen, // Make it optional

  }) : super(key: key) {
    _databaseHelper = DatabaseHelper.instance;
  }

  @override
  State<CustomAppBarWithSync> createState() => _CustomAppBarWithSyncState();


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarWithSyncState extends State<CustomAppBarWithSync> {
  List<Map<String, dynamic>> campsData = [];
  var mrCodedb;
  late String answersdb;
  late DatabaseHelper _databaseHelper;
  Map<String, dynamic> resultData = {};
  bool showSyncedSnackbar = false;
  final LoginController loginController = Get.find<LoginController>();
  final Connectivity _connectivity = Connectivity();
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => widget.destinationScreen!),
                  (route) => false,
            );
          } else {
            Navigator.of(context).pop(); // Default back navigation
          }        },
        color: ColorConstants.colorR13,
      )
          : null,
      title: Align(
        alignment: Alignment.center,
        child: Text(
          widget.title,
          style:  TextStyle(
            fontFamily: 'Quicksand-Bold',
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      centerTitle: true,
      toolbarHeight: kToolbarHeight,
      actions: [
        IconButton(
          icon: FutureBuilder<int>(
            future: getCountOfUnsyncedData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          WidgetSpan(
                            child: Icon(Icons.sync, color: ColorConstants.colorR13),
                          ),
                          WidgetSpan(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red, // Set background color to red
                              ),
                              padding: const EdgeInsets.all(6.0), // Adjust padding as needed
                              child: Text(
                                snapshot.data.toString(), // Display the count
                                style: TextStyle(
                                  fontSize: 10.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Icon(Icons.error, color: Colors.red), // Handle error case
                  );
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(), // Show loading indicator while fetching data
                );
              }
            },
          ),
          onPressed: () {
            if (widget.onSync != null) {
              widget.onSync!();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: DropdownButton<String>(
            icon:  Icon(Icons.more_vert, color: Colors.black),
            underline: Container(), // This removes the underline
            onChanged: (String? value) {
              handleDropdownOption(value);
            },
            items: const [
               DropdownMenuItem(
                value: 'Switch',
                child: Text('Home'),
              ),
              DropdownMenuItem(
                value: 'Logout',
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
        // Use the spread operator (...) to include the actions
        ...(widget.actions != null
            ? widget.actions!
            .map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: action,
          );
        })
            .toList()
            : []),
      ],
    );
  }

  void handleDropdownOption(String? value) {
    if (value == 'Logout') {
      DataSingleton().clearSubscriberId();
      DataSingleton().EndCampBtn = "";
      DataSingleton().brands?.clear();
      DataSingleton().displayAddDoctorbtn=true;
      DataSingleton().CampWithSeniorDropDown = "false";
      DataSingleton().print_btn = "";
      DataSingleton().download_btn = "";
      DataSingleton().download_print_btn = "";
      DataSingleton().drConsentText = "";
      DataSingleton().doctorSpecialtyDropDown = null;

      // DataSingleton().ptConsentText = "";
      performLogout();
    } else if (value == 'Switch') {
      DataSingleton().EndCampBtn = "";
      DataSingleton().brands?.clear();
      DataSingleton().displayAddDoctorbtn=true;
      DataSingleton().print_btn = "";
      DataSingleton().download_btn = "";
      DataSingleton().download_print_btn = "";
      performSwitch();
    }
  }




  Future<void> performLogout() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      // No internet connection
      // Default logout logic
      print('Logging out...withsync');
      await s3Upload.initializeAndFetchDivisionDetails();
      await s3Upload.uploadJsonToS3();
      // Clear all data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final prefs1 = await SharedPreferences.getInstance();
      prefs1.setString("device_serial_number",DataSingleton().device_serial_number.toString());

      // Clear users table using DatabaseHelper
      await widget._databaseHelper.clearUsersTable();
      if(DataSingleton().clearDoctor==true){
        await widget._databaseHelper.clearDoctorsTable();
      }

      DataSingleton().bottom_logo = null;
      DataSingleton().top_logo = null;
      DataSingleton().Disclaimer = null;
      DataSingleton().font_size = 16.0;
      DataSingleton().addDoctorBtn = false;
      // Default logout logic
      print('Logging out...');
      Get.offAll(LoginScreen());
    } else {
      CustomSnackbar.showErrorSnackbar(
        title: 'No Internet',
        message: 'Please check your internet connection.',
      );
    }
  }

  void performSwitch() {
    // Default switch logic
    print('Switching...');
    Get.offAll(DivisionsScreen());
  }

  Future<int> getCountOfUnsyncedData() async {
    int doctorsCount = await widget._databaseHelper.getCampsCount();
    return doctorsCount;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight+50);
}
