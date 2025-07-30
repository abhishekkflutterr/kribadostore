import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/src/widgets/text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/models/BrandPrescriptionsRequest.dart';
import 'package:kribadostore/models/CampPlan.dart';
import 'package:kribadostore/models/CampPlanList.dart';
import 'package:kribadostore/models/CheckPassword.dart';
import 'package:kribadostore/models/DateRangeFilterCount.dart';
import 'package:kribadostore/models/ExecuteCamp.dart';
import 'package:kribadostore/models/PlannedCampsResponse.dart';
import 'package:kribadostore/models/database_models/camp_plan_data.dart';
import 'package:kribadostore/screens/camp_list_screen.dart';
import 'package:kribadostore/screens/login_screen.dart';
import 'package:kribadostore/screens/userGuide.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DatabaseHelper.dart';
import '../NetworkHelper.dart';
import '../Resources.dart';
import '../constants/urls.dart';
import '../models/FilterByDateCountResponse.dart';
import '../models/user_login_response.dart';
import '../custom_widgets/text_field.dart';

class LoginController extends GetxController {
  List<Division> divisionsoff = <Division>[].obs;
  NetworkHelper networkHelper = NetworkHelper();
  String sr_no = "";

  final S3Upload s3Upload = S3Upload();

  List<Division> changeJobListData(List<Division> jobListData) {
    divisionsoff.clear();
    divisionsoff.addAll(jobListData);

    return divisionsoff;
  }

  LoginResponse? userLoginResponse;
  DatabaseHelper? _databaseHelper;

  // Add a private field to store the login error message
  var _loginErrorMessage = ''.obs;

  // Add a getter to retrieve the login error message
  String get loginErrorMessage => _loginErrorMessage.value;

  // Observable campPlan
  var campPlan = false.obs;

  // Method to update campPlan
  void updateCampPlan(bool value) {
    campPlan.value = value;
  }

  // Add a method to update the login error message
  void setLoginErrorMessage(String message) {
    _loginErrorMessage.value = message;
  }

  void updateUserLoginResponse(LoginResponse response) {
    userLoginResponse = response;
    update(); // Call update() to rebuild the UI
  }

  void setUserLoginResponse(LoginResponse response) {
    userLoginResponse = response;
    update(); // Notify listeners of the change
  }

  List<Division> get divisions {
    if (userLoginResponse?.data?.user?.divisions != null) {
      return userLoginResponse!.data!.user!.divisions;
    } else {
      return [];
    }
  }

  final emailText = TextEditingController();
  final passText = TextEditingController();

  // Add a private field to store the loading state
  var _isLoading = false.obs;

  // Add a getter to retrieve the loading state
  bool get isLoading => _isLoading.value;

  // Add a method to update the loading state
  void setLoading(bool value) {
    _isLoading.value = value;
  }

  Future<void> ForgotPasswordlogin(
      BuildContext context, String username, String email) async {
    try {
      setLoading(true); // Set loading state to true

      bool isOnline = await networkHelper.isInternetAvailable();

      if (!isOnline) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      print('@@## ' + username);
      print('@@## ' + email);

      http.Response response = await http.post(
        Uri.parse('${baseurl}/forgetPassword'),
        body: {'username': username, 'email': email},
      );

      print('@@## ' + response.statusCode.toString());
      if (response.statusCode == 200) {
        setLoading(false); // Set loading state to false after successful login

        // Parse the response body into your model
        LoginResponse userLoginResponse =
            LoginResponse.fromJson(json.decode(response.body));

        setLoginErrorMessage(userLoginResponse.message);
      } else {
        LoginResponse userLoginResponse =
            LoginResponse.fromJson(json.decode(response.body));

        setLoginErrorMessage(userLoginResponse.message);

        setLoading(false); // Set loading state to false after failed login
      }
    } catch (e) {
      print(e.toString());
      setLoading(false); // Set loading state to false after failed login
    }
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

  Future<void> CheckDeviceOrPOS(
      BuildContext context, String email, String pass) async {
    try {
      String? deviceName = await getDeviceName();

      if (["Alps Q1", "Alps JICAI Q1", "Q1", "JICAI Q2", "Z91"]
          .contains(deviceName)) {
        print('@@##SNOhere');
        final prefs = await SharedPreferences.getInstance();
        String? sno = prefs.getString('device_serial_number');

        // Line 37

        print('@@##SNO ' + sno.toString());

        if (sno == null || sno.isEmpty) {
          showDialogDeviceSerialNo(context, email, pass);
        } else {
          CheckPasswordloginWithSerialNo(context, email, pass, sno.toString());
        }
      } else {
        CheckPasswordlogin(context, email, pass);
      }
    } catch (e) {
      print(e.toString());
      setLoading(false); // Set loading state to false after failed login
    }
  }

  Future<void> CheckPasswordlogin(
      BuildContext context, String email, String pass) async {
    try {
      setLoading(true); // Set loading state to true

      bool isOnline = await networkHelper.isInternetAvailable();

      if (!isOnline) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      http.Response response = await http.post(
        Uri.parse('${baseurl}/check_username'),
        body: {'username': email},
      );

      if (response.statusCode == 200) {
        setLoading(false); // Set loading state to false after successful login

        // Parse the response body into your model
        CheckPassword userLoginResponse =
            CheckPassword.fromJson(json.decode(response.body));

        if (userLoginResponse.hasPassword == 1) {
          showDialogWithFields(context);
        } else {
          login(email, pass, context);
        }
      } else {
        setLoginErrorMessage(
            'Authentication failed ! Please check your login credentials');

        setLoading(false); // Set loading state to false after failed login
      }
    } catch (e) {
      print(e.toString());
      setLoading(false); // Set loading state to false after failed login
    }
  }

  Future<void> CheckPasswordloginWithSerialNo(
      BuildContext context, String email, String pass, String srno) async {
    try {
      setLoading(true); // Set loading state to true

      bool isOnline = await networkHelper.isInternetAvailable();

      if (!isOnline) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      http.Response response = await http.post(
        Uri.parse('${baseurl}/check_username'),
        body: {'username': email, "type": "device", "serial_no": srno},
      );

      if (response.statusCode == 200) {
        setLoading(false); // Set loading state to false after successful login

        // Parse the response body into your model
        CheckPassword userLoginResponse =
            CheckPassword.fromJson(json.decode(response.body));

        sr_no = srno;

        if (userLoginResponse.hasPassword == 1) {
          showDialogWithFields(context);
        } else {
          CheckPasswordlogin(context, email, pass);
        }
      } else {
        setLoginErrorMessage(
            'Authentication failed ! Please check your login credentials');

        setLoading(false); // Set loading state to false after failed login
      }
    } catch (e) {
      print(e.toString());
      setLoading(false); // Set loading state to false after failed login
    }
  }

  Future<void> login(String email, String pass, BuildContext context) async {
    try {
      setLoading(true); // Set loading state to true

      bool isOnline = await networkHelper.isInternetAvailable();

      if (!isOnline) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      http.Response response = await http.post(
        Uri.parse('${baseurl}/login'),
        body: {'username': email, 'password': pass},
      );

      print('@@## statusCode' + response.statusCode.toString());

      if (response.statusCode == 200) {
        setLoading(false); // Set loading state to false after successful login

        //for storing json res in offline
        DataSingleton().userLoginOffline = response.body.toString();

        // Parse the response body into your model
        LoginResponse userLoginResponse =
            LoginResponse.fromJson(json.decode(response.body));

        Get.find<LoginController>().setUserLoginResponse(userLoginResponse);
        Get.find<LoginController>().updateUserLoginResponse(userLoginResponse);

        // Access the user details
        String userId = userLoginResponse.data.user.id;
        String userName = userLoginResponse.data.user.name;
        String img = userLoginResponse.data.user.divisions.length.toString();

        print('@@@@@@@@logintime  mrid ${userLoginResponse.data.user.mrId}');
        print(
            '@@@@@@@@logintime empcode ${userLoginResponse.data.user.empCode}');

        //set to shared prefs login creds
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_serial_number', sr_no);
        await prefs.setString('user_id', userLoginResponse.data.user.id);
        await prefs.setString('token', userLoginResponse.data.token);
        await prefs.setString('username', userLoginResponse.data.user.username);
        await prefs.setString('name', userLoginResponse.data.user.name);
        await prefs.setString('lastLogin',
            '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}');
        await prefs.setString('version_code', 'v1.0');
        await prefs.setString(
            'loginjson', '${DataSingleton().userLoginOffline}');
        await prefs.setString(
            'mr_id', '${userLoginResponse.data.user.empCode}');
        await prefs.setString(
            'subscriber_id', '${userLoginResponse.data.user.mrId}');

        //set value initially for last sync

        String syncedNow = "No records Synced for Today";
        await prefs.setString('lastSync', syncedNow);

        await autoLoginapiandINsert(context);
      } else {
        LoginResponse userLoginResponse =
            LoginResponse.fromJson(json.decode(response.body));

        setLoginErrorMessage(userLoginResponse.message);

        setLoading(false); // Set loading state to false after failed login
      }
    } catch (e) {
      print(e.toString());
      setLoading(false); // Set loading state to false after failed login
    }
  }

  Future<void> SendBrandPrescriptions(
      BuildContext context, BrandPrescriptionsRequest prescriptions) async {
    try {
      setLoading(true); // Set loading state to true

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      // String jsonPrescriptions = prescriptions.toJson();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";
      final div_id = prefs.getInt('divisonid') ?? 0;

      var headers1 = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      var request = http.Request(
          'POST', Uri.parse('${baseurl}/brand_prescriptions/$div_id'));
      request.body = prescriptions.toJson();
      request.headers.addAll(headers1);

      http.StreamedResponse response = await request.send();

      // print('@@## '+response.statusCode.toString());

      if (response.statusCode == 200) {
        // print('@@##here in 200 ');
        // Set loading state to false after successful login
        setLoading(false); // Set loading state to false
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('prescriptionPopup', true);

        Get.snackbar('success', 'Brand Prescriptions Added Successfully',
            snackPosition: SnackPosition.BOTTOM);
        Navigator.pop(context);
      } else if (response.statusCode == 401) {
        print('Session expired');
        showAlertDialog(context);
      } else {
        CustomSnackbar.showErrorSnackbar(title: 'Failed', message: 'Failed');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> SendCampWithSenior(BuildContext context, String campId,
      String doctorId, String seniorDesignation) async {
    try {
      setLoading(true); // Set loading state to true

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";
      final divId = prefs.getInt('divisonid') ?? 0;
      // final campid = prefs.getString('campid')!;
      // final doctorId = prefs.getString('doctorInfo')!;

      var headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      var body = jsonEncode({
        "camp_id": campId,
        "doctor_id": doctorId,
        "senior_designation": seniorDesignation
      });

      // Print the request body before sending
      print('Request Body: $body');

      var response = await http.post(
        Uri.parse('$baseurl/camp_with_senior/$divId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // print('campwithseniorrrrrrrr ${response.body}');
        // Decode response body
        var responseData = jsonDecode(response.body);
        String message = responseData['message'] ?? "Successfull!";

        // Show toast message
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else if (response.statusCode == 401) {
        print('Session expired');
        showAlertDialog(context);
      } else {
        CustomSnackbar.showErrorSnackbar(
            title: 'Failed', message: 'Failed ! (Camp with Senior)');
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      CustomSnackbar.showErrorSnackbar(title: 'Error', message: e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> autoLoginapi(BuildContext context) async {
    print('@@##**Call autologin');
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final user_id = prefs.getString('user_id');

    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };

    http.Response response = await http.post(
      Uri.parse('$baseurl/auto_login'),
      body: {'username': username, 'user_id': user_id},
      headers: headers,
    );

    if (response.statusCode == 200) {
      print('@@##&& 1');
      LoginResponse userLoginResponse =
          LoginResponse.fromJson(json.decode(response.body));

      Get.find<LoginController>().setUserLoginResponse(userLoginResponse);
      Get.find<LoginController>().updateUserLoginResponse(userLoginResponse);

      String theme_color = "";
      String text_color = "";

      // Assuming response.body.toString() contains the JSON data
      Map<String, dynamic> responseData = json.decode(response.body.toString());
      String status = responseData['status'];
      String message = responseData['message'];
      await prefs.setString('status', status);
      await prefs.setString('message', message);

      Map<String, dynamic>? userData = responseData['data']['user'];
      List<dynamic> divisions = userData?['divisions'] ?? [];
      Map<String, dynamic> formattedDivisions =
          {}; // Use a map instead of a list

      int? divisionIntId;

// Initialize variables to store meta, scales, and brands
      List<dynamic> metaList = [];
      List<dynamic> scalesList = [];
      List<dynamic> brandsList = [];

      for (var division in divisions) {
        // Build the division map, excluding null values
        Map<String, dynamic> formattedDivision = {};

        // Add only non-null fields to the formattedDivision map
        if (division['division_id'] != null)
          formattedDivision['id'] = division['division_id'];
        if (division['division_name'] != null)
          formattedDivision['name'] = division['division_name'];
        if (division['company_id'] != null)
          formattedDivision['company_id'] = division['company_id'];
        if (division['logo'] != null)
          formattedDivision['logo'] = division['logo'];
        if (division['is_demo'] != null)
          formattedDivision['is_demo'] = division['is_demo'];
        if (division['report_type'] != null)
          formattedDivision['report_type'] = division['report_type'];
        if (division['login_type'] != null)
          formattedDivision['login_type'] = division['login_type'];
        if (division['android_version'] != null)
          formattedDivision['android_version'] = division['android_version'];
        if (division['ios_version'] != null)
          formattedDivision['ios_version'] = division['ios_version'];
        if (division['created_at'] != null)
          formattedDivision['created_at'] = division['created_at'];
        if (division['updated_at'] != null)
          formattedDivision['updated_at'] = division['updated_at'];
        if (division['division_int_id'] != null)
          formattedDivision['division_int_id'] = division['division_int_id'];
        if (division['base64_logo'] != null)
          formattedDivision['base64_logo'] = division['base64_logo'];

        // Capture the division_int_id for use later
        divisionIntId = division['division_id_int'];

        // Collect meta, scales, and brands
        metaList.addAll(division['meta'] ?? []);
        scalesList.addAll(division['scales'] ?? []);
        brandsList.addAll(division['brands'] ?? []);

        // Add the formatted division to the map using division_int_id as the key
        formattedDivisions[divisionIntId.toString()] = formattedDivision;
      }

      Map<String, dynamic> formattedResponse = {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': {
          'division': formattedDivisions, // Division as an object
          'meta': metaList, // Meta outside the division object
          'scales': scalesList, // Scales outside the division object
          'brands': brandsList, // Brands outside the division object
          // Include any other fields that are required in the specific format
        },
      };

      DataSingleton().meta = metaList;

      print("metaList ${metaList}");

      // print('Formatted Response: ${json.encode(formattedResponse)}');
      // DataSingleton().brands=divisionDetailsResponse.data.brands;
      // final prefs = await SharedPreferences.getInstance();
      //
      // await prefs.setString('brands', res.body);

      // print('divisionidzzzz ${divisionIntId.toString()}');

      // Check if the doctor exists
      int? doctorExists = await _databaseHelper
          ?.doesDivisionsDetailsExist(divisionIntId.toString());
      print('@@##**E ' + doctorExists.toString());

      if (doctorExists == 0 || doctorExists == null) {
        await _databaseHelper?.clearDivisionDetail_Table();

        await _databaseHelper?.insertDivisiondetail(
          Resources(
            user_id: divisionIntId.toString(),
            // division_detail: DataSingleton().userLoginOffline.toString(),
            division_detail: response.body,
            scales_list: json.encode(formattedResponse),
            s3_json: "",
          ),
        );
      } else {
        // Perform database insertion
        await _databaseHelper?.updateDivisiondetailField(
            divisionIntId.toString(),
            "scales_list",
            json.encode(formattedResponse));

        // Perform database insertion
        await _databaseHelper?.updateDivisiondetailField(
            divisionIntId.toString(), "division_detail", response.body);
      }

      if (responseData.containsKey('data') && responseData['data'] != null) {
        List<dynamic> divisions = responseData['data']['user']['divisions'];

        for (var division in divisions) {
          if (division.containsKey('meta') && division['meta'] != null) {
            List<dynamic> metaList = division['meta'];

            for (var metaItem in metaList) {
              if (metaItem['key'] == "THEME_COLOUR") {
                // print("smcsmcs ${metaItem['value']}");
                theme_color = metaItem['value'];
              }

              if (metaItem['key'] == "TEXT_COLOUR") {
                text_color = metaItem['value'];
              }

              // print("Metaxxcccccxxxxxxxeeee Key: ${metaItem['key']}");
              // print("Meta Value: ${metaItem['value']}");
            }
          } else {
            // print("Meta data not available for this division.");
          }
        }
      } else {
        // print("Data section not found in the response.");
      }

      DataSingleton().userLoginOffline = response.body.toString();

      List<Map<String, dynamic>> resources =
          await _databaseHelper!.getAllDivisiondetail();

      for (var resource in resources) {
        if (resource.containsKey('division_detail') &&
            resource['division_detail'] != null) {
          Map<String, dynamic> divisionDetail =
              json.decode(resource['division_detail']);

          List<Division> divisionsoff1 = (divisionDetail['data']['user']
                  ['divisions'] as List<dynamic>)
              .map((dynamic divisionData) => Division.fromJson(divisionData))
              .toList();

          changeJobListData(divisionsoff1);
        } else {
          print('Division detail not available');
        }
      }

      // await _databaseHelper?.allDetails(
      //   AutoLoginResp(
      //     resp: response.body.toString(),
      //   ),
      // );
    } else if (response.statusCode == 400) {
      Map<String, dynamic> responseData = json.decode(response.body.toString());
      String status = responseData['status'];
      String message = responseData['message'];
      await prefs.setString('status', status);
      await prefs.setString('message', message);
      DataSingleton().status = true;
    } else if (response.statusCode == 401) {
      print('Session expired');
      showAlertDialog(context);
    }
  }

  Future<void> autoLoginapiandINsert(BuildContext context) async {
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final user_id = prefs.getString('user_id');

    DataSingleton().device_serial_number =
        prefs.getString('device_serial_number');

    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };

    http.Response response = await http.post(
      Uri.parse('$baseurl/auto_login'),
      body: {'username': username, 'user_id': user_id},
      headers: headers,
    );

    if (response.statusCode == 200) {
      print('@@##&& 1');
      LoginResponse userLoginResponse =
          LoginResponse.fromJson(json.decode(response.body));

      Get.find<LoginController>().setUserLoginResponse(userLoginResponse);
      Get.find<LoginController>().updateUserLoginResponse(userLoginResponse);

      String theme_color = "";
      String text_color = "";

      // Assuming response.body.toString() contains the JSON data
      Map<String, dynamic> responseData = json.decode(response.body.toString());
      Map<String, dynamic>? userData = responseData['data']['user'];
      List<dynamic> divisions = userData?['divisions'] ?? [];
      for (var division in divisions) {
        print('Division: $division');
      }
      Map<String, dynamic> formattedDivisions =
          {}; // Use a map instead of a list

      int? divisionIntId;

// Initialize variables to store meta, scales, and brands
      List<dynamic> metaList = [];
      List<dynamic> scalesList = [];
      List<dynamic> brandsList = [];

      for (var division in divisions) {
        // Build the division map, excluding null values
        Map<String, dynamic> formattedDivision = {};

        // Add only non-null fields to the formattedDivision map
        if (division['division_id'] != null)
          formattedDivision['id'] = division['division_id'];
        if (division['division_name'] != null)
          formattedDivision['name'] = division['division_name'];
        if (division['company_id'] != null)
          formattedDivision['company_id'] = division['company_id'];
        if (division['logo'] != null)
          formattedDivision['logo'] = division['logo'];
        if (division['is_demo'] != null)
          formattedDivision['is_demo'] = division['is_demo'];
        if (division['report_type'] != null)
          formattedDivision['report_type'] = division['report_type'];
        if (division['login_type'] != null)
          formattedDivision['login_type'] = division['login_type'];
        if (division['android_version'] != null)
          formattedDivision['android_version'] = division['android_version'];
        if (division['ios_version'] != null)
          formattedDivision['ios_version'] = division['ios_version'];
        if (division['created_at'] != null)
          formattedDivision['created_at'] = division['created_at'];
        if (division['updated_at'] != null)
          formattedDivision['updated_at'] = division['updated_at'];
        if (division['division_int_id'] != null)
          formattedDivision['division_int_id'] = division['division_int_id'];
        if (division['base64_logo'] != null)
          formattedDivision['base64_logo'] = division['base64_logo'];

        // Capture the division_int_id for use later
        divisionIntId = division['division_id_int'];
        // print('isjkscnxkcndjund $divisionIntId');

        // Collect meta, scales, and brands
        metaList.addAll(division['meta'] ?? []);
        scalesList.addAll(division['scales'] ?? []);
        brandsList.addAll(division['brands'] ?? []);

        // Add the formatted division to the map using division_int_id as the key
        formattedDivisions[divisionIntId.toString()] = formattedDivision;
      }

      Map<String, dynamic> formattedResponse = {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': {
          'division': formattedDivisions, // Division as an object
          'meta': metaList, // Meta outside the division object
          'scales': scalesList, // Scales outside the division object
          'brands': brandsList, // Brands outside the division object
          // Include any other fields that are required in the specific format
        },
      };

      // Check if the doctor exists
      int? doctorExists = await _databaseHelper
          ?.doesDivisionsDetailsExist(divisionIntId.toString());

      if (doctorExists == 0 || doctorExists == null) {
        await _databaseHelper?.clearDivisionDetail_Table();

        await _databaseHelper?.insertDivisiondetail(
          Resources(
            user_id: divisionIntId.toString(),
            // division_detail: DataSingleton().userLoginOffline.toString(),
            division_detail: response.body,
            scales_list: json.encode(formattedResponse),
            s3_json: "",
          ),
        );
      } else {
        // Perform database insertion
        await _databaseHelper?.updateDivisiondetailField(
            divisionIntId.toString(),
            "scales_list",
            json.encode(formattedResponse));

        // Perform database insertion
        await _databaseHelper?.updateDivisiondetailField(
            divisionIntId.toString(), "division_detail", response.body);
      }

      DataSingleton().userLoginOffline = response.body.toString();

      Get.off(const ScaffoldExample());

      setLoading(false);
    } else if (response.statusCode == 401) {
      print('Session expired');
      showAlertDialog(context);
    } else {
      setLoading(false);
    }
  }

  showAlertDialog(BuildContext context) {
    print('@@@@@@@calledtimesalertsession');

    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Center(
        child: Text(
          'Session Timeout!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      insetPadding: EdgeInsets.fromLTRB(5, 0, 5, 0),
      content: Text(
        'Your session has expired. Please click on login button to relogin!',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      actions: [
        Align(
          alignment: Alignment.bottomRight,
          child: CustomElevatedButton(
            text: 'Login',
            onPressed: () async {
              DataSingleton().bottom_logo = null;
              DataSingleton().top_logo = null;
              DataSingleton().Disclaimer = null;
              DataSingleton().font_size = 16.0;
              DataSingleton().drConsentText = "";

              if (DataSingleton().clearDoctor == true) {
                print('@@@@@@@@@@clearsdoctorrrr');
                await _databaseHelper!.clearDoctorsTable();
              }

              // DataSingleton().displayAddDoctorbtn = true;

              await s3Upload.initializeAndFetchDivisionDetails();
              await s3Upload.uploadJsonToS3();

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Navigator.of(context).pop(); // Close the dialog
              setLoading(false);
              Get.offAll(LoginScreen());
              // Add further logic here for login redirection if needed
            },
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );

    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<FilterByDateCountResponse?> RetrieveCampCount(BuildContext context,
      DateRangeFilterCount prescriptions, String divisionId) async {
    try {
      setLoading(true); // Set loading state to true

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false
        return null;
      }

      // String jsonPrescriptions = prescriptions.toJson();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      var headers1 = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      // print("divisoncheckkk ${divisions.length}");

      var request = http.Request(
          'POST', Uri.parse('${baseurl}/employee_counts/$divisionId'));
      // print("jcxbcjxbcnjsfbsjfs ${DataSingleton().division_id}");
      request.body = prescriptions.toJson();

      // print("bodyofdatefilter $request");
      request.headers.addAll(headers1);

      http.StreamedResponse response = await request.send();

      // print('@@## ' + response.statusCode.toString());

      if (response.statusCode == 200) {
        // print('@@##here in 200 ');
        setLoading(false); // Set loading state to false after successful login
        var responseString = await response.stream.bytesToString();

        // print("responseofCountttt $responseString");

        Get.snackbar('success', 'Records found',
            snackPosition: SnackPosition.BOTTOM);

        return FilterByDateCountResponse.fromJson(json.decode(responseString));
      } else if (response.statusCode == 401) {
        print('Session expired');
        showAlertDialog(context);
      } else {
        CustomSnackbar.showErrorSnackbar(title: 'Failed', message: 'Failed');
      }
    } catch (e) {
      // print("sfsjfnsjssjcns ${e.toString()}");
    }
    return null;
  }

  Future<PlannedCampsResponse?> CampPlanListData(
      BuildContext context1, String divisonId, CampPlanList camplanlist) async {
    try {
      setLoading(true); // Set loading state to true

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false
      }

      print('doctoidofcl=ampplan $divisonId');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      var headers1 = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      var request = http.Request(
          'POST', Uri.parse('${baseurl}/planned_camps/$divisonId'));

      request.body = camplanlist.toJson();
      request.headers.addAll(headers1);

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        print('@@@@@@@@jsonresponseofcamplisttt $jsonResponse');

        int exists = await DatabaseHelper.instance.doesCampPlanDetailExist();
        print('fjskfjkfjsfksjfkscmzxk $exists');
        if (exists == 1) {
          await _databaseHelper?.updateCampPlanDetail(jsonEncode(responseBody));
        } else {
          await _databaseHelper?.insertCampPlanDetail(
              CampPlanData(camp_plan_data: responseBody));
        }

        // Extract status and message from the response
        String status = jsonResponse['status'];
        String message = jsonResponse['message'];

        setLoading(false); // Set loading state to false after successful login
        return PlannedCampsResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        print('Session expired');
        showAlertDialog(context1);
      } else {
        // Convert StreamedResponse to a Response by reading its stream
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> SendCampPlan(
      BuildContext context, String divisonId, CampPlan camplan) async {
    try {
      setLoading(true); // Set loading state to true

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      var headers1 = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      var request =
          http.Request('POST', Uri.parse('${baseurl}/camp_plan/$divisonId'));
      request.body = camplan.toJson();
      request.headers.addAll(headers1);

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        // Extract status and message from the response
        String status = jsonResponse['status'];
        String message = jsonResponse['message'];

        setLoading(false); // Set loading state to false after successful login

        Get.snackbar(
          status, // Use dynamic status from the response
          message, // Use dynamic message from the response
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.off(CampListScreen());
      } else if (response.statusCode == 401) {
        print('Session expired');
        showAlertDialog(context);
      } else {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        String status = jsonResponse['status'] ?? 'Failed';
        String message = jsonResponse['message'] ?? 'Failed to add Camp Plan.';

        CustomSnackbar.showErrorSnackbar(
          title: status, // Dynamic error title
          message: message, // Dynamic error message
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> ExecuteCampPlan(
      BuildContext context, String divisonId, ExecuteCamp executeCamp) async {
    try {
      setLoading(true); // Set loading state to true

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        setLoading(false); // Set loading state to false

        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      var headers1 = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      var request =
          http.Request('POST', Uri.parse('${baseurl}/camp_execute/$divisonId'));
      request.body = executeCamp.toJson();
      request.headers.addAll(headers1);

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        // Extract status and message from the response
        String status = jsonResponse['status'];
        String message = jsonResponse['message'];

        setLoading(false); // Set loading state to false after successful login

        Fluttertoast.showToast(
            msg: '$message',
            backgroundColor: Colors.white,
            textColor: Colors.black,
            toastLength: Toast.LENGTH_LONG);
      } else if (response.statusCode == 401) {
        print('Session expired');
        showAlertDialog(context);
      } else {
        // Convert StreamedResponse to a Response by reading its stream
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);

        String status = jsonResponse['status'] ?? 'Failed';
        String message = jsonResponse['message'] ?? 'Failed to execute.';

        CustomSnackbar.showErrorSnackbar(
          title: status, // Dynamic error title
          message: message, // Dynamic error message
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  //register
  var companies = <Map<String, dynamic>>[].obs; // Store list of company maps
  Future<void> getCompanies() async {
    try {
      final response = await http.get(Uri.parse("$baseurl/companies"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Extract "data" from response
        if (jsonResponse.containsKey("data") && jsonResponse["data"] is List) {
          companies.value =
              List<Map<String, dynamic>>.from(jsonResponse["data"]);
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Failed to load companies");
      }
    } catch (e) {
      print("Error fetching companies: $e");
    } finally {}
  }

  Future<Map<String, dynamic>> fetchDataWithHeaders(
    String url,
    Map<String, String> headers, {
    String method = 'GET',
    Map<String, String>? queryParams, // Allow optional query parameters
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final request = http.Request(method, uri);
      request.headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during request: $e');
    }
  }

  RxList<Map<String, dynamic>> divisionDetails = <Map<String, dynamic>>[].obs;

  Future<void> divisionDetailsApi(String companyId) async {
    String baseUrl = '$baseurl/divisions?company_id=$companyId';
    var headers = {'Authorization': ''};
    Map<String, String> queryParams = {'company_id': companyId};

    try {
      final data = await fetchDataWithHeaders(baseUrl, headers,
          queryParams: queryParams);
      print('detailssdataaaaa $data'); // Log the full response

      if (data != null && data['status'] == 'success' && data['data'] is List) {
        List<Map<String, dynamic>> mappedData =
            (data['data'] as List<dynamic>).map((item) {
          return {
            'id': item['id'] ?? 'No ID',
            'name': item['name'] ?? 'No Name',
            'logo': item['logo'], // Keeping logo if needed
          };
        }).toList();

        print('Mapped divisionDetails: $mappedData');
        divisionDetails.value = mappedData;
      } else {
        print('Error: Invalid response or status');
      }
    } catch (e) {
      print('Error: $e'); // Catch any errors during the process
    }
  }

  Future<Map<String, dynamic>?> postDataWithHeaders(String url,
      Map<String, String> headers, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Parse error response
        Map<String, dynamic> errorResponse = jsonDecode(response.body);
        String errorMessage = "Server error";

        // Extracting dynamic error messages
        if (errorResponse.containsKey("errors")) {
          errorMessage = errorResponse["errors"]
              .values
              .map((errorList) =>
                  errorList.join(", ")) // Join multiple errors if any
              .join("\n"); // Join multiple fields if any
        } else if (errorResponse.containsKey("message")) {
          errorMessage = errorResponse["message"];
        }

        // Display error message in Snackbar
        Get.snackbar("Error", errorMessage, colorText: Colors.black);

        print("Error: ${response.statusCode}, $errorMessage");
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (e) {
      print("Exception in postDataWithHeaders: $e");
      Get.snackbar("Error", "Network error");
      return {'status': 'error', 'message': 'Network error'};
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData, String id) async {
    try {
      String url = '$baseurl/register/$id'; // API endpoint
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      var response = await postDataWithHeaders(url, headers, userData);
      print('API Response: $response');

      if (response != null && response['status'] == 'success') {
        print('registeration success done.');
        String successMessage =
            response['message'] ?? "Registration successful";
        Get.snackbar("Success", successMessage,
            snackPosition: SnackPosition.TOP);
      } else {
        String errorMessage = response?['message'] ?? "Something went wrong";
        Get.snackbar("Error", errorMessage, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      print("Error in registerUser API: $e");
      Get.snackbar("Error", "Failed to register user",
          snackPosition: SnackPosition.TOP);
    }
  }

  void openDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Dialog'),
        content: const Text('This is a dialog'),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  void showDialogDeviceSerialNo(
      BuildContext context, String email, String pass) {
    showDialog(
      context: context,
      builder: (_) {
        var serialNoController = TextEditingController();

        return AlertDialog(
          title: Text(
            "Serial Number Require",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              color: Colors.blue,
            ),
          ),
          content: SingleChildScrollView(
              child: Column(
            children: [
              CustomTextField(
                controller: serialNoController,
                hintText: 'Serial Number.',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.person,
              ),
            ],
          )),
          actions: [
            TextButton(
              onPressed: () async {
                // Send them to your email maybe?
                if (serialNoController.text.toString().trim().isEmpty) {
                  CustomSnackbar.showErrorSnackbar(
                    title: 'Serial Number is Require',
                    message: 'Please Enter Serial Number.',
                  );
                } else {
                  final prefs = await SharedPreferences.getInstance();
                  //  await prefs.setString('device_serial_number', serialNoController.text.trim().toString());

                  CheckPasswordloginWithSerialNo(context, email, pass,
                      serialNoController.text.trim().toString());
                  Navigator.pop(context);
                }
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void showDialogWithFields(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        var passwordController = TextEditingController();

        return AlertDialog(
          title: Text(
            "Password Require",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              color: Colors.blue,
            ),
          ),
          content: SingleChildScrollView(
              child: Column(
            children: [
              CustomTextField(
                obscureText: true,
                controller: passwordController,
                hintText: 'Password',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.person,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialogForgotPassword(context);
                  },
                  child: const Text('Forget Password?'),
                ),
              )
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Send them to your email maybe?
                if (passwordController.text.toString().trim().isEmpty) {
                  CustomSnackbar.showErrorSnackbar(
                    title: 'Password is Require',
                    message: 'Please Enter Password.',
                  );
                } else {
                  login(emailText.text.toString().trim(),
                      passwordController.text.toString().trim(), context);
                  Navigator.pop(context);
                }

                // Navigator.pop(context);
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void showDialogForgotPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        var emailController = TextEditingController();
        return AlertDialog(
          title: Text(
            "Forgot Password",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              color: Colors.blue,
            ),
          ),
          content: SingleChildScrollView(
              child: Column(
            children: [
              CustomTextField(
                controller: emailController,
                hintText: 'Email',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.person,
              ),
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Send them to your email maybe?
                if (emailController.text.toString().trim().isEmpty) {
                  CustomSnackbar.showErrorSnackbar(
                    title: 'Email is Require',
                    message: 'Please Enter Email.',
                  );
                } else {
                  ForgotPasswordlogin(context, emailText.text.toString().trim(),
                      emailController.text.toString().trim());
                  Navigator.pop(context);
                }

                // Navigator.pop(context);
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }
}
