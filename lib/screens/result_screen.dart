import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/custom_widgets/CustomButtonRow.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/helper/sharedpref_helper.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:kribadostore/screens/print/BluetoothPrinterService.dart';
import 'package:kribadostore/screens/patient_details_screen.dart';
import 'package:kribadostore/screens/print.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/services/s3upload.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:kribadostore/Resources.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../NetworkHelper.dart';
import '../controllers/login_controller.dart';
import '../custom_widgets/Score_Widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'BrandsPrescription_screen.dart';

class result_screen extends StatefulWidget {
  late var Test_Name,
      Scale_Name,
      Score,
      Interpretation,
      Patient_name,
      Patient_age,
      Patient_gender;

  result_screen(
      this.Test_Name,
      this.Scale_Name,
      this.Score,
      this.Interpretation,
      this.Patient_name,
      this.Patient_age,
      this.Patient_gender);

  @override
  State<result_screen> createState() => _result_screenState();
}

class _result_screenState extends State<result_screen> {
  final LoginController loginController = Get.find<LoginController>();

  DataSingleton dataSingleton = DataSingleton();

  late DatabaseHelper _databaseHelper;
  final S3Upload s3Upload = S3Upload();


  DateTime? lastPressedTime;
  img.Image? image;

  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;

  late String doctorName = '';

  late int currYear;

  late List<String> buttonLabels;

  late List<VoidCallback> buttonActions;

  var i_print_btn;

  int printcount = 0; // Track print count in the session

  var i_download_btn; // Variable to hold the doctor's name

  get data_name => null;

  get scale_id => DataSingleton().scale_id;
  late bool other_score = false;

  String print_btn = "False";
  String download_btn = "False";

  final BluetoothPrinterService printerService = BluetoothPrinterService();

  List<BluetoothInfo> items = [];

  bool _progress = false;
  String _msj = '';

  var firstquestion;

  var firstanswer;

  String? selectedDesignation;
  final List<String> designations = ["ABM", "RBM", "ZBM"];
  String campSenior = "";

  List<Map<String, dynamic>> campsData = [];

  var campidFromDb = '';

  var dridFromDb = '';


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

  @override
  void initState() {
    print('@@## call');
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper.initializeDatabase();
    _databaseHelper.getAlldoctors();
    fetchCampsData();
    campSenior =  DataSingleton().CampWithSeniorDropDown;
    getBluetoots();

    syncButtons();

    //fetchButtons();

    _insertOfflineData();

    fetchResources();
    fetchDoctors();

    setPrefforEndCamp();

    _networkHelper.checkInternetConnection();

    _subscription = _networkHelper.isOnline.listen((isOnline) {
      if (!isOnline) {
        print("No internet connection result screnn");
        //_fetchOfflineData();
      } else {
        print("Active internet result screen");
        print(
            'ddgsfsfsfscxcxcxcxcxc ${DataSingleton().userLoginOffline.toString()}');
      }
    });

    print('useroffline resultr ${DataSingleton().userLoginOffline.toString()}');

    if (scale_id.contains("WOMAC.kribado")) {
      other_score = true;
      print('@@##scale id_result screen:$scale_id');
    }

    // s3Service();

    super.initState();
  }


  Future<void> fetchCampsData() async {
    campsData = await _databaseHelper.getAllcamps();
    // print('campssdatas33333uploaddd $campsData');
    for (final doctor in campsData) {
       campidFromDb = doctor['camp_id'];
       dridFromDb = doctor['dr_id'];
      // print('fhsfshfkshjsfhwujjs $campidFromDb  $dridFromDb');
    }
  }


  Future<void> s3Service() async {
    await s3Upload.initializeAndFetchDivisionDetails();
    await s3Upload.uploadJsonToS3();
    // await s3Upload.clearCampsTable();

    // Use the fetched division details here
  }


  Future<void> setPrefforEndCamp() async {
    String campid = dataSingleton
        .generateMd5(
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}_${DataSingleton().division_id}_${DataSingleton().subscriber_id}")
        .toString();

    //doctorInfo =dataSingleton.generateMd5('${doc_name}${doc_code}${divisionIdNumeric}').toString();
    int divisionIdNumeric = DataSingleton().division_id.toInt();
    String? doc_name = DataSingleton().doc_name?.trim().toLowerCase();
    String? doc_code = DataSingleton().doc_code?.trim().toLowerCase();
    int divison_id = DataSingleton().division_id;

    String doctorInfo = dataSingleton.generateMd5(
        '$doc_code'.toLowerCase().trim() +
            '$doc_name'.toLowerCase().trim() +
            '$divisionIdNumeric'.toLowerCase().trim());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('campid', campid);
    await prefs.setString('doctorInfo', doctorInfo);
    await prefs.setInt('divisonid', divison_id);
  }

  Future<void> fetchButtons() async {
    List<Map<String, dynamic>> themes = await _databaseHelper!.getButtons();
    // print('thjemrr: $themes');

    String print_btn = "";
    String download_btn = "";
    String download_print_btn = "";

    i_print_btn = themes[0]["print_btn"];
    i_download_btn = themes[0]["download_btn"];
    String i_download_print_btn = themes[0]["print_download_btn"];

    //DataSingleton().print_btn = i_print_btn;
    //DataSingleton().download_btn = i_download_btn;
    //DataSingleton().download_print_btn = i_download_print_btn;
  }

  Future<void> fetchDoctors() async {
    final List<Map<String, dynamic>> doctors =
        await _databaseHelper.getAlldoctors();

    print(' docotrs result screen  $doctors');

    if (doctors.isNotEmpty) {
      String docName = doctors.first[
          'doc_name']; // Extracting doc_name property from the first doctor
      // print('Doctor Name: $docName');

      // Update the doctorName variable with the fetched doctor's name
      setState(() {
        doctorName = docName;
      });
    }
  }

  Future<void> fetchResources() async {


    List<dynamic> inputsScale = DataSingleton().inputs;
    print('@@@@@@@@questionsprint $inputsScale');

    List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;
    print('@@@@@@@@answersprint $questions');

    firstquestion = inputsScale[0]['title'];
    print('ijfsifjsijxcikz $firstquestion');

    firstanswer = questions[0]['answer'];
    print('vjvjvnvjjnxvnvjv $firstanswer');


    final List<Map<String, dynamic>> resourcesDataOffline =
        await _databaseHelper.getAllresources();

    // print('result screen  $resourcesDataOffline');

    if (resourcesDataOffline.isNotEmpty) {
      // Assuming "division_detail" is stored as a String in the database
      String scalesList = resourcesDataOffline[0]["scales_list"];

      // print('scalesList result $scalesList');

      Map<String, dynamic> jsonData = jsonDecode(scalesList);

      String disclaimer = jsonData['data']['meta'].firstWhere(
          (meta) => meta['key'] == 'DISCLAIMER',
          orElse: () => {'value': 'No Disclaimer'})['value'];

      // print('Disclaimer: $disclaimer');

      //  DataSingleton().Disclaimer = disclaimer;

      String scalesList1 = resourcesDataOffline[0]["division_detail"];
      Map<String, dynamic> jsonData1 = jsonDecode(scalesList1);

      Map<String, dynamic> userData = jsonData1['data']['user'];
      int mrid = userData['mr_id'];
      // print('jdnsfnjsfnsfj  $mrid');

      // DataSingleton().subscriber_id = mrid;
    } else {
      print('No Discalimer available');
    }
  }

  Future<void> _insertOfflineData() async {
    // Check if any of the required data is null
    if (DataSingleton().division_id == null ||
        DataSingleton().userLoginOffline == null ||
        DataSingleton().divisionDetailOffline == null ||
        DataSingleton().s3jsonOffline == null) {
      // print("One or more required values are null. Skipping database insertion.");

      // Print the values to identify which one is null
      // print("division_id: ${DataSingleton().division_id}");
      // print("userLoginOffline: ${DataSingleton().userLoginOffline}");
      // print("divisionDetailOffline: ${DataSingleton().divisionDetailOffline}");
      // print("s3jsonOffline: ${DataSingleton().s3jsonOffline}");

      return;
    }

    // Check if any of the required data is empty
    if (DataSingleton().division_id.toString().isEmpty ||
        DataSingleton().userLoginOffline.toString().isEmpty ||
        DataSingleton().divisionDetailOffline.toString().isEmpty ||
        DataSingleton().s3jsonOffline.toString().isEmpty) {
      print(
          "One or more required values are empty. Skipping database insertion.");
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

  Future<void> syncButtons() async {
    // print('@@##&&   Call here');
    // print("@@##&&  ${DataSingleton().print_btn}");
    // print("@@##&&   ${DataSingleton().download_btn}");
    // print("sjfhdjgnsjxncjxcnxmnsjjss ${DataSingleton().Disclaimer}");

    buttonLabels = ['New Patient', 'Print']; // Include 'Print' by default
    buttonActions = [
      () {
        Get.off(const PatientsDetailsScreen());
      },
      () async {
        String? mac = await SharedprefHelper.getUserData("printer");
        if (mac != null && mac.isNotEmpty) {
          Get.to(PrintScreen(
            automaticprint: true,
          ));
        } else {
          Get.to(PrintScreen(
            automaticprint: false,
          ));
        }
      }
    ];

    if (DataSingleton().print_btn.toString() == "True") {
      buttonLabels.add('Print');
    }

    // Check if print_btn is "False", then remove 'Print' button
    if (DataSingleton().print_btn.toString() == "False") {
      buttonLabels.remove('Print');
      buttonActions.removeAt(1); // Remove corresponding action
    }

    if (DataSingleton().download_btn.toString() == "True") {
      buttonLabels.add('Download');
      buttonActions.add(() {
        _printScreen();
        Fluttertoast.showToast(
          msg: "Download...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
      });
    }

    // if (DataSingleton().EndCampBtn.toString() == "False") {
    //   buttonLabels.remove('End Camp');
    //   buttonActions.removeAt(3); // Remove corresponding action
    // }

    if (DataSingleton().EndCampBtn.toString() == "True") {
      buttonLabels.add('End Camp');
      buttonActions.add(() {
        Get.to(const BrandsPrescription());
      });
    }

    // // Check if print_btn is "False", then remove 'Print' button
    // if (DataSingleton().download_btn == "False") {
    //   buttonLabels.remove('Download');
    //   buttonActions.removeAt(2); // Remove corresponding action
    // }

    // print("####buttonlabels $buttonLabels");
  }

  @override
  Widget build(BuildContext context) {
    DateTime nowDate = DateTime.now();
    currYear = nowDate.year;
    currYear = nowDate.year;

    bool CalculatedRisk = false;
    bool FssgLabelRegional = false;
    // print("printbtnstatus ${DataSingleton().print_btn}");
    // print("download_btnbtnstatus ${DataSingleton().download_btn}");
    if (DataSingleton().scale_id == "FSSG.Nepali.Regional.kribado" || DataSingleton().scale_id == "FSSG.Bangladesh.kribado") {
      FssgLabelRegional = true;
    }

    if (DataSingleton().scale_id == "ASCVD.risk.kribado" ||
        DataSingleton().scale_id == "ASCVD.risk.estimator.kribado") {
      // print("Inside ASCVD.risk.kribado condition");
      // print("widget.Score before appending: ${widget.Score}");

      // Ensure widget.Score is a string
      DataSingleton().Score = "${widget.Score} %";
      // print("DataSingleton().Score after appending: ${DataSingleton().Score}");

      DataSingleton().Scale_Name = "10 Year ${widget.Scale_Name}";
      // print("DataSingleton().Scale_Name: ${DataSingleton().Scale_Name}");

      CalculatedRisk = true;

      // print("ascvvvvvvvvdzzzz");
    } else {
      // print("Inside else condition");
      // print("widget.Score: ${widget.Score}");

      DataSingleton().Score = widget.Score;
      DataSingleton().Scale_Name = widget.Scale_Name;

      // print("DataSingleton().Score: ${DataSingleton().Score}");

      // print("ascvvdddddddasasasasasasvvvvvvd");
    }

    DataSingleton().Test_Name = widget.Test_Name;
    // DataSingleton().Score = widget.Score;
    DataSingleton().Interpretation = widget.Interpretation;
    DataSingleton().Patient_name = widget.Patient_name;
    DataSingleton().Patient_age = widget.Patient_age;
    DataSingleton().Patient_gender = widget.Patient_gender;

    // late String Test_Name, Scale_Name, Score, Interpretation,Patient_name,Patient_age,Patient_gender;

    return WillPopScope(
      onWillPop: () async {
        // Handle back button pressDataSingleton().division_id
        // For example, navigate to a specific screen
        Get.off(const PatientsDetailsScreen());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: widget.Test_Name,showKebabMenu: true,showHome: true,showSwitchPrinter: true,showLogout: true,destinationScreen:PatientsDetailsScreen(),showBackButton:true,pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: ShapeDecoration(
                        color: ColorConstants.colorR1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(
                                color: ColorConstants.colorR1))),
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor Name : ${(DataSingleton().doc_name ?? doctorName).substring(0, 1).toUpperCase()}${(DataSingleton().doc_name ?? doctorName).substring(1)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            'Patient Information ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            textAlign: TextAlign.start,
                          ),
                          if (widget.Patient_name != null &&
                              widget.Patient_name!.isNotEmpty)
                            Text(
                              'Patient Name : ${widget.Patient_name.substring(0, 1).toUpperCase()}${widget.Patient_name.substring(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              Text(
                                'Age : ${widget.Patient_age}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Text(
                                'Gender : ${widget.Patient_gender.substring(0, 1).toUpperCase()}${widget.Patient_gender.substring(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    // color:Theme.of(context).primaryColor,
                    decoration: ShapeDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        )),
                    margin: const EdgeInsets.all(10),

                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            scale_id == "FRAX.osteocalc.kribado" ?   Text("${DataSingleton().fraxHeader}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Quicksand',
                                  fontSize: 20,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                )) : Text("Score",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Quicksand',
                                  fontSize: 20,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                )),
                            const SizedBox(
                              height: 10,
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: scale_id == "FRAX.osteocalc.kribado" ?   ScoreWidget(
                                    score: "${DataSingleton().fraxBmiRound}") :  ScoreWidget(
                                    score: "${DataSingleton().Score}"),
                              ),
                            ),

                            Visibility(
                              visible: other_score,
                              child: Center(
                                child: Text(
                                  ' out of 96',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            const SizedBox(height: 2),

                            Visibility(
                              visible: other_score,
                              child: Center(
                                child: Text(
                                  'Pain Score: ${DataSingleton().score1to5} out of 20',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Visibility(
                              visible: other_score,
                              child: Center(
                                child: Text(
                                  ' Stiffness Score: ${DataSingleton().score6and7} out of 8',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Visibility(
                              visible: other_score,
                              child: Center(
                                child: Text(
                                  ' Physical Functional Difficulty Score: ${DataSingleton().scoreBeyond7} out of 68',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // Text(
                            //   widget.Test_Name,
                            //   style: const TextStyle(
                            //     fontSize: 18,
                            //     color: Colors.green,
                            //   ),
                            // ),
                            const SizedBox(height: 2),
                            Visibility(
                              visible: FssgLabelRegional,
                              child: Center(
                                child: Column(
                                  children: [
                                    Text(
                                        'Acid Reflux Score: ${DataSingleton().reflux_score_only}'),
                                    Text(
                                        'Dyspeptic Symptom Score: ${DataSingleton().dyspeptic_score_only}'
                                        '\n'),
                                  ],
                                ),
                              ),
                            ),
                            Visibility(
                              visible: CalculatedRisk,
                              child: Center(
                                child: Text(
                                  '(Calculated Risk)',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            if (DataSingleton().option_selected_logo != null && DataSingleton().option_selected_logo!.isNotEmpty) ...[
                              Center(
                                child: Image.memory(
                                  base64Decode("${DataSingleton().option_selected_logo}"),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],


                            Center(
                              child: Text(
                                widget.Interpretation,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Add patient information
                            const SizedBox(height: 10),

                            scale_id == "ASCVD.Custom.kribado" || scale_id == "HbA1c.kribado" ?
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center, // Centers the row's children horizontally
                                    children: [
                                      // First Text
                                      Text(
                                        '$firstquestion',
                                        style: TextStyle(
                                          fontSize: 15,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                SizedBox(width: 10), // Optional spacing between the two Text widgets
                                      // Second Text
                                      Text(
                                        '${DataSingleton().hbA1c}', // Replace with your second text variable
                                        style: TextStyle(
                                          fontSize: 15,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                            ): Container()



                          ],
                        ),
                      ),
                    ),
                  ),
                  CustomButtonRow(
                    buttonVisibility: [
                      "true", // Assuming Datasingelton().home returns a string "true" or "false"
                      DataSingleton().print_btn.toLowerCase().trim(),
                      DataSingleton().download_btn.toLowerCase().trim(),
                      DataSingleton().EndCampBtn.toLowerCase().trim(),
                    ],
                    buttonActions: [
                      () => Get.off(
                          const PatientsDetailsScreen()), // Action 1: Navigate to PatientsDetailsScreen

                      // Declare printcount outside the function if you want to persist it across calls.

                      () async {
                        String? deviceName = await getDeviceName();

                        if (kDebugMode) {
                          print("Device name: $deviceName");
                        }

                        print("Print Count $printcount");

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

                          if (items.isEmpty) {
                            await getBluetoots();
                          }

                          String? bluetoothmac =
                              await SharedprefHelper.getUserData("printer");

                          if (bluetoothmac == null || bluetoothmac.isEmpty) {
                            String printerType = deviceName == "Z91"
                                ? "bluetoothprint"
                                : "iposprinter";
                            await handlePrinterSelection(context, printerType);
                          } else {
                            await handlePrinterConnection(
                                context, bluetoothmac);
                          }
                        } else {
                          String? mac =
                              await SharedprefHelper.getUserData("printer");
                          Get.to(PrintScreen(
                              automaticprint: mac != null && mac.isNotEmpty));
                        }
                      },

                      // Action 2: Printer handling based on device name

                      () {
                        try {
                          PdfComponents pdfComponents = PdfComponents();
                          pdfComponents.downloadPdf(
                              context,
                              widget.Score.toString(),
                              widget.Interpretation.toString());
                        } catch (e) {
                          print("Getting $e while performing pdf operation");
                        }
                      }, // Action 3: Placeholder for another action (printing screen)

                      () => Get.to(
                          const BrandsPrescription()), // Action 4: Navigate to BrandsPrescription
                    ],
                    buttonColors: const [
                      ColorConstants.colorR2,
                      ColorConstants.colorR3,
                      ColorConstants.colorR4,
                      ColorConstants.colorR5
                    ],
                  ),
                  campSenior == "false"  ?  SizedBox.shrink() : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDesignation,
                          hint: Text("Camp with Senior", style: TextStyle(color: Colors.grey[600])),
                          items: designations.map((String designation) {
                            return DropdownMenuItem<String>(
                              value: designation,
                              child: Text(designation, style: TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDesignation = newValue;
                              loginController.SendCampWithSenior(context,campidFromDb,dridFromDb ,'$selectedDesignation');
                            });
                          },
                          isExpanded: true, // Ensures dropdown expands properly
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black54), // Custom dropdown icon
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (DataSingleton().References != null &&
                            DataSingleton().References!.isNotEmpty) ...[
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            'Reference :',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              DataSingleton().References!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: ColorConstants.colorR7,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 30), // Add more spacing between sections
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '© $currYear Indigital Technologies LLP',
                              style: const TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  void _printScreen() async {
    final disclaimer = DataSingleton().Disclaimer ??
        'This is a customized service by Indigital Technologies LLP...';
    final Directory? directory;
    final ByteData fontData =
        await rootBundle.load('fonts/Quicksand-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Define base64 string for the image (for demo purposes)
    String? base64String =
        DataSingleton().bottom_logo?.replaceAll("data:image/png;base64,", "");


    String? base64StringTopLogo =
    DataSingleton().top_logo?.replaceAll("data:image/png;base64,", "");

    print('@@@@@@pdftoplogo $base64StringTopLogo');

    // print('ugjfjfsjsfjsfxnxxnjdgnjeg $base64String');

    // print('widgetscalename ${widget.Test_Name}');
    // print('widgetscaleid ${DataSingleton().scale_id}');
    // print('widgetScaleNAme ${DataSingleton().Scale_Name}');

    // Convert base64 string to Uint8List (bytes)
    Uint8List? imageBytes =
        base64String != null ? base64Decode(base64String) : null;


    // Convert base64 string to Uint8List (bytes) - its for top logo
    Uint8List? imageBytesTopLogo =
        base64StringTopLogo != null ? base64Decode(base64StringTopLogo) : null;


    //setting up optionselectedLogo
    String? base64String1 = DataSingleton().option_selected_logo?.replaceAll("data:image/png;base64,", "");
    Uint8List? imageBytes1 = base64String1 != null ? base64Decode(base64String1) : null;

    if(DataSingleton().option_selected_logo !=null){

      String base64String1 = DataSingleton().option_selected_logo?.replaceAll(
                "data:image/png;base64,",
                "",
              ) ??
          "";
      Uint8List bytesImg = base64.decode(base64String1);

      imageBytes1 =bytesImg;
    }

    String? pName = (widget.Patient_name != null &&
            widget.Patient_name.isNotEmpty)
        ? "Name : ${widget.Patient_name[0].toUpperCase()}${widget.Patient_name.substring(1)}"
        : '';


    print('@@disclaimer $disclaimer');

    try {
      final doc = pw.Document();
      int itemsPerPage = 10; // You can adjust this value based on content size

      // Add Doctor and Patient Information on the first page
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

                  if (imageBytesTopLogo != null)
                    if (imageBytesTopLogo != null && imageBytesTopLogo.isNotEmpty)
                      pw.Center(
                    child: pw.Image(pw.MemoryImage(imageBytesTopLogo!),
                        fit: pw.BoxFit.contain,width: 300,height: 300),
                            ),

                  pw.SizedBox(height: 30),

                  pw.Text(
                    "Doctor Information",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                        fontSize: 25),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Name : ${DataSingleton().doc_name != null && DataSingleton().doc_name!.isNotEmpty ? '${DataSingleton().doc_name?[0].toUpperCase()}${DataSingleton().doc_name?.substring(1)}' : ''}",
                    style: pw.TextStyle(font: ttf, fontSize: 20),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "Patient Information",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                        fontSize: 25),
                  ),
                  pw.SizedBox(height: 5),
                  if (pName != null)
                    pw.Text(
                      pName,
                      style: pw.TextStyle(font: ttf, fontSize: 20),
                    ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Age : ${widget.Patient_age}",
                    style: pw.TextStyle(font: ttf, fontSize: 20),
                  ),
                  pw.Text(
                    "Gender : ${widget.Patient_gender != null && widget.Patient_gender.isNotEmpty ? '${widget.Patient_gender[0].toUpperCase()}${widget.Patient_gender.substring(1)}' : ''}",
                    style: pw.TextStyle(font: ttf, fontSize: 20),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "${widget.Scale_Name} ",
                    style: pw.TextStyle(font: ttf, fontSize: 25),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Your total score is : ${widget.Score} ",
                    style: pw.TextStyle(
                        font: ttf,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 25),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Interpretation : ${widget.Interpretation} ",
                    style: pw.TextStyle(font: ttf, fontSize: 25),
                  ),
                  pw.SizedBox(height: 30),
                  if(scale_id =="TNSS.kribado")
                    pw.Text(
                      '''
• None = 0 : You have no nasal symptoms, indicating good nasal health.
• If your score is less than 6 : Your nasal symptoms are considered mild. It is advisable to monitor
your symptoms and consult your doctor if they persist or worsen.
• If your score is between 6 and 9 : Your nasal symptoms are considered moderate. Consulting
your doctor for possible treatments could help manage your symptoms more effectively.
• If your score is greater than 9 : Your nasal symptoms are considered severe. It is recommended
to consult your doctor for a thorough evaluation and potential treatment options to improve
your quality of life.
                       ''',
                      style: pw.TextStyle(font: ttf, fontSize: 18),
                    ),
                  pw.SizedBox(height: 20),
                  if (DataSingleton().option_selected_logo != null)
                    if (imageBytes1 != null && imageBytes1.isNotEmpty)
                      pw.Center(
                        child: pw.Image(pw.MemoryImage(imageBytes1),
                            fit: pw.BoxFit.contain,width: 300,height: 300),
                      ),
                ],
              ),
            ),
          ],
        ),
      );

      if (DataSingleton().questionAndAnswers == "True") {
        List<dynamic> inputsScale = DataSingleton().inputs;

        print('childQuestionsss ${DataSingleton().childQuestion}');
        print('childGroupvalue ${DataSingleton().childGroupValue}');


        // Create a map of question_id to title
        Map<int, String> questionTitleMap = {};
        for (var input in inputsScale) {
          questionTitleMap[input['id']] = input['title'];
        }

        List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;
        List<Map<String, dynamic>> transformedResponses = [];

        if(DataSingleton().childQuestion !=null && DataSingleton().childQuestion!.isNotEmpty){
          print('childquestionisthere');

          // First, add the main questions to transformedResponses
          for (var response in questions) {
            int questionId = response['question_id'];
            String? title = questionTitleMap[questionId];
            transformedResponses.add({
              'title': title,
              'score': response['score'],
              'answer': response['answer']
            });
          }

          // Change only the title of the second object if it exists
          if (transformedResponses.length > 1) {
            transformedResponses[1]['title'] = DataSingleton().childQuestion;
          }

          DataSingleton().tranformedRepsonsesParentChild = transformedResponses;



          print('transformedformatifffff $transformedResponses');

          int questionNumber = 1;

          doc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) => [
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Using pw.Wrap for dynamic content layout
                      pw.Wrap(
                        children: transformedResponses.map((question) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Q ${questionNumber}: ${question['title']}", // Add question number
                                style: pw.TextStyle(font: ttf, fontSize: 20),
                              ),
                              pw.Text(
                                "A: ${question['answer']}",
                                style: pw.TextStyle(font: ttf, fontSize: 20),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );



        } else {
          for (var response in questions) {
            int questionId = response['question_id'];
            String? title = questionTitleMap[questionId];
            transformedResponses.add({
              'title': title ,
              'score': response['score'],
              'answer': response['answer']
            });
          }

          print('transformedformat $transformedResponses');

          int questionNumber = 1;

          doc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) => [
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Using pw.Wrap for dynamic content layout
                      pw.Wrap(
                        children: transformedResponses.map((question) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Q ${questionNumber++}: ${question['title']}", // Add question number
                                style: pw.TextStyle(font: ttf, fontSize: 20),
                              ),
                              pw.Text(
                                "A: ${question['answer']}",
                                style: pw.TextStyle(font: ttf, fontSize: 20),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

        }




      }





      if (DataSingleton().scale_id == "AllergicRhinitisCustom.kribado") {
        List<dynamic> inputsScale = DataSingleton().inputs;

        // Create a map of question_id to title
        Map<int, String> questionTitleMap = {};
        for (var input in inputsScale) {
          questionTitleMap[input['id']] = input['title'];
        }

        List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;
        List<Map<String, dynamic>> transformedResponses = [];
        for (var response in questions) {
          int questionId = response['question_id'];
          String? title = questionTitleMap[questionId];
          transformedResponses.add({
            'title': title,
            'score': response['score'],
            'answer': response['answer']
          });
        }

        // Replace specific options with corresponding statements for questions from 11th onward
        List<Map<String, dynamic>> filteredResponses = transformedResponses;

        // Define the option to statement mapping
        Map<String, String> optionStatementMap = {
          "Suburban":
              "Suburban areas might offer a balance between urban pollution and green spaces. However, depending on proximity to highways or industrial zones, symptoms could be influenced by pollution levels. Seasonal changes in pollen counts can also impact symptoms.",
          "Village":
              "Living in a rural or village setting often exposes individuals to a variety of allergens like pollen, dust, and agricultural chemicals. Such environments may lead to increased respiratory symptoms, particularly if you are sensitive to outdoor allergens or pollutants.",
          "Urban":
              "Urban settings typically expose individuals to higher levels of pollution, including vehicle emissions and industrial pollutants. These can aggravate symptoms, especially in people with pre-existing respiratory conditions. Urban dwellers may experience more consistent symptoms due to ongoing exposure to environmental irritants.",
          "Winter":
              "In winter, symptoms may worsen due to cold air, increased indoor heating, and reduced ventilation, which can concentrate indoor allergens like dust mites. People sensitive to cold or indoor allergens may notice an increase in respiratory or allergic symptoms during this season.",
          "Summer":
              "Summer often brings high pollen counts, which can trigger allergies and worsen respiratory conditions. Heat and humidity can also exacerbate symptoms in individuals sensitive to these factors.",
          "Rainy":
              "Rainy seasons may increase mold growth and dampness, leading to higher exposure to mold spores and damp environments. This can worsen symptoms, particularly for individuals with mold allergies or asthma.",
          "Every Morning":
              "Morning symptoms could be due to overnight accumulation of indoor allergens such as dust mites or poor air quality due to closed windows. These symptoms may also relate to the body natural cortisol rhythm, which is lower in the morning, potentially worsening inflammation.",
          "Mid-day":
              "Mid-day symptoms may be associated with outdoor activities and exposure to allergens like pollen or pollution. The body exposure to allergens during the day can lead to a peak in symptoms.",
          "Late Evening":
              "Evening symptoms may arise from a combination of daily exposure to allergens and the body circadian rhythm. Fatigue and reduced activity in the evening might also make symptoms more noticeable.",
          "Mid Night":
              "Midnight symptoms can be particularly troubling and might be related to lying down, which can exacerbate respiratory conditions like asthma. Indoor allergens like dust mites in bedding or the concentration of allergens in poorly ventilated rooms could contribute to these symptoms.",
          "Market Place/Street Vendor":
              "Working in open markets exposes individuals to various pollutants, including dust, vehicle emissions, and possibly agricultural products. Such environments can exacerbate symptoms, particularly for those sensitive to outdoor allergens or pollutants.",
          "Agriculture":
              "Agricultural work often involves exposure to dust, pollen, pesticides, and other airborne particles. These can significantly aggravate symptoms, especially respiratory or skin-related conditions.",
          "Industry":
              "Industrial environments might expose workers to chemicals, dust, and fumes, which can trigger or worsen respiratory symptoms and other allergic reactions.",
          "Office/School":
              "While typically more controlled, office and school environments can still harbor indoor allergens like dust, mold, and dander, especially in poorly ventilated or damp areas. Symptoms might be less severe but could still persist due to prolonged indoor exposure.",
          "Pets":
              "Exposure to pets can lead to allergic reactions, particularly if you're sensitive to pet dander. This can worsen respiratory symptoms or skin reactions, especially if pets are allowed in sleeping areas.",
          "Dust":
              "Dust exposure is a common trigger for allergic reactions, including asthma and allergic rhinitis. Symptoms might be more severe in environments with poor air quality and frequent dust accumulation.",
          "Insects":
              "Insect exposure, particularly to cockroaches or dust mites, can exacerbate allergic reactions. Insect allergens can be potent triggers, especially in urban or poorly maintained environments.",
          "Dampened walls":
              "Damp walls are often associated with mold growth, which can significantly aggravate respiratory conditions like asthma. Long-term exposure to damp environments can lead to chronic symptoms and even the development of respiratory issues in previously healthy individuals.",
        };

        // Replace selected option with corresponding statement
        List<Map<String, dynamic>> finalResponses =
            filteredResponses.map((response) {
          String? answer = response['answer'];
          String? statement = optionStatementMap[answer];
          if (statement != null) {
            response['answer'] =
                statement; // Replace the answer with the detailed statement
          }
          return response;
        }).toList();

        int totalItems = finalResponses.length;
        int questionNumber = 1; // Initialize question number counter

        for (int i = 0; i < totalItems; i += itemsPerPage) {
          doc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return [
                  // Include the "Screening Report" header only on the first page
                  if (i == 0 &&
                      DataSingleton().scale_id ==
                          "AllergicRhinitisCustom.kribado") ...[
                    pw.Text(
                      "Screening Report :",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                          fontSize: 25),
                    ),
                    pw.SizedBox(height: 5),
                  ],

                  // Wrap the rest of the questions and answers
                  pw.Wrap(
                    children: finalResponses
                        .sublist(
                            i,
                            (i + itemsPerPage <= totalItems)
                                ? i + itemsPerPage
                                : totalItems) // Adjust the range to make sure the last item is included
                        .map((question) => pw.Container(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    "Q${questionNumber++}: ${question['title']}", // Display question number
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 20),
                                  ),
                                  pw.Text(
                                    "A: ${question['answer'].toString().trim()}",
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 20),
                                  ),
                                  pw.SizedBox(height: 5),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ];
              },
            ),
          );
        }

      }


      if(DataSingleton().References !=null && DataSingleton().References!.isNotEmpty)
        // Add Reference
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text(
                      "Reference : ${DataSingleton().References}",
                      style: pw.TextStyle(font: ttf, fontSize: 25),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );

      // Add Disclaimer
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Disclaimer :",
                    style: pw.TextStyle(
                        font: ttf,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 25),
                  ),
                  pw.Text(
                    disclaimer,
                    style: pw.TextStyle(font: ttf),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "© ${DateTime.now().year} Indigital Technologies LLP",
                    style: pw.TextStyle(font: ttf, fontSize: 20),
                  ),
                  pw.SizedBox(height: 10), // Add space between text and image
                  if (imageBytes != null)
                    if (imageBytes != null && imageBytes.isNotEmpty)
                      pw.Center(
                        child: pw.Image(pw.MemoryImage(imageBytes),
                            fit: pw.BoxFit.contain),
                      ),
                ],
              ),
            ),
          ],
        ),
      );

      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        CustomSnackbar.showErrorSnackbar(
          title: 'Directory',
          message: "Document directory not available",
        );
        return;
      }

      String path = directory.path;
      String myFile =
          '$path/${DataSingleton().pat_name}_${DataSingleton().getCurrentDateTimeInIST()}.pdf';
      final file = File(myFile);
      await file.writeAsBytes(await doc.save());
      OpenFile.open(myFile);
    } catch (e) {
      debugPrint("$e");
      CustomSnackbar.showErrorSnackbar(title: 'PDF Not Created', message: '$e');
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

  String formatDecimal(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toString();
    }
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
      await printerService.printTicket1();
      Future.delayed(const Duration(seconds: 4), () {
        Navigator.of(dialogContext).pop(); // Close only the dialog
      });
    } else {
      Fluttertoast.showToast(msg: "Unable to connect to printer");
      Navigator.of(dialogContext).pop(); // Close only the dialog on failure
    }
  }



}




