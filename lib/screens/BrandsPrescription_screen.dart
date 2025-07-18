import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/custom_widgets/elevated_button_color.dart';
import 'package:kribadostore/custom_widgets/text_field.dart';
import 'package:kribadostore/models/BrandPrescriptionsRequest.dart';
import 'package:kribadostore/screens/doctor_selection_screen.dart';
import 'package:kribadostore/screens/patient_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Camp.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../Doctor.dart';
import '../NetworkHelper.dart';
import '../controllers/login_controller.dart';
import '../models/division_details_response.dart';
import '../models/user_login_response.dart';
import 'package:flutter/cupertino.dart';

class BrandsPrescription extends StatefulWidget {

  const BrandsPrescription({super.key});


  State<BrandsPrescription> createState() => _BrandsPrescriptionScreenState();

}

class _BrandsPrescriptionScreenState extends State<BrandsPrescription> {
  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;
  final Connectivity _connectivity =
  Connectivity();
  List<String> doctorNames = [];
  String? subscriber_id;
  String? mr_id;
  DataSingleton dataSingleton = DataSingleton();
  // final LoginController loginController = Get.find<LoginController>();
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
  String dr_id_to_check = '';
  //List<String>? Values=[];
  List<Map<String, dynamic>> fields = [];
  late Map<String, String> fields_doctor;
  List<String> Values = []; // Initialize Values to an empty list
  late Map<String, TextEditingController> controllers;
  late Map<String, String> errors;
  final remarkTextEditController = TextEditingController();


  @override
  void initState() {
    super.initState();

    sharedPrefsData();
    DataSingleton().questionAndAnswers = "";
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();
    _initializeControllersData();
    _initializeControllers();
    setPrescriptionPopupToFalse();
  }

  Future<void> sharedPrefsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriber_id = prefs.getString('subscriber_id');
    mr_id = prefs.getString('mr_id');
  }

  Future<void> setPrescriptionPopupToFalse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prescriptionPopup', false);
  }


  Future<void> _initializeControllersData() async {
    // if (DataSingleton().mData == null) {
    final prefs = await SharedPreferences.getInstance();
    final brands_json = prefs.getString('brands');
    print("brands_json  $brands_json");
    var br = jsonDecode(brands_json!)["data"]["brands"];
    print("sfkfmskmxcx $br");

    if (brands_json != null) {
      var br = jsonDecode(brands_json)["data"]["brands"] as List;
      print("sfkfmskmxcx $br");

      List<Brands> brandList = br.map((brand) => Brands.fromJson(brand)).toList();
      DataSingleton().brands = brandList;
      // Fetch meta information from the database
      try {
        if (DataSingleton().brands != null) {
          for (var j = 0; j < DataSingleton().brands!.length; j++) {
            fields.add({
              "key": DataSingleton().brands?[j].name,
              "label": DataSingleton().brands?[j].name,
              "REGEX": "name",
              "Icon": "",
              "ReqKey": DataSingleton().brands?[j].name,
              "ReqValue": DataSingleton().brands?[j].name
            });
          }
        } else {
          // Handle case when DataSingleton().brands is null
          print("DataSingleton().brands is null");
        }
      } catch (e) {
        print("Error: $e");
      }


      // Trigger a UI update when offline data is loaded
      setState(() {
        _initializeControllers();
      });
    }




  }


  Future<void> _insertDataWhenNoConsent(String doctor_meta) async {
    print('#####Database entered NO CONSENT try block');
    // String testString=dataSingleton.generateMd5("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${encoded}_${DataSingleton().scale_name}").toString();
    try {
      doctorInfo =

      '${controllers["DOCTOR_NAME"]!.text.toLowerCase().trim()}${controllers["DOCTOR_CODE"]!.text.toLowerCase().trim()}${divisionIdNumeric.toString().toLowerCase().trim()}';


      encoded = dataSingleton.generateMd5(doctorInfo).toString();
      print('#####Database entered try block2');
      print('#####Database entered try block2'+doctorInfo);
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
          patient_meta:""

      ));
      //setState(() {});
      print("#####Database success CampNoConsent");
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

    print('@@## In validation');

    // Check if the value is required and empty
    if (requiredValue == 'True' && value.trim().isEmpty) {
      setState(() {
        errors[key] = 'Please enter $label';
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
      final key = field['key']!;
      final label = field['label']!;
      final regexValue = field['REGEX'];
      final requiredKey = field['ReqKey'];
      final requiredValue = field['ReqValue'];
      // Check if the key ends with "REQ" and its value is true
      // final regex = _getRegex(key);
      var regex;
      if(regexValue == "age"){
        regex = RegExp(r'^[1-9]\d?$|^100$'); // Accepts numbers from 1 to 100 - working
      } else if(regexValue == "name"){
        regex = RegExp(r'^[a-zA-Z ]*$'); // Accepts only alphabets (no numbers)  - working
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

      if(key!="SPECIALITY"){

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
    print('@@@ entered1 ');
    var drConsentAltText = DataSingleton().drConsentText;
    if(drConsentAltText == null){
      drConsentAltText = "I agree that my Patient data may be used in an anonymous aggregated manner for analysis/ publication purposes in India or abroad. In particular, I understand and agree that Patients data may be used by a service provider company (other than Indigital Technology) in India or abroad, in order to be properly de-identified before any further utilization for analysis purposes.";
    }
    // Validate fields before showing consent dialogue
    if (_validateFields()) {
      print('@@@ entered2 ');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            title: Center(child: Text('Doctor Consent',style: TextStyle(fontWeight: FontWeight.bold),)),
            content: Text(
                '$drConsentAltText',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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

                    print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());
                  }

                  String jsonstringmap = json.encode(fields_doctor);

                  _insertDataIntoDatabase(0,jsonstringmap);
                  _insertDataWhenNoConsent(jsonstringmap);
                  Get.to(DoctorSelectionScreen());
                  // Optionally, you can handle decline action
                },
              ),
              CustomElevatedButton(
                text: 'Accept',
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog







                  fields_doctor = {};

                  for (var field in fields) {
                    fields_doctor.addAll({
                      field['key']! : controllers[field['key']!]!.text.toString().toLowerCase().trim()
                    });

                    print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());
                  }

                  String jsonstringmap = json.encode(fields_doctor);
                  print("@@## jsonstringmap "+jsonstringmap);



                  _insertDataIntoDatabase(1,jsonstringmap);
                  DataSingleton().doc_name = controllers["DOCTOR_NAME"]!.text.toString().toLowerCase().trim();
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
                  Get.to(PatientsDetailsScreen());

                },
              ),
            ],
          );
        },
      );
    }

  }

  void loadDoctorNames() async {
    try {
      // Fetch doctors from the database
      final doctors = await _databaseHelper?.getAlldoctors();
      print("####doctors_list from detailsScreen : $doctors");

      // Filter out duplicates
      List<String> uniqueDoctorNames = doctors!
          .map((doctor) => doctor['doc_name'] as String)
          .toSet()
          .toList();

      setState(() {
        doctorNames = uniqueDoctorNames;
        print("####doctors_name from detailsScreen: $doctorNames");
      });
    } catch (e) {
      print('Error loading doctor names: $e');
    }
  }



  void _insertDataIntoDatabase(int consent, String jsonstringmap) async {
    print('#####entered3 ');




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
      print('##### entered4 ');
      await _databaseHelper?.insertDoctor(Doctor(
          country_code: "INDIA",
          // state_code: controllers["AREA_NAME"]!.text.toString().toLowerCase().trim(),
          //city_code: controllers["CITY_NAME"]!.text.toString().toLowerCase().trim(),
          //area_code: controllers["AREA_NAME"]!.text.toString().toLowerCase().trim(),
          state_code: "",
          city_code: "",
          area_code: "",
          doc_code: controllers["DOCTOR_CODE"]!.text.toLowerCase().trim(),
          doc_name: controllers["DOCTOR_NAME"]!.text.toLowerCase().trim(),
          doc_speciality: "",
          // doc_speciality: controllers["SPECIALITY"]!.text.toString().toLowerCase().trim(),
          div_id: divisionIdNumeric,
          dr_id: encoded,
          dr_consent: consent,
          doctor_meta: jsonstringmap
      ));
      print("#####Database success Doctor");

      // Reset controllers and errors
      _initializeControllers();
    } catch (e) {
      print("Error inserting into database: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'No. of Prescriptions Generated', showBackButton: true,showKebabMenu: false,showLogout: true ,pageNavigationTime:"${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
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
                    keyboardType: TextInputType.number,
                    //prefixIcon: _getIconData(field['key']!),
                    //  prefixIcon: IconData(IconData(58840, fontFamily: 'MaterialIcons')),
                    //   prefixIcon:   _getIconData(field['key']!),
                    errorText: errors[field['key']]!,
                  ),
                ),

              TextField(
                  controller: remarkTextEditController,
                decoration: InputDecoration(hintText: "Remarks By Doctor"
                  , border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),),
                keyboardType: TextInputType.multiline,
                minLines: 1,//Normal textInputField will be displayed
                maxLines: 5,// when user presses enter it will adapt to it
              ),
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomElevatedButton1(
                    text: 'Reset',
                    onPressed: () {
                      _initializeControllers();
                      setState(() {});
                    },
                  ),
                  SizedBox(width: 10,),
                  CustomElevatedButton(
                    text: 'Submit',
                    onPressed: ()  async {
                      //checkAndInsertDoctor();
                      // doctorInfo = '${controllers["DOCTOR_NAME"]!.text}${controllers["DOCTOR_CODE"]!.text}${divisionIdNumeric.toString()}';
                      // dr_id_to_check = dataSingleton.generateMd5(doctorInfo).toString();
                      // print("###dr_id_to_check: ${dr_id_to_check}");
                      //
                      // // Check if the doctor exists
                      // int? doctorExists = await _databaseHelper?.doesDoctorExist(dr_id_to_check);

                      // // If the doctor doesn't exist, insert data
                      // if (checkAndInsertDoctor == 0) {
                      //    _insertData(); // Make sure to await the insertion
                      // } else {
                      //   // Doctor already exists, handle accordingly (show a message, etc.)
                      //   print('Doctor already exists. Do something here...');
                      // }

                      fields_doctor = {};

                      for (var field in fields) {
                        fields_doctor.addAll({
                          field['key']! : controllers[field['key']!]!.text.toString().toLowerCase().trim()
                        });

                        print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());


                      }

                      divisionIdNumeric = DataSingleton().division_id.toInt();
                        String? doc_name = DataSingleton().doc_name?.trim().toLowerCase();
                        String? doc_code = DataSingleton().doc_code?.trim().toLowerCase();

                      // print('@@## Doctor Name '+doc_name!);
                      // print('@@## Doctor code '+doc_code!);
                      print('@@## Doctor divisionIdNumeric '+divisionIdNumeric.toString());

                      String campid= dataSingleton
                          .generateMd5(
                          "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}_${DataSingleton().division_id}_$subscriber_id")
                          .toString();

                      //doctorInfo =dataSingleton.generateMd5('${doc_name}${doc_code}${divisionIdNumeric}').toString();
                      String doctorInfo =
                      dataSingleton.generateMd5('${doc_code}'.toLowerCase().trim()+  '${doc_name}'.toLowerCase().trim() +
                          '${divisionIdNumeric}'.toLowerCase().trim());

                      print('@@## Doctor divisionIdNumeric '+doctorInfo);

                      print('@@## Camp ID: $campid');
                      List<Prescription> prescriptions = [];

                      int cont=0;
                      for (var field in fields) {
                        var brand = field['key']!.toString().trim();
                        var count = controllers[field['key']!]!.text.toString().trim()==""?"0":controllers[field['key']!]!.text.toString().trim();

                        if(count=="0"){
                          cont++;

                        }

                        prescriptions.add(Prescription(brand: brand, count: count));
                        print("@@## Get from abhishek $brand - $count");

                        fields_doctor.addAll({
                          field['key']! : controllers[field['key']!]!.text.toString().toLowerCase().trim()
                        });

                        print("@@## Get from "+field['key']!+" - "+controllers[field['key']!]!.text.toString().toLowerCase().trim());


                      }


                      var connectivityResult = await _connectivity.checkConnectivity();


                      if(cont==DataSingleton().brands?.length){
                        CustomSnackbar.showErrorSnackbar(title: 'Require',
                            message: 'Please Enter Prescriptions Count!');
                      } else if(connectivityResult == ConnectivityResult.none) {
                        // No internet connection
                        setState(() {
                          CustomSnackbar.showErrorSnackbar(
                            title: 'No Internet',
                            message: 'Please check your internet connection.',
                          );
                        });
                        return;
                      }


                      else{


                        final prefs = await SharedPreferences.getInstance();
                        final campids = prefs.getString('campid');
                        final doctorInfos = prefs.getString('doctorInfo');
                        String campid_prefs = campids!;
                        String doctorInfo_prefs = doctorInfos!;

                        BrandPrescriptionsRequest prescriptionsRequest=new BrandPrescriptionsRequest(campId: campid_prefs, doctorId: doctorInfo_prefs, prescriptions: prescriptions,remarkByDoctor: remarkTextEditController.text);
                        print("prescriptionsRequestTOJSON" + prescriptionsRequest.toJson());
                        loginController.SendBrandPrescriptions(context,prescriptionsRequest);

                      }
                    },
                  ),


                ],
              ),

              SizedBox(height: 10,),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkAndInsertDoctor() async {
    print('Doctor already exists. Do something here1111...');
    divisionIdNumeric = DataSingleton().division_id.toInt();
    doctorInfo =
    '${controllers["DOCTOR_NAME"]!.text.toLowerCase().trim()}${controllers["DOCTOR_CODE"]!.text.toLowerCase().trim()}${divisionIdNumeric.toString().toLowerCase().trim()}';


    dr_id_to_check = dataSingleton.generateMd5(doctorInfo).toString();
    print("###dr_id_to_check: ${dr_id_to_check}");

    // Check if the doctor exists
    int? doctorExists = await _databaseHelper?.doesDoctorExist(dr_id_to_check);

    // If the doctor doesn't exist, insert data
    if (doctorExists == 0) {
      print('Doctor already exists. Do something here22...');
      await _insertData(); // Make sure to await the insertion
    } else {
      CustomSnackbar.showErrorSnackbar(title: "Doctor Exists!!!", message: "Try with Different Doctor Name or Code");
      Get.to(DoctorSelectionScreen());
      // Doctor already exists, handle accordingly (show a message, etc.)
      print('Doctor already exists. Do something here33...');
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
