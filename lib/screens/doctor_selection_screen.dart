// Import necessary packages
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/custom_widgets/CustomAppBarWithSync.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/models/ExecuteCamp.dart';
import 'package:kribadostore/screens/BrandsPrescription_screen.dart';
import 'package:kribadostore/screens/divisions_screen.dart';
import 'package:kribadostore/screens/doctor_details_screen.dart';
import 'package:kribadostore/screens/patient_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DatabaseHelper.dart';
import '../NetworkHelper.dart';
import 'package:kribadostore/screens/scales_screen_list.dart';
import '../controllers/login_controller.dart';
import 'package:aws_client/network_firewall_2020_11_12.dart';
import 'package:aws_client/s3_2006_03_01.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_widgets/CustomTextBox.dart';
import '../custom_widgets/customappbar.dart';
import '../custom_widgets/customsnackbar.dart';


class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({Key? key}) : super(key: key);


  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}




class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> with WidgetsBindingObserver{
  List<String> doctorNames = [];
  Map<String, String> doctorIdToNameMap = {};
  String selectedDoctor = 'Select a doctor'; // Set a default value
  String selectedCode = ''; // Set a default value
  late DatabaseHelper _databaseHelper;
  final LoginController loginController = Get.find<LoginController>();
  List<Map<String, dynamic>> campsData = [];

  bool isSyncButtonEnabled = true;

  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;
  final Connectivity _connectivity =
  Connectivity(); // Create an instance of Connectivity

  String uploadStatus = '';
  Map<String, dynamic> resultData = {};

  var mrCodedb;
  late String answersdb;
  get floatingActionButton => null;
  String? last_sync_date_time;

  get syncedNow => null;
  bool showSyncedSnackbar = false; // Add this variable
  String? subscriber_id;
  String? mr_id;


  // Future<String?> get last_sync_date_time async => await getLastSyncedTime();



  @override
  void initState() {


    super.initState();

    print('ietietueiueiueitueite ${DataSingleton().addDoctorBtn}');

   String doctorCode = Get.arguments?['doctorCode'] ?? '';
    String  doctorName = Get.arguments?['doctorName'] ?? '';

    print('@@## doctorCode Select '+doctorCode);
    print('@@## doctorName Select '+doctorName);

    WidgetsBinding.instance.addObserver(this);
    DataSingleton().questionAndAnswers = "";
    //Tanvir Dalal
    selectedDoctor=doctorName;
    selectedCode=doctorCode;


    sharedPrefsData();

    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper!.getAlldoctors();
    _databaseHelper!.getDoctors();
    getLastSyncedTime();

    //String last_sync_date_time= getLastSyncedTime() as String;




    // Check internet connectivity
    _networkHelper.checkInternetConnection();
    _subscription = _networkHelper.isOnline.listen((isOnline) {
      if (!isOnline) {
        fetchOffline();
      } else {

      }
    });

    loadDoctorNames();



    // Execute _fetchDoctors after 5 seconds
   Future<void>.delayed(const Duration(milliseconds: 1000), () async {

      await _fetchDoctors();
      await uploadJsonToS3();
    });
  }

  Future<void> sharedPrefsData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriber_id = prefs.getString('subscriber_id');
    mr_id = prefs.getString('mr_id');
    print('@@@@@@@@checkingmeiddd $mr_id');

  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if(state == AppLifecycleState.resumed){
      // user returned to our app

    }else if(state == AppLifecycleState.inactive){
      // app is inactive
    }else if(state == AppLifecycleState.paused){
      // user quit our app temporally
    }
  }

  Future<void> getLastSyncedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    last_sync_date_time = prefs.getString('lastSync');


  }



  void _enableSyncButton() {
    setState(() {
      isSyncButtonEnabled = true;
      showSyncedSnackbar = true; // Set the variable to true when the sync button is pressed
    });
  }

  Future<void> _syncData() async {
    if (!isSyncButtonEnabled) {
      return;
    }

    setState(() {
      isSyncButtonEnabled = false;
    });

    await _fetchDoctors();
    await uploadJsonToS3();


    Timer(const Duration(seconds: 5), _enableSyncButton);
   /* final prefs = await SharedPreferences.getInstance();
    String syncedNow="${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} IST";
    await prefs.setString('lastSync', syncedNow);*/
    //print('#####syncedNow from dsc: ${syncedNow}');
  }

  Future<void> fetchOffline() async {


    final List<Map<String, dynamic>> resourcesDataOffline =
    await _databaseHelper.getAllresources();

    if (resourcesDataOffline.isNotEmpty) {
      String divisionDetail = resourcesDataOffline[0]["division_detail"];
      Map<String, dynamic> responseJson = json.decode(divisionDetail);

      try {
        Map<String, dynamic> awsCreds = responseJson['data']['aws_creds'];
        DataSingleton().accessKeyId = awsCreds['AWS_ACCESS_KEY_ID'];
        DataSingleton().secretAccessKey = awsCreds['AWS_SECRET_ACCESS_KEY'];
        DataSingleton().bucket = awsCreds['AWS_BUCKET'];
        DataSingleton().bucketFolder = awsCreds['AWS_BUCKET_FOLDER'];

      } catch (e) {
       // print('Error accessing AWS credentials: $e');
      }
    } else {
     // print('No offline data available');
    }
  }

  Future<void> _fetchDoctors() async {

    final List<Map<String, dynamic>> doctorsData =
    await _databaseHelper.getAlldoctors();
    campsData = await _databaseHelper.getAllcamps();
    await _databaseHelper.getAllcamps();
    final List<Map<String, dynamic>> usersData =
    await _databaseHelper.getAllusers();

    final List<Map<String, dynamic>> getDoc =
    await _databaseHelper.getDoctors();
    print('amankaDoctorlist $getDoc');

    // print('jxfhdjfndjfnc $usersData');
    var campId = '';
    var doctorId;
    var doc_code = "";
   // final divisionId = prefs.getString('divisionid_string');
   // print('jnsfhsjnzxmzdnsd $divisionId');



      for (int i = 0; i < 1 && i < campsData.length; i++) {
         campId = campsData[i]['camp_id'];
         doctorId = campsData[i]['dr_id'];
         doc_code = campsData[i]['doc_code'];

        print('##Camp ID: $campId, Doctor ID: $doctorId, doc code: $doc_code');
      }

      String planDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      print('Today\'s Date: $planDate');
      DateTime planDateTime = DateTime.parse(planDate); // Convert String to DateTime


    //we will get doctor sc code and match with doctors list if mathes then will take it
    List<Map<String, dynamic>> resources = await _databaseHelper.getAllDivisiondetail();

    List<Map<String, dynamic>> allDoctors = []; // List to hold all doctors

    bool doctorFound = false; // To track if a match is found
    var finaldocId = '';

    for (var resource in resources) {
      if (resource.containsKey('division_detail') && resource['division_detail'] != null) {
        // Decode the division detail from JSON
        Map<String, dynamic> divisionDetail = json.decode(resource['division_detail']);

        // Access the list of doctors
        List<dynamic> doctorsList = divisionDetail['data']['user']['doctors'];

        // Add the doctors to allDoctors
        allDoctors.addAll(List<Map<String, dynamic>>.from(doctorsList));

        for (var doctor in doctorsList) {
          String scCode = doctor['sc_code'];
          if (doc_code == scCode) {
            doctorFound = true;
          print('&&&&Doctor Name: ${doctor['name']}');
          print('&&&&Doctor SC Code: ${doctor['sc_code']}');
          print('&&&&Doctor Mobile: ${doctor['mobile']}');
          print('&&&&Doctor Speciality: ${doctor['speciality']}');
          print('&&&&Doctor id: ${doctor['id']}');
          finaldocId = doctor['id'];
        }
          if (doctorFound) break;
        }


      } else {
        print('Division detail not available');
      }
    }


    // bool? camp_plan = prefs.getBool('camp_plan');
    if(DataSingleton().camp_plan == true && campId.isNotEmpty) {
        print('##isNotemptycampexeut');
        ExecuteCamp executeCamp = ExecuteCamp(
            doctorId: finaldocId, planDate: planDateTime, camp_id: campId);
         loginController.ExecuteCampPlan(context, DataSingleton().division_encoded!, executeCamp);
      }

    /////
    final List<Map<String, dynamic>> resourcesDataOffline =
    await _databaseHelper.getAllDivisiondetail();


    if (resourcesDataOffline.isNotEmpty) {
      String divisionDetail = resourcesDataOffline[0]["division_detail"];
      Map<String, dynamic> responseJson = json.decode(divisionDetail);


      try {
        Map<String, dynamic> awsCreds = responseJson['data']['aws_creds'];
        DataSingleton().accessKeyId = awsCreds['AWS_ACCESS_KEY_ID'];
        DataSingleton().secretAccessKey = awsCreds['AWS_SECRET_ACCESS_KEY'];
        DataSingleton().bucket = awsCreds['AWS_BUCKET'];
        DataSingleton().bucketFolder = awsCreds['AWS_BUCKET_FOLDER'];
      } catch (e) {
        print('Error accessing AWS credentials: $e');
      }
    } else {
      print('No offline data available');
    }
    /////////////



    if (campsData.isNotEmpty) {
      answersdb = campsData[0]['answers'];
    }

    if (usersData.isNotEmpty) {
      mrCodedb = usersData[0]['mr_code'];
      // subsid = usersData[0]['subscriber_id'];
      var subid = int.parse(usersData[0]['subscriber_id']); // Parse the string to an integer
      // print("vdjdgjdgdgjdg $subid");
      print("@@@@doctorSelection Mrcode $mrCodedb");
      print("@@@@doctorselection Subsid $subid");

      DataSingleton().mr_code = mrCodedb;
      DataSingleton().subscriber_id = subid;
      //
      // print("doctorselectionscreenSubscid ${DataSingleton().subscriber_id}");

      // print('divisonscreen mrcode offline ${DataSingleton().mr_code}');

    } else {
      print('No user data available.');
    }

    if ((campsData == null || campsData.isEmpty) && !showSyncedSnackbar) {
      print('No data available');
      return;
    }



    // Static device data
    final Map<String, dynamic> deviceData = {
      "appVersion":  DataSingleton().appversion.toString(),
      "dataType": "4G",
      "lastused": "",
      "mobileData": "False",
      "networkType": "5G",
      "signalStrength": "Poor",
      "simCountryId": "platformVersion",
      "simId": "mobileNumber",
      "totalDisk": "totalSpace",
      "totalRam": "totalRam",
      "usedDisk": "diskSpace",
      "usedRam": "usedRam",
      "wifi": "False",
      "device_serial_number":DataSingleton().device_serial_number,
      "device_brand": "deviceInfo+deviceInfo2",
      "device_os": "deviceInfo3",
      "channel": DataSingleton().device_serial_number==""?"App":"Device",
    };

    // Structure data array with nested "answers" field
    final List<Map<String, dynamic>> dataArray = [];
    for (final doctor in campsData) {
      final String answersString = doctor["answers"];
      List<Map<String, dynamic>> answersList;
      try {
        // Replace single quotes with double quotes and add double quotes around keys
        final formattedString = answersString
            .replaceAll("'", "\"")
            .replaceAll("question_id", "\"question_id\"")
            .replaceAll("score", "\"score\"")
            .replaceAll("answer", "\"answer\"")
            .replaceAll("child_id", "\"child_id\"")
            .replaceAllMapped(
            RegExp(r'"answer":\s*([^,}\]]+)', multiLine: true),
                (match) => '"answer": "${match.group(1)}"');

        // Decode the formatted string
        answersList =
        List<Map<String, dynamic>>.from(json.decode(formattedString));
      } catch (e) {
        print("Error decoding answersString: $e");
        answersList = [];
      }

      // answersList = answersList ?? [];

       // print('@@##Remove '+doctor["patient_meta"].replaceAll('/\/', ""));

      final Map<String, dynamic> doctorData = {
       /* "pat_age": doctor["pat_age"]==null:,
        "pat_gender": doctor["pat_gender"],
        "pat_email": doctor["pat_email"],
        "pat_mobile": doctor["pat_mobile"],
        "pat_name": doctor["pat_name"],*/
        "pat_id": doctor["pat_id"],
        "pat_consent": doctor["patient_consent"],
        "answers": answersList, // Add your answers data here
        "camp_id": doctor["camp_id"],
        "camp_date": doctor["camp_date"],
        "division_id": doctor["division_id"],
        "test_date": doctor["test_date"],
        "test_start_time": doctor["test_start_time"],
        "test_end_time": doctor["test_end_time"],
        "created_at": doctor["created_at"],
        "scale_id": doctor["scale_id"],
        "test_score": doctor["test_score"],
        "interpretation": doctor["interpretation"],
        "language": doctor["language"],
        "mr_code": doctor["mr_code"],
        "country_code": doctor["country_code"],
       /* "state_code": doctor["state_code"],
        "city_code": doctor["city_code"],
        "area_code": doctor["area_code"],*/
        "doc_consent": doctor["dr_consent"],
        "doc_code": doctor["doc_code"],
        "dr_id": doctor["dr_id"],
       /* "name": doctor["doc_name"],
        "speciality": doctor["doc_speciality"],*/
        "subscriber_id": doctor["subscriber_id"],
        "patient":doctor["patient_meta"].replaceAll('/\/', ""),
        "doctor":doctor["doctor_meta"]
        // ... other patient-related fields
      };

      dataArray.add(doctorData);
    }

    // Combine device and data into Fthe final result
    resultData = {
      "device": deviceData,
      "data": dataArray,
    };
    print('@@##result:$resultData');
  }

  Future<void> uploadJsonToS3() async {
    var connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection

        CustomSnackbar.showErrorSnackbar(
          title: 'No Internet',
          message: 'Please check your internet connection',
        );

      return;
    }

    if (campsData == null || campsData.isEmpty) {
      // Handle the case where campsData is null or empty
      print('No data uploaded');
      setState(() {
        if (showSyncedSnackbar){
          // uploadStatus =;
          CustomSnackbar.showErrorSnackbar(
            title: 'Already Done',
            message: 'Already Synced successfully.',
          );
        }

      });
      // You may show an error message or handle it as needed
      return;
    } else {
      final awsCreds = loginController.userLoginResponse?.data.awsCreds;
      final awsCredentials = AwsClientCredentials(
        accessKey: '${awsCreds?.accessKeyId ?? DataSingleton().accessKeyId}',
        secretKey:
        '${awsCreds?.secretAccessKey ?? DataSingleton().secretAccessKey}',
      );

      final s3 = S3(region: 'ap-south-1', credentials: awsCredentials);

      String? data_name =
      ("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}_${DataSingleton().division_id}_$mr_id")
          .toString();
      final bucketName = '${awsCreds?.bucket ?? DataSingleton().bucket}';
      var ok =
          '${awsCreds?.bucketFolder ?? DataSingleton().bucketFolder}/${data_name.toString()}.json';
      final objectKey = '$ok';
      try {
        final jsonData = resultData;
        // print('Structured Data11111: $jsonData');
        // print('Structured bucketName: $bucketName');
        // print('Structured objectKey: $objectKey');
        // print('Structured objectKey:' +jsonEncode(jsonData));
        // Convert JSON data to Uint8List
        final jsonDataBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(jsonData)));

        // Upload the JSON file to S3
        await s3.putObject(
          bucket: bucketName,
          key: objectKey,
          body: jsonDataBytes,
        );

        setState(()  {


          // uploadStatus =;
          CustomSnackbar.showErrorSnackbar(
            title: 'Success',
            message: 'Data sync successful.',
          );



          clearCampsTable();

          reloadPage();

        });
      } catch (e) {
        setState(() {
          // uploadStatus = ;
          CustomSnackbar.showErrorSnackbar(
            title: 'Error',
            message: 'sync error ',
          );
        });
      } finally {
        s3.close();
      }
    }
  }

  Future<void> clearCampsTable() async {
    await _databaseHelper.clearCampsTable();
    // print('Database cleared successfully');

    final prefs = await SharedPreferences.getInstance();
    String syncedNow="${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} IST";
    await prefs.setString('lastSync', syncedNow);
  }

  void loadDoctorNames() async {
    try {
      final doctors = await _databaseHelper?.getAlldoctors();

      List<Map<String, dynamic>> doctorInfoList = [];

      if (doctors != null) {
        doctorInfoList = doctors.map((doctor) {
          return {
            'doc_name': doctor['doc_name'] as String,
            'doc_code': doctor['doc_code'] as String,
            'dr_id': doctor['dr_id'] as String, // Assuming 'doc_id' is the key
          };
        }).toList();
      }

      // Populate doctorNames and doctorIdToNameMap
      setState(() {
        doctorNames = doctorInfoList
            .map((doctorInfo) =>
        '${doctorInfo['doc_name']}-${doctorInfo['doc_code']}' as String)
            .toList();
        doctorIdToNameMap = Map.fromIterable(doctorInfoList,
            key: (doctorInfo) => doctorInfo['dr_id'],
            value: (doctorInfo) =>
            '${doctorInfo['doc_name']}-${doctorInfo['doc_code']}');
        // print('@@##doctorNames:$doctorNames');
        // print('@@##doctorIdToNameMap:$doctorIdToNameMap');
      });
    } catch (e) {
      print('Error loading doctor names: $e');
    }
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
          Get.back();
        return false;
      },
      child:
      Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBarWithSync(
          title: 'Select a Doctor',
          showBackButton: true,
          onSync: _syncData,
         // destinationScreen: ScalesScreenList(),
          showKebabMenu: true,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return doctorNames
                          .where((String option) => option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()))
                          .toList();
                    },
                    onSelected: (String selected) async {
                      selectedDoctor = selected;

                    List<Map<String, dynamic>> resources = await _databaseHelper.getAllDivisiondetail();
                    Map<String, dynamic> screenDetail;
                    for (var resource in resources) {
                      if (resource.containsKey('scales_list') && resource['scales_list'] != null) {
                        screenDetail = json.decode(resource['scales_list']);

                        List<dynamic> metaList = [];
                        if (screenDetail.containsKey('data')) {
                          Map<String, dynamic> data = screenDetail['data'];
                          if (data.containsKey('meta')) {
                            metaList = data['meta'];

                            for (var meta in metaList) {
                              var key = meta['key'];
                              var value = meta['value'];

                              if (key == "TOP_LOGO_" + DataSingleton().scale_id.toString()) {
                                DataSingleton().top_logo = meta['value'];
                              }

                              if (key == "BOTTOM_LOGO_" + DataSingleton().scale_id.toString()) {
                                DataSingleton().bottom_logo = meta['value'];
                              }

                              if (key == "PRINT_QUESTIONS_" + DataSingleton().scale_id.toString()) {
                                DataSingleton().questionAndAnswers = meta['value'];
                              }

                              if (key == "DR_CONSENT") {
                                DataSingleton().drConsentAllowOrNot = meta['value'];
                              }

                              if (key == "END_CAMP_BTN") {
                                DataSingleton().EndCampBtn = meta['value'];
                              }
                            }
                          }
                        }
                      }
                    }
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                      child: TextFormField(
                        autofocus: false,
                        controller: textEditingController,
                        focusNode: focusNode,
                        onChanged: (String value) {
                          selectedDoctor = value;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ColorConstants.colorR8,
                          hintText: selectedDoctor?.isNotEmpty == true ? selectedDoctor : 'Select Doctor',
                          hintStyle: TextStyle(color: Colors.black, fontFamily: 'Quicksand', fontWeight: FontWeight.bold, fontSize: 16.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(color: ColorConstants.colorR11),
                          ),
                          contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.4)),
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down, // You can change this to the icon you want
                            color: Colors.grey, // You can change the color of the icon
                          ),
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Material(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Container(
                            height: 200,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: ColorConstants.kDropShadowColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children: options
                                  .map((String option) => ListTile(
                                title: Text(option),
                                onTap: () {
                                  onSelected(option);
                                },
                              ))
                                  .toList(),
                            ),
                          )),
                    );
                  },
                ),

                CustomElevatedButton(
                  onPressed: () async {
                    print('@@##'+selectedDoctor);

                    String selected_doc_id="";
                    if (selectedCode.isNotEmpty) {

                      final List<Map<String, dynamic>> doctorsData =
                      await _databaseHelper.getAlldoctorsByCode(selectedCode);

                      if (doctorsData != null) {
                        for (final doctor in doctorsData) {
                          if (doctor['doc_code'] == selectedCode) {
                            selected_doc_id=doctor['dr_id'];
                          }
                        }
                      }
                    }else{
                       selected_doc_id = doctorIdToNameMap.keys
                          .firstWhere(
                            (key) => doctorIdToNameMap[key] == selectedDoctor,
                        orElse: () {
                          Get.snackbar('Error', 'No Data Found!',
                              snackPosition: SnackPosition.BOTTOM);
                          throw Exception("No Data Found!");
                        },
                      );
                    }



                        if (selectedDoctor.isNotEmpty) {


                      print('@@##'+selected_doc_id);

                      int check_consent = await fetchDoctorDetails(selected_doc_id);
                      if (check_consent == 1) {
                        print('Here');
                        Get.off(PatientsDetailsScreen());
                      }
                    } else {
                      Get.snackbar('Error', 'Select a doctor first',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  horizontalPadding: 112,
                  text: 'Start Camp',
                  icon: Icon(Icons.play_arrow_outlined),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final displayBtn = DataSingleton().displayAddDoctorbtn;
                  final addBtn = DataSingleton().addDoctorBtn;

                  print('displayAddDoctorbtn: $displayBtn');
                  print('addDoctorBtn: $addBtn');

                  final shouldShow = displayBtn == true || (displayBtn == false && addBtn == true);

                  return shouldShow
                      ? Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomElevatedButton(
                        onPressed: () {
                          Get.to(DoctorDetailsScreen());
                        },
                        text: 'Add Doctor',
                        icon: Icon(Icons.add_circle_outline),
                        horizontalPadding: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                      : SizedBox.shrink();
                },
              ),
            ),




            Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                "Last Sync Time: $last_sync_date_time ",
                style: TextStyle(
                    fontFamily: 'Quicksand',
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    )
    );
  }


  void showUpdateDialog(String dr_id) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text('The Selected Doctor Has Not Given Any Consent',style: TextStyle(fontWeight: FontWeight.bold))),
          content: Text('Do you wish to change the consent to "Yes"',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                _databaseHelper.updateDoctorField(dr_id, "dr_consent", 1);
                CustomSnackbar.showErrorSnackbar(
                    title: "Consent Updated!!!",
                    message:
                    'Doctor Consent has been changed Updated to "YES"');
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Don't Update"),
            ),
          ],
        );
      },
    );
  }

  void reloadPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DoctorSelectionScreen()),
    );
  }


  Future<int> fetchDoctorDetails(String selectedDoctorName) async {


    try {
      final doctors = await _databaseHelper?.getAlldoctors();
      Map<String, dynamic>? selectedDoctor;
      String? doctor_meta;

      if (doctors != null) {
        for (final doctor in doctors) {
          if (doctor['dr_id'] == selectedDoctorName) {
            selectedDoctor = doctor;
            doctor_meta=doctor['doctor_meta'];
            // print('@@## '+doctor['doctor_meta']);
            break;
          }
        }
      }

      if (selectedDoctor != null) {
        // print('@@###drConsentAllowOrNot '+DataSingleton().drConsentAllowOrNot.toString());
        DataSingleton().doc_name = selectedDoctor['doc_name'];
      /*  DataSingleton().doc_speciality = selectedDoctor['doc_speciality'];
        DataSingleton().area_code = selectedDoctor["area_code"];
        DataSingleton().city_code = selectedDoctor["city_code"];
        DataSingleton().state_code = selectedDoctor["state_code"];*/
        DataSingleton().doc_code = selectedDoctor["doc_code"];
        DataSingleton().dr_consent = selectedDoctor["dr_consent"];
        DataSingleton().country_code = "IN";
        DataSingleton().dr_id = selectedDoctor["dr_id"];
        DataSingleton().doctor_meta = doctor_meta;
        if (selectedDoctor["dr_consent"] == 1 || DataSingleton().drConsentAllowOrNot!="True") {
          DataSingleton().doc_name = selectedDoctor['doc_name'];
          /*DataSingleton().doc_speciality = selectedDoctor['doc_speciality'];
          DataSingleton().area_code = selectedDoctor["area_code"];
          DataSingleton().city_code = selectedDoctor["city_code"];
          DataSingleton().state_code = selectedDoctor["state_code"];
         */ DataSingleton().doc_code = selectedDoctor["doc_code"];
          DataSingleton().dr_consent = selectedDoctor["dr_consent"];
          DataSingleton().country_code = "IN";
          DataSingleton().dr_id = selectedDoctor["dr_id"];
        } else {
          String dr_id_to_check = selectedDoctor["dr_id"];
          showUpdateDialog(dr_id_to_check);
          //CustomSnackbar.showErrorSnackbar(title: "Consent Error", message: "Doctor Has not given consent");
          return 0;
        }
        return 1;
      } else {
        print('Doctor not found.');
        return 0; // Add this line to explicitly return a value
      }
    } catch (e) {
      print('Error fetching doctor details: $e');
      return 0; // Add this line to explicitly return a value
    }
  }
}
