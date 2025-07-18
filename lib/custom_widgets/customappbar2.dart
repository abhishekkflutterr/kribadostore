import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/NetworkHelper.dart';
import '../controllers/login_controller.dart';
import '../DatabaseHelper.dart';
import '../constants/ColorConstants.dart';

class CustomAppBar2 extends StatefulWidget implements PreferredSizeWidget {
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

  CustomAppBar2({
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
  State<CustomAppBar2> createState() => _CustomAppBar2State();



  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);
}

class _CustomAppBar2State extends State<CustomAppBar2> {
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
    );
  }




  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 50);
}
