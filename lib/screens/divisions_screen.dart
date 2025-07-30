import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kribadostore/custom_widgets/customappbar1.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/models/CampPlanList.dart';
import 'package:kribadostore/models/FilterByDateCountResponse.dart';
import 'package:kribadostore/screens/camp_list_screen.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:install_plugin/install_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/screens/camp_report_screen.dart';
import 'package:kribadostore/screens/scales_screen_list.dart';
import 'package:kribadostore/screens/verify_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:url_launcher/url_launcher.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../Doctor.dart';
import '../NetworkHelper.dart';
import '../controllers/ThemeController.dart';
import '../controllers/login_controller.dart';
import '../models/user_login_response.dart';
import 'package:http/http.dart' as http;

class DivisionsScreen extends StatefulWidget {
  const DivisionsScreen({Key? key}) : super(key: key);

  @override
  State<DivisionsScreen> createState() => _DivisionsScreenState();
}

class _DivisionsScreenState extends State<DivisionsScreen> {
  ThemeController themeController = Get.put(ThemeController());
  LoginController loginController = Get.find<LoginController>();
  Color? primaryColor;
  Color? primaryTextColor;
  late DatabaseHelper _databaseHelper;
  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;

  // List<Division> divisionsoff = [];
  DateTime? lastPressedTime;

//comment

  bool camp_plan = false;



  List<Map<String, dynamic>> campsData = [];
  var mrCodedb;
  late String answersdb;
  Map<String, dynamic> resultData = {};

  late int divisionIdNumeric;
  late String doctorInfo;
  late Map<String, TextEditingController> controllers;
  late String encoded;
  late Map<String, String> errors;
  List<Map<String, dynamic>> fields = [];
  DataSingleton dataSingleton = DataSingleton();
  late Map<String, String> fields_doctor;
  late bool _loading;

  List<Doctors> doctorsMetaList = [];

  bool show_popup = true;
  String messaage = "Data Loading,Please Wait...";
  int camp_post=0;

  String? username = "";

  var divisionIdEncoded = '';
  // Controller_Refresh offlinedatacontrol  = Get.put(Controller_Refresh());
  @override
  void initState() {
    super.initState();
    _loading = false;
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper.initializeDatabase();



    _fetchDivisionsOffline();




    DataSingleton().status = true;
    DataSingleton().clearDoctor = false;

    DataSingleton().pat_name = '';

    doctorsMetaList = [];
    DataSingleton().questionAndAnswers = "";
    DataSingleton().qr_url = "";

    doctorsMetaList = [];
    _fetchDivisionsOffline();


    appUpdate();

    Future.delayed(const Duration(milliseconds: 8000), () {
      // Here you can write your code

      setState(() {
        // Here you can write your code for open new view
        messaage =
            "No internet connection,Please Connect to internet and Click on Try Again button.";
      });
    });

   // addDoctorsList();
  }

  void addDoctorsList() {
    fields_doctor = {};
    late Map<String, String> _doctor1;
    _doctor1 = {};
    for (Doctors doctor in doctorsMetaList) {
      _doctor1.addAll({
        "DOCTOR_NAME": doctor.name,
        "DOCTOR_CODE": doctor.scCode,
        "DOCTOR_PHONE": doctor.mobile.toString(),
        "DOCTOR_CITY": doctor.city.toString(),
        "DOCTOR_SPECIALITY": doctor.speciality,
      });

      String jsonstringmap = json.encode(_doctor1);

      DataSingleton().displayAddDoctorbtn = false;
      DataSingleton().clearDoctor = true;

      _insertDataIntoDatabase(doctor.scCode, doctor.name, doctor.speciality,
          doctor.divisionId, jsonstringmap);
    }
  }

  void _insertDataIntoDatabase(String doc_code, String doc_name,
      String speciality, int division_id, String jsonstringmap) async {

    // Generate unique doctorInfo string and encode it using MD5
    String doctorInfo = '${doc_code}'.toLowerCase().trim() +
        '${doc_name}'.toLowerCase().trim() +
        '${division_id}'.toString().toLowerCase().trim();

    String encoded = dataSingleton.generateMd5(doctorInfo).toString();

    // Check if the doctor exists

    // Check if the doctor already exists in the database
    int? doctorExists = await _databaseHelper?.doesDoctorExist('${encoded}');

    if (doctorExists == 1) {
      // If the doctor exists, update all fields
      try {
        await _databaseHelper.updateDoctorTable(
            encoded,                    // Use the same encoded ID as for insertion
            "INDIA",                    // country_code
            "",                         // state_code
            "",                         // city_code
            "",                         // area_code
            doc_code,                   // doc_code
            doc_name,                   // doc_name
            speciality,                 // doc_speciality
            division_id,                // division_id
            encoded,                    // dr_id
            1,                          // dr_consent (assumed consent as 1)
            jsonstringmap               // doctor_meta (the JSON string map)
        );
        print("#####Doctor updated successfully.");
      } catch (e) {
        print("Error updating doctor in database: $e");
      }
    } else {
      // If the doctor does not exist, insert a new doctor record
      try {
        await _databaseHelper?.insertDoctor(Doctor(
            country_code: "INDIA",
            state_code: "",
            city_code: "",
            area_code: "",
            doc_code: doc_code,
            doc_name: doc_name,
            doc_speciality: speciality,
            div_id: division_id,
            dr_id: encoded,
            dr_consent: 1,
            doctor_meta: jsonstringmap
        ));
        print("#####Database success Doctor inserted.");
      } catch (e) {
        print("Error inserting into database: $e");
      }
    }
  }
  Future<void> _fetchDivisionsOffline() async {


    final prefs = await SharedPreferences.getInstance();
    DataSingleton().device_serial_number= prefs.getString('device_serial_number');
     username = prefs.getString('name');

    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    await databaseHelper.initializeDatabase();
    List<Map<String, dynamic>> resources =
        await databaseHelper.getAllDivisiondetail();



    List<Map<String, dynamic>> allDoctors = []; // List to hold all doctors
      for (var resource in resources) {

        if (resource.containsKey('division_detail') &&
            resource['division_detail'] != null) {

          Map<String, dynamic> divisionDetail =
          json.decode(resource['division_detail']);


          print('vcvxvxvxvxvdadadadadad ${divisionDetail['data']}');


          Map<String, dynamic> scalesDetail = json.decode(resource['scales_list']);
          var divisionData = scalesDetail['data']['division'];

          divisionData.forEach((key, value) {
             divisionIdEncoded = value['id'];
            print('Division ID for key $key: $divisionIdEncoded');  // Prints id for each division (e.g., JvqVE4KY for key 15, etc.)
          });

          DateTime now = DateTime.now();
          String savedDateString = DateFormat('yyyy-MM-dd').format(now)+" 00:00:00.000";
          DateTime? startDateTime =  DateFormat("yyyy-MM-dd hh:mm:ss").parse(savedDateString);


          CampPlanList date = CampPlanList(
            from_date: startDateTime,
            to_date: startDateTime,
            prescriberType: 'all',
          );
          DataSingleton().division_encoded_Plan = divisionIdEncoded;


          loginController.CampPlanListData(context, divisionIdEncoded, date);


          List<Division> divisionsoff1 =
          (divisionDetail['data']['user']['divisions'] as List<dynamic>)
              .map((dynamic divisionData) => Division.fromJson(divisionData))
              .toList();



          for (int i=0; i<divisionsoff1[0].meta.length;i++) {

            print('djsdjskdjskdjcnzmnzmcnzcmus ${divisionsoff1[0].meta[i].key}');

            if (divisionsoff1[0].meta[i].key == "CAMP_PLAN" && divisionsoff1[0].meta[i].value == "True") {
              DataSingleton().camp_plan = true;
              DataSingleton().displayAddDoctorbtn = false;
              DataSingleton().clearDoctor = true;
              camp_post=i;
            }

            if(divisionsoff1[0].meta[i].key == "DR_CONSENT_TEXT") {
              DataSingleton().drConsentText =  divisionsoff1[0].meta[i].value;
            }

            if(divisionsoff1[0].meta[i].key == "DR_CONSENT_TEXT") {
              DataSingleton().ptConsentText =  divisionsoff1[0].meta[i].value;
            }

            if(divisionsoff1[0].meta[i].key == "CAMP_WITH_SENIOR") {
              DataSingleton().CampWithSeniorDropDown = "true";
            }


          }

          loginController.changeJobListData(divisionsoff1);

         // Access the list of doctors
          List<dynamic> doctorsList = divisionDetail['data']['user']['doctors'];
          fields_doctor = {};
          late Map<String, String> _doctor1;
          _doctor1 = {};
          // Add the doctors to allDoctors

          allDoctors.addAll(List<Map<String, dynamic>>.from(doctorsList));

          for (var doctor in doctorsList) {
            print('&&&&Doctor id: ${doctor['id']}');

            _doctor1.addAll({
              "DOCTOR_NAME": doctor['name'],
              "DOCTOR_CODE": doctor['sc_code'],
              "DOCTOR_PHONE": doctor['mobile'].toString(),
              "DOCTOR_CITY": doctor['city'].toString(),
              "DOCTOR_SPECIALITY": doctor['speciality'],
            });

            String jsonstringmap = json.encode(_doctor1);

            DataSingleton().displayAddDoctorbtn = false;
            DataSingleton().clearDoctor = true;

            _insertDataIntoDatabase(doctor['sc_code'], doctor['name'], doctor['speciality'],
                doctor['division_id'], jsonstringmap);

          }


        } else {
          print('Division detail not available');
        }




      }




    _networkHelper.checkInternetConnection();
    _subscription = _networkHelper.isOnline.listen((isOnline) async {
      if (isOnline) {
        loginController.autoLoginapi(context);
      }
    });


  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        DateTime currentTime = DateTime.now();
        // If lastPressedTime is null or more than 1 second ago, reset it.
        if (lastPressedTime == null ||
            currentTime.difference(lastPressedTime!) > Duration(seconds: 5)) {
          lastPressedTime = currentTime;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 5),
            ),
          );
          return false;
        }
        // If back button is pressed twice within 1 second, exit the app
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar1(
            title: "Home",
            showKebabMenu: true,
            showLogout: true,
            pageNavigationTime:
                "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
        body: Obx(() => loginController.divisionsoff.length > 0
            ? ListView.builder(
                itemCount: loginController.divisionsoff.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                    child: Column(
                      children: [

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '  Hello, ${username!.capitalize}',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),


                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              side:  BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 0,
                            color: Theme.of(context).primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      'Overall Camp Details',
                                      style: TextStyle(
                                        color: Colors.white, // White text color
                                        fontSize: 14.0, // Adjust font size
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Space between the title and stats
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatCard(
                                          'Total Camps',
                                          loginController.divisionsoff[index]
                                              .camp_count_total),
                                      _buildVerticalDivider(),
                                      // Divider between the stats
                                      _buildStatCard(
                                          'Total Patients',
                                          loginController.divisionsoff[index]
                                              .pat_count_total),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 5.0),
                          child: CustomElevatedButton(
                            onPressed: () {
                              Get.to(
                                CampReportScreen(),
                                arguments: {
                                  'divisionId': loginController.divisionsoff[index].divisionId,
                                  'scales': loginController.divisionsoff
                                },
                              );
                            },
                            text: 'View Camp Report',
                            icon: const Icon(Icons.library_books_outlined),
                            horizontalPadding: 82,
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0,0.0,20.0,5.0),
                          child: camp_post!=0 && loginController.divisionsoff[index].meta.isNotEmpty && loginController.divisionsoff[index].meta[camp_post].value== "True"?
                          CustomElevatedButton(
                            onPressed: () async {

                              Get.to(() => CampListScreen(), arguments: {
                                'divisionId': loginController.divisionsoff[index].divisionId,
                              });

                            },
                              text: 'Camp Planning',
                              icon: Icon(Icons.local_hospital_outlined),
                              horizontalPadding: 97,
                              backgroundColor: Theme.of(context).primaryColor,
                            ):Container()
                          ),



                        SizedBox(
                          height: 5,
                        ),
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 150.0,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.92,
                          ),
                          items: [
                            {
                              'title': '* Today',
                              'camp_count': loginController
                                  .divisionsoff[index].camp_count_today,
                              'pat_count': loginController
                                  .divisionsoff[index].pat_count_today,
                            },
                            {
                              'title': '* Yesterday',
                              'camp_count': loginController
                                  .divisionsoff[index].camp_count_yesterday,
                              'pat_count': loginController
                                  .divisionsoff[index].pat_count_yesterday,
                            },
                            {
                              'title': '* This Week',
                              'camp_count': loginController
                                  .divisionsoff[index].camp_count_this_week,
                              'pat_count': loginController
                                  .divisionsoff[index].pat_count_this_week,
                            },
                          ].map((camp) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      // Rounded corners
                                      border: Border.all(
                                        color: Colors
                                            .grey.shade300, // Border color
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // "Today" strip spanning full height
                                        Container(
                                          width: 40, // Adjust width as needed
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor, // Purple color
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(10.0),
                                              bottomLeft: Radius.circular(10.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Text(
                                                camp['title'] as String,
                                                style: const TextStyle(
                                                  fontFamily: 'Quicksand',
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 16.0,
                                                ),
                                                textAlign: TextAlign.left,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 1),
                                        // Camp count on the right side
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    _buildStatCard1(
                                                        'Camps',
                                                        camp['camp_count']
                                                            as int),
                                                    _buildVerticalDivider1(),
                                                    // Divider between the stats
                                                    _buildStatCard1(
                                                        'Patients',
                                                        camp['pat_count']
                                                            as int),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (loginController.divisionsoff[index].verified ==
                                null) {
                              Get.to(VerifyScreen(), arguments: {
                                'divisionId': loginController
                                    .divisionsoff[index].divisionId
                              });
                            } else {
                              _fetchDivisionsOffline();
                              if (loginController.divisionsoff.length > 0) {
                                DataSingleton().division_id = loginController
                                    .divisionsoff[index].divisionIdInt;
                                Get.to(
                                  ScalesScreenList(),
                                  arguments: {
                                    'divisionId': loginController
                                        .divisionsoff[index].divisionId,
                                    'subscriptionCode': loginController
                                        .divisionsoff[index].subscriptionCode,
                                    'division_id_numeric':
                                        loginController.divisionsoff[index].id,
                                  },
                                );
                              } else {
                                Get.snackbar('Please Wait',
                                    'Please wait data is loading....',
                                    snackPosition: SnackPosition.BOTTOM);
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20.0, 10.0, 20.0, 0.0),
                            child: Container(
                              decoration: ShapeDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  side: const BorderSide(
                                    color: ColorConstants.newGreenColor,
                                  ),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      // Center the content horizontally
                                      children: [
                                        Icon(
                                          Icons.play_arrow_outlined,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          " Start New Camp",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Quicksand',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(child: Text('* Note : Count will be updated in every 3 hours.',style: TextStyle(color: Colors.black,fontSize: 12),))
                          ],
                        )
                      ],
                    ),
                  );
                },
              )
            : Container(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: messaage == "Data Loading,Please Wait..."
                        ? Text(
                            messaage,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Quicksand',
                              color: Colors.black,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Image.asset('assets/no_nternet.png'),
                                ),
                                const SizedBox(height: 80),
                                const Text(
                                  'No Internet Connection',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No internet connection found. Check your \n connection and try again!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 50),
                                GestureDetector(
                                    onTap: () async {
                                      _networkHelper.checkInternetConnection();
                                      _subscription = _networkHelper.isOnline
                                          .listen((isOnline) async {
                                        if (isOnline) {
                                          loginController.autoLoginapi(context);
                                        } else {
                                          Get.snackbar('No internet', 'Check your connection and try again',
                                              snackPosition:
                                                  SnackPosition.BOTTOM);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: ShapeDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          side: const BorderSide(
                                            color: ColorConstants.newGreenColor,
                                          ),
                                        ),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              // Center the content horizontally
                                              children: [
                                                Icon(
                                                  Icons.play_arrow_outlined,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "Try Again",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Quicksand',
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                        ],
                                      ),
                                    ))
                              ],
                            ),
                          ),
                  ),
                ),
              )),
        bottomNavigationBar: Obx(() => loginController.divisionsoff.length >
                    0 &&
                loginController.divisionsoff[0].base64_logo != null &&
                loginController.divisionsoff[0].base64_logo.trim().isNotEmpty
            ? SizedBox(
                height: 140.0, // Set the height you want for your bottom bar
                width: 300, // Make sure it spans the full width of the screen
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: loginController.divisionsoff[0].base64_logo
                          .trim()
                          .isNotEmpty
                      ? Image.memory(const Base64Decoder().convert(
                          loginController.divisionsoff[0].base64_logo
                              .replaceAll("data:image/png;base64,", "")))
                      : const SizedBox(
                          height:
                              140.0, // Set the height you want for your bottom bar
                          width:
                              300, // Make sure it spans the full width of the screen
                        ),
                ),
              )
            : const SizedBox(
                height: 140.0, // Set the height you want for your bottom bar
                width: 300, // Make sure it spans the full width of the screen
              )),
      ),
    );
  }

// Helper method to build each stat card
  Widget _buildStatCard(String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white, // White text color
            fontSize: 30.0, // Larger font size for emphasis
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0), // Space between number and label
        Text(
          title, // Replaces spaces with new lines to force wrapping
          style: const TextStyle(
              color: Colors.white, // White text color
              fontSize: 14.0, // Adjust font size
              fontWeight: FontWeight.normal),
          textAlign: TextAlign.center, // Center-align the text
          overflow: TextOverflow
              .visible, // Show the full content without cutting it off
        ),
      ],
    );
  }

// Helper method to build vertical divider
  Widget _buildVerticalDivider() {
    return Container(
      height: 80.0,
      // Height of the divider
      width: 1.0,
      // Thickness of the divider
      color: Colors.white.withOpacity(0.6),
      // White color with some transparency
      margin: const EdgeInsets.symmetric(
          horizontal: 16.0), // Space around the divider
    );
  }

  Future<void> appUpdate() async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    await databaseHelper.initializeDatabase();
    List<Map<String, dynamic>> resources =
    await databaseHelper.getAllDivisiondetail();


    for (var resource in resources) {

      if (resource.containsKey('division_detail') &&
          resource['division_detail'] != null) {

        Map<String, dynamic> divisionDetail =
        json.decode(resource['division_detail']);


        Map<String, dynamic> apiVersion = divisionDetail['data']['app_version'];


        String androidVersion = apiVersion['android']['version_code'];
        String iosVersion = apiVersion['ios']['version_code'];


        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String appVersion = packageInfo.version;
        String checkPlatform = Platform.operatingSystem;
        print('checkkkkkkkkkkkk $checkPlatform');




        String platformType = Platform.isAndroid ? androidVersion : iosVersion;
        DataSingleton().appversion=checkPlatform+" "+appVersion.toString();
        print('#####platformtype $platformType');

        if (compareVersionCodes(appVersion, platformType) < 0) {
          showUpdateDialog(context, platformType);
        }

      } else {
        print('Division detail not available');
      }


      //  print('@@##**** ac '+divisionsoff.length.toString());
    }
  }


  int compareVersionCodes(String currentVersion, String apiVersion) {
    return currentVersion.compareTo(apiVersion);
  }


  void showUpdateDialog(BuildContext context, String newVersion) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dismissing by back button
          child: StatefulBuilder(
            builder: (context, setState) {
              // Use StatefulBuilder to update UI inside dialog
              return AlertDialog(
                title: const Text('New Version Available'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_loading)
                      Text(
                        'A new version ($newVersion) is available. Update now?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    else
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            backgroundColor: Colors.red,
                            strokeWidth: 8,
                          ),
                          SizedBox(height: 11),
                          Text(
                            "Downloading...",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      exit(0);
                    },
                    child: const Text('Exit'),
                  ),
                  if (!_loading)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                        });



           if(Platform.isAndroid){

                        // Call the update process here
             launchPlayStore();

           }else {
            lauchAppStore();
          
           }

                      },
                      child: const Text('Update'),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  Future<void> launchPlayStore() async {
    String packageName = 'com.indigitalit.kribadostore';
    String appStoreUrl = 'https://apps.apple.com/app/$packageName';
    String playStoreUrl =
        'https://play.google.com/store/apps/details?id=$packageName';


    if (await canLaunch(appStoreUrl) && !Platform.isAndroid) {
      await launch(appStoreUrl);
    } else if (await canLaunch(playStoreUrl) && Platform.isAndroid) {
      String? deviceName = await getDeviceName();


      if (["Alps Q1", "Alps JICAI Q1", "Q1", "JICAI Q2", "Z91"]
          .contains(deviceName)) {
        _downloadFileAndInstallApk(
          context,
          "app-release.apk",
          "https://s3.ap-south-1.amazonaws.com/kribado2.0/app-release.apk",
        );
      } else {
        await launch(playStoreUrl);
      }
    } else {
      throw 'Could not launch store';
    }
  }


  void launchPlayStore1() async {
    final Uri url = Uri.parse(
        'https://s3.ap-south-1.amazonaws.com/kribado2.0/app-release.apk');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }


  void lauchAppStore() async {
    final Uri url =
    Uri.parse('https://apps.apple.com/in/app/kribado/id6475755271');
    // await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $e');
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


  Future<void> _downloadFileAndInstallApk(
      BuildContext context, String fileName, String url) async {
    setState(() {
      _loading = true;
    });


    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }


      var installStatus = await Permission.requestInstallPackages.status;
      if (!installStatus.isGranted) {
        await Permission.requestInstallPackages.request();
      }
    }


    String downloadsPath = "/storage/emulated/0/Download/";
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String newFileName = '$fileName-$timestamp.apk';
    String filePath = '$downloadsPath$newFileName';


    try {
      var response = await http.get(Uri.parse(url));


      if (response.statusCode == 200) {
        File file = File(filePath);


        // Save the downloaded file to the custom download path
        await file.writeAsBytes(response.bodyBytes);


        // Print the file path
        print('File saved to: ${file.path}');


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File Downloaded Successfully'),
            duration: Duration(seconds: 2),
          ),
        );


        setState(() {
          _loading = false;
        });


        // Install the APK using the Install Plugin
     /*   await InstallPlugin.installApk(filePath).catchError((error) {
          print('Error installing APK: $error');


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error installing APK: $error'),
              duration: const Duration(seconds: 2),
            ),
          );
        }).then((_) async {
          // Delete the APK file after installation
          if (await file.exists()) {
            try {
              await file.delete();
              print('APK file deleted: $filePath');
            } catch (e) {
              print('Error deleting APK file: $e');
            }
          }
        });*/
      } else {
        setState(() {
          _loading = false;
        });


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to download file',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading file: $e');
      }


      setState(() {
        _loading = false;
      });


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file due to $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

}

//different color
// Helper method to build each stat card
Widget _buildStatCard1(String title, int count) {
  return Column(
    children: [
      Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.black, // White text color
          fontSize: 30.0, // Larger font size for emphasis
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4.0), // Space between number and label
      Text(
        title, // Replaces spaces with new lines to force wrapping
        style: const TextStyle(
            color: Colors.black, // White text color
            fontSize: 14.0, // Adjust font size
            fontWeight: FontWeight.normal),
        textAlign: TextAlign.center, // Center-align the text
        overflow: TextOverflow
            .visible, // Show the full content without cutting it off
      ),
    ],
  );
}

// Helper method to build vertical divider
Widget _buildVerticalDivider1() {
  return Container(
    height: 80.0, // Height of the divider
    width: 1.0, // Thickness of the divider
    color: Colors.black.withOpacity(0.6), // White color with some transparency
    margin: const EdgeInsets.symmetric(
        horizontal: 16.0), // Space around the divider
  );
}


String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
