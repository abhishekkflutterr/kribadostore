import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/custom_widgets/elevated_button_color.dart';
import 'package:kribadostore/custom_widgets/text_field.dart';
import 'package:kribadostore/models/FilterByDateCountResponse.dart';
import 'package:kribadostore/screens/doctor_selection_screen.dart';
import 'package:kribadostore/screens/patient_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Camp.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../Doctor.dart';
import '../controllers/login_controller.dart';
import '../models/division_details_response.dart';
import '../models/user_login_response.dart';

class DoctorDetailsScreen extends StatefulWidget {

  const DoctorDetailsScreen({super.key});


  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();

}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {


  List<String> doctorNames = [];
  DataSingleton dataSingleton = DataSingleton();
  final LoginController loginController = Get.find<LoginController>();
  DatabaseHelper? _databaseHelper;
  late LoginResponse loginResponse;
  late String divisionId;
  late int divisionIdNumeric;
  late String dr_id;
  late Scales scale;
  String locale = '';
  late String encoded;
  late String doctorInfo;
  String _pincode = '';
  String _stateName = '';
  String _cityName = '';
  String dr_id_to_check='';
  //List<String>? Values=[];
  List<Map<String, dynamic>> fields=[];
  late Map<String, String> fields_doctor;
  List<String> Values = []; // Initialize Values to an empty list
  late Map<String, TextEditingController> controllers;
  late Map<String, String> errors;

  String? subscriber_id;
  String? mr_id;


  @override
  void initState() {
    super.initState();
    print('@@@@@@settinggg ${DataSingleton().drConsentText}');

    DataSingleton().questionAndAnswers = "";
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();
    _initializeControllersData();
    _initializeControllers();



    sharedPrefsData();


  }

  Future<void> sharedPrefsData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriber_id = prefs.getString('subscriber_id');
    mr_id = prefs.getString('mr_id');

  }



  Future<void> _initializeControllersData() async {




    // if (DataSingleton().mData == null) {

    // print("@@## here");
    // Fetch meta information from the database
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


      List<Map<String, dynamic>> resources = await databaseHelper.getAllDivisiondetail();
      Map<String, dynamic> screenDetail;
      for (var resource in resources) {

        if (resource.containsKey('scales_list') && resource['scales_list'] != null) {
          screenDetail = json.decode(resource['scales_list']);
          // print('mvncvcnvrugjdfd   $screenDetail');

          List<dynamic> metaList=[];
          if (screenDetail.containsKey('data')) {
            Map<String, dynamic> data = screenDetail['data'];
            if (data.containsKey('meta')) {
              metaList = data['meta'];


              for (var meta in metaList) {


                var key = meta['key'];
                var value = meta['value'];


                if (key=="TOP_LOGO_"+DataSingleton().scale_id.toString()) {
                  DataSingleton().top_logo=meta['value'];
                }
                if (key=="BOTTOM_LOGO_"+DataSingleton().scale_id.toString()) {
                  DataSingleton().bottom_logo=meta['value'];
                }

                if (key=="PRINT_QUESTIONS_"+DataSingleton().scale_id.toString()) {
                  DataSingleton().questionAndAnswers=meta['value'];
                }

                if (key=="DR_CONSENT") {
                  DataSingleton().drConsentAllowOrNot=meta['value'];
                }

                if (key.startsWith("DOCTOR") && key.endsWith("_LABEL")) {

                  // Printing key-value pairs
                  // print('Key: $key, Value: $value');

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

          // print('@@## '+doctor_Fields.length.toString());
          // print('@@## '+doctor_Fields_Lable.length.toString());
          // print('@@## '+doctor_Fields_Lable_Value.length.toString());
          // print('@@## '+doctor_Fields_Hint.length.toString());
          // print('@@## '+doctor_Fields_REQ.length.toString());
          // print('@@## '+doctor_Fields_REGEX.length.toString());


          for (var i = 0; i < doctor_Fields_Hint.length; i++) {


            for (var meta in metaList) {


              var key = meta['key'];
              var value = meta['value'];

              if (key==doctor_Fields_Hint[i]) {
                doctor_Fields_Hint_Value.add(value);
              }

              if (key==doctor_Fields_REQ[i]) {
                doctor_Fields_REQ_Value.add(value);
              }


              if (key==doctor_Fields_REGEX[i]) {
                //doctor_Fields_REGEX_Value.add(meta.value);
                doctor_Fields_REGEX_Value.add(value);
              }

              if (key==doctor_Fields[i].replaceAll("_LABEL", "")) {
                doctor_Fields_Type.add(value);
                doctor_Fields_Controllers.add(key.replaceAll("_LABEL", ""));

              }

              if (key==doctor_Fields[i].replaceAll("_LABEL", "_ICON")) {
                doctor_Fields_Icons_Value.add(value);
              }

            }

          }


          for (var j = 0; j < doctor_Fields_Hint.length; j++) {


            fields.add({"key": doctor_Fields_Controllers[j], "label": doctor_Fields_Hint_Value[j],"REGEX":doctor_Fields_REGEX_Value[j],"Icon":doctor_Fields_Icons_Value[j], "ReqKey":doctor_Fields_REQ[j],"ReqValue":doctor_Fields_REQ_Value[j]});
          }

          // Trigger a UI update when offline data is loaded
          setState(() {
            _initializeControllers();
          });
        } else {
          //  print('screen detail not available');
        }
      }
    } catch (e) {
      print('Error fetching offline data: $e');
    }
    /* }
    else {
      print("@@## else");
      // Process mData if it's not null


      DataSingleton().mData?.forEach((meta) {




       *//* if(meta.key == "DOCTOR_NAME_HINT" || meta.key == "DOCTOR_CODE_HINT" || meta.key == "DOCTOR_PHONE_HINT" || meta.key == "DOCTOR_CITY_HINT" || meta.key == "DOCTOR_AREA_HINT" || meta.key == "DOCTOR_SPECIALITY_HINT"  ){
          Values.add(meta.value);
        }
      //  print("@@@@@ ${Values}");
        fields = [
          {"key": "DOCTOR_NAME", "label": Values.isNotEmpty ? Values[0] : "Name"},
          {"key": "DOCTOR_CODE", "label": Values.length > 1 ? Values[1] : "Code"},
          *//**//* {"key": "PHONE_NUMBER", "label": Values.length > 2 ? Values[2] : "Phone"},
          {"key": "CITY_NAME", "label": Values.length > 3 ? Values[3] : "City"},
          {"key": "AREA_NAME", "label": Values.length > 4 ? Values[4] : "Area"},
        *//**//*  {"key": "SPECIALITY", "label": Values.length > 5 ? Values[5] : "Speciality"},
        ];*//*
      });

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


      DataSingleton().mData?.forEach((meta) {

        if (meta.key.startsWith("DOCTOR") && meta.key.endsWith("_LABEL")) {
          doctor_Fields.add(meta.key);
          doctor_Fields_Lable.add(meta.key);
          doctor_Fields_Lable_Value.add(meta.value);
          doctor_Fields_Hint.add(meta.key.replaceAll('LABEL', 'HINT'));
          doctor_Fields_REQ.add(meta.key.replaceAll('LABEL', 'REQ'));
          doctor_Fields_REGEX.add(meta.key.replaceAll('LABEL', 'REGEX'));
        }
      });

      for (var i = 0; i < doctor_Fields_Hint.length; i++) {

        DataSingleton().mData?.forEach((meta) {

          if (meta.key==doctor_Fields_Hint[i]) {
            doctor_Fields_Hint_Value.add(meta.value);
          }

          if (meta.key==doctor_Fields_REQ[i]) {
            doctor_Fields_REQ_Value.add(meta.value);
          }

          if (meta.key==doctor_Fields_REGEX[i]) {
            doctor_Fields_REGEX_Value.add(meta.value);
          }

          if (meta.key==doctor_Fields[i].replaceAll("_LABEL", "")) {
            doctor_Fields_Type.add(meta.value);
            doctor_Fields_Controllers.add(meta.key.replaceAll("_LABEL", ""));

          }

          if (meta.key==doctor_Fields[i].replaceAll("_LABEL", "_ICON")) {
            doctor_Fields_Icons_Value.add(meta.value);
          }

        });

      }








      for (var i = 0; i < doctor_Fields_Hint.length; i++) {


        print("@@##REGEX "+doctor_Fields_REGEX_Value[i]);
        fields.add({"key": doctor_Fields_Controllers[i], "label": doctor_Fields_Hint_Value[i],"REGEX":doctor_Fields_REGEX_Value[i],"Icon":doctor_Fields_Icons_Value[i]});
      }



    setState(() {
        _initializeControllers();
      });

      }*/
  }


  Future<void> _insertDataWhenNoConsent(String doctor_meta) async {
    // print('#####Database entered NO CONSENT try block');
    // String testString=dataSingleton.generateMd5("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${encoded}_${DataSingleton().scale_name}").toString();
    try {
      doctorInfo =

      '${controllers["DOCTOR_NAME"]!.text.toLowerCase().trim()}${controllers["DOCTOR_CODE"]!.text.toLowerCase().trim()}${divisionIdNumeric.toString().toLowerCase().trim()}';


      encoded = dataSingleton.generateMd5(doctorInfo).toString();
      // print('#####Database entered try block2');
      // print('#####Database entered try block2'+doctorInfo);
      await _databaseHelper?.insertCamp(Camp(
        //camp_id: dataSingleton.generateMd5("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${encoded}_${DataSingleton().scale_name}").toString(),
          camp_id: dataSingleton.generateMd5("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${encoded}_${DataSingleton().scale_name}_${DataSingleton().division_id}_$subscriber_id").toString(),
          camp_date: dataSingleton.getCurrentDateTimeInIST(),
          test_date: dataSingleton.getCurrentDateTimeInIST(),
          test_start_time: dataSingleton.getCurrentDateTimeInIST(),
          test_end_time: dataSingleton.getCurrentDateTimeInIST(),
          created_at: dataSingleton.getCurrentDateTimeInIST(),
          scale_id: DataSingleton().scale_id.toString(),
          test_score: 0.0,
          interpretation: 'No Consent',
          language: "en",
          pat_age: 'No Consent',
          pat_gender: 'No Consent',
          pat_email: "NA",
          pat_mobile: "NA",
          pat_name: 'No Consent',
          pat_id: 'No Consent',
          answers: 'No Test Given',
          division_id: DataSingleton().division_id,
          subscriber_id: subscriber_id.toString(),
          mr_code: mr_id.toString(),
          patient_consent: 0,
          country_code: "IN",
          // state_code: controllers["AREA_NAME"]!.text.toString().toLowerCase().trim(),
          state_code: "01",
          city_code: "01",
          // city_code: controllers["CITY_NAME"]!.text.toString().toLowerCase().trim(),
          area_code: "01",
          // area_code: controllers["AREA_NAME"]!.text.toString().toLowerCase().trim(),
          doc_code: "T",
          doc_name: "T",
          doc_speciality: "T",
          dr_id: encoded,
          dr_consent: 0,
          doctor_meta:doctor_meta,
          patient_meta:"{\"PATIENT_NAME\":\"\",\"PATIENT_AGE\":\"\",\"PATIENT_GENDER\":\"\"}"

      ));
      //setState(() {});
      // print("#####Database success CampNoConsent");
      // print("#####Print from doctor_details_screen: ${testString}");
    } catch (e) {
      print("ERROR on scaeNav: $e");
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

  bool _validateField(
      String key,
      String label,
      RegExp? regex,
      String errorMessage,
      String requiredKey,
      String requiredValue,
      ) {
    final value = controllers[key]!.text;

    // print('@@## In validation');

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
    if (regex != null && !regex.hasMatch(value)) {
      setState(() {
        errors[key] = errorMessage;
      });
      return false;
    }

    setState(() {
      errors[key] = ''; // Clear error message when input field is valid
    });
    return true;
  }




  bool _validateFields() {
    List<String> errorMessages = [];


    for (var field in fields) {

      // print("@@##T "+field['REGEX']!);
      final key = field['key']!;
      final label = field['label']!;
      final regexValue = field['REGEX'];
      final requiredKey = field['ReqKey'];
      final requiredValue = field['ReqValue'];
      // print("labelreqsfafaf %$key  xxx $regexValue");
      // Check if the key ends with "REQ" and its value is true


      // final regex = _getRegex(key);

      var regex;
      if(regexValue == "age"){
        regex = RegExp(r'^[1-9]\d?$|^100$'); // Accepts numbers from 1 to 100 - working
      } else if (regexValue == "name") {
        regex = RegExp(r'^[a-zA-Z. ]*$'); // Accepts alphabets, spaces, and dots
      } else if(regexValue == "mobile_number"){
        regex = RegExp(r'^[0-9]{10}$'); // Accepts exactly 10 digits  - working
      } else if(regexValue == "number"){
        regex = RegExp(r'^\d+$'); // Accepts only numeric characters - working
      } else if(regexValue == "doctor_code"){
        regex = RegExp(r'^[a-zA-Z0-9 ]*$'); // Accepts alapanumeric -working
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
        // print("ssdsdsdxxvddgdgdgdgdg $requiredKey $requiredValue");
        // errorMessages.add("Mandatory");

      }



      if(key != "SPECIALITY"){

        if (!_validateField(key, label, regex, errorMessage,requiredKey,requiredValue)) {

          errorMessages.add(errorMessage);
        }
      }

    }

    if (errorMessages.isNotEmpty) {
      // Handle error messages if needed
      return false;
    }

    return true;
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
     */ default:
      return 'Invalid $key';
    }
  }

  RegExp? _getRegex(String key,String regx) {
    switch (key) {
      case 'DOCTOR_NAME':
        return RegExp(r"[a-zA-Z0-9]+|\s");
      case 'PHONE_NUMBER':
        return RegExp(r'^[0-9]\d{9}$');
      case 'DOCTOR_CODE':
        return RegExp(r"[a-zA-Z0-9]+|\s");
      case 'CITY_NAME':
        return RegExp(r"[a-zA-Z0-9]+|\s");
      case 'AREA_NAME':
        return RegExp(r"[a-zA-Z0-9]+|\s");
      case 'SPECIALITY':
        return RegExp(r"[a-zA-Z0-9]+|\s");
      default:
        return null;
    }
  }

  RegExp? _getRegex1(String regx) {

    return RegExp(regx);

  }


  Future<void> _insertData() async {


    // Validate fields before showing consent dialogue
    if (_validateFields()) {
      // print('@@@ DR_CONSENT '+DataSingleton().drConsentAllowOrNot.toString());
      DataSingleton().drConsentAllowOrNot.toString()=="True"?
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            title: Center(child: Text('Doctor Consent',style: TextStyle(fontWeight: FontWeight.bold),)),
            content: Text(
              DataSingleton().drConsentText!.trim().isNotEmpty?
                   DataSingleton().drConsentText!
                  : "I agree that my patients’ data may be used in an anonymized and aggregated manner for analysis and publication purposes, either in India or abroad. Specifically, I understand and agree that such data may be shared with a service provider (other than Indigital Technologies) located in India or abroad, provided the data is properly de-identified before any further use for analytical purposes.",
              style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
            ),

            actions: [

              CustomElevatedButton1(
                text: 'Decline',
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog

                  fields_doctor = {};

                  for (var field in fields) {
                    fields_doctor.addAll({
                      field['key']! : controllers[field['key']!]!.text.toString().toLowerCase().trim()
                    });

                    // print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());
                  }

                  String jsonstringmap = json.encode(fields_doctor);

                  _insertDataIntoDatabase(0,jsonstringmap);
                  _insertDataWhenNoConsent(jsonstringmap);
                  Get.off(DoctorSelectionScreen());
                  // Optionally, you can handle decline action
                },
              ),

              SizedBox(width: 5,),
              CustomElevatedButton(
                text: 'Accept',
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog

                  fields_doctor = {};

                  for (var field in fields) {
                    fields_doctor.addAll({
                      field['key']! : controllers[field['key']!]!.text.toString().toLowerCase().trim()
                    });

                    // print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());
                  }

                  String jsonstringmap = json.encode(fields_doctor);
                  // print("@@## jsonstringmap "+jsonstringmap);



                  _insertDataIntoDatabase(1,jsonstringmap);
                  String doctorName = controllers["DOCTOR_NAME"]!.text.toString().toLowerCase().trim();
                  if (!doctorName.startsWith("dr")) {
                    doctorName = "Dr. " + doctorName;
                  }

                  // Capitalize the first letter of the doctor's name after "Dr."
                  doctorName = doctorName.split(' ').map((word) {
                    if (word.isNotEmpty) {
                      return word[0].toUpperCase() + word.substring(1).toLowerCase();
                    }
                    return word;
                  }).join(' ');


                  print('@#####docnameDr $doctorName');
                  DataSingleton().doc_name = doctorName;                 // DataSingleton().doc_speciality = controllers["SPECIALITY"]!.text.toString().toLowerCase().trim();
                  DataSingleton().doc_speciality = "Test";
                  DataSingleton().area_code = "01";
                  DataSingleton().city_code = "01";
                  DataSingleton().state_code = "01";
                  DataSingleton().doc_code = controllers["DOCTOR_CODE"]!.text.toString().toLowerCase().trim();
                  DataSingleton().dr_consent =1;
                  DataSingleton().country_code = "IN";
                  DataSingleton().dr_id = encoded;
                  DataSingleton().doctor_meta = jsonstringmap;
                  DataSingleton().patient_meta = "";
                  Get.off(PatientsDetailsScreen());

                },
              ),
            ],
          );
        },
      ):fields_doctor = {};

      for (var field in fields) {
        fields_doctor.addAll({
          field['key']! : controllers[field['key']!]!.text.toString().toLowerCase().trim()
        });

        // print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());
      }

      String jsonstringmap = json.encode(fields_doctor);
      // print("@@## jsonstringmap "+jsonstringmap);

      String doctorName = controllers["DOCTOR_NAME"]!.text.toString().toLowerCase().trim();
      if (!doctorName.startsWith("dr")) {
        doctorName = "Dr. " + doctorName;
      }

      // Capitalize the first letter of the doctor's name after "Dr."
      doctorName = doctorName.split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
        return word;
      }).join(' ');


      print('@@##Call here data');
      if(DataSingleton().drConsentAllowOrNot.toString()=="False"){
        _insertDataIntoDatabase(1,jsonstringmap);
      }

      DataSingleton().doc_name = doctorName;
      // DataSingleton().doc_speciality = controllers["SPECIALITY"]!.text.toString().toLowerCase().trim();
      DataSingleton().doc_speciality = "Test";
      DataSingleton().area_code = "01";
      DataSingleton().city_code = "01";
      DataSingleton().state_code = "01";
      DataSingleton().doc_code = controllers["DOCTOR_CODE"]!.text.toString().toLowerCase().trim();
      DataSingleton().dr_consent =1;
      DataSingleton().country_code = "IN";
      DataSingleton().dr_id = encoded;
      DataSingleton().doctor_meta = jsonstringmap;
      DataSingleton().patient_meta = "";
      Get.off(PatientsDetailsScreen());
    }

  }

  void loadDoctorNames() async {
    try {
      // Fetch doctors from the database
      final doctors = await _databaseHelper?.getAlldoctors();
      // print("####doctors_list from detailsScreen : $doctors");

      // Filter out duplicates
      List<String> uniqueDoctorNames = doctors!
          .map((doctor) => doctor['doc_name'] as String)
          .toSet()
          .toList();

      setState(() {
        doctorNames = uniqueDoctorNames;
        // print("####doctors_name from detailsScreen: $doctorNames");
      });
    } catch (e) {
      print('Error loading doctor names: $e');
    }
  }



  void _insertDataIntoDatabase(int consent, String jsonstringmap) async {
    // print('#####entered3 ');

    String doctorName = controllers["DOCTOR_NAME"]!.text.toString().toLowerCase().trim();
    if (!doctorName.contains("Dr.".trim().toLowerCase()) && !doctorName.contains("Dr".trim().toLowerCase())) {
      doctorName = "Dr. $doctorName";
    }

    // Capitalize the first letter of the doctor's name after "Dr."
    doctorName = doctorName.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).join(' ');



    divisionIdNumeric = DataSingleton().division_id.toInt();
    doctorInfo =
    '${controllers["DOCTOR_NAME"]!.text.toLowerCase().trim()}${controllers["DOCTOR_CODE"]!.text.toLowerCase().trim()}${divisionIdNumeric.toString().toLowerCase().trim()}';


    encoded = dataSingleton.generateMd5(doctorInfo).toString();

    // print('@@@state_code: ${controllers["AREA_NAME"]!.text.toString().toLowerCase().trim()}');
    // print('@@@city_code: ${controllers["CITY_NAME"]!.text.toString().toLowerCase().trim()}');
    // print('@@@area_code: ${controllers["AREA_NAME"]!.text.toString().toLowerCase().trim()}');
    // print('@@@doc_code: ${controllers["DOCTOR_CODE"]!.text.toString().toLowerCase().trim()}');
    //print('@@@doc_name: ${controllers["DOCTOR_NAME"]!.text.toString().toLowerCase().trim()}');
    // print('@@@doc_speciality: ${controllers["SPECIALITY"]!.text.toString().toLowerCase().trim()}');
    // print('@@@div_id: $divisionIdNumeric');
    //print('@@@dr_id: $encoded');
    //print('@@@dr_consent: $consent');

    // Insert data into the database
    try {
      // print('##### entered4 ');
      await _databaseHelper?.insertDoctor(Doctor(
          country_code: "INDIA",
          // state_code: controllers["AREA_NAME"]!.text.toString().toLowerCase().trim(),
          //city_code: controllers["CITY_NAME"]!.text.toString().toLowerCase().trim(),
          //area_code: controllers["AREA_NAME"]!.text.toString().toLowerCase().trim(),
          state_code: "",
          city_code: "",
          area_code: "",
          doc_code: controllers["DOCTOR_CODE"]!.text.toLowerCase().trim(),
          doc_name: doctorName.trim(),
          doc_speciality: "",
          // doc_speciality: controllers["SPECIALITY"]!.text.toString().toLowerCase().trim(),
          div_id: divisionIdNumeric,
          dr_id: encoded,
          dr_consent: consent,
          doctor_meta: jsonstringmap
      ));
      // print("#####Database success Doctor");

      // Reset controllers and errors
      _initializeControllers();
    } catch (e) {
      print("Error inserting into database: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Handle back button pressDataSingleton().division_id
          // For example, navigate to a specific screen

          // Get.to(DoctorSelectionScreen());
          Get.back();
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(title: 'Doctor Details', showBackButton: true,pageNavigationTime:"${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  for (var field in fields)

                     Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomTextField(
                        controller: controllers[field['key']]!,
                        hintText: field['label']!,
                        keyboardType: field['label'] == "Phone"
                            ? TextInputType.number
                            : TextInputType.text,
                        errorText: errors[field['key']]!,
                      ),
                    ),

                    Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Aligns buttons to the end (right side)
                    children: [
                      CustomElevatedButton1(
                        text: 'Reset',
                        onPressed: () {
                          _initializeControllers();
                          setState(() {});
                        },
                      ),
                      SizedBox(width: 16), // Add some spacing between the buttons
                      CustomElevatedButton(
                        text: 'Submit',
                        onPressed: () {

                          if(controllers["DOCTOR_NAME"]!.text.toLowerCase().trim().startsWith("dr.".trim()) ||
                              controllers["DOCTOR_NAME"]!.text.toLowerCase().trim().startsWith("dr".trim())){
                            CustomSnackbar.showErrorSnackbar(title: "Error", message: "Please Remove Dr prefix.");

                          }else{
                            checkAndInsertDoctor();
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
  var drConsentAltText;
  Future<void> checkAndInsertDoctor() async {
    // print('Doctor already exists. Do something here1111...');
    divisionIdNumeric = DataSingleton().division_id.toInt();
    doctorInfo =
    '${controllers["DOCTOR_NAME"]!.text.toLowerCase().trim()}${controllers["DOCTOR_CODE"]!.text.toLowerCase().trim()}${divisionIdNumeric.toString().toLowerCase().trim()}';


    dr_id_to_check = dataSingleton.generateMd5(doctorInfo).toString();
    // print("###dr_id_to_check: ${dr_id_to_check}");

    // Check if the doctor exists
    int? doctorExists = await _databaseHelper?.doesDoctorExist(dr_id_to_check);

    print('settingtextsingleton ${DataSingleton().drConsentText}');

    drConsentAltText = (DataSingleton().drConsentText != null && DataSingleton().drConsentText!.trim().isNotEmpty)
        ? DataSingleton().drConsentText
        : "I agree that my Patient data may be used in an anonymous aggregated manner for analysis/publication purposes in India or abroad. In particular, I understand and agree that Patient data may be used by a service provider company (other than Indigital Technologies) in India or abroad, in order to be properly de-identified before any further utilization for analysis purposes.";


    // If the doctor doesn't exist, insert data
    if (doctorExists == 0) {
      // print('Doctor already exists. Do something here22...');
      await _insertData(); // Make sure to await the insertion
    } else {
      CustomSnackbar.showErrorSnackbar(title: "Doctor Exists!!!", message: "Try with Different Doctor Name or Code");
      Get.off(DoctorSelectionScreen());
      // Doctor already exists, handle accordingly (show a message, etc.)
      // print('Doctor already exists. Do something here33...');
    }
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



}
