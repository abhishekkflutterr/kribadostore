import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:intl/intl.dart';
import 'package:kribadostore/NetworkHelper.dart';

import 'models/division_details_response.dart';
import 'models/user_login_response.dart';


class DataSingleton {
  static final DataSingleton _singleton = DataSingleton._internal();

  factory DataSingleton() {
    
    return _singleton;
  }


  DataSingleton._internal() : division_id = 0,dr_consent=0,patient_consent=0, lastLogin="${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";


  bool status = false;

  bool camp_plan = false;
  String? pngBytes;
  String? pngBytesChart1;
  String? pngBytesChart2;

  String? scaleS3Url;
  String? doc_name;
  String? scale_name;
  String? scale_id;
  String? age_range;
  String? age_min="1";
  String? age_max="100";
  String? device_serial_number="";
  String? appversion="";
  String? channel="App";
  int division_id;
  int dr_consent;
  int patient_consent;

  String? division_encoded;
  int? subscriber_id;
  String? doc_speciality;
  String? mr_code;

  //divisionIdEncoded camp plan
  String? division_encoded_Plan;

  String? country_code;

  String? state_code;
  String? city_code;
  String? area_code;
  String? doc_code;
  String? dr_id;
  String? doctor_meta;
  String? patient_meta;

  //for printing purpose
  String? Scale_Name;
  String? Test_Name;
  String? Score;
  String? Interpretation;
  String? Patient_name;
  String? Patient_age;
  String? Patient_gender;
  String? References;
  num? TotalScore;
  String? Disclaimer;
  num? reflux_score_only = 0;
  num? dyspeptic_score_only = 0;


  //scales list b64data
  // String? scalesList


  //calculation bmi rounded for frax
  int? fraxBmiRound = 0;
  //frax header in result screen
  String fraxHeader = 'without BMD';


  //s3 creds
  String? accessKeyId;
  String? secretAccessKey;
  String? bucket;
  String? bucketFolder;


  //to check child question heading
  String? childQuestion;
  int? childGroupValue;
  List<Map<String, dynamic>> tranformedRepsonsesParentChild = [];


  String hbA1c = "0.0";

  //as we have added locale selection screen after patient consent accept
  String patient_data='';
  String patientGlucoseRange = "";
  String patientUricRange = "";
  String? uricAcidFinalLine;
  String glucoseFinalLine='';
  String? pat_id;
  String? camp_date;
  String? test_date;
  String? test_start_time;
  String? pat_age;
  String? pat_name;
  String? pat_gender;
  String? pat_height;
  String? pat_weight;

  //locale consent
  String? locale;
 //locale title
  String? localeTitle;

  //for iap chart
  String? Patient_namechart;
  String? Patient_agechart;
  String? Patient_genderchart;
  String? pat_idc;
  String? camp_datec;
  String? test_datec;
  String? test_start_timec;
  String? pat_agec;
  String? pat_namec;
  String? pat_genderc;

  //for WOMAC
  num? score1to5;
  num? score6and7;
  num? scoreBeyond7;


  //for ios interpretation
  String? heightinter;
  String? weightinter;

  //for dynamic hints
  List<String>? metaHintsDetails= [];
  List<Meta>? mData;

  //for dynamic doctor & patient consent text
  String? ptConsentText;
  String? drConsentText= "";
  String? drConsentAllowOrNot;
  String EndCampBtn = "false";
  bool? displayAddDoctorbtn=true;
  bool? clearDoctor=false;


  //for end camp : camp with senior
  String CampWithSeniorDropDown = "false";
  bool? addDoctorBtn = false;
  String? doctorSpecialtyDropDown;


  //scalejson - inputs array data
  List<dynamic> inputs = [];

  //for question & answers print dynamic on receipt
  String questionAndAnswers = "";

  //for enabling disabling print and pdf buttons
  String print_btn = "";
  String download_btn = "";
  String download_print_btn = "";
  String qr_url = "";
  String qr_label = "";
  String ios_qr_label = "";
  String ios_qr_url = "";


  //for font_size of test screen only
  double font_size = 16.0;
  // int? getFontSize() {
  //   return font_size ?? 16.0;
  // }

  List<Map<String, dynamic>> resultDataformat = [];

  //for offline purpose
  String? userLoginOffline;
  String? divisionDetailOffline;
  String? s3jsonOffline;
  String? top_logo;
  String? bottom_logo;
  String? option_selected_logo;

  String fraxOptionTitle = "";
  String fraxAnswer10 = "";
  String fraxchilId = "";


//for auto Logout
  String? lastLogin;
  // int? lastLogin;

  String imgStringInCache='';

  //for remebering connected device info
  String? bluetoothConnected;

  //Brands list for endcamp
  List<Brands>? brands;
  // Method to clear subscriber ID & mr code
  void clearSubscriberId() {
    subscriber_id = null;
    mr_code = null;
  }


  //only for chart make it true if it goes to printchart.dart
  bool? skip_sync = false;
  bool? skip_reinsert_print_btn = false;


  //for hCG scale
  num? Percentagedifference;
  num? absoluteDifference;
  num? doublingTime;
  num? oneDayIncrease;
  num? twoDayIncrease;



  // Add DateService instance
  final DateService _dateService = DateService.instance;

  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;
  bool isInternet=false;


  void checkInternet(){
     _networkHelper.checkInternetConnection();
    _subscription = _networkHelper.isOnline.listen((isOnline) async {
      if (isOnline) {
       isInternet= true;
      }else{
         isInternet= false;
      }

    });
     
  }

  // Function to get the current date and time in IST in ISO 8601 format
  String getCurrentDateTimeInIST() {
    return _dateService.getCurrentDateTimeInIST();
  }

  String generateMd5(String data){
    // return generateMd5(data); //Sachin branch changes
    return md5.convert(utf8.encode(data)).toString();
  }
}

class DateService {
  // Private constructor
  DateService._privateConstructor();

  // Singleton instance
  static final DateService _instance = DateService._privateConstructor();

  // Getter to access the singleton instance
  static DateService get instance => _instance;

  // Function to get the current date and time in IST in ISO 8601 format
  String getCurrentDateTimeInIST() {
    DateTime now = DateTime.now();
    // Assuming IST is 5 hours and 30 minutes ahead of UTC
    DateTime istDateTime = now.toUtc().add(Duration(hours: 5, minutes: 30));

    // Format the date and time in ISO 8601 format
    String formattedDateTime = DateFormat('yyyy-MM-ddTHH:mm:ss').format(istDateTime);

    return formattedDateTime;
  }

}


class CalculateMD5ForInput {
  CalculateMD5ForInput._privateConstructor();
  get hex => null;

  String generateMd5(String data) {
    var content = new Utf8Encoder().convert(data);
    var md5 = crypto.md5;
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

}