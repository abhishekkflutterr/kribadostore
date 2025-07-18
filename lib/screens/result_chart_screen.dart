import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:aws_client/network_firewall_2020_11_12.dart';
import 'package:aws_client/s3_2006_03_01.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/Resources.dart';
import 'package:kribadostore/controllers/login_controller.dart';
import 'package:kribadostore/screens/divisions_screen.dart';
import 'package:kribadostore/helper/sharedpref_helper.dart';
import 'package:kribadostore/screens/patient_details_screen.dart';
import 'package:kribadostore/screens/print.dart';
import 'package:kribadostore/screens/print/BluetoothPrinterServiceChart.dart';
import 'package:kribadostore/screens/print_chart.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Camp.dart';
import '../DatabaseHelper.dart';
import '../custom_widgets/customsnackbar.dart';
import '../custom_widgets/elevated_button.dart';
import 'login_screen.dart';

class ResultChartScreen extends StatefulWidget {
  @override
  State<ResultChartScreen> createState() => _ResultChartScreenState();
}

class _ResultChartScreenState extends State<ResultChartScreen> {
  DataSingleton dataSingleton = DataSingleton();
  List<Map<String, dynamic>> campsData = [];

  final S3Upload s3Upload = S3Upload();
  String? mr_id = "";

  var mrCodedb;
  double heightInput = 0.0;
  double weightInput = 0.0;

  late String answersdb;
  Map<String, dynamic> resultData = {};
  final LoginController loginController = Get.find<LoginController>();


  final Connectivity _connectivity = Connectivity();

  bool showSyncedSnackbar = false;
  GlobalKey _globalKey = new GlobalKey();
  DatabaseHelper? _databaseHelper;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotController _screenshotController1 = ScreenshotController();

  String? _base64Image;
  String? _base64Image1;
  late DatabaseHelper _databaseHelper1;

  TextEditingController height_interpretation = new TextEditingController();
  TextEditingController weight_interpretation = new TextEditingController();

  String inter = "";

  List<BluetoothInfo> items = [];
  bool _progress = false;
  String _msj = '';

  late List<Map<String, dynamic>> genderset = heightDataboy;
  final Bluetoothprinterservicechart printerService =
      Bluetoothprinterservicechart();

  String currentGender = "";
  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _progress = false;
    });

    if (listResult.isEmpty) {
      _msj =
          "There are no bluetooths linked, go to settings and link the printer";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(
      () {
        items = listResult;
      },
    );
  }



  Future<void> performLogout() async {
    var connectivityResult = await _connectivity.checkConnectivity();


    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      // No internet connection


      await s3Upload.initializeAndFetchDivisionDetails();
      await s3Upload.uploadJsonToS3();

      // Default logout logic
      print('Logging out...');
      // await _fetchDoctors();
      // await uploadJsonToS3();

      // Clear all data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final prefs1 = await SharedPreferences.getInstance();
      prefs1.setString("device_serial_number",DataSingleton().device_serial_number.toString());

      // Clear users table using DatabaseHelper
      await _databaseHelper?.clearUsersTable();
      if(DataSingleton().clearDoctor==true){
        await _databaseHelper1.clearDoctorsTable();
      }

      // Clear camps table using DatabaseHelper
      // await clearCampsTable();
      DataSingleton().bottom_logo = null;
      DataSingleton().top_logo = null;
      DataSingleton().Disclaimer = null;
      DataSingleton().font_size = 16.0;


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

  Future<void> _capturePng() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    String bs64 = base64Encode(pngBytes);

    DataSingleton().pngBytes = bs64;

    DataSingleton().Interpretation = "chart";
  }

  Future<void> fetchResources() async {
    final List<Map<String, dynamic>> resourcesDataOffline =
        await _databaseHelper!.getAllresources();

    if (resourcesDataOffline.isNotEmpty) {
      // Assuming "division_detail" is stored as a String in the database
      String scalesList = resourcesDataOffline[0]["scales_list"];



      Map<String, dynamic> jsonData = jsonDecode(scalesList);

      String disclaimer = jsonData['data']['meta'].firstWhere(
          (meta) => meta['key'] == 'DISCLAIMER',
          orElse: () => {'value': 'No Disclaimer'})['value'];

      String scalesList1 = resourcesDataOffline[0]["division_detail"];
      Map<String, dynamic> jsonData1 = jsonDecode(scalesList1);

      Map<String, dynamic> userData = jsonData1['data']['user'];
      int mrid = userData['mr_id'];

      String mrcode = userData['emp_code'];

      DataSingleton().subscriber_id = mrid;
      DataSingleton().mr_code = mrcode;

      DataSingleton().Disclaimer = disclaimer;
    } else {
      print('No Discalimer available');
    }
  }

  Future<void> _insertData() async {


    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? subscriber_id = prefs.getString('subscriber_id');
     mr_id = prefs.getString('mr_id');

    print('@@@@@@chartscreensubsid $subscriber_id');


    DataSingleton().heightinter = height_interpretation.text.toString();
    DataSingleton().weightinter = weight_interpretation.text.toString();

    String? scale_id = DataSingleton().scale_id;

    try {
      int divNumeric = DataSingleton().division_id;
      await _databaseHelper?.insertCamp(Camp(
          camp_id: dataSingleton
              .generateMd5(
                  "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}_${DataSingleton().division_id}_$subscriber_id")
              .toString(),
          camp_date: DataSingleton().camp_datec.toString(),
          test_date: DataSingleton().test_datec.toString(),
          test_start_time: DataSingleton().test_start_timec.toString(),
          test_end_time: dataSingleton.getCurrentDateTimeInIST(),
          created_at: dataSingleton.getCurrentDateTimeInIST(),
          scale_id: scale_id.toString(),
          test_score: 0,
          interpretation:
              '${height_interpretation.text.toString()} , ${weight_interpretation.text.toString()}',
          language: "en",
          pat_age: DataSingleton().pat_agec.toString(),
          pat_gender: DataSingleton().pat_genderc.toString(),
          pat_email: "NA",
          pat_mobile: "NA",
          pat_name: DataSingleton().pat_namec.toString(),
          pat_id: DataSingleton().pat_idc.toString(),
          answers: DataSingleton().resultDataformat.toString(),
          division_id: divNumeric,
          subscriber_id: subscriber_id.toString(),
          doc_speciality: DataSingleton().doc_speciality.toString(),
          mr_code: mr_id.toString(),
          dr_consent: DataSingleton().dr_consent,
          patient_consent: DataSingleton().patient_consent,
          country_code: DataSingleton().country_code.toString(),
          state_code: DataSingleton().state_code.toString(),
          city_code: DataSingleton().city_code.toString(),
          area_code: DataSingleton().area_code.toString(),
          doc_code: DataSingleton().doc_code.toString(),
          doc_name: DataSingleton().doc_name.toString(),
          dr_id: DataSingleton().dr_id.toString(),
          doctor_meta: DataSingleton().doctor_meta.toString(),
          patient_meta: DataSingleton().patient_meta.toString()));

      setState(() {});
      print("Database success Camp");
    } catch (e) {
      print("ERROR on scaeNav: $e");
    }
  }

  Future<void> _insertOfflineData() async {
    // Check if any of the required data is null
    if (DataSingleton().division_id == null ||
        DataSingleton().userLoginOffline == null ||
        DataSingleton().divisionDetailOffline == null ||
        DataSingleton().s3jsonOffline == null) {
      print(
          "One or more required values are null. Skipping database insertion.");

      // Print the values to identify which one is null
      print("division_id: ${DataSingleton().division_id}");
      print("userLoginOffline: ${DataSingleton().userLoginOffline}");
      print("divisionDetailOffline: ${DataSingleton().divisionDetailOffline}");
      print("s3jsonOffline: ${DataSingleton().s3jsonOffline}");

      return;
    }

    // Check if any of the required data is empty
    if (DataSingleton().division_id.toString().isEmpty ||
        DataSingleton().userLoginOffline.toString().isEmpty ||
        DataSingleton().divisionDetailOffline.toString().isEmpty ||
        DataSingleton().s3jsonOffline.toString().isEmpty) {
      print("One or more required values are empty. Skipping database insertion.");
      return;
    }

    // Perform database insertion
    await _databaseHelper?.insertResources(
      Resources(
        user_id: DataSingleton().division_id.toString(),
        division_detail: DataSingleton().userLoginOffline.toString(),
        scales_list: DataSingleton().divisionDetailOffline.toString(),
        s3_json: DataSingleton().s3jsonOffline.toString(),
      ),
    );

    print("Database offline insertion success ");
  }

  // resultformat chart [{question_id: 1, score: 3, answer: 3}, {question_id: 2, score: 1, answer: 1}, {question_id: 3, score: 1, answer: Boy}, {question_id: 4, score: 19, answer: 19}, {question_id: 5, score: 20, answer: 20}]

  // resultformat chart
  List<Map<String, dynamic>> resultFormatChart = [
    {'question_id': 1, 'score': 3, 'answer': 18},
    {'question_id': 2, 'score': 1, 'answer': 1},
    {'question_id': 3, 'score': 1, 'answer': 'boy'},
    {'question_id': 4, 'score': 19, 'answer': 166},
    {'question_id': 5, 'score': 20, 'answer': 46},
  ];

  //Start*********************************1 to 4//
  //1st 3rd 5th 15th 25th 50th 75th 85th 95th 97th 99th

  final List<Map<String, dynamic>> heightDataboy_1_4 =    [
    {
      "Age": 0.0,
      "1": 45.5,
      "3": 46.3,
      "5": 46.8,
      "15": 47.9,
      "25": 48.6,
      "50": 49.9,
      "75": 51.2,
      "85": 51.8,
      "95": 53.0,
      "97": 53.4,
      "99": 54.3
    },
    {
      "Age": 0.5,
      "1": 61.0,
      "3": 61.9,
      "5": 62.4,
      "15": 63.7,
      "25": 64.5,
      "50": 65.9,
      "75": 67.3,
      "85": 68.1,
      "95": 69.4,
      "97": 69.9,
      "99": 70.8
    },
    {
      "Age": 1.0,
      "1": 70.2,
      "3": 71.3,
      "5": 71.8,
      "15": 73.3,
      "25": 74.1,
      "50": 75.7,
      "75": 77.4,
      "85": 78.2,
      "95": 79.7,
      "97": 80.2,
      "99": 81.3
    },
    {
      "Age": 1.5,
      "1": 75.1,
      "3": 76.3,
      "5": 76.9,
     "15": 78.5,
      "25": 79.5,
      "50": 81.2,
      "75": 83.0,
      "85": 84.0,
      "95": 85.6,
      "97": 86.2,
      "99": 87.4
    },
    {
      "Age": 2.0,
      "1": 80.7,
      "3": 82.1,
      "5": 82.8,
      "15": 84.6,
      "25": 85.8,
      "50": 87.8,
      "75": 89.9,
      "85": 91.0,
      "95": 92.8,
      "97": 93.6,
      "99": 94.9
    },
    {
      "Age": 3.0,
      "1": 87.5,
      "3": 89.1,
      "5": 90.0,
      "15": 92.2,
      "25": 93.6,
      "50": 96.1,
      "75": 98.6,
      "85": 99.9,
      "95": 102.2,
      "97": 103.1,
      "99": 104.7
    },
    {
      "Age": 3.5,
      "1": 90.1,
      "3": 91.9,
      "5": 92.8,
      "15": 95.2,
      "25": 96.6,
      "50": 99.2,
      "75": 101.9,
      "85": 103.3,
      "95": 105.7,
      "97": 106.6,
      "99": 108.4,

    },
    {
      "Age": 4.0,
      "1": 93.6,
      "3": 95.4,
      "5": 96.4,
      "15": 99.0,
      "25": 100.5,
      "50": 103.3,
      "75": 106.2,
      "85": 107.7,
      "95": 110.2,
      "97": 111.2,
      "99": 113.1
    },
    {
      "Age": 4.5,
      "1": 95.9,
      "3": 97.9,
      "5": 98.9,
      "15": 101.6,
      "25": 103.2,
      "50": 106.1,
      "75": 109.1,
      "85": 110.7,
      "95": 113.3,
      "97": 114.3,
      "99": 116.3
    }
  ];


  final List<Map<String, dynamic>> heightDatagirl_1_4 = [
    {
      "Age": 0.0,
      "1": 44.8,
      "3": 45.6,
      "5": 46.1,
      "15": 47.2,
      "25": 47.9,
      "50": 49.1,
      "75": 50.4,
      "85": 51.1,
      "95": 52.2,
      "97": 52.7,
      "99": 53.5
    },
    {
      "Age": 0.5,
      "1": 58.9,
      "3": 59.9,
      "5": 60.4,
      "15": 61.7,
      "25": 62.5,
      "50": 64.0,
      "75": 65.5,
      "85": 66.3,
      "95": 67.7,
      "97": 68.2,
      "99": 69.2
    },
    {
      "Age": 1.0,
      "1": 68.0,
      "3": 69.2,
      "5": 69.8,
      "15": 71.3,
      "25": 72.3,
      "50": 74.0,
      "75": 75.8,
      "85": 76.7,
      "95": 78.3,
      "97": 78.9,
      "99": 80.0
    },
    {
      "Age": 1.5,
      "1": 73.0,
      "3": 74.3,
      "5": 75.0,
      "15": 76.7,
      "25": 77.7,
      "50": 79.7,
      "75": 81.6,
      "85": 82.6,
      "95": 84.4,
      "97": 85.0,
      "99": 86.3,
    },

    {
      "Age": 2.0,
      "1": 78.9,
      "3": 80.3,
      "5": 81.1,
      "15": 83.1,
      "25": 84.2,
      "50": 86.4,
      "75": 88.6,
      "85": 89.8,
      "95": 91.7,
      "97": 92.5,
      "99": 93.9
    },
    {
      "Age": 2.5,
      "1": 81.8,
      "3": 83.4,
      "5": 84.2,
      "15": 86.3,
      "25": 87.6,
      "50": 89.9,
      "75": 92.2,
      "85": 93.5,
      "95": 95.6,
      "97": 96.4,
      "99": 98.0
    },
    {
      "Age": 3.0,
      "1": 86.2,
      "3": 87.9,
      "5": 88.8,
      "15": 91.1,
      "25": 92.5,
      "50": 95.1,
      "75": 97.6,
      "85": 99.0,
      "95": 101.3,
      "97": 102.2,
      "99": 103.9
    },
    {
      "Age": 3.5,
      "1": 89.0,
      "3": 90.8,
      "5": 91.8,
      "15": 94.2,
      "25": 95.7,
      "50": 98.4,
      "75": 101.1,
      "85": 102.6,
      "95": 105.0,
      "97": 106.0,
      "99": 107.8
    },
    {
      "Age": 4.0,
      "1": 92.7,
      "3": 94.6,
      "5": 95.6,
      "15": 98.3,
      "25": 99.8,
      "50": 102.7,
      "75": 105.6,
      "85": 107.2,
      "95": 109.8,
      "97": 110.8,
      "99": 112.8
    },
    {
      "Age": 4.5,
      "1": 95.2,
      "3": 97.2,
      "5": 98.2,
      "15": 101.0,
      "25": 102.6,
      "50": 105.6,
      "75": 108.6,
      "85": 110.3,
      "95": 113.0,
      "97": 114.1,
      "99": 116.1
    }
  ];

  final List<Map<String, dynamic>> weightDataboy_1_4 = [
    {
      "Age": 0.0,
      "1": 2.3,
      "3": 2.5,
      "5": 2.6,
      "15": 2.9,
      "25": 3.0,
      "50": 3.3,
      "75": 3.7,
      "85": 3.9,
      "95": 4.2,
      "97": 4.3,
      "99": 4.6,
    },
    {
      "Age": 0.5,
      "1": 5.8,
      "3": 6.1,
      "5": 6.2,
      "15": 6.7,
      "25": 7.0,
      "50": 7.5,
      "75": 8.1,
      "85": 8.4,
      "95": 9.0,
      "97": 9.2,
      "99": 9.7
    },
    {
      "Age": 1.0,
      "1": 7.5,
      "3": 7.8,
      "5": 8.1,
      "15": 8.6,
      "25": 9.0,
      "50": 9.6,
      "75": 10.4,
      "85": 10.8,
      "95": 11.5,
      "97": 11.8,
      "99": 12.4
    },
    {
      "Age": 2.0,
      "1": 9.3,
      "3": 9.8,
      "5": 10.1,
      "15": 10.8,
      "25": 11.3,
      "50": 12.2,
      "75": 13.1,
      "85": 13.7,
      "95": 14.7,
      "97": 15.1,
      "99": 15.9
    },
    {
      "Age": 2.5,
      "1": 10.0,
      "3": 10.5,
      "5": 10.8,
      "15": 11.6,
      "25": 12.1,
      "50": 13.1,
      "75": 14.2,
      "85": 14.8,
      "95": 15.9,
      "97": 16.4,
      "99": 17.3
    },
    {
      "Age": 3.0,
      "1": 10.8,
      "3": 11.4,
      "5": 11.8,
      "15": 12.7,
      "25": 13.2,
      "50": 14.3,
      "75": 15.6,
      "85": 16.3,
      "95": 17.5,
      "97": 18.0,
      "99": 19.1
    },
    {
      "Age": 3.5,
      "1": 11.4,
      "3": 12.1,
      "5": 12.4,
      "15": 13.4,
      "25": 14.0,
      "50": 15.2,
      "75": 16.5,
      "85": 17.3,
      "95": 18.6,
      "97": 19.2,
      "99": 20.3
    },
    {
      "Age": 4.0,
      "1": 12.2,
      "3": 12.9,
      "5": 13.3,
      "15": 14.3,
      "25": 15.0,
      "50": 16.3,
      "75": 17.8,
      "85": 18.7,
      "95": 20.2,
      "97": 20.9,
      "99": 22.1
    },
    {
      "Age": 4.5,
      "1": 12.7,
      "3": 13.5,
      "5": 13.9,
      "15": 15.0,
      "25": 15.7,
      "50": 17.2,
      "75": 18.8,
      "85": 19.7,
      "95": 21.4,
      "97": 22.1,
      "99": 23.4
    }
  ];

  final List<Map<String, dynamic>> weightDatagirl_1_4 = [
    {
      "Age": 0.0,
      "1": 2.3,
      "3": 2.4,
      "5": 2.5,
      "15": 2.8,
      "25": 2.9,
      "50": 3.2,
      "75": 3.6,
      "85": 3.7,
      "95": 4.0,
      "97": 4.2,
      "99": 4.4
    },
    {
      "Age": 0.5,
      "1": 5.2,
      "3": 5.5,
      "5": 5.6,
      "15": 6.1,
      "25": 6.4,
      "50": 6.9,
      "75": 7.5,
      "85": 7.8,
      "95": 8.4,
      "97": 8.7,
      "99": 9.2
    },
    {
      "Age": 1.0,
      "1": 6.8,
      "3": 7.1,
      "5": 7.3,
      "15": 7.9,
      "25": 8.2,
      "50": 8.9,
      "75": 9.7,
      "85": 10.2,
     "95": 11.0,
      "97": 11.3,
      "99": 12.0
    },
    {
      "Age": 1.5,
      "1": 7.6,
      "3": 8.0,
      "5": 8.2,
      "10": 8.6,
      "15": 8.8,
      "25": 9.2,
      "50": 10.0,
      "75": 10.9,
      "85": 11.4,
      "90": 11.8,
      "95": 12.3,
      "97": 12.7,
      "99": 13.5
    },
    {
      "Age": 2.0,
      "1": 8.7,
      "3": 9.2,
      "5": 9.4,
      "15": 10.1,
      "25": 10.6,
      "50": 11.5,
      "75": 12.5,
      "85": 13.1,
      "95": 14.2,
      "97": 14.6,
      "99": 15.5
    },
    {
      "Age": 2.5,
      "1": 9.5,
      "3": 10.0,
      "5": 10.2,
      "15": 11.0,
      "25": 11.5,
      "50": 12.5,
      "75": 13.6,
      "85": 14.3,
      "95": 15.5,
      "97": 16.0,
      "99": 17.0
    },
    {
      "Age": 3.0,
      "1": 10.4,
      "3": 11.0,
      "5": 11.3,
      "15": 12.1,
      "25": 12.7,
      "50": 13.9,
      "75": 15.1,
      "85": 15.9,
      "95": 17.3,
      "97": 17.8,
      "99": 19.0
    },
    {
      "Age": 3.5,
      "1": 11.0,
      "3": 11.6,
      "5": 12.0,
      "15": 12.9,
      "25": 13.5,
      "50": 14.8,
      "75": 16.2,
      "85": 17.0,
      "95": 18.6,
      "97": 19.2,
      "99": 20.5
    },
    {
      "Age": 4.0,
      "1": 11.8,
      "3": 12.5,
      "5": 12.9,
      "15": 14.0,
      "25": 14.7,
      "50": 16.1,
      "75": 17.7,
      "85": 18.6,
      "95": 20.4,
      "97": 21.1,
      "99": 22.6
    },
    {
      "Age": 4.5,
      "1": 12.4,
      "3": 13.1,
      "5": 13.5,
      "15": 14.7,
      "25": 15.4,
      "50": 17.0,
      "75": 18.7,
      "85": 19.8,
      "95": 21.7,
      "97": 22.5,
      "99": 24.2
    }
  ]
  ;

  ////

  List<Map<String, dynamic>> getHeightDataBasedOnGender_1_4(String gender) {
    return (gender.toLowerCase() == 'boy')
        ? heightDataboy_1_4
        : heightDatagirl_1_4;
  }

  List<Map<String, dynamic>> getWeightDataBasedOnGender_exp_1_4(String gender) {
    return (gender.toLowerCase() == 'boy')
        ? weightDataboy_1_4
        : weightDatagirl_1_4;
  }

  /////////
  List<FlSpot> convertHeightDataToFlSpot_1_4(String gender) {
    List<FlSpot> spots = [];
    List<Map<String, dynamic>> heightData =
    getHeightDataBasedOnGender_1_4(gender);

    genderset = heightData;
    for (var data in heightData) {
      double age = data['Age'].toDouble();
      double? height = data['$age']?.toDouble();
      if (height != null) {
        spots.add(FlSpot(age, height));
      }
    }

    return spots;
  }

  List<FlSpot> convertWeightDataToFlSpot_1_4(String gender) {
    List<FlSpot> spots = [];
    List<Map<String, dynamic>> heightData =
    getWeightDataBasedOnGender_exp_1_4(gender);

    genderset = heightData;
    for (var data in heightData) {
      double age = data['Age'].toDouble();
      double? height = data['$age']?.toDouble();
      if (height != null) {
        spots.add(FlSpot(age, height));
      }
    }

    return spots;
  }

  ///

  //End*********************************1 to 4//

  final List<Map<String, dynamic>> heightDataboy = [
    {'Age': 5, '3': 99, '10': 102.3, '25': 105.6, '50': 108.9, '75': 112.4, '90': 115.9, '97': 119.4},
    {'Age': 5.5, '3': 101.6, '10': 105.0, '25': 108.4, '50': 111.9, '75': 115.4, '90': 119.0, '97': 122.7},
    {'Age': 6, '3': 104.2, '10': 107.7, '25': 111.2, '50': 114.8, '75': 118.5, '90': 122.2, '97': 126.0},
    {'Age': 6.5, '3': 106.8, '10': 110.4, '25': 114.0, '50': 117.8, '75': 121.6, '90': 125.4, '97': 129.3},
    {'Age': 7, '3': 109.3, '10': 113.0, '25': 116.8, '50': 120.7, '75': 124.6, '90': 128.6, '97': 132.6},
    {'Age': 7.5, '3': 111.8, '10': 115.7, '25': 119.6, '50': 123.5, '75': 127.6, '90': 131.7, '97': 135.9},
    {'Age': 8, '3': 114.3, '10': 118.2, '25': 122.3, '50': 126.4, '75': 130.5, '90': 134.8, '97': 139.1},
    {'Age': 8.5, '3': 116.7, '10': 120.8, '25': 124.9, '50': 129.1, '75': 133.4, '90': 137.8, '97': 142.2},
    {'Age': 9, '3': 119.0, '10': 123.2, '25': 127.5, '50': 131.8, '75': 136.3, '90': 140.7, '97': 145.3},
    {'Age': 9.5, '3': 121.3, '10': 125.6, '25': 130.0, '50': 134.5, '75': 139.1, '90': 143.7, '97': 148.3},
    {'Age': 10, '3': 123.6, '10': 128.1, '25': 132.6, '50': 137.2, '75': 141.9, '90': 146.6, '97': 151.4},
    {'Age': 10.5, '3': 125.9, '10': 130.5, '25': 135.2, '50': 139.9, '75': 144.7, '90': 149.5, '97': 154.4},
    {'Age': 11, '3': 128.2, '10': 133.0, '25': 137.8, '50': 142.7, '75': 147.6, '90': 152.5, '97': 157.5},
    {'Age': 11.5, '3': 130.7, '10': 135.6, '25': 140.6, '50': 145.5, '75': 150.5, '90': 155.6, '97': 160.6},
    {'Age': 12, '3': 133.2, '10': 138.3, '25': 143.3, '50': 148.4, '75': 153.5, '90': 158.6, '97': 163.7},
    {'Age': 12.5, '3': 135.7, '10': 141.0, '25': 146.2, '50': 151.4, '75': 156.5, '90': 161.7, '97': 166.8},
    {'Age': 13, '3': 138.3, '10': 143.7, '25': 149.0, '50': 154.3, '75': 159.5, '90': 164.7, '97': 169.9},
    {'Age': 13.5, '3': 140.9, '10': 146.4, '25': 151.8, '50': 157.2, '75': 162.4, '90': 167.6, '97': 172.7},
    {'Age': 14, '3': 143.4, '10': 149.0, '25': 154.5, '50': 159.9, '75': 165.1, '90': 170.3, '97': 175.4},
    {'Age': 14.5, '3': 145.8, '10': 151.5, '25': 157.0, '50': 162.3, '75': 167.6, '90': 172.7, '97': 177.7},
    {'Age': 15, '3': 148.0, '10': 153.7, '25': 159.2, '50': 164.5, '75': 169.7, '90': 174.8, '97': 179.7},
    {'Age': 15.5, '3': 150.0, '10': 155.7, '25': 161.2, '50': 166.5, '75': 171.6, '90': 176.5, '97': 181.4},
    {'Age': 16, '3': 151.8, '10': 157.4, '25': 162.9, '50': 168.1, '75': 173.1, '90': 178.0, '97': 182.7},
    {'Age': 16.5, '3': 153.4, '10': 159.1, '25': 164.5, '50': 169.6, '75': 174.5, '90': 179.3, '97': 183.8},
    {'Age': 17, '3': 155.0, '10': 160.6, '25': 165.9, '50': 171.0, '75': 175.8, '90': 180.4, '97': 184.8},
    {'Age': 17.5, '3': 156.6, '10': 162.1, '25': 167.3, '50': 172.3, '75': 177.0, '90': 181.5, '97': 185.8},
    {'Age': 18, '3': 158.1, '10': 163.6, '25': 168.7, '50': 173.6, '75': 178.2, '90': 182.5, '97': 186.7},
  ];

  final List<Map<String, dynamic>> heightDataGirl = [
    {'Age': 5.0, '3': 97.2, '10': 100.5, '25': 103.9, '50': 107.5, '75': 111.3, '90': 115.2, '97': 119.3},
    {'Age': 5.5, '3': 99.8, '10': 103.2, '25': 106.8, '50': 110.5, '75': 114.4, '90': 118.3, '97': 122.5},
    {'Age': 6.0, '3': 102.3, '10': 106.0, '25': 109.7, '50': 113.5, '75': 117.4, '90': 121.5, '97': 125.6},
    {'Age': 6.5, '3': 104.9, '10': 108.7, '25': 112.5, '50': 116.5, '75': 120.5, '90': 124.6, '97': 128.7},
    {'Age': 7.0, '3': 107.4, '10': 111.4, '25': 115.4, '50': 119.4, '75': 123.5, '90': 127.7, '97': 131.9},
    {'Age': 7.5, '3': 110.0, '10': 114.1, '25': 118.2, '50': 122.4, '75': 126.6, '90': 130.8, '97': 135.0},
    {'Age': 8.0, '3': 112.6, '10': 116.8, '25': 121.1, '50': 125.4, '75': 129.6, '90': 133.9, '97': 138.1},
    {'Age': 8.5, '3': 115.2, '10': 119.6, '25': 124.0, '50': 128.4, '75': 132.7, '90': 137.0, '97': 141.3},
    {'Age': 9.0, '3': 117.8, '10': 122.4, '25': 126.9, '50': 131.4, '75': 135.8, '90': 140.2, '97': 144.5},
    {'Age': 9.5, '3': 120.5, '10': 125.2, '25': 129.9, '50': 134.4, '75': 138.9, '90': 143.3, '97': 147.6},
    {'Age': 10.0, '3': 123.3, '10': 128.1, '25': 132.8, '50': 137.4, '75': 142.0, '90': 146.4, '97': 150.8},
    {'Age': 10.5, '3': 126.1, '10': 130.9, '25': 135.7, '50': 140.4, '75': 145.0, '90': 149.5, '97': 153.9},
    {'Age': 11.0, '3': 128.8, '10': 133.7, '25': 138.6, '50': 143.3, '75': 147.9, '90': 152.4, '97': 156.8},
    {'Age': 11.5, '3': 131.5, '10': 136.4, '25': 141.2, '50': 145.9, '75': 150.6, '90': 155.1, '97': 159.6},
    {'Age': 12.0, '3': 134.0, '10': 138.9, '25': 143.7, '50': 148.4, '75': 153.0, '90': 157.5, '97': 162.0},
    {'Age': 12.5, '3': 136.3, '10': 141.1, '25': 145.8, '50': 150.5, '75': 155.1, '90': 159.6, '97': 164.1},
    {'Age': 13.0, '3': 138.2, '10': 142.9, '25': 147.6, '50': 152.2, '75': 156.8, '90': 161.3, '97': 165.9},
    {'Age': 13.5, '3': 139.9, '10': 144.5, '25': 149.1, '50': 153.6, '75': 158.2, '90': 162.7, '97': 167.2},
    {'Age': 14.0, '3': 141.3, '10': 145.8, '25': 150.2, '50': 154.7, '75': 159.2, '90': 163.7, '97': 168.2},
    {'Age': 14.5, '3': 142.4, '10': 146.8, '25': 151.1, '50': 155.5, '75': 160.0, '90': 164.5, '97': 169.0},
    {'Age': 15.0, '3': 143.3, '10': 147.5, '25': 151.8, '50': 156.1, '75': 160.5, '90': 165.0, '97': 169.5},
    {'Age': 15.5, '3': 144.1, '10': 148.1, '25': 152.3, '50': 156.6, '75': 160.9, '90': 165.3, '97': 169.8},
    {'Age': 16.0, '3': 144.7, '10': 148.6, '25': 152.7, '50': 156.9, '75': 161.2, '90': 165.6, '97': 170.1},
    {'Age': 16.5, '3': 145.2, '10': 149.1, '25': 153.1, '50': 157.2, '75': 161.4, '90': 165.7, '97': 170.2},
    {'Age': 17.0, '3': 145.7, '10': 149.5, '25': 153.4, '50': 157.4, '75': 161.6, '90': 165.9, '97': 170.4},
    {'Age': 17.5, '3': 146.2, '10': 149.8, '25': 153.6, '50': 157.6, '75': 161.7, '90': 166.0, '97': 170.5},
    {'Age': 18.0, '3': 146.6, '10': 150.2, '25': 153.9, '50': 157.8, '75': 161.9, '90': 166.1, '97': 170.6},
  ];

  List<Map<String, dynamic>> getHeightDataBasedOnGender(String gender) {
    return (gender.toLowerCase() == 'boy') ? heightDataboy : heightDataGirl;
  }

  List<Map<String, dynamic>> getWeightDataBasedOnGender_exp(String gender) {
    return (gender.toLowerCase() == 'boy') ? weightDataboy : weightDataGirl;
  }

  List<FlSpot> convertHeightDataToFlSpot(String gender) {
    List<FlSpot> spots = [];
    List<Map<String, dynamic>> heightData = getHeightDataBasedOnGender(gender);

    genderset = heightData;
    for (var data in heightData) {
      double age = data['Age'].toDouble();
      double? height = data['$age']?.toDouble();
      if (height != null) {
        spots.add(FlSpot(age, height));
      }
    }

    return spots;
  }

  LineChartBarData createUserEnteredPoint() {
    // Find the answer for question_id 1 (age)
    var ageAnswer = resultFormatChart.firstWhere(
            (element) => element['question_id'] == 1,
        orElse: () => {'score': 0})['score'];
    double age = ageAnswer.toDouble();

    print('@@@@@@@@@resultchart $resultFormatChart');

    // Find the answer for question_id 4 (height)
    var heightAnswer = resultFormatChart.firstWhere(
            (element) => element['question_id'] == 4,
        orElse: () => {'answer': 0})['answer'];

    print('@@@@@heightanswer $heightAnswer');


     heightInput = (heightAnswer is double)
        ? heightAnswer
        : double.tryParse(heightAnswer.toString()) ?? 0.0;
    print('@@@@heightchart $heightInput');


    return LineChartBarData(
      spots: [
        FlSpot(age, heightInput),
      ],
      isCurved: false,
      color: Colors.black,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }

  String determinePercentileText(
      double age, double month, double height, String gender, String type) {
    double cal_age = age + (month / 10);
    DataSingleton().Patient_agechart = cal_age.toString();
    DataSingleton().pat_gender = gender;

    if (type == "Height") {
      DataSingleton().pat_height = height.toString();
    }
    if (type == "Weight") {
      DataSingleton().pat_weight = height.toString();
    }

    List<Map<String, dynamic>> heightData;
    if (type == 'Height') {
      heightData = getHeightDataBasedOnGender(gender);
    } else {
      heightData = getWeightDataBasedOnGender_exp(gender);
    }
    if (age == 18 && month >= 0) {
      age = 18;
    } else if (month >= 5 && month <= 11) {
      age = age + 0.5;
    } else if (month == 12) {
      age = age + 1;
    }

    print("@@##**&&currentAge " + age.toString());

    print("@@##**&&currentmonth " + month.toString());
    print("@@##**&&type " + type.toString() + " " + height.toString());

    // Iterate through heightDataboy to find corresponding percentiles
    for (var data in heightData) {
      double currentAge = data['Age'].toDouble();
      int? previousPercentile;
      for (var percentile in ['3', '10', '25', '50', '75', '90', '97']) {
        double? percentileHeight = data[percentile]?.toDouble();
        double? minimum = data['3']?.toDouble();
        double? maximum = data['97']?.toDouble();

        print("@@##**type m" + type.toString() + " " + minimum.toString());
        print("@@##**type mx" + type.toString() + " " + maximum.toString());

        print("@@##**Exp age currentAge " + age.toString());
        print("@@##**Exp currentAge " + currentAge.toString());

        if (percentileHeight != null && currentAge == age) {
          print("@@##%%height" + height.toString());
          print("@@##**&&Gender" + gender.toString());
          print("@@##**&&Gender sing " + DataSingleton().pat_gender.toString());
          print("@@##%%percentileHeight" + percentileHeight.toString());


          if (height == percentileHeight) {
            // Return the percentile information for a perfect match
            return '$type is' + '${percentile}th percentile';
          } else if (height < minimum!) {
            return '$type Below 3rd percentile';
          }else if (type=='Height' && height>=187 && gender=='boy') {
            return 'Input $type is out of range.';
          } else if (type=='Weight' && height>=89 && gender=='girl') {
            return 'Input $type is out of range.';
          }else if (type=='Height' && height>=171 && gender=='boy') {
            return 'Input $type is out of range.';
          } else if (type=='Weight' && height>=74 && gender=='girl') {
            return 'Input $type is out of range.';
          }  else if (height > maximum!) {
            return '$type Above 97th percentile';
          } else if (height < percentileHeight) {
            // Return the percentile information for values less than the percentile
            return '$type Between ${(previousPercentile ?? 0) + 0}th and ${percentile}th percentile';
          }
          // Store the current percentile for the next iteration
          previousPercentile = int.parse(percentile);
        }
      }
    }
    return 'Input $type is out of range.';
  }

  String determinePercentileText1_4(
      double age, double month, double height, String gender, String type) {
    print('@@##Exp gender '+gender);

    double cal_age=age+(month/10);
    DataSingleton().Patient_agechart = cal_age.toString();
    DataSingleton().pat_gender=gender;

    print('@@##**&& before current'+age.toString());
    if(type=="Height"){
      DataSingleton().pat_height=height.toString();
    }if(type=="Weight"){
      DataSingleton().pat_weight=height.toString();
    }

    List<Map<String, dynamic>> heightData;
    if (type == 'Height') {
      heightData = getHeightDataBasedOnGender_1_4(gender);
    } else {
      heightData = getWeightDataBasedOnGender_exp_1_4(gender);
    }

    /*if (month >= 5 && month <= 11) {
      age = age + 0.5;
    } else if (month == 12) {
      age = age + 1;
    }*/


    if(age==0 && month<=4){
      age= 0.5;
    }else if (month >= 5 && month <= 11) {
      age = age + 0.5;
    } else if (month == 12) {
      age = age + 1;
    }



    print("@@##**&& currentAge " + age.toString());
    print("@@##**&& currentmonth " + month.toString());
    print("@@##**&& type " + type.toString() + " " + height.toString());

    // Iterate through heightDataboy to find corresponding percentiles
    for (var data in heightData) {
      double currentAge = data['Age'].toDouble();
      int? previousPercentile;
      for (var percentile in ['1','3', '5','15', '25', '50', '75','85' ,'95', '97','99']) {
        double? percentileHeight = data[percentile]?.toDouble();
        double? minimum = data['1']?.toDouble();
        double? maximum = data['99']?.toDouble();

        print("@@##**type m" + type.toString() + " " + minimum.toString());
        print("@@##**type mx" + type.toString() + " " + maximum.toString());

        if (percentileHeight != null && currentAge == age) {
          print("@@##%%height" + height.toString());
          print("@@##%%percentileHeight" + percentileHeight.toString());

          if (height == percentileHeight) {
            // Return the percentile information for a perfect match
            return '$type is' + '${percentile}th percentile';
          } else if (height < minimum!) {
            return '$type Below 1st percentile';
          } else if (type=='Height' && height>=117 && gender=='boy') {
            return 'Input $type is out of range.';
          } else if (type=='Weight' && height>=25 && gender=='girl') {
            return 'Input $type is out of range.';
          }else if (type=='Weight' && height>=117 && gender=='boy') {
            return 'Input $type is out of range.';
          } else if (type=='Weight' && height>=25 && gender=='girl') {
            return 'Input $type is out of range.';
          }else if (height > maximum!) {
            return '$type Above 99th percentile';
          } else if (height < percentileHeight) {
            // Return the percentile information for values less than the percentile
            return '$type Between ${(previousPercentile ?? 0) + 0}th and ${percentile}th percentile';
          }
          // Store the current percentile for the next iteration
          previousPercentile = int.parse(percentile);
        }
      }
    }
    return 'Input $type is out of range.';
  }
  // Function to manually add a user-entered point to the chart
  void addUserPoint(double age, double height) {
    setState(() {
      heightDataboy.add({'Age': age, 'UserHeight': height});
    });
  }

  //// for weight thing chart changes

  final List<Map<String, dynamic>> weightDataboy = [
    {'Age': 5.0, '3': 13.2, '10': 14.3, '25': 15.6, '50': 17.1, '75': 19.0, '90': 21.3, '97': 24.2},
    {'Age': 5.5, '3': 13.8, '10': 15.0, '25': 16.5, '50': 18.2, '75': 20.3, '90': 22.9, '97': 26.1},
    {'Age': 6.0, '3': 14.5, '10': 15.8, '25': 17.4, '50': 19.3, '75': 21.7, '90': 24.6, '97': 28.3},
    {'Age': 6.5, '3': 15.3, '10': 16.8, '25': 18.6, '50': 20.7, '75': 23.3, '90': 26.6, '97': 30.8},
    {'Age': 7.0, '3': 16.0, '10': 17.6, '25': 19.6, '50': 21.9, '75': 24.9, '90': 28.6, '97': 33.4},
    {'Age': 7.5, '3': 16.7, '10': 18.5, '25': 20.7, '50': 23.3, '75': 26.6, '90': 30.8, '97': 36.2},
    {'Age': 8.0, '3': 17.5, '10': 19.5, '25': 21.9, '50': 24.8, '75': 28.5, '90': 33.2, '97': 39.4},
    {'Age': 8.5, '3': 18.3, '10': 20.5, '25': 23.2, '50': 26.4, '75': 30.5, '90': 35.7, '97': 42.6},
    {'Age': 9.0, '3': 19.1, '10': 21.5, '25': 24.3, '50': 27.9, '75': 32.3, '90': 38.0, '97': 45.5},
    {'Age': 9.5, '3': 19.9, '10': 22.4, '25': 25.6, '50': 29.4, '75': 34.3, '90': 40.5, '97': 48.6},
    {'Age': 10.0, '3': 20.7, '10': 23.5, '25': 26.9, '50': 31.1, '75': 36.3, '90': 43.0, '97': 51.8},
    {'Age': 10.5, '3': 21.6, '10': 24.6, '25': 28.3, '50': 32.8, '75': 38.5, '90': 45.8, '97': 55.2},
    {'Age': 11.0, '3': 22.6, '10': 25.9, '25': 29.8, '50': 34.7, '75': 40.9, '90': 48.7, '97': 58.7},
    {'Age': 11.5, '3': 23.8, '10': 27.3, '25': 31.6, '50': 36.9, '75': 43.5, '90': 51.8, '97': 62.5},
    {'Age': 12.0, '3': 24.9, '10': 28.7, '25': 33.3, '50': 39.0, '75': 46.0, '90': 54.8, '97': 66.1},
    {'Age': 12.5, '3': 26.1, '10': 30.2, '25': 35.1, '50': 41.2, '75': 48.6, '90': 57.8, '97': 69.5},
    {'Age': 13.0, '3': 27.5, '10': 31.8, '25': 37.0, '50': 43.3, '75': 51.1, '90': 60.7, '97': 72.6},
    {'Age': 13.5, '3': 29.0, '10': 33.6, '25': 39.1, '50': 45.7, '75': 53.8, '90': 63.6, '97': 75.6},
    {'Age': 14.0, '3': 30.7, '10': 35.5, '25': 41.3, '50': 48.2, '75': 56.4, '90': 66.3, '97': 78.3},
    {'Age': 14.5, '3': 32.6, '10': 37.7, '25': 43.7, '50': 50.8, '75': 59.1, '90': 69.1, '97': 80.9},
    {'Age': 15.0, '3': 34.5, '10': 39.8, '25': 45.9, '50': 53.1, '75': 61.6, '90': 71.5, '97': 83.1},
    {'Age': 15.5, '3': 36.1, '10': 41.6, '25': 47.9, '50': 55.2, '75': 63.6, '90': 73.4, '97': 84.7},
    {'Age': 16.0, '3': 37.5, '10': 43.1, '25': 49.5, '50': 56.8, '75': 65.2, '90': 74.8, '97': 85.8},
    {'Age': 16.5, '3': 38.7, '10': 44.4, '25': 50.9, '50': 58.2, '75': 66.6, '90': 76.1, '97': 86.8},
    {'Age': 17.0, '3': 39.8, '10': 45.6, '25': 52.1, '50': 59.5, '75': 67.8, '90': 77.1, '97': 87.5},
    {'Age': 17.5, '3': 40.8, '10': 46.7, '25': 53.2, '50': 60.6, '75': 68.7, '90': 77.8, '97': 88.0},
    {'Age': 18.0, '3': 41.8, '10': 47.7, '25': 54.3, '50': 61.6, '75': 69.7, '90': 78.6, '97': 88.4},
  ];

  final List<Map<String, dynamic>> weightDataGirl = [
    {'Age': 5.0, '3': 12.3, '10': 13.4, '25': 14.8, '50': 16.4, '75': 18.5, '90': 21.3, '97': 25.0},
    {'Age': 5.5, '3': 13.0, '10': 14.3, '25': 15.7, '50': 17.6, '75': 19.9, '90': 22.9, '97': 27.0},
    {'Age': 6.0, '3': 13.7, '10': 15.1, '25': 16.7, '50': 18.7, '75': 21.3, '90': 24.6, '97': 29.1},
    {'Age': 6.5, '3': 14.4, '10': 15.9, '25': 17.7, '50': 19.9, '75': 22.7, '90': 26.3, '97': 31.2},
    {'Age': 7.0, '3': 15.1, '10': 16.8, '25': 18.7, '50': 21.2, '75': 24.2, '90': 28.2, '97': 33.4},
    {'Age': 7.5, '3': 15.9, '10': 17.7, '25': 19.9, '50': 22.5, '75': 25.9, '90': 30.1, '97': 35.7},
    {'Age': 8.0, '3': 16.7, '10': 18.7, '25': 21.1, '50': 24.0, '75': 27.6, '90': 32.2, '97': 38.1},
    {'Age': 8.5, '3': 17.5, '10': 19.7, '25': 22.3, '50': 25.5, '75': 29.5, '90': 34.4, '97': 40.7},
    {'Age': 9.0, '3': 18.5, '10': 20.9, '25': 23.7, '50': 27.2, '75': 31.5, '90': 36.7, '97': 43.4},
    {'Age': 9.5, '3': 19.5, '10': 22.1, '25': 25.3, '50': 29.0, '75': 33.6, '90': 39.3, '97': 46.3},
    {'Age': 10.0, '3': 20.7, '10': 23.5, '25': 26.9, '50': 31.0, '75': 36.0, '90': 42.0, '97': 49.4},
    {'Age': 10.5, '3': 22.0, '10': 25.1, '25': 28.8, '50': 33.2, '75': 38.4, '90': 44.8, '97': 52.6},
    {'Age': 11.0, '3': 23.3, '10': 26.7, '25': 30.7, '50': 35.4, '75': 41.0, '90': 47.7, '97': 55.9},
    {'Age': 11.5, '3': 24.8, '10': 28.4, '25': 32.6, '50': 37.6, '75': 43.6, '90': 50.6, '97': 59.1},
    {'Age': 12.0, '3': 26.2, '10': 30.0, '25': 34.5, '50': 39.8, '75': 46.0, '90': 53.4, '97': 62.1},
    {'Age': 12.5, '3': 27.6, '10': 31.6, '25': 36.3, '50': 41.8, '75': 48.2, '90': 55.8, '97': 64.8},
    {'Age': 13.0, '3': 28.9, '10': 33.1, '25': 37.9, '50': 43.6, '75': 50.2, '90': 57.9, '97': 67.1},
    {'Age': 13.5, '3': 30.2, '10': 34.4, '25': 39.4, '50': 45.1, '75': 51.8, '90': 59.7, '97': 69.0},
    {'Age': 14.0, '3': 31.3, '10': 35.6, '25': 40.6, '50': 46.4, '75': 53.2, '90': 61.1, '97': 70.4},
    {'Age': 14.5, '3': 32.3, '10': 36.6, '25': 41.7, '50': 47.5, '75': 54.3, '90': 62.2, '97': 71.4},
    {'Age': 15.0, '3': 33.1, '10': 37.5, '25': 42.5, '50': 48.4, '75': 55.1, '90': 62.9, '97': 72.1},
    {'Age': 15.5, '3': 34.0, '10': 38.3, '25': 43.3, '50': 49.1, '75': 55.8, '90': 63.5, '97': 72.5},
    {'Age': 16.0, '3': 34.7, '10': 39.1, '25': 44.0, '50': 49.7, '75': 56.3, '90': 64.0, '97': 72.8},
    {'Age': 16.5, '3': 35.5, '10': 39.8, '25': 44.7, '50': 50.3, '75': 56.9, '90': 64.4, '97': 73.1},
    {'Age': 17.0, '3': 36.2, '10': 40.5, '25': 45.3, '50': 50.9, '75': 57.3, '90': 64.7, '97': 73.3},
    {'Age': 17.5, '3': 36.9, '10': 41.1, '25': 46.0, '50': 51.5, '75': 57.8, '90': 65.0, '97': 73.4},
    {'Age': 18.0, '3': 37.6, '10': 41.8, '25': 46.6, '50': 52.0, '75': 58.2, '90': 65.3, '97': 73.5},
  ];



  List<Map<String, dynamic>> getWeightDataBasedOnGender(String gender1) {
    return (gender1.toLowerCase() == 'boy') ? weightDataboy : weightDataGirl;
  }

  List<FlSpot> convertWeightDataToFlSpot1(String gender1) {
    List<FlSpot> spots1 = [];
    List<Map<String, dynamic>> weightData = getWeightDataBasedOnGender(gender1);

    for (var data in weightData) {
      double age = data['Age'].toDouble();
      double? weight = data['$age']?.toDouble();
      if (weight != null) {
        spots1.add(FlSpot(age, weight));
      }
    }

    return spots1;
  }

  LineChartBarData createUserEnteredPointWeight() {
    // Find the answer for question_id 1 (age)
    var ageAnswer = resultFormatChart.firstWhere(
            (element) => element['question_id'] == 1,
        orElse: () => {'score': 0})['score'];
    double age = ageAnswer.toDouble();

    // Find the answer for question_id 4 (height)
    var weightAnswer = resultFormatChart.firstWhere(
            (element) => element['question_id'] == 5,
        orElse: () => {'answer': 0})['answer'];

    weightInput = (weightAnswer is double)
        ? weightAnswer
        : double.tryParse(weightAnswer.toString()) ?? 0.0;
    print('@@@@weightchart $weightInput');


    return LineChartBarData(
      spots: [
        FlSpot(age, weightInput),
      ],
      isCurved: false,
      color: Colors.black,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }

  String determinePercentileTextWeight(
      double age, double height, String gender) {


    // Iterate through heightDataboy to find corresponding percentiles
    for (var data in weightDataboy) {
      double currentAge = data['Age'].toDouble();

      print('@@##currentAge ' + '$currentAge');
      int? previousPercentile;
      for (var percentile in ['3', '10', '25', '50', '75', '90', '97']) {
        double? percentileHeight = data[percentile]?.toDouble();
        double? minimum = data['3']?.toDouble();
        double? maximum = data['97']?.toDouble();

        if (percentileHeight != null && currentAge == age) {
          if (height < minimum!) {
            return 'Weight Below 3rd percentile';
          } else if (height > maximum!) {
            return 'Weight Above 97th percentile';
          } else if (height < percentileHeight) {
            // Return the percentile information for values less than the percentile
            return 'Weight Between ${(previousPercentile ?? 0) + 0}th and ${percentile}th percentile';
          } else if (height == percentileHeight) {
            // Return the percentile information for a perfect match
            return 'Weight is ${percentile}th percentile';
          }
          // Store the current percentile for the next iteration
          previousPercentile = int.parse(percentile);
        }
      }
    }
    // Default return if no match found
    return 'No percentile information found';
  }

  @override
  void initState() {
    super.initState();
    getBluetoots();
    _databaseHelper1 = DatabaseHelper.instance;
    _databaseHelper1?.initializeDatabase();

    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();
    // _insertData();

    DataSingleton().skip_sync = false;
    DataSingleton().skip_reinsert_print_btn = false;

    fetchResources();
    print('times run');
    _insertOfflineData();

    Future.delayed(const Duration(milliseconds: 10), () {
      _captureAndPrintScreenshot();
    });



    // // Check if methods haven't been called yet
    // if (!_methodsCalled) {
    //   // Call your methods here
    //   _capturePng();
    //   _insertData();
    //   print('worked 1');
    //   // Set the flag to true to indicate that methods have been called
    //   _methodsCalled = true;
    // }


    resultFormatChart = DataSingleton().resultDataformat;




    var ageYM = resultFormatChart
        .firstWhere((element) => element['question_id'] == 1, orElse: () => {'score': 0})['score']
        .toString() + '.' +
        resultFormatChart
            .firstWhere((element) => element['question_id'] == 2, orElse: () => {'score': 0})['score'].toString();



    print('hsjnjckxncmn $ageYM');

    double ageYMd = double.parse(ageYM);

// Round ageYMd to two decimal places
    double roundedAge = double.parse(ageYMd.toStringAsFixed(2));

    if (roundedAge >=18) {
      // Update age to 18.0
      print('age 18.0');

      DataSingleton().pat_agec = '18.0';
    } else {
      DataSingleton().pat_agec = ageYM;
    }

    var genderquestion = resultFormatChart
        .firstWhere((element) => element['question_id'] == 3, orElse: () => {'score': 0})['score']
        .toString();



    if(genderquestion.contains("0")){

      DataSingleton().pat_genderc = "F";

    }else{
      DataSingleton().pat_genderc = "M";
    }






  }

  @override
  Widget build(BuildContext context) {



    var genderAnswer = resultFormatChart.firstWhere(
            (element) => element['question_id'] == 3,
        orElse: () => {'answer': 'boy'})['answer'];
    String gender = genderAnswer.toLowerCase();

    var ageAnswer = resultFormatChart
        .firstWhere((element) => element['question_id'] == 1,
        orElse: () => {'score': 0})['score']
        .toDouble();

    List<Map<String, dynamic>> heightData;
    if (ageAnswer >= 5) {
      heightData = getHeightDataBasedOnGender(gender);
    } else {
      heightData = getHeightDataBasedOnGender_1_4(gender);
    }

    var monthAnswer = resultFormatChart
        .firstWhere((element) => element['question_id'] == 2,
        orElse: () => {'score': 0})['score']
        .toDouble();

    // var heightAnswer = resultFormatChart
    //     .firstWhere((element) => element['question_id'] == 4,
    //     orElse: () => {'score': 0})['score']
    //     .toDouble();

    List<LineChartBarData> createLineChartBars() {
      List<LineChartBarData> lineChartBars = [];

      for (var percentile in ['3', '10', '25', '50', '75', '90', '97']) {
        List<FlSpot> spots = [];

        for (var data in heightData) {
          double age = data['Age'].toDouble();
          double? height = data[percentile]?.toDouble();

          if (height != null) {
            spots.add(FlSpot(age, height));
          }
        }

        LineChartBarData lineChartBar = LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Colors.black,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );

        lineChartBars.add(lineChartBar);
      }

      lineChartBars.add(createUserEnteredPoint());

      return lineChartBars;
    }

    List<LineChartBarData> createLineChartBars_1_4() {
      List<LineChartBarData> lineChartBars = [];

      for (var percentile in [
        '1',
        '3',
        '5',
        '15',
        '25',
        '50',
        '75',
        '85',
        '95',
        '97'
      ]) {
        List<FlSpot> spots = [];

        for (var data in heightData) {
          double age = data['Age'].toDouble();
          double? height = data[percentile]?.toDouble();

          if (height != null) {
            spots.add(FlSpot(age, height));
          }
        }

        LineChartBarData lineChartBar = LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Colors.black,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );

        lineChartBars.add(lineChartBar);
      }

      lineChartBars.add(createUserEnteredPoint());

      return lineChartBars;
    }

    /////for weight
    var genderAnswer1 = resultFormatChart.firstWhere(
            (element) => element['question_id'] == 3,
        orElse: () => {'answer': 'boy'})['answer'];
    String gender1 = genderAnswer1.toLowerCase();


    var ageAnswer1 = resultFormatChart
        .firstWhere((element) => element['question_id'] == 1,
        orElse: () => {'score': 0})['score']
        .toDouble();

    List<Map<String, dynamic>> heightData1 ;

    if(ageAnswer1>=5){
      heightData1 =
          getWeightDataBasedOnGender(gender1);
    }else{
      heightData1 =
          getWeightDataBasedOnGender_exp_1_4(gender1);
    }



    var monthAnswer1 = resultFormatChart
        .firstWhere((element) => element['question_id'] == 2,
        orElse: () => {'score': 0})['score']
        .toDouble();

    // var heightAnswer1 = resultFormatChart
    //     .firstWhere((element) => element['question_id'] == 5,
    //     orElse: () => {'score': 0})['score']
    //     .toDouble();

    List<LineChartBarData> createLineChartBars1() {
      List<LineChartBarData> lineChartBars1 = [];

      for (var percentile in ['3', '10', '25', '50', '75', '90', '97']) {
        List<FlSpot> spots1 = [];

        for (var data in heightData1) {
          double age = data['Age'].toDouble();
          double? height = data[percentile]?.toDouble();

          if (height != null) {
            spots1.add(FlSpot(age, height));
          }
        }

        LineChartBarData lineChartBar = LineChartBarData(
          spots: spots1,
          isCurved: false,
          color: Colors.black,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );

        lineChartBars1.add(lineChartBar);
      }

      lineChartBars1.add(createUserEnteredPointWeight());

      return lineChartBars1;
    }
    List<LineChartBarData> createLineChartBars1_4() {
      List<LineChartBarData> lineChartBars1 = [];

      for (var percentile in [
        '1',
        '3',
        '5',
        '15',
        '25',
        '50',
        '75',
        '85',
        '95',
        '97'
      ]) {
        List<FlSpot> spots1 = [];

        for (var data in heightData1) {
          double age = data['Age'].toDouble();
          double? height = data[percentile]?.toDouble();

          if (height != null) {
            spots1.add(FlSpot(age, height));
          }
        }

        LineChartBarData lineChartBar = LineChartBarData(
          spots: spots1,
          isCurved: false,
          color: Colors.black,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );

        lineChartBars1.add(lineChartBar);
      }

      lineChartBars1.add(createUserEnteredPointWeight());

      return lineChartBars1;
    }

    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        // Add other theme properties as needed
      ),
      child: WillPopScope(
        onWillPop: () async {
          // Handle back button pressDataSingleton().division_id
          // For example, navigate to a specific screen

          if (DataSingleton().skip_sync != null &&
              DataSingleton().skip_sync == true) {
          } else if (DataSingleton().skip_sync == false) {
            _capturePng();
            _insertData();
          }

          Get.off(const PatientsDetailsScreen());
          return false;
        },
        child: Scaffold(
            // CustomAppBar(title: DataSingleton().scale_name.toString() ?? "Graph Result", showKebabMenu: true,pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),

           // appBar: CustomAppBarPrinter(title: DataSingleton().scale_name.toString() ?? "Graph Result",showKebabMenu: true,showBackButton:true,destinationScreen:PatientsDetailsScreen(),pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
           //     capturePng: _capturePng,insertData: exampleClick,),
           // CustomAppBar(title: DataSingleton().scale_name.toString() ?? "Graph Result", showKebabMenu: true,pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
            appBar: AppBar(
              title: Text(DataSingleton().scale_name.toString() ?? "Graph Result"),
              leading: GestureDetector(
                onTap: () {

            if (DataSingleton().skip_sync == false) {

                   _capturePng();
                  _insertData();
            }
                  Get.off(PatientsDetailsScreen());
                },
                child: Icon(
                  Icons.arrow_back_ios,  // add custom icons also
                ),
              ),
              actions: <Widget>[

            PopupMenuButton(
            itemBuilder: (context) => [
             PopupMenuItem(
             child: Text("Home"),
             onTap: () {

               if (DataSingleton().skip_sync == false) {
                 _capturePng();
                 _insertData();
               }
               DataSingleton().EndCampBtn = "";
               DataSingleton().brands?.clear();
               DataSingleton().displayAddDoctorbtn=true;
               DataSingleton().print_btn = "";
               DataSingleton().download_btn = "";
               DataSingleton().download_print_btn = "";
               Get.offAll(DivisionsScreen());
             },
             ),
              PopupMenuItem(
                child: Text("Switch Printer"),
                onTap: () {
                  Get.to(PrintScreen(
                    automaticprint: false,
                  ));
                },
              ),
              PopupMenuItem(
                child: Text("Log out"),
                onTap: () {
                  _capturePng();
                  _insertData();
                  DataSingleton().clearSubscriberId();
                  DataSingleton().EndCampBtn = "";
                  DataSingleton().brands?.clear();
                  DataSingleton().displayAddDoctorbtn=true;
                  DataSingleton().print_btn = "";
                  DataSingleton().download_btn = "";
                  DataSingleton().download_print_btn = "";
                  DataSingleton().addDoctorBtn = false;
                  performLogout();
                },
              )
           ],
    ),
              ],
            ),
            body: Container(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  RepaintBoundary(
                      key: _globalKey,
                      child: Container(
                          color: Colors.white,
                          child: Column(children: [
                            Text(
                              'IAP  Height-for-age percentile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor),
                            ),
                            ageAnswer1 >= 5
                                ? Text(
                                    '$gender  Height 5-18',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  )
                                : Text(
                                    '$gender  Height 0-4',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  ),
                            /* Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            height: 255,
                            child: LineChart(
                              LineChartData(
                                minX: 5,
                                maxX: 18,
                                minY: 0,
                                maxY: 200,
                                lineBarsData: createLineChartBars(),
                              ),
                            ),
                          ),*/

                            ageAnswer1 >= 5
                                ? Screenshot(
                                    controller: _screenshotController,
                                    child: Container(
                                      color: Colors
                                          .white, // Set white background color

                                      padding: const EdgeInsets.all(10),
                                      width: double.infinity,
                                      height: 255,
                                      child: LineChart(
                                        LineChartData(
                                          minX: 5,
                                          maxX: 18,
                                          minY: 0,
                                          maxY: 200,
                                          lineBarsData: createLineChartBars(),
                                        ),
                                      ),
                                    ),
                                  )
                                : Screenshot(
                                    controller: _screenshotController,
                                    child: Container(
                                      color: Colors
                                          .white, // Set white background color

                                      padding: const EdgeInsets.all(10),
                                      width: double.infinity,
                                      height: 255,
                                      child: LineChart(
                                        LineChartData(
                                          minX: 0,
                                          maxX: 4.5,
                                          minY: 0,
                                          maxY: 125,
                                          lineBarsData:
                                              createLineChartBars_1_4(),
                                        ),
                                      ),
                                    ),
                                  ),
                            ageAnswer >= 5
                                ? Text(
                                    height_interpretation.text =
                                        determinePercentileText(
                                            ageAnswer,
                                            monthAnswer,
                                            heightInput,
                                            gender,
                                            "Height"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  )
                                : Text(
                                    height_interpretation.text =
                                        determinePercentileText1_4(
                                            ageAnswer,
                                            monthAnswer,
                                            heightInput,
                                            gender,
                                            "Height"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  ),
                            Text(
                              '**************',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'IAP Weight-for-age percentile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor),
                            ),
                            ageAnswer1 >= 5
                                ? Text(
                                    '$gender  Weight 5-18',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  )
                                : Text(
                                    '$gender  Weight 0-4',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  ),
                            ageAnswer1 >= 5
                                ? Screenshot(
                                    controller: _screenshotController1,
                                    child: Container(
                                      color: Colors
                                          .white, // Set white background color

                                      padding: const EdgeInsets.all(10),
                                      width: double.infinity,
                                      height: 255,
                                      child: LineChart(
                                        LineChartData(
                                          minX: 5,
                                          maxX: 18,
                                          minY: 0,
                                          maxY: 200,
                                          lineBarsData: createLineChartBars1(),
                                        ),
                                      ),
                                    ),
                                  )
                                : Screenshot(
                                    controller: _screenshotController1,
                                    child: Container(
                                      color: Colors
                                          .white, // Set white background color

                                      padding: const EdgeInsets.all(10),
                                      width: double.infinity,
                                      height: 255,
                                      child: LineChart(
                                        LineChartData(
                                          minX: 0,
                                          maxX: 4.5,
                                          minY: 0,
                                          maxY: 25,
                                          lineBarsData:
                                              createLineChartBars1_4(),
                                        ),
                                      ),
                                    ),
                                  ),
                            ageAnswer1 >= 5
                                ? Text(
                                    weight_interpretation.text =
                                        determinePercentileText(
                                            ageAnswer1,
                                            monthAnswer1,
                                            weightInput,
                                            gender,
                                            "Weight"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  )
                                : Text(
                                    weight_interpretation.text =
                                        determinePercentileText1_4(
                                            ageAnswer1,
                                            monthAnswer1,
                                            weightInput,
                                            gender,
                                            "Weight"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Theme.of(context).primaryColor),
                                  ),
                          ]))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First button: Home
                      CustomElevatedButton(
                        onPressed: () {
                          if (DataSingleton().skip_sync != null &&
                              DataSingleton().skip_sync == true) {
                            // Do nothing if skip_sync is true
                          } else if (DataSingleton().skip_sync == false) {
                            _capturePng();
                            _insertData();
                          }

                          // Navigate to PatientsDetailsScreen
                          Get.off(PatientsDetailsScreen());
                        },
                        text: 'Home', // Button text
                        backgroundColor:   Colors.tealAccent
                      ),

                      const SizedBox(width: 25), // Spacing between buttons

                      // Second button: Print
                      CustomElevatedButton(
                        onPressed: () async {
                          if (DataSingleton().skip_reinsert_print_btn != null &&
                              DataSingleton().skip_reinsert_print_btn == true) {
                            // Do nothing if skip_reinsert_print_btn is true
                          } else if (DataSingleton().skip_reinsert_print_btn ==
                              false) {
                            await _capturePng();
                            await _insertData();
                          }

                          DataSingleton().skip_sync = true;

                          String? deviceName = await getDeviceName();

                          if ([
                            "Alps Q1",
                            "Alps JICAI Q1",
                            "Q1",
                            "JICAI Q2",
                            "Z91"
                          ].contains(deviceName)) {
                            bool isBluetoothEnabled =
                                await PrintBluetoothThermal.bluetoothEnabled;
                            int batteryLevel =
                                await PrintBluetoothThermal.batteryLevel;

                            // Check Bluetooth and battery status early
                            if (!isBluetoothEnabled) {
                              Fluttertoast.showToast(
                                  msg: "Please Turn On Bluetooth");
                              return;
                            }
                            if (batteryLevel <= 15) {
                              lowbattery(context);
                              return;
                            }

                            // Fetch Bluetooth devices only if the items list is empty
                            if (items.isEmpty) {
                              await getBluetoots();
                            }

                            String? bluetoothmac =
                                await SharedprefHelper.getUserData("printer");

                            if (bluetoothmac == null || bluetoothmac.isEmpty) {
                              String printerType = deviceName == "Z91"
                                  ? "bluetoothprint"
                                  : "iposprinter";
                              await handlePrinterSelection(
                                  context, printerType);
                            } else {
                              await handlePrinterConnection(
                                  context, bluetoothmac);
                            }
                          } else {
                            // Handle non-Q1/Q2 devices
                            String? mac =
                                await SharedprefHelper.getUserData("printer");
                            Get.to(PrintChartScreen());
                          }
                        },
                        text: 'Print', // Button text
                        backgroundColor:   Colors.tealAccent
                      ),
                    ],
                  ),
                ],
              ),
            ))),
      ),
    );
  }

  Future<void> _captureAndPrintScreenshot() async {
    // Capture screenshot
    Uint8List? imageBytes = await _screenshotController.capture();
    Uint8List? imageBytes1 = await _screenshotController1.capture();
    // Convert to base64 string
    if (imageBytes != null && imageBytes1 != null) {
      setState(() {
        _base64Image = base64Encode(imageBytes);
        _base64Image1 = base64Encode(imageBytes1);
      });
      print('Base64 Image: $_base64Image');
      DataSingleton().pngBytesChart1 = _base64Image;
      DataSingleton().pngBytesChart2 = _base64Image1;
    } else {
      print('Failed to capture screenshot');
    }
  }

  Widget imageFromBase64String(String base64String,
      {required int width, required int height}) {
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover, // Adjust the fit according to your needs
    );
  }

  Future<String?> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model; // Device model name
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name; // Device name
    }
    return null; // If platform is not Android or iOS
  }

  void showPrintingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(
                  "Printing, please wait...",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> handlePrinterSelection(
      BuildContext context, String printername) async {
    try {
      // Attempt to find the printer from the items list
      final BluetoothInfo targetPrinter = items.firstWhere(
        (item) => item.name.toLowerCase() == printername,
        orElse: () => throw Exception("Printer not found"),
      );

      await SharedprefHelper.saveUserData("printer", targetPrinter.macAdress);
      String? mac = await SharedprefHelper.getUserData("printer");

      if (mac != null && mac.isNotEmpty) {
        await handlePrinterConnection(context, mac);
      }
    } catch (e) {
      // Handle the exception with a dialog notifying the user
      _showErrorDialog(context, e.toString());
      print("Error finding printer: $e");
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent closing by tapping outside the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message), // Display the error message
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> handlePrinterConnection(
      BuildContext dialogContext, String mac) async {
    showPrintingDialog(dialogContext);

    bool status = await printerService.connect(mac);

    if (status) {
      await printerService.printTest();
      Future.delayed(const Duration(seconds: 4), () {
        Navigator.of(dialogContext).pop(); // Close only the dialog
      });
    } else {
      Fluttertoast.showToast(msg: "Unable to connect to printer");
      Navigator.of(dialogContext).pop(); // Close only the dialog on failure
    }
  }

  Future<dynamic> lowbattery(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.battery_alert, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Low Battery Warning',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/batterylow.png', height: 70),
              const SizedBox(height: 10),
              const Text(
                'Your battery level is below 15%. To continue using the printer, please ensure the battery level is greater than 15%.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
