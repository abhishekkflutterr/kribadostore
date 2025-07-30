import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kribadostore/Camp.dart';
import 'package:kribadostore/DatabaseHelper.dart';
import 'package:kribadostore/NetworkHelper.dart';
import 'package:kribadostore/custom_widgets/customappbar2.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/models/division_details_response.dart';
import 'package:kribadostore/screens/doctor_selection_screen.dart';
import 'package:kribadostore/screens/web_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DataSingleton.dart';
import '../constants/ColorConstants.dart';
import '../custom_widgets/elevated_button.dart';
import '../custom_widgets/elevated_button_color.dart';
import '../custom_widgets/text_field.dart';
import '../models/user_login_response.dart';
// Import any other necessary models or classes

class PatientsDetailsScreen extends StatefulWidget {
  const PatientsDetailsScreen({super.key});

  @override
  State<PatientsDetailsScreen> createState() => _PatientsDetailsScreenState();
}

class _PatientsDetailsScreenState extends State<PatientsDetailsScreen> {
  DatabaseHelper? _databaseHelper;
  DataSingleton dataSingleton = DataSingleton();
  late LoginResponse loginResponse;
  DateTime dt = DateTime.now();
  late String scaleId;

  Map<String, String> fields_doctor = {};
  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;

  String? subscriber_id;
  String? mr_id;

  List<String> doctor_Fields_genderOptions_Key = [];
  // List<String> doctor_Fields_genderOptions_Value = [];
  String doctor_Fields_genderOptions_Value = "";

  var tTokenList;
  late Map<String, dynamic> scaleJson;

  var pt_consent;
  get utcIso8601 => null;
  late String patient_id;
  late String camp_date;
  late String test_date;
  late String test_start_time;
  late String print_doc_name;

  DateTime? lastPressedTime;
  List<Map<String, dynamic>> fields = [];
  List<String> Values = []; // Initialize Values to an empty list
  late Map<String, TextEditingController> controllers;
  late Map<String, String> errors;

  Future<List<Scales>?>? divisionDetails() {
    // TODO: implement divisionDetails
    throw UnimplementedError();
  }

  IconData? _getIconData(String key) {
    switch (key) {
      case 'DOCTOR_NAME':
        return Icons.person;
      case 'DOCTOR_CODE':
        return Icons.code;
      case 'PHONE_NUMBER':
        return Icons.phone;
      case 'CITY_NAME':
        return Icons.location_city;
      case 'AREA_NAME':
        return Icons.location_on;
      case 'SPECIALITY':
        return Icons.star;
    // Add more cases for other keys
      default:
        return null;
    }
  }

  Future<void> _clearCacheAndRefresh() async {
    // Clear your cache and re-hit the API here
    // Simulating API call with a delay
    await Future.delayed(Duration(seconds: 1));
    await _fetchs3Offline();
    setState(() {});
    // Refresh the UI
  }

  @override
  void initState() {
    super.initState();
    scaleId = Get.arguments?['name'] ?? '';
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();
    print_doc_name = DataSingleton().doc_name.toString();

    DataSingleton().hbA1c = "0.0";

    print("@@##### " + dataSingleton.scale_id.toString());
    print("@@##### " + DataSingleton().divisionDetailOffline.toString());

    _downloadAndSaveScaleJson(); // <-- Download scale JSON on init

    _fetchs3Offline();
    getfieldfromlocal();
    sharedPrefsData();
  }

  String? _localScalePath = ''; // Initialize to empty string or null

  Future<void> _downloadAndSaveScaleJson() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/scale_${DataSingleton().scale_id}.html'; // Save as .html
      _localScalePath = filePath; // Ensure this is set before use
      final url = 'https://scales5.kribado.com/?scale=${DataSingleton().scale_id}&mode=download';
      print("Scale Url for offline download: $url");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsString(response.body);
        print('Scale HTML saved at $_localScalePath');
      } else {
        print('Failed to download scale HTML');
      }
    } catch (e) {
      print('Error downloading scale HTML: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadScaleJsonFromFile() async {
    try {
      if (_localScalePath == null || _localScalePath!.isEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        _localScalePath = '${dir.path}/scale_${DataSingleton().scale_id}.html'; // Use .html
      }
      final file = File(_localScalePath!);
      if (await file.exists()) {
        final contents = await file.readAsString();
        // If you need to parse JSON, do it here. If you just want to load HTML, return the string.
        // return json.decode(contents); // For JSON
        return {"html": contents}; // For HTML, wrap in a map for compatibility
      }
    } catch (e) {
      print('Error reading scale HTML from file: $e');
    }
    return null;
  }

  Future<void> sharedPrefsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriber_id = prefs.getString('subscriber_id');
    mr_id = prefs.getString('mr_id');
  }

  Future<void> _fetchs3Offline() async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    await databaseHelper.initializeDatabase();

    print('fetchofflineoce');

    List<Map<String, dynamic>> resources1 =
    await databaseHelper.getAllDivisiondetail();
    Map<String, dynamic> screenDetail, division_detail;
    for (var resource in resources1) {
      if (resource.containsKey('scales_list') &&
          resource['scales_list'] != null) {
        screenDetail = json.decode(resource['scales_list']);
        division_detail = json.decode(resource['division_detail']);

        List<dynamic> metaList = [];
        if (screenDetail.containsKey('data')) {
          Map<String, dynamic> data = screenDetail['data'];
          if (data.containsKey('scales')) {
            metaList = data['scales'];

            for (var meta in metaList) {
              var name = meta['name'];
              Map<String, dynamic> data = meta['scale_json'];

              if (DataSingleton().scale_id.toString() == name) {
                if (data['age'] != null) {
                  DataSingleton().age_range = data['age'];

                  List<String> dateParts = data['age'].split("-");
                  DataSingleton().age_min = dateParts[0].toString();
                  DataSingleton().age_max = dateParts[1].toString();
                } else {
                  DataSingleton().age_min = "1";
                  DataSingleton().age_max = "100";
                }

                //           print("@@##^dataxxx "+data['age']);

                /* String refer = data['references'];
               DataSingleton().References = refer;*/

                /* String scalesList1 = resources1[0]["division_detail"];
                 print("@@##^scalesList1 "+scalesList1.toString());
                 Map<String, dynamic> jsonData1 = jsonDecode(division_detail.toString());
*/
                Map<String, dynamic> userData = division_detail['data']['user'];
                int mrid = userData['mr_id'];

                // DataSingleton().subscriber_id = mrid;
              }
            }
          }
        }
      }
    }
  }

  Future<void> _insertData(int i, String jsonstringmap) async {
    print('Database entered try block');
    try {
      print('Database entered try block 1');
      print(
          'Camp ID: ${dataSingleton
              .generateMd5("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}")
              .toString()}');
      print('Camp Date: ${dataSingleton.getCurrentDateTimeInIST()}');
      print('Test Date: ${dataSingleton.getCurrentDateTimeInIST()}');
      print('Test Start Time: ${dataSingleton.getCurrentDateTimeInIST()}');
      print('Test End Time: ${dataSingleton.getCurrentDateTimeInIST()}');
      print('Created At: ${dataSingleton.getCurrentDateTimeInIST()}');
      print('Scale ID: No Test Given');
      print('Test Score: 0.0');
      print('Interpretation: No Test Given');
      print('Language: en');
      print('Patient Age: ${_ageController.text}');
      print('Patient Gender: $myGroupValue');
      print('Patient Email: NA');
      print('Patient Mobile: NA');
      print('Patient Name: ${_nameController.text}');
      print('Patient ID: $patient_id');
      print('Answers: No Test Given');
      print('Division ID: ${DataSingleton().division_id}');
      print('Subscriber abhi ID: ${subscriber_id.toString()}}');
      print('Doctor Speciality: ${DataSingleton().doc_speciality.toString()}');
      print('MR abhi Code: ${mr_id.toString()}');
      print('Doctor Consent: ${DataSingleton().dr_consent}');
      print('Patient Consent: 0');
      print('Country Code: ${DataSingleton().country_code.toString()}');
      print('State Code: ${DataSingleton().state_code.toString()}');
      print('City Code: ${DataSingleton().city_code.toString()}');
      print('Area Code: ${DataSingleton().area_code.toString()}');
      print('Doctor Code: ${DataSingleton().doc_code.toString()}');
      print('Doctor Name: ${DataSingleton().doc_name.toString()}');
      print('Doctor ID: ${DataSingleton().dr_id.toString()}');

      print('Database entered try block2');
      await _databaseHelper?.insertCamp(Camp(
          camp_id: dataSingleton
              .generateMd5(
              "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}_${DataSingleton().division_id}_$subscriber_id")
              .toString(),
          camp_date: dataSingleton.getCurrentDateTimeInIST(),
          test_date: dataSingleton.getCurrentDateTimeInIST(),
          test_start_time: dataSingleton.getCurrentDateTimeInIST(),
          test_end_time: dataSingleton.getCurrentDateTimeInIST(),
          created_at: dataSingleton.getCurrentDateTimeInIST(),
          scale_id: DataSingleton().scale_id.toString(),
          test_score: 0.0,
          interpretation: 'No Test Given',
          language: "en",
          pat_age: _ageController.text,
          pat_gender: myGroupValue,
          pat_email: "NA",
          pat_mobile: "NA",
          pat_name: _nameController.text,
          pat_id: patient_id,
          answers: 'No Test Given',
          division_id: DataSingleton().division_id,
          subscriber_id: subscriber_id.toString(),
          doc_speciality: DataSingleton().doc_speciality.toString(),
          mr_code: mr_id.toString(),
          dr_consent: DataSingleton().dr_consent,
          patient_consent: 0,
          country_code: DataSingleton().country_code.toString(),
          state_code: DataSingleton().state_code.toString(),
          city_code: DataSingleton().city_code.toString(),
          area_code: DataSingleton().area_code.toString(),
          doc_code: DataSingleton().doc_code.toString(),
          doc_name: DataSingleton().doc_name.toString(),
          dr_id: DataSingleton().dr_id.toString(),
          doctor_meta: DataSingleton().doctor_meta.toString(),
          patient_meta: jsonstringmap.toString()));
      print("Database success Camp");
    } catch (e) {
      print("ERROR on scaeNav: $e");
    }
  }

  String myGroupValue = "";
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String label1 = "M";
  String label2 = "F";
  String? nameError;
  String? ageError;
  String? genderError;
  Icon? genderIcon;

  String result = "";

  List<String> resultList = [];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Get.off(DoctorSelectionScreen());
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar2(
            title: 'Patient Details',
            showBackButton: true,
            showKebabMenu: false,
            destinationScreen: DoctorSelectionScreen(),
            pageNavigationTime:
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(28.0, 0.0, 28.0, 16.0),
              child: Column(
                children: [
                  Text("Doctors name: $print_doc_name"),
                  for (var field in fields)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomTextField(
                        controller: controllers[field['key']]!,
                        hintText: field['label']!,
                        // prefixIcon: _getIconData(field['key']!),
                        showRadio: field['label']!.toLowerCase() ==
                            'Gender', // Check if the label is 'Gender'
                        errorText: errors[field['key']]!,
                        // radioValues: field['key']!.toLowerCase().trim() == 'PATIENT_GENDER_OPTIONS' ? doctor_Fields_genderOptions_Value : ['Male'],
                        // radioValues: doctor_Fields_genderOptions_Value,
                        radioValues: DataSingleton().scale_id == "MRS.kribado"
                            ? ['Female']
                            : ['Male', 'Female'],
                        // radioValues: ['Male','Female'],
                        keyboardType: field['key'] == "PATIENT_AGE"
                            ? TextInputType.number
                            : TextInputType.text,
                        onClearCacheAndRefresh: _clearCacheAndRefresh,
                      ),
                    ),
                  Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: ColorConstants.lightGrey,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    surfaceTintColor: ColorConstants.cultured,
                    child: Visibility(
                      visible: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ListTile(
                            leading: genderIcon ??
                                const Icon(
                                  Icons.wc,
                                  color: ColorConstants.cyanCornflowerBlueColor,
                                ),
                            title: const Text(
                              'Gender',
                              style: TextStyle(
                                  color: ColorConstants.cyanCornflowerBlueColor,
                                  fontFamily: 'Quicksand',
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Radio(
                                value: label1,
                                groupValue: myGroupValue,
                                onChanged: (value) {
                                  setState(() {
                                    myGroupValue = value.toString();
                                    genderError = null;
                                    genderIcon = const Icon(
                                      Icons.male_rounded,
                                      color: ColorConstants
                                          .cyanCornflowerBlueColor,
                                    );
                                  });
                                },
                              ),
                              const Text(
                                "M",
                                style: TextStyle(
                                    color:
                                    ColorConstants.cyanCornflowerBlueColor,
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 16),
                              Radio(
                                value: label2,
                                groupValue: myGroupValue,
                                onChanged: (value) {
                                  setState(() {
                                    myGroupValue = value.toString();
                                    genderError = null;
                                    genderIcon = const Icon(
                                      Icons.female,
                                      color: ColorConstants
                                          .cyanCornflowerBlueColor,
                                    );
                                  });
                                },
                              ),
                              const Text(
                                "F",
                                style: TextStyle(
                                    color:
                                    ColorConstants.cyanCornflowerBlueColor,
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (genderError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                genderError!,
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomElevatedButton1(
                        onPressed: () {
                          resetForm();
                          setState(() {});
                        },
                        text: 'Reset',
                      ),

                      SizedBox(
                          width: 10), // Add some spacing between the buttons

                      CustomElevatedButton(
                        text: 'Submit',
                        onPressed: () async {
                          // Perform validation before showing the consent dialog
                          // if (validateAndSubmit()) {

                          if (pt_consent.toString().toLowerCase() == "true") {
                            var ptConsentAltText =
                                DataSingleton().ptConsentText;
                            if (ptConsentAltText == null) {
                              ptConsentAltText =
                              "Do you give consent for the Test?";
                            }

                            if (_validateFields()) {
                              // Show the consent dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Center(
                                        child: Text('Patient Consent',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    insetPadding:
                                    EdgeInsets.fromLTRB(5, 0, 5, 0),
                                    content: Text('$ptConsentAltText',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    // Your consent text here
                                    actions: [
                                      CustomElevatedButton1(
                                        text: 'Decline',
                                        onPressed: () {
                                          // Perform actions for declining
                                          patient_id = dataSingleton.generateMd5(
                                              "${controllers["PATIENT_AGE"]!.text.toString().toLowerCase().trim()}${dataSingleton.getCurrentDateTimeInIST()}");
                                          fields_doctor = {};

                                          // Set up fields_doctor with the appropriate values or nulls
                                          for (var field in fields) {
                                            final key = field['key']!;
                                            var value = controllers[key]
                                                ?.text
                                                .toString()
                                                .toLowerCase()
                                                .trim() ??
                                                ''; // Default to empty string if null
                                            fields_doctor[key] =
                                                value; // Set the value to empty string if no value is found
                                          }

                                          // Convert to JSON string if needed
                                          // Map<String,dynamic> jsonstringmap = json.encode(fields_doctor) as Map<String, dynamic>;
                                          String jsonstringmap =
                                          json.encode(fields_doctor);
                                          _insertData(0, jsonstringmap);

                                          print(
                                              '@@@@@patientformdetials  $jsonstringmap');

                                          print(
                                              'Database consent patient page');
                                          Navigator.of(context).pop();
                                          Get.off(DoctorSelectionScreen());
                                        },
                                      ),
                                      CustomElevatedButton(
                                        text: 'Accept',
                                        onPressed: () async {
                                          for (var field in fields) {
                                            fields_doctor.addAll({
                                              field['key']!:
                                              controllers[field['key']!]!
                                                  .text
                                                  .toString()
                                                  .toLowerCase()
                                                  .trim()
                                            });

                                            print("@@## Get from " +
                                                field['key']! +
                                                " - " +
                                                controllers[field['key']!]!
                                                    .text
                                                    .toString()
                                                    .toLowerCase()
                                                    .trim());
                                          }

                                          String jsonstringmap =
                                          json.encode(fields_doctor);

                                          patient_id = dataSingleton.generateMd5(
                                              "${controllers["PATIENT_AGE"]!.text.toString().toLowerCase().trim()}${dataSingleton.getCurrentDateTimeInIST()}");
                                          camp_date = dataSingleton
                                              .getCurrentDateTimeInIST();
                                          test_date = dataSingleton
                                              .getCurrentDateTimeInIST();
                                          test_start_time = dataSingleton
                                              .getCurrentDateTimeInIST();
                                          DataSingleton().patient_consent = 1;

                                          try {
                                            Navigator.of(context).pop();

                                            print(
                                                "xcxcxczxzczcsfsfsffs $jsonstringmap");
                                            if (fields_doctor
                                                .containsKey("PATIENT_NAME")) {
                                              print(
                                                  "ItContainsPatientName $jsonstringmap");
                                              DataSingleton()
                                                  .Patient_namechart =
                                                  controllers["PATIENT_NAME"]!
                                                      .text
                                                      .toString()
                                                      .toLowerCase()
                                                      .trim();
                                              DataSingleton().pat_namec =
                                                  controllers["PATIENT_NAME"]!
                                                      .text
                                                      .toString()
                                                      .toLowerCase()
                                                      .trim();
                                              DataSingleton().pat_name =
                                                  controllers["PATIENT_NAME"]!
                                                      .text
                                                      .toString()
                                                      .toLowerCase()
                                                      .trim();
                                              String patientName =
                                              controllers["PATIENT_NAME"]!
                                                  .text
                                                  .toString()
                                                  .toLowerCase()
                                                  .trim();
                                            } else {
                                              print(
                                                  "The fields_doctor map does not contain the key 'PATIENT_NAME'");
                                            }

                                            //for iap growth chart setting print and s3
                                            DataSingleton().Patient_agechart =
                                                _ageController.text;
                                            DataSingleton()
                                                .Patient_genderchart =
                                                myGroupValue;

                                            DataSingleton().pat_idc =
                                                patient_id;
                                            DataSingleton().camp_datec =
                                                camp_date;
                                            DataSingleton().test_datec =
                                                test_date;
                                            DataSingleton().test_start_timec =
                                                test_start_time;
                                            // DataSingleton().pat_agec = _ageController.text;
                                            DataSingleton().pat_genderc =
                                                controllers["PATIENT_GENDER"]!
                                                    .text
                                                    .toString()
                                                    .toLowerCase()
                                                    .trim();
                                            DataSingleton().patient_meta =
                                                jsonstringmap;

                                            //setting to singleton as we have added locale selection screen after this
                                            DataSingleton().pat_id = patient_id;
                                            DataSingleton().camp_date =
                                                camp_date;
                                            DataSingleton().test_date =
                                                test_date;
                                            DataSingleton().test_start_time =
                                                test_start_time;
                                            DataSingleton().pat_age =
                                                controllers["PATIENT_AGE"]!
                                                    .text
                                                    .toString()
                                                    .toLowerCase()
                                                    .trim();
                                            // DataSingleton().pat_name = patientName.isNotEmpty ? patientName : DataSingleton().pat_name;
                                            DataSingleton().pat_gender =
                                                controllers["PATIENT_GENDER"]!
                                                    .text
                                                    .toString()
                                                    .toLowerCase()
                                                    .trim();

                                            ////
                                            List<Map<String, dynamic>>?
                                            resources1 =
                                            await _databaseHelper
                                                ?.getAllDivisiondetail();
                                            Map<String, dynamic>? screenDetail;
                                            Map<String, dynamic>?
                                            division_detail;

                                            if (resources1 != null) {
                                              for (var resource in resources1) {
                                                if (resource.containsKey(
                                                    'scales_list') &&
                                                    resource['scales_list'] !=
                                                        null) {
                                                  screenDetail = json.decode(
                                                      resource['scales_list']);
                                                  division_detail = json.decode(
                                                      resource[
                                                      'division_detail']);

                                                  List<dynamic> metaList = [];
                                                  if (screenDetail!
                                                      .containsKey('data')) {
                                                    Map<String, dynamic> data =
                                                    screenDetail['data'];
                                                    if (data.containsKey(
                                                        'scales')) {
                                                      metaList = data['scales'];

                                                      for (var meta
                                                      in metaList) {
                                                        var name = meta['name'];
                                                        Map<String, dynamic>
                                                        data =
                                                        meta['scale_json'];

                                                        if (DataSingleton()
                                                            .scale_id
                                                            .toString() ==
                                                            name) {
                                                          print("@@##^Name " +
                                                              name);
                                                          print("@@##^data " +
                                                              data.toString());

                                                          scaleJson = data;
                                                          tTokenList =
                                                          data['t_token'];
                                                          // print('@@##^t_token: $tTokenList');

                                                          // DataSingleton().subscriber_id = mrid;
                                                        }
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }

                                            ////
                                            // Check internet connectivity
                                            // _networkHelper.checkInternetConnection();
                                            // _subscription = _networkHelper.isOnline.listen((isOnline) async {
                                            //   if (!isOnline) {
                                            //     // Offline: Load scale HTML from file and use it
                                            //     final offlineScaleHtml = await _loadScaleJsonFromFile();
                                            //     if (offlineScaleHtml != null) {
                                            //       scaleJson = offlineScaleHtml;
                                            //       print("Loaded scale HTML from local file for offline use.");
                                            //       // Only show snackbar and navigate if the widget is still mounted
                                            //       if (!mounted) return;
                                            //       // Optionally, show a message to the user
                                            //       final rootContext = Navigator.of(context, rootNavigator: true).context;
                                            //       if (!mounted) return; // <-- Add this line before using rootContext
                                            //       ScaffoldMessenger.of(rootContext).showSnackBar(
                                            //         SnackBar(
                                            //           content: Text('No internet. Loaded offline scale.'),
                                            //           backgroundColor: Colors.orange,
                                            //         ),
                                            //       );
                                            //       // Open WebViewScreen with local file using file:// URL
                                            //       final file = File(_localScalePath!);
                                            //       if (await file.exists()) {
                                            //         print("Opening WebViewScreen with file://${file.path}");
                                            //         if (!mounted) return;
                                            //         Get.to(() => const TestWebViewScreen());
                                            //
                                            //       } else {
                                            //         print("Offline scale file not found at $_localScalePath");
                                            //         if (!mounted) return;
                                            //         ScaffoldMessenger.of(rootContext).showSnackBar(
                                            //           SnackBar(
                                            //             content: Text('Offline scale file not found.'),
                                            //             backgroundColor: Colors.red,
                                            //           ),
                                            //         );
                                            //       }
                                            //     } else {
                                            //       print("No offline scale found or failed to load.");
                                            //       if (!mounted) return;
                                            //       final rootContext = Navigator.of(context, rootNavigator: true).context;
                                            //       if (!mounted) return; // <-- Add this line before using rootContext
                                            //       ScaffoldMessenger.of(rootContext).showSnackBar(
                                            //         SnackBar(
                                            //           content: Text('No internet and no offline scale found.'),
                                            //           backgroundColor: Colors.red,
                                            //         ),
                                            //       );
                                            //     }
                                            //     return;
                                            //   } else {
                                            //     DataSingleton().locale = "en";
                                            //     if (!mounted) return;
                                            //     Get.to(() => const TestWebViewScreen());
                                            //
                                            //     print("Scale Url: " + 'https://scales5.kribado.com/?scale=${DataSingleton().scale_id}&mode=download');
                                            //     print("Scale Json $scaleJson");
                                            //   }
                                            // });

                                            Get.to(() =>  WebViewPage());


                                          } catch (e) {
                                            print("Error is here ${e}");
                                          }
                                        },
                                      ),
                                    ],
                                    actionsAlignment:
                                    MainAxisAlignment.spaceBetween,
                                  );
                                },
                              );
                            }
                          } else if (pt_consent == "False") {
                            if (_validateFields()) {
                              for (var field in fields) {
                                fields_doctor.addAll({
                                  field['key']!: controllers[field['key']!]!
                                      .text
                                      .toString()
                                      .toLowerCase()
                                      .trim()
                                });

                                print("@@## Get from " +
                                    field['key']! +
                                    " - " +
                                    controllers[field['key']!]!
                                        .text
                                        .toString()
                                        .toLowerCase()
                                        .trim());
                              }

                              String jsonstringmap = json.encode(fields_doctor);

                              patient_id = dataSingleton.generateMd5(
                                  "${controllers["PATIENT_AGE"]!.text.toString().toLowerCase().trim()}${dataSingleton.getCurrentDateTimeInIST()}");
                              camp_date =
                                  dataSingleton.getCurrentDateTimeInIST();
                              test_date =
                                  dataSingleton.getCurrentDateTimeInIST();
                              test_start_time =
                                  dataSingleton.getCurrentDateTimeInIST();
                              DataSingleton().patient_consent = 1;

                              try {
                                Navigator.of(context).pop();

                                print("xcxcxczxzczcsfsfsffs $jsonstringmap");
                                if (fields_doctor.containsKey("PATIENT_NAME")) {
                                  print("ItContainsPatientName $jsonstringmap");
                                  DataSingleton().Patient_namechart =
                                      controllers["PATIENT_NAME"]!
                                          .text
                                          .toString()
                                          .toLowerCase()
                                          .trim();
                                  DataSingleton().pat_namec =
                                      controllers["PATIENT_NAME"]!
                                          .text
                                          .toString()
                                          .toLowerCase()
                                          .trim();
                                  DataSingleton().pat_name =
                                      controllers["PATIENT_NAME"]!
                                          .text
                                          .toString()
                                          .toLowerCase()
                                          .trim();
                                  String patientName =
                                  controllers["PATIENT_NAME"]!
                                      .text
                                      .toString()
                                      .toLowerCase()
                                      .trim();
                                } else {
                                  print(
                                      "The fields_doctor map does not contain the key 'PATIENT_NAME'");
                                }

                                //for iap growth chart setting print and s3
                                DataSingleton().Patient_agechart =
                                    _ageController.text;
                                DataSingleton().Patient_genderchart =
                                    myGroupValue;

                                DataSingleton().pat_idc = patient_id;
                                DataSingleton().camp_datec = camp_date;
                                DataSingleton().test_datec = test_date;
                                DataSingleton().test_start_timec =
                                    test_start_time;
                                // DataSingleton().pat_agec = _ageController.text;
                                DataSingleton().pat_genderc =
                                    controllers["PATIENT_GENDER"]!
                                        .text
                                        .toString()
                                        .toLowerCase()
                                        .trim();
                                DataSingleton().patient_meta = jsonstringmap;

                                //setting to singleton as we have added locale selection screen after this
                                DataSingleton().pat_id = patient_id;
                                DataSingleton().camp_date = camp_date;
                                DataSingleton().test_date = test_date;
                                DataSingleton().test_start_time =
                                    test_start_time;
                                DataSingleton().pat_age =
                                    controllers["PATIENT_AGE"]!
                                        .text
                                        .toString()
                                        .toLowerCase()
                                        .trim();
                                // DataSingleton().pat_name = patientName.isNotEmpty ? patientName : DataSingleton().pat_name;
                                DataSingleton().pat_gender =
                                    controllers["PATIENT_GENDER"]!
                                        .text
                                        .toString()
                                        .toLowerCase()
                                        .trim();

                                ////
                                List<Map<String, dynamic>>? resources1 =
                                await _databaseHelper
                                    ?.getAllDivisiondetail();
                                Map<String, dynamic>? screenDetail;
                                Map<String, dynamic>? division_detail;

                                if (resources1 != null) {
                                  for (var resource in resources1) {
                                    if (resource.containsKey('scales_list') &&
                                        resource['scales_list'] != null) {
                                      screenDetail = json.decode(
                                          resource['scales_list']);
                                      division_detail = json.decode(
                                          resource['division_detail']);

                                      List<dynamic> metaList = [];
                                      if (screenDetail!.containsKey('data')) {
                                        Map<String, dynamic> data =
                                        screenDetail['data'];
                                        if (data.containsKey('scales')) {
                                          metaList = data['scales'];

                                          for (var meta in metaList) {
                                            var name = meta['name'];
                                            Map<String, dynamic> data =
                                            meta['scale_json'];

                                            if (DataSingleton()
                                                .scale_id
                                                .toString() ==
                                                name) {
                                              print("@@##^Name " + name);
                                              print("@@##^data " +
                                                  data.toString());

                                              scaleJson = data;
                                              tTokenList = data['t_token'];
                                              // print('@@##^t_token: $tTokenList');

                                              // DataSingleton().subscriber_id = mrid;
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }

                                DataSingleton().locale = "en";
                                Get.to(() =>  WebViewPage());

                                print("Scale Json $scaleJson");
                              } catch (e) {
                                print("Error is here ${e}");
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  // ... (rest of the code remains the same)

  void resetForm() {
    controllers = {};
    errors = {};
    for (var field in fields) {
      final key = field['key']!;
      controllers[key] = TextEditingController();
      errors[key] = '';
    }
  }

  bool validateAndSubmit() {
    String name = _nameController.text;
    String age = _ageController.text;

    // Reset errors
    setState(() {
      nameError = null;
      ageError = null;
      genderError = null;
    });

    // Validate name
    //RegExp nameRegExp = RegExp(r'^[a-zA-Z]+$');
    RegExp nameRegExp = RegExp(r"[a-zA-Z0-9]+|\s");
    if (name.isEmpty) {
      setState(() {
        nameError = 'Please enter a Name';
      });
      return false;
    } else if (!nameRegExp.hasMatch(name)) {
      setState(() {
        nameError = 'Name should contain only alphabets';
      });
      return false;
    }

    // Validate age
    RegExp ageRegExp = RegExp(r'^[1-9]\d?$|^100$');
    if (age.isEmpty) {
      setState(() {
        ageError = 'Please enter Age';
      });
      return false;
    } else if (!ageRegExp.hasMatch(age)) {
      setState(() {
        ageError = 'Age should be between 1 and 100';
      });
      return false;
    }

    int ageValue = int.tryParse(age) ??
        0; // Convert age to int, default to 0 if parsing fails

    if (ageValue <= 0) {
      setState(() {
        ageError = 'Age must be greater than zero';
      });
      return false;
    }

    if (myGroupValue.isEmpty) {
      setState(() {
        genderError = 'Please select a gender';
      });
      return false;
    }

    // Set gender icon based on selection
    setState(() {
      genderIcon = myGroupValue == label1
          ? const Icon(Icons.person)
          : const Icon(Icons.person_outline);
    });

    // If all validations pass, proceed with submission
    print('Name: $name, Age: $age, Gender: $myGroupValue');

    // Get.to(ScalesTestScreen());
    // Assuming you have a Test widget to navigate to, otherwise, replace Test() with your desired destination.
    // Get.to(Test());

    return true;
  }

  Future<void> getfieldfromlocal() async {
    print('getfieldfromlocal');

    try {
      DatabaseHelper databaseHelper = DatabaseHelper.instance;
      await databaseHelper.initializeDatabase();

      List<String> doctor_Fields = [];
      List<String> doctor_Fields_Controllers = [];
      List<String> doctor_Fields_Type = [];
      List<String> doctor_Fields_Lable = [];
      List<String> doctor_Fields_Lable_Value = [];
      List<String> doctor_Fields_Hint = [];
      List<String> doctor_Fields_Hint_Value = [];
      List<String> doctor_Fields_REQ = [];
      List<String> doctor_Fields_REQ_Value = [];
      List<String> doctor_Fields_REGEX = [];
      List<String> doctor_Fields_REGEX_Value = [];
      List<String> doctor_Fields_Icons_Value = [];

      // Use a Set to track added keys
      Set<String> addedKeys = {};

      List<Map<String, dynamic>> resources =
      await databaseHelper.getAllDivisiondetail();
      Map<String, dynamic> screenDetail;
      for (var resource in resources) {
        if (resource.containsKey('scales_list') &&
            resource['scales_list'] != null) {
          screenDetail = json.decode(resource['scales_list']);
          print('mvncvcnvrugjdfd   $screenDetail');

          List<dynamic> metaList = [];
          if (screenDetail.containsKey('data')) {
            Map<String, dynamic> data = screenDetail['data'];
            if (data.containsKey('meta')) {
              metaList = data['meta'];

              for (var meta in metaList) {
                var key = meta['key'];
                var value = meta['value'];

                if (key.startsWith("PATIENT") &&
                    key.endsWith("_OPTIONS") &&
                    !addedKeys.contains(key)) {
                  addedKeys.add(key);

                  doctor_Fields_genderOptions_Key.add(key);
                  doctor_Fields_genderOptions_Value = value;

                  doctor_Fields_Lable.add(key);
                  doctor_Fields_Lable_Value.add(value);
                }

                // Check for duplicates before adding
                if (key.startsWith("PATIENT") &&
                    key.endsWith("_LABEL") &&
                    !addedKeys.contains(key)) {
                  // Mark the key as added
                  addedKeys.add(key);

                  // Printing key-value pairs
                  print('abhishekKey: $key, Value: $value');

                  doctor_Fields.add(key);
                  doctor_Fields_Lable.add(key);
                  doctor_Fields_Lable_Value.add(value);
                  doctor_Fields_Hint.add(key.replaceAll('LABEL', 'HINT'));
                  doctor_Fields_REQ.add(key.replaceAll('LABEL', 'REQ'));
                  doctor_Fields_REGEX.add(key.replaceAll('LABEL', 'REGEX'));
                }
              }
            }
          }

          print('@@## ' + doctor_Fields.toString());
          print('@@## ' + doctor_Fields_Lable.toString());
          print('@@## ' + doctor_Fields_Lable_Value.toString());
          print('@@## ' + doctor_Fields_Hint.toString());
          print('@@## ' + doctor_Fields_REQ.toString());
          print('@@## ' + doctor_Fields_REGEX.toString());

          String formattedString = doctor_Fields_genderOptions_Value.toString();
          print('@@@@@@@@@formattestring $formattedString');

          String genderString = "Male,Female";

          // Split the string by the comma
          List<String> genderList = formattedString.split(',');

          // Add single quotes around each element
          List<String> quotedList = genderList.map((e) => "$e").toList();

          // Join the quoted elements and print
          String result = quotedList.join(',');

          print('gdgfhgxvxxvxv $result');

          // Convert the result string back into a list
          resultList = result.split(',');

          print('fkdfmkmsldm  $resultList');

          // Split the string by the comma
          // List<String> genderList = formattedString.split(',');

          // Print the result
          // Print the result without brackets
          // print("@@@@gender Male: ${genderList[0]}");  // This will print "Male"
          // print("@@@@gender Female: ${genderList[1]}");  // This will print "Female"
          // print('@@##genderoptionsvalue ' + doctor_Fields_genderOptions_Value.toString().split(','));
          print('@@##genderoptions ' +
              doctor_Fields_genderOptions_Key.toString());
          print('@@##genderoptions ' + addedKeys.toString());

          for (var i = 0; i < doctor_Fields_Hint.length; i++) {
            for (var meta in metaList) {
              var key = meta['key'];
              print('sfksfksfksckc $key');

              if (key == "PT_CONSENT") {
                pt_consent = meta['value'];
                print('gjgutzczcasdafaf $pt_consent');
              }

              var value = meta['value'];

              if (key == doctor_Fields_Hint[i]) {
                doctor_Fields_Hint_Value.add(value);
              }

              if (key == doctor_Fields_REQ[i]) {
                doctor_Fields_REQ_Value.add(value);
              }

              if (key == doctor_Fields_REGEX[i]) {
                doctor_Fields_REGEX_Value.add(value);
              }

              if (key == doctor_Fields[i].replaceAll("_LABEL", "")) {
                doctor_Fields_Type.add(value);
                doctor_Fields_Controllers.add(key.replaceAll("_LABEL", ""));
              }

              if (key == doctor_Fields[i].replaceAll("_LABEL", "_ICON")) {
                doctor_Fields_Icons_Value.add(value);
              }
            }
          }

          for (var j = 0; j < doctor_Fields_Hint.length; j++) {
            print("@@##**control" + doctor_Fields_Controllers[j]);

            fields.add({
              "key": doctor_Fields_Controllers[j],
              "label": doctor_Fields_Hint_Value[j],
              "REGEX": doctor_Fields_REGEX_Value[j],
              "Icon": doctor_Fields_Icons_Value[j],
              "ReqKey": doctor_Fields_REQ[j],
              "ReqValue": doctor_Fields_REQ_Value[j],
              "inputtype": "Num"
            });
          }

          // Trigger a UI update when offline data is loaded
          setState(() {
            _initializeControllers();
          });
        } else {
          print('screen detail not available');
        }
      }
    } catch (e) {
      print('Error fetching offline data: $e');
    }
  }

  void _initializeControllers() {
    controllers = {};
    errors = {};
    for (var field in fields) {
      final key = field['key']!;
      controllers[key] = TextEditingController();
      errors[key] = '';
    }
  }

  bool _validateFields() {
    List<String> errorMessages = [];

    print("@@##T");
    for (var field in fields) {
      print("@@##T " + field['REGEX']!);
      final key = field['key']!;
      print('jxvndjvnxvjxnvxfbhjfsb $key');
      final label = field['label']!;
      final regexValue = field['REGEX'];
      final requiredKey = field['ReqKey'];
      final requiredValue = field['ReqValue'];
      print("labelreqsfafaf %$key  xxx $regexValue");
      // Check if the key ends with "REQ" and its value is true

      // final regex = _getRegex(key);

      var regex;

      /* if(regexValue == "age"){
       regex = RegExp(r'^[1-9]\d?$|^100$'); // Accepts numbers from 1 to 100
     } else */
      if (regexValue == "name") {
        regex = RegExp(r'^[a-zA-Z ]*$'); // Accepts only alphabets (no numbers)
      } else if (regexValue == "mobile_number") {
        regex = RegExp(r'^[0-9]{10}$'); // Accepts exactly 10 digits
      } else if (regexValue == "number") {
        regex = RegExp(r'^\d+$'); // Accepts only numeric characters
      }

      // age
      // name
      // doctor_code
      // mobile_number
      // number

      // final regex =_getRegex1(r'[a-zA-Z0-9]+|\s');
      //final regex =RegExp("'"+field['REGEX']!+"'");

      String errorMessage = "";
      errorMessage = _getErrorMessage(field['label']!);

      if (requiredKey != null && requiredValue == "True") {
        // Show error message
        print("ssdsdsdxxvddgdgdgdgdg");
        // errorMessages.add("Mandatory");
      }

      // String errorMessage = _getErrorMessage(field['label']!);
      //String errorMessage = "Text";

      if (regexValue == "age") {
        print("@@##here" + controllers[key]!.text);

        if (controllers[key]!.text.length == 0 ||
            int.parse(controllers[key]!.text) <
                int.parse(DataSingleton().age_min.toString()) ||
            int.parse(controllers[key]!.text) >
                int.parse(DataSingleton().age_max.toString())) {
          setState(() {
            errors[key] = "Please Enter Age between " +
                DataSingleton().age_min.toString() +
                " to " +
                DataSingleton().age_max.toString() +
                ".";
            errorMessages.add(errorMessage);
          });
        } else {}
      } else {
        if (!_validateField(
            key, label, regex, errorMessage, requiredKey, requiredValue)) {
          errorMessages.add(errorMessage);
        }
      }
    }
    print("@@##here" + errorMessages.length.toString());
    if (errorMessages.isNotEmpty) {
      // Handle error messages if needed
      return false;
    }

    return true;
  }

  RegExp? _getRegex1(String regx) {
    return RegExp(regx);
  }

  String _getErrorMessage(String key) {
    switch (key) {
    /*case 'DOCTOR_NAME':
       return 'Please enter only alphabets.';
     case 'PHONE_NUMBER':
       return 'Please enter a valid 10-digit phone number.';


     case 'DOCTOR_CODE':
       return 'Please enter correct format';
     case 'CITY_NAME':
       return 'Please enter only alphabets.';
     case 'AREA_NAME':
       return 'Please enter only alphabets.';
     case 'SPECIALITY':
       return 'Please enter only alphabets.';
    */
      default:
        return 'Invalid $key';
    }
  }

  bool _validateField(
      String key,
      String label,
      RegExp? regex,
      String errorMessage,
      String requiredKey,
      String requiredValue,
      ) {
    final value = controllers[key]!.text;

    print('@@## In validation');

    // Check if the value is required and empty
    if (requiredValue == 'True' && value.trim().isEmpty) {
      setState(() {
        errors[key] = 'Please Enter $label';
      });
      return false;
    }

    // If the field is not required, no need to check the regex
    if (requiredValue != 'True') {
      setState(() {
        errors[key] = ''; // Clear error message when input field is valid
      });
      return true;
    }

    // If the field is required, check against regex
    if (key == "age") {
      print('@@###her');
      setState(() {
        errors[key] = "My Name is tanvir ";
      });
      return false;
    } else {
      if (regex != null && !regex.hasMatch(value)) {
        setState(() {
          errors[key] = errorMessage;
        });
        return false;
      }
    }

    setState(() {
      errors[key] = ''; // Clear error message when input field is valid
    });
    return true;
  }
}
