import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kribadostore/AppSettingsHelper.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/helper/sharedpref_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../DataSingleton.dart';
import '../custom_widgets/customappbar.dart';

class PrintScreen extends StatefulWidget {
  bool automaticprint;
  PrintScreen({super.key, this.automaticprint = false});

  @override
  _PrintChartScreenState createState() => _PrintChartScreenState();
}

class _PrintChartScreenState extends State<PrintScreen> with WidgetsBindingObserver{
  bool connected = false;

  List<BluetoothInfo> items = [];
  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  String _msj = '';
  String? _printerMacAddress; // Store the MAC address globally
  bool _progress = false;
  int? selectedIndex; // To track the selected index

  bool? isPrintComplete;
  bool isConnectionComplete = true;

  bool defaultPrint = false;

  bool _disconnectTimerActive =
  false; // Flag to track if the disconnect timer is active

  int count = 0;

  late Uint8List bytesImg;

  img.Image? image;

  Uint8List? _bitmap;

  bool first_ticket = false;
  bool second_ticket = false;

  PermissionStatus? status = PermissionStatus.denied; // Declare globally

  @override
  void initState() {
    super.initState();
    initPlatformState();
    WidgetsBinding.instance.addObserver(this); // ✅ Correct way to add observer

    _generateImage();
    if (Platform.isAndroid) {
      checkPermissions();
    }

    if (Platform.isIOS) {
      if (widget.automaticprint) {
        _retrieveAndConnectPrinter();

        Future.delayed(const Duration(seconds: 8), () {
          _retrieveAndPrint();
        });
      }
    } else if (Platform.isAndroid) {
      if (widget.automaticprint) {
        startPrintingProcess();
      }
    }
  }

  Future<void> _retrieveAndPrint() async {
    try {
      setState(() {
        if (connected) {
          print("Comes in If Block");
          printTicket1();
          if (scale_id.toString().contains("Regional")) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              setState(() {
                // Navigator.of(context).pop();
              });
            });
          }
        } else {
          changePrinter(context);
          if (kDebugMode) {
            print("Comes in Else Block");
          }
        }
      });
    } catch (e) {
      print("$e");
    }
  }

  void startPrintingProcess() {
    _retrieveAndConnectPrinter().then((_) {
      _retrieveAndPrint();
    }).catchError((error) {
      // Handle any errors that occur during the process
      if (kDebugMode) {
        print('Error: $error');
      }
    });
  }

  Future<void> _retrieveAndConnectPrinter() async {
    String? mac = await SharedprefHelper.getUserData("printer");

    if (mac != null && mac.isNotEmpty) {
      try {
        await connect(mac); // Await the connect method as well
      } catch (e) {
        defaultPrint = false;
        print("Not Connected Due to $e");
      }
    } else {
      defaultPrint = false;
      print("Mac is Empty");
    }
  }

  get scale_id => DataSingleton().scale_id;

  Future<void> checkPermissions() async {
    await checkPermission(Permission.bluetoothConnect);
    await checkPermission(Permission.bluetoothScan);
    isCheckingPermission = false; // ✅ Reset flag after checking

  }

  Future<void> checkPermission(Permission permission) async {
    status = await permission.request();
    print('statussssofpermission $status');
    switch (permission) {
      case Permission.bluetooth:
        break;
      default:
    }
  }

  Future<bool> checkAndRequestBluetoothPermission() async {
    if (await Permission.bluetooth.status.isGranted &&
        await Permission.bluetoothScan.status.isGranted &&
        await Permission.bluetoothConnect.status.isGranted) {
      print("Bluetooth permissions already granted.");
      return true;
    }

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.bluetooth]?.isGranted == true &&
        statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true) {
      print("Bluetooth permissions granted.");
      return true;
    } else {
      print("Bluetooth permissions denied.");
      return false;
    }
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    if (kDebugMode) {
      print("bluetooth enabled: $result");
    }
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    setState(
          () {},
    );
  }

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

  Future<void> connect(String mac) async {
    await clearCache();

    setState(() {
      _progress = true;
    });

    try {
      final bool result =
      await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (result) {
        setState(() {
          connected = true;
          _msj = "Connected with printer";
          _printerMacAddress = mac;
        });
      } else {
        setState(() {
          connected = false;
          _msj = "Could not connect to the printer";
        });
      }
    } catch (e) {
      setState(() {
        connected = false;
        _msj = "Connection failed due to: $e";
      });
    } finally {
      setState(() {
        _progress = false;
      });
    }
  }

  Future<void> disconnect() async {
    if (connected) {
      try {
        // Log before disconnecting
        if (kDebugMode) {
          print("Attempting to disconnect...");
        }

        // Await the disconnect method and log its status
        final bool status = await PrintBluetoothThermal.disconnect;

        // Ensure the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            connected = false;
            _msj = "";
            selectedIndex = -1;
          });
        }

        // Log the status after disconnecting
        if (kDebugMode) {
          print("Status disconnect $status");
        }
      } catch (e) {
        // Catch and log any errors
        if (kDebugMode) {
          print("Error during disconnect: $e");
        }
      }
    }
  }

  Future<void> printTest() async {
    try {
      bool conexionStatus = await PrintBluetoothThermal.connectionStatus;

      if (conexionStatus) {
        // Ensure the printer is connected before printing
        if (!connected) {
          if (_printerMacAddress != null) {
            // If not connected, reconnect to the previously connected printer
            await connect(_printerMacAddress!);
          } else {
            if (kDebugMode) {
              print("No previous printer MAC address found.");
            }
            return;
          }
        }
        if (Platform.isAndroid || Platform.isIOS) {
          List<int> ticket = await testTicket();
          await PrintBluetoothThermal.writeBytes(ticket);
        }
      } else {
        if (kDebugMode) {
          print("Printer is not connected.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in printTest: $e");
      }
    }
  }

  Future<void> clearCache() async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();

      // Get the cache directory
      final cacheDir = await getTemporaryDirectory();

      // Delete files in the temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }

      // Delete files in the cache directory
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }

      print("Cache cleared successfully");
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    String base64String = DataSingleton().top_logo?.replaceAll(
      "data:image/png;base64,",
      "",
    ) ??
        "";

    if (DataSingleton().top_logo != null) {
      bytesImg = base64.decode(base64String);
      image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image!.width ~/ 1.6,
          height: image!.height ~/ 1.8,
          interpolation: img.Interpolation.linear,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }

      if (Platform.isAndroid) {
        final resizedImage = img.copyResize(
          image!,
          width: 300,
          height: 80,
          interpolation: img.Interpolation.cubic,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }
      //Using `ESC *`
      if (image != null) {
        // bytes += generator.image(image);
        bytes += generator.imageRaster(image!);
      }
    }

    if (DataSingleton().doc_name != null) {
      // Capitalize the first letter
      String doctorName = DataSingleton().doc_name!;
      String capitalizedDocName =
          '${(DataSingleton().doc_name ?? doctorName).substring(0, 1).toUpperCase()}${(DataSingleton().doc_name ?? doctorName).substring(1)}';

      bytes += generator.feed(2);

      if (kDebugMode) {
        print('@@### before$capitalizedDocName');
      }

      if (capitalizedDocName.startsWith("dr") ||
          capitalizedDocName.startsWith("dr.") ||
          capitalizedDocName.startsWith("dr. ") ||
          capitalizedDocName.startsWith("DR") ||
          capitalizedDocName.startsWith("DR.") ||
          capitalizedDocName.startsWith("DR. ")) {
        capitalizedDocName = "Dr. $capitalizedDocName";
      }

      if (kDebugMode) {
        print('@@### after$capitalizedDocName');
      }
      bytes += generator.text(
        "Doctor Name - $capitalizedDocName",
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    bytes += generator.text(
      '- - - - - - - - - - - - - - - - ',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

    bytes += generator.text(
      "Patient Information",
      styles: const PosStyles(align: PosAlign.center, bold: false),
    );

    String? patientName, age, gender;

    // String capitalizedPatientName =
    //     '${(DataSingleton().Patient_name ?? patientName).substring(0, 1).toUpperCase()}${(DataSingleton().Patient_name ?? patientName).substring(1)}';
    //
    // String capitalizedGender =
    //     '${(DataSingleton().Patient_gender ?? gender).substring(0, 1).toUpperCase()}${(DataSingleton().Patient_gender ?? gender).substring(1)}';

    if (DataSingleton().Patient_name != null &&
        DataSingleton().Patient_name!.isNotEmpty) {
      patientName =
      '${(DataSingleton().Patient_name ?? patientName)?.substring(0, 1).toUpperCase()}${(DataSingleton().Patient_name ?? patientName)?.substring(1)}';
    }

    if (DataSingleton().Patient_gender != null &&
        DataSingleton().Patient_gender!.isNotEmpty) {
      gender =
      '${(DataSingleton().Patient_gender ?? gender)?.substring(0, 1).toUpperCase()}${(DataSingleton().Patient_gender ?? gender)?.substring(1)}';
    }

    age = DataSingleton().Patient_age;
    String patientInfo = "";

    // Check if patient name is not null before adding to patientInfo
    if (patientName != null && patientName!.isNotEmpty) {
      patientInfo += '\nName: $patientName';
    }

    // Check if patient age is not null before adding to patientInfo
    if (age != null) {
      patientInfo += '\nAge: $age';
    }

    // Check if patient gender is not null before adding to patientInfo
    if (gender != null) {
      patientInfo += '\nGender: $gender\n';
      if (kDebugMode) {
        print("Gender$gender");
      }
    }

    // Only add Uric Acid and Glucose info for specific scale IDs
    if (scale_id == "Short.Womac.kribado" || scale_id == "FRAX.osteocalc.kribado") {
      if (DataSingleton().uricAcidFinalLine != null) {
        patientInfo += '\n${DataSingleton().uricAcidFinalLine}';
      }
      patientInfo += '\n'; // Add final newline
      if (DataSingleton().glucoseFinalLine.isNotEmpty) {
        patientInfo += '\n${DataSingleton().glucoseFinalLine}';
      }
    }

    patientInfo += '\n'; // Add final newline

    if (patientInfo.isNotEmpty) {
      bytes += generator.text(
        patientInfo,
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    if (patientInfo.isNotEmpty) {
      bytes += generator.text(
        '- - - - - - - - - - - - - - - - ',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (DataSingleton().scale_id == "HbA1c.kribado") {
      bytes += generator.text(
        '',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );
    }else{

      if (DataSingleton().scale_id == "FRAX.osteocalc.kribado") {
        bytes += generator.text(
          '${DataSingleton().Scale_Name}' '\n',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            fontType: PosFontType.fontB,
          ),
        );
      }else {
        bytes += generator.text(
          '${DataSingleton().Scale_Name}' '\n',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            fontType: PosFontType.fontA,
          ),
        );
      }



    }

    if (scale_id.contains("WOMAC.kribado")) {
      bytes += generator.text(
        'Score:' " ${DataSingleton().TotalScore} " ' out of 96\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        'Pain Score:' " ${DataSingleton().score1to5}" ' out of 20\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        'Stiffness Score:' " ${DataSingleton().score6and7}" ' out of 8\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        'Physical Functional Difficulty Score:'
            " ${DataSingleton().scoreBeyond7}"
            ' out of 68\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    } else {
      if (DataSingleton().scale_id != "FSSG.Nepali.Regional.kribado" && DataSingleton().scale_id != "HbA1c.kribado") {
        if(DataSingleton().scale_id == "FRAX.osteocalc.kribado"){
          bytes += generator.text(
            '${DataSingleton().fraxHeader}: ' "${DataSingleton().Score}" '\n',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        } else if(DataSingleton().scale_id == "BP.Monitoring.kribado"){
          bytes += generator.text(
            '',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        else {
          bytes += generator.text(
            'Score: ' "${DataSingleton().Score}" '\n',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }

      }
    }
    if (DataSingleton().scale_id == "HbA1c.kribado") {
    }
    if (DataSingleton().scale_id == "FSSG.Regional.kribado") {
      bytes += generator.text(
        "Acid Reflux Score: ${DataSingleton().reflux_score_only}",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );

      bytes += generator.text(
        "Dyspeptic Symptom Score: ${DataSingleton().dyspeptic_score_only}" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    if (DataSingleton().scale_id == "FSSG.Nepali.Regional.kribado") {
      bytes += generator.text(
        "Acid Reflux Score: ${DataSingleton().reflux_score_only}",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );

      bytes += generator.text(
        "Dyspeptic Symptom Score: ${DataSingleton().dyspeptic_score_only}" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }

    if (DataSingleton().scale_id == "FSSG.Bangladesh.kribado") {
      bytes += generator.text(
        "Acid Reflux Score: ${DataSingleton().reflux_score_only}",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );

      bytes += generator.text(
        "Dyspeptic Symptom Score: ${DataSingleton().dyspeptic_score_only}" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }

    if (DataSingleton().scale_id == "ASCVD.risk.kribado" ||
        DataSingleton().scale_id == "ASCVD.risk.estimator.kribado" || DataSingleton().scale_id == "LipidProfileCustom.kribado") {
      bytes += generator.text(
        "(Calculated Risk)" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }

    String base64String1 = DataSingleton().option_selected_logo?.replaceAll(
      "data:image/png;base64,",
      "",
    ) ??
        "";

    if (DataSingleton().option_selected_logo != null &&
        DataSingleton().option_selected_logo!.isNotEmpty) {
      bytesImg = base64.decode(base64String1);
      img.Image? image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image.width ~/ 1.5,
          height: image.height ~/ 1.6,
          interpolation: img.Interpolation.linear,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }

      if (Platform.isAndroid) {
        final resizedImage = img.copyResize(
          image!,
          width: 300,
          height: 300,
          interpolation: img.Interpolation.cubic,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }

      if (image != null) {
        bytes += generator.imageRaster(
          image,
        );
        bytes += generator.feed(2);
      }
    }
    if (DataSingleton().scale_id == "HbA1c.kribado") {
      bytes += generator.text(
        "${DataSingleton().Interpretation}",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }

    if (DataSingleton().scale_id == "Short.Womac.kribado") {
      bytes += generator.text(
        "${DataSingleton().Interpretation}",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );

      bytes += generator.feed(2);


      bytes += generator.text(
        "Note: Kindly consult your doctor for further medication.",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }


    else{
      bytes += generator.text(
        "${DataSingleton().Interpretation}" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }


    if (DataSingleton().questionAndAnswers == "True") {
      // scale inputs array
      List<dynamic> inputsScale = DataSingleton().inputs;
      print('jsfsjfsncxnczzz $inputsScale');

      // Create a map of question_id to title
      Map<int, String> questionTitleMap = {};
      for (var input in inputsScale) {
        questionTitleMap[input['id']] = input['title'];
      }

      print("fisjfkxcmxkveiejfisfjs $questionTitleMap");

      // Fetch data from DataSingleton
      List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;

      // Transform responses to replace question_id with title
      List<Map<String, dynamic>> transformedResponses = [];

      List questions1 = [
        "Incomplete Emptying",
        "Frequency",
        "Intermittency",
        "Urgency",
        "Weak Stream",
        "Straining",
        "Nocturia",
        "QOL Impact"
      ];

      int i = 0;
      for (var response in questions) {
        int questionId = response['question_id'];
        String? title = questionTitleMap[questionId];

        if (DataSingleton().scale_id == "IPSSCustom.kribado") {
          transformedResponses.add({
            'title': questions1[i],
            'score': response['score'],
            'answer': response['answer']
          });
          i++;
        } else {
          transformedResponses.add({
            'title': title,
            'score': response['score'],
            'answer': response['answer']
          });
        }
      }

      if (DataSingleton().childQuestion != null &&
          DataSingleton().childQuestion!.isNotEmpty) {
        List<Map<String, dynamic>> transformedResponsesforChild = [];

        // First, add the main questions to transformedResponses
        for (var response in questions) {
          int questionId = response['question_id'];
          String? title = questionTitleMap[questionId];
          transformedResponsesforChild.add({
            'title': title,
            'score': response['score'],
            'answer': response['answer']
          });
        }

        // Change only the title of the second object if it exists
        if (transformedResponsesforChild.length > 1) {
          transformedResponsesforChild[1]['title'] =
              DataSingleton().childQuestion;
        }

        num a = 1;
        print(
            'jdfjdfjcmxcxmcxmcmxmxm ${DataSingleton().tranformedRepsonsesParentChild}');
        // Iterate through the list of questions
        for (var question in transformedResponsesforChild) {
          String questionId = question['title'];
          String answer = question['answer'];
          double? numericAnswer = double.tryParse(answer.toString());

          a;
          // Print each question_id and answer on a new line
          bytes += generator.text(
            'Q$a: $questionId',
            styles: const PosStyles(align: PosAlign.left),
          );

          bytes += generator.text(
            formatDecimal(numericAnswer!),
            styles: const PosStyles(align: PosAlign.left),
          );

        }
      } else if (DataSingleton().scale_id == "HbA1c.kribado") {
        if (transformedResponses.isNotEmpty) {

          transformedResponses = transformedResponses.sublist(0, 1);
          print('Transformed Responses print: $transformedResponses');
          var firstQuestion = transformedResponses[0];
          String questionTitle = firstQuestion['title'];
          String answer = firstQuestion['answer'];

          bytes += generator.text(
            '$questionTitle',
            styles: const PosStyles(align: PosAlign.center),
          );

          bytes += generator.text(
            '$answer',
            styles: const PosStyles(align: PosAlign.center),
          );

          print('Transformed Responses (after slicing): $transformedResponses');
        }
      } else if (DataSingleton().scale_id == "ASCVD.Custom.kribado") {
        if (transformedResponses.isNotEmpty) {

          transformedResponses = transformedResponses.sublist(0, 1);
          print('Transformed Responses print: $transformedResponses');
          var firstQuestion = transformedResponses[0];
          String questionTitle = firstQuestion['title'];
          String answer = firstQuestion['answer'];

          bytes += generator.text(
            '$questionTitle',
            styles: const PosStyles(align: PosAlign.center),
          );

          bytes += generator.text(
            '$answer',
            styles: const PosStyles(align: PosAlign.center),
          );

          print('Transformed Responses (after slicing): $transformedResponses');
        }
      } else {
        num a = 0;
// Iterate through the list of questions
        for (var question in transformedResponses) {
          String questionId = question['title'];
          String answer = question['answer'].toString();
          double? numericAnswer = double.tryParse(answer);

          a++;
          // Print question title with a line break after
          bytes += generator.text(
            'Q$a: $questionId',
            styles: const PosStyles(align: PosAlign.left),
          );

          // Print answer with "Ans:" prefix
          bytes += generator.text(
            'Ans: ${numericAnswer != null ? formatDecimal(numericAnswer) : answer}\n',
            styles: const PosStyles(align: PosAlign.left),
          );
        }
      }
    }

    if (DataSingleton().scale_id == "Asthma.kribado" ||
        DataSingleton().scale_id == "COPD.kribado" ||
        DataSingleton().scale_id == "VAS.kribado") {
      bytes += generator.text(
        'Interpretation:',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );
    }

    if (DataSingleton().scale_id == "Asthma.kribado") {
      bytes += generator.feed(2);

      bytes += generator.text(
        '- Total score: 0-20',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );

      bytes += generator.text(
        '- <4: Less likelihood of Asthma',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );
      bytes += generator.text(
        '- >=4: Asthma',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );

      bytes += generator.feed(1);
    }

    if (DataSingleton().scale_id == "COPD.kribado") {
      bytes += generator.feed(2);

      bytes += generator.text(
        '- 0-10 Low: Indicates mild to minimal impact of COPD on daily life.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );

      bytes += generator.text(
        '- 11-20 Medium: Suggests a moderate impact of COPD on daily life.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );
      bytes += generator.text(
        '- 21-30 High: Indicates a high impact of COPD on daily life.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );
      bytes += generator.text(
        '- 31-40 Very high: Suggests a very high impact of COPD on daily life.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );

      bytes += generator.feed(1);
    }

    if (DataSingleton().scale_id == "VAS.kribado") {
      bytes += generator.feed(2);

      bytes += generator.text(
        '- 50 points and above: Uncontrolled Allergic Rhinitis.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );

      bytes += generator.text(
        '- 20 to 49 points: Partially controlled Allergic Rhinitis.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );
      bytes += generator.text(
        '- Below 20 points: Well-controlled Allergic Rhinitis.',
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      );

      bytes += generator.feed(1);
    }

    bytes += generator.text(
      '- - - - - - - - - - - - - - - - ',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    bytes += generator.feed(1);

    if (DataSingleton().References != null &&
        DataSingleton().References!.isNotEmpty) {
      bytes += generator.text(
        'Reference : \n' "${DataSingleton().References}",
        styles: const PosStyles(
          align: PosAlign.left,
          fontType: PosFontType.fontB,
        ),
      );
    }

    // final disclaimer = DataSingleton()?.Disclaimer ?? 'This is a customized service by Indigital Technologies LLP Although, great care has been taken in compiling and checking the information given in this service to ensure it is accurate, the author/s, the printer/s, the publisher/s and their servant/s or agent/s and purchaser/s shall not be responsible or in any way liable for any errors, omissions or inaccuracies whether arising from negligence or otherwise howsoever or due diligence of copyrights or for any consequences arising there from. In spite of best efforts the information in this service may become outdated over time. Indigital Technologies LLP accepts no liability for the completeness or use of the information contained in this service or its update.';

    print("njgeigjzkzkczc ${DataSingleton().questionAndAnswers}");

    //bytes += generator.cut();
    return bytes;
  }

  Future<void> regionalPrintFirstTicket() async {
    List<int> ticket = await generateBasicTicket();
    bool result2 = await PrintBluetoothThermal.writeBytes(ticket);

    if (!result2) {
      if (kDebugMode) {
        print(
          "Failed to print the second ticket.",
        );
      }
    }
  }

  String formatDecimal(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toString();
    }
  }

  Future<void> regionalPrintsecondTicketIOS() async {
    List<int> ticket = await generateDetailedTicket();
    bool result2 = await PrintBluetoothThermal.writeBytes(ticket);

    if (!result2) {
      if (kDebugMode) {
        print(
          "Failed to print the second ticket.",
        );
      }
    } else {
      Future.delayed(const Duration(milliseconds: 4000), () {
        setState(
              () {
            Navigator.of(context).pop();
          },
        );
      });
    }
  }

  Future<void> printTicket1() async {
    try {
      isPrintComplete = false;
      bool? result;
      if (Platform.isIOS) {
        if (scale_id.toString().contains('Regional')) {
          // This likely prints the second ticket
          regionalPrintFirstTicket();
          Future.delayed(const Duration(milliseconds: 1000), () {
            regionalPrintsecondTicketIOS();
          });

          Future.delayed(const Duration(milliseconds: 3000), () {
            setState(() {
              if (second_ticket) {
                printBottomTicket();
              }
            });
          });
        } else {
          regionalPrintFirstTicket();
          Future.delayed(const Duration(milliseconds: 1000), () {
            regionalPrintsecondTicketIOS();
          });

          Future.delayed(const Duration(milliseconds: 3000), () {
            setState(() {
              if (second_ticket) {
                printBottomTicket();
              }
            });
          });
        }
      } else if (Platform.isAndroid) {
        if (scale_id.toString().contains('Regional')) {
          List<int> ticket1 = await generateBasicTicket();
          // Print the basic ticket
          bool result = await PrintBluetoothThermal.writeBytes(ticket1);

          if (result) {
            try {
              List<int> ticket2 = await generateDetailedTicket();

              // Print the detailed ticket
              bool result1 = await PrintBluetoothThermal.writeBytes(ticket2);

              if (result1) {
                Future.delayed(const Duration(milliseconds: 1000), () async {
                  List<int> ticket3 = await printBottomBanner();
                  bool result3 =
                  await PrintBluetoothThermal.writeBytes(ticket3);
                });

                if (kDebugMode) {
                  print(
                    "Both tickets printed successfully.",
                  );
                }
              } else {
                if (kDebugMode) {
                  print(
                    "Failed to print the detailed ticket.",
                  );
                }
              }
            } catch (e) {
              Fluttertoast.showToast(msg: "Due to ${e.toString()}");
            } // Generate the bytes for the detailed ticket
          }
        } else {
          List<int> ticket1 = await testTicket();
          bool result = await PrintBluetoothThermal.writeBytes(ticket1);

          if (result) {
            await printBottomTicket();
          }
        }
      }

      if (!result!) {
        if (kDebugMode) {
          print(
            "Failed to print the second ticket.",
          );
        }
      } else {
        isPrintComplete = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print("E Strig$e");
      }
    }
  }

  Future<List<int>> generateBasicTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    bytes += generator.reset();

    // Add top logo if available
    String base64String = DataSingleton().top_logo?.replaceAll(
      "data:image/png;base64,",
      "",
    ) ??
        "";

    if (DataSingleton().top_logo != null) {
      bytesImg = base64.decode(base64String);
      image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image!.width ~/ 1.6,
          height: image!.height ~/ 1.6,
          interpolation: img.Interpolation.linear,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      } else if (Platform.isAndroid) {
        final resizedImage = img.copyResize(
          image!,
          width: 300,
          height: 80,
          interpolation: img.Interpolation.cubic,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }
      if (image != null) {
        bytes += generator.imageRaster(image!);
      }
    }

    if (DataSingleton().doc_name != null) {
      String docName = DataSingleton().doc_name!;
      String capitalizedDocName =
          docName[0].toUpperCase() + docName.substring(1).toLowerCase();

      bytes += generator.feed(2);

      if (capitalizedDocName.startsWith("dr") &&
          capitalizedDocName.startsWith("DR") &&
          capitalizedDocName.startsWith("dr.") &&
          capitalizedDocName.startsWith("DR.")) {
        capitalizedDocName = "Dr. $capitalizedDocName";
      }

      bytes += generator.text(
        "Doctor Name - $capitalizedDocName",
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    bytes += generator.text(
      '- - - - - - - - - - - - - - - - ',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

    bytes += generator.text(
      "Patient Information",
      styles: const PosStyles(align: PosAlign.center, bold: false),
    );

    String? patientName, age, gender;

    patientName = DataSingleton().Patient_name;
    age = DataSingleton().Patient_age;
    gender = DataSingleton().Patient_gender;
    String patientInfo = "";

    if (patientName!.isNotEmpty) {
      patientInfo += '\nName: $patientName';
    }

    if (age != null) {
      patientInfo += '\nAge: $age';
    }

    if (gender != null) {
      patientInfo += '\nGender: $gender\n';
      if (kDebugMode) {
        print("Gender$gender");
      }
    }

    
       // Only add Uric Acid and Glucose info for specific scale IDs
    if (scale_id == "Short.Womac.kribado" || scale_id == "FRAX.osteocalc.kribado") {

      print("Uric Acid Final Line: ${DataSingleton().uricAcidFinalLine}");
      if (DataSingleton().uricAcidFinalLine != null) {
        print('Uric Acid Final Line is not null');
        patientInfo += '\n${DataSingleton().uricAcidFinalLine}';
      }
      patientInfo += '\n'; // Add final newline
      if (DataSingleton().glucoseFinalLine.isNotEmpty) {
        patientInfo += '\n${DataSingleton().glucoseFinalLine}';
      }
      print("Patient Info: $patientInfo");
    }

    if (patientInfo.isNotEmpty) {
      bytes += generator.text(
        patientInfo,
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

  


print("Patient Info 1: $patientInfo");

    if (patientInfo.isNotEmpty) {
      bytes += generator.text(
        '- - - - - - - - - - - - - - - - ',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    return bytes;
  }

  Future<List<int>> generateDetailedTicket() async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);

    // Add additional content based on scale_id
    if (scale_id.toString().contains('Regional')) {
      ui.Image image = await generateBitmapFromText(
        "${DataSingleton().scale_name.toString()}\n"
            "${DataSingleton().Score.toString()}\n"
            "${DataSingleton().Interpretation.toString()}\n\n",
        fontSize: 80.0,
        textColor: Colors.black,
        backgroundColor: Colors.white,
        width: 400,
        height: 300, // Adjust height as needed
      );

      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List imageBytes = byteData!.buffer.asUint8List();
      // Uint8List bytesImg = data.buffer.asUint8List();
      img.Image? image3 = img.decodeImage(imageBytes);

      if (_bitmap != null) {
        image3 = img.decodeImage(_bitmap!);
      } else {
        image3 = img.decodeImage(imageBytes);
      }

      final resizedImage;
      if (Platform.isIOS) {
        resizedImage = img.copyResize(
          image3!,
          width: 300,
          height: 210,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resizedImage = img.copyResize(
          image3!,
          width: 300,
          height: 300,
          interpolation: img.Interpolation.cubic,
        );
      }

      final bytesimg = Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
        ),
      );
      image3 = img.decodeImage(
        bytesimg,
      );
      if (image3 != null) {
        bytes += generator.imageRaster(image3);
      }
    } else {
      if (scale_id.contains("WOMAC.kribado")) {
        bytes += generator.text(
          'Score:' " ${DataSingleton().TotalScore} " ' out of 96\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
        bytes += generator.text(
          'Pain Score:' " ${DataSingleton().score1to5}" ' out of 20\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
        bytes += generator.text(
          'Stiffness Score:' " ${DataSingleton().score6and7}" ' out of 8\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
        bytes += generator.text(
          'Physical Functional Difficulty Score:'
              " ${DataSingleton().scoreBeyond7}"
              ' out of 68\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      } else if (DataSingleton().scale_id!.contains("ASCVD.Custom.kribado")) {
        List<dynamic> inputsScale = DataSingleton().inputs;
        print('jsfsjfsncxnczzz $inputsScale');

        // Create a map of question_id to title
        Map<int, String> questionTitleMap = {};
        for (var input in inputsScale) {
          questionTitleMap[input['id']] = input['title'];
        }

        print("fisjfkxcmxkveiejfisfjs $questionTitleMap");

        // Fetch data from DataSingleton
        List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;

        // Transform responses to replace question_id with title
        List<Map<String, dynamic>> transformedResponses = [];

        List questions1 = [
          "Incomplete Emptying",
          "Frequency",
          "Intermittency",
          "Urgency",
          "Weak Stream",
          "Straining",
          "Nocturia",
          "QOL Impact"
        ];

        int i = 0;
        for (var response in questions) {
          int questionId = response['question_id'];
          String? title = questionTitleMap[questionId];

          if (DataSingleton().scale_id == "IPSSCustom.kribado") {
            transformedResponses.add({
              'title': questions1[i],
              'score': response['score'],
              'answer': response['answer']
            });
          } else {
            transformedResponses.add({
              'title': title,
              'score': response['score'],
              'answer': response['answer']
            });
          }
        }
        if (transformedResponses.isNotEmpty) {
          transformedResponses = transformedResponses.sublist(0, 1);
          print('Transformed Responses print: $transformedResponses');
          var firstQuestion = transformedResponses[0];
          String questionTitle = firstQuestion['title'];
          String answer = firstQuestion['answer'];

          bytes += generator.text(
            '${DataSingleton().Test_Name}\n\nScore: ${DataSingleton().Score} ',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );

          bytes += generator.feed(2);


          bytes += generator.text(
            "${DataSingleton().Interpretation}",
            styles: const PosStyles(
              align: PosAlign.center,
            ),
          );

          bytes += generator.feed(2);

          bytes += generator.text(
            '$questionTitle\n${DataSingleton().hbA1c}',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );

          bytes += generator.text(
            '- - - - - - - - - - - - - - - - ',
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
            ),
          );
        }
      } else {
        bytes += generator.text(
          '${DataSingleton().Scale_Name}' '\n',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        if (DataSingleton().scale_id != "FSSG.Nepali.Regional.kribado") {
          bytes += generator.text(
            'Score: ' "${DataSingleton().Score}" '\n',
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
            ),
          );
        }
      }

      if (DataSingleton().scale_id == "FSSG.Regional.kribado") {
        bytes += generator.text(
          "Acid Reflux Score: ${DataSingleton().reflux_score_only}",
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );

        bytes += generator.text(
          "Dyspeptic Symptom Score: ${DataSingleton().dyspeptic_score_only}"
              '\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      if (DataSingleton().scale_id == "FSSG.Nepali.Regional.kribado") {
        bytes += generator.text(
          "Acid Reflux Score: ${DataSingleton().reflux_score_only}",
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );

        bytes += generator.text(
          "Dyspeptic Symptom Score: ${DataSingleton().dyspeptic_score_only}"
              '\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      if (DataSingleton().scale_id == "ASCVD.risk.kribado" ||
          DataSingleton().scale_id == "ASCVD.risk.estimator.kribado" || DataSingleton().scale_id == "LipidProfileCustom.kribado") {
        bytes += generator.text(
          "(Calculated Risk)" '\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      if (DataSingleton().option_selected_logo != null &&
          DataSingleton().option_selected_logo!.isNotEmpty) {
        // Add top logo if available
        String base64String = DataSingleton().option_selected_logo?.replaceAll(
          "data:image/png;base64,",
          "",
        ) ??
            "";
        print("Base64 string: $base64String");
        bytesImg = base64.decode(base64String);
        image = img.decodeImage(bytesImg);

        if (Platform.isIOS) {
          final resizedImage = img.copyResize(
            image!,
            width: 250,
            height: 250,
            interpolation: img.Interpolation.linear,
          );
          final bytesimg = Uint8List.fromList(
            img.encodeJpg(
              resizedImage,
            ),
          );
          image = img.decodeImage(
            bytesimg,
          );
        } else if (Platform.isAndroid) {
          final resizedImage = img.copyResize(
            image!,
            width: 300,
            height: 300,
            interpolation: img.Interpolation.cubic,
          );
          final bytesimg = Uint8List.fromList(
            img.encodeJpg(
              resizedImage,
            ),
          );
          image = img.decodeImage(
            bytesimg,
          );
        }
        if (image != null) {
          bytes += generator.imageRaster(image!);
        }
        print("Base64 string: $bytes");
      }

      if (!DataSingleton().scale_id!.contains("ASCVD.Custom.kribado")) {
        bytes += generator.text(
          "${DataSingleton().Interpretation}" '\n',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      if (DataSingleton().questionAndAnswers == "True" &&
          !DataSingleton().scale_id!.contains("ASCVD.Custom.kribado")) {
        List<dynamic> inputsScale = DataSingleton().inputs;

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

        num a = 0;
        for (var question in transformedResponses) {
          String questionId = question['title'];
          String answer = question['answer'];
        double? numericAnswer = double.tryParse(answer);

          a++;
          // Print question title with a line break after
          bytes += generator.text(
            'Q$a: $questionId',
            styles: const PosStyles(align: PosAlign.left),
          );

          // Print answer with "Ans:" prefix
          bytes += generator.text(
            'Ans: ${numericAnswer != null ? formatDecimal(numericAnswer) : answer}\n',
            styles: const PosStyles(align: PosAlign.left),
          );
        }
      }
    }

    bytes += generator.text(
      '- - - - - - - - - - - - - - - - ',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

    bytes += generator.feed(1);

    if (DataSingleton().References != null &&
        DataSingleton().References!.isNotEmpty) {
      bytes += generator.text(
        'Reference : \n' "${DataSingleton().References}",
        styles: const PosStyles(
          align: PosAlign.left,
          fontType: PosFontType.fontB,
        ),
      );

      if (Platform.isIOS) {
        bytes += generator.feed(1);
      }
    }

    // final disclaimer = DataSingleton()?.Disclaimer ?? 'This is a customized service by Indigital Technologies LLP Although, great care has been taken in compiling and checking the information given in this service to ensure it is accurate, the author/s, the printer/s, the publisher/s and their servant/s or agent/s and purchaser/s shall not be responsible or in any way liable for any errors, omissions or inaccuracies whether arising from negligence or otherwise howsoever or due diligence of copyrights or for any consequences arising there from. In spite of best efforts the information in this service may become outdated over time. Indigital Technologies LLP accepts no liability for the completeness or use of the information contained in this service or its update.';

    print("njgeigjzkzkczc ${DataSingleton().questionAndAnswers}");

    setState(() {
      second_ticket = true;
    });

    return bytes;
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);

    count = 0;
    isPrintComplete = false;
    await disconnect();
  }



  bool isCheckingPermission = false; // ✅ Prevents continuous calls


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {

      if (Platform.isAndroid) {

        if (!isCheckingPermission) {
          isCheckingPermission = true;
          checkPermissions();
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Print Screen',
        showBackButton: true,
        destinationScreen: null,
        showKebabMenu: false,
        pageNavigationTime:
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: widget.automaticprint
          ? isPrintComplete ?? true
          ? Center(
        child: Image.asset(
          "assets/printing.gif",
        ),
      )
          : Column(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(
                10.0,
              ),
              child: Text(
                'Select Printer',
                style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(items[index].macAdress,
                          style: const TextStyle(
                            fontSize: 10,
                          )),
                    ],
                  ),
                  trailing: (selectedIndex == (index))
                      ? const Icon(Icons.check,
                      color: Colors.green) // Check mark icon
                      : null,
                  onTap: isConnectionComplete
                      ? () async {
                    if (connected) {
                      await disconnect();
                    }
                    await SharedprefHelper.deleteUserData(
                        "printer");

                    setState(() {
                      _progress = true;
                      isConnectionComplete =
                      false; // Disable the list during connection
                    });

                    _printerMacAddress = items[index].macAdress;

                    final bool result =
                    await PrintBluetoothThermal.connect(
                        macPrinterAddress:
                        items[index].macAdress);

                    if (result) {
                      setState(() {
                        _progress = false;
                        _msj =
                        "Connected with ${items[index].name}";
                        connected = true;
                        selectedIndex = index;
                      });

                      await SharedprefHelper.saveUserData(
                          "printer", _printerMacAddress!);
                    } else {
                      setState(() {
                        _progress = false;
                        _msj =
                        "Could not connect with ${items[index].name}";
                        connected = false;
                        selectedIndex = -1;
                      });
                    }

                    setState(() {
                      isConnectionComplete =
                      true; // Re-enable the list after connection
                    });
                  }
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _msj,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _progress,
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Please Wait..",
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomElevatedButton(
                onPressed: () {
                  getBluetoots();
                },
                text: 'Search Printer',
              ),
              CustomElevatedButton(
                onPressed: () async {
                  try {
                    if (connected) {
                      await SharedprefHelper.deleteUserData(
                          "printer");
                      await disconnect();
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print(e.toString());
                    }
                  }
                },
                text: 'Disconnect',
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 200,
            height: 50,
            child: CustomElevatedButton(
              onPressed: () {
                setState(() {
                  if (kDebugMode) {
                    print(
                        "Conntected Status $connected  ${SharedprefHelper.getUserData("printer").toString()}");
                  }

                  if (connected) {
                    if (count == 0) {
                      printTicket1();
                      count++;
                    } else {
                      if (Platform.isIOS) {
                        if (isPrintComplete == false) {
                          _printAgain(context);
                        } else {
                          if (kDebugMode) {
                            print("Comes in another block");
                          }
                        }
                      }
                      if (Platform.isAndroid) {
                        if (isPrintComplete == true) {
                          _printAgain(context);
                        } else {
                          if (kDebugMode) {
                            print("Comes in another block");
                          }
                        }
                      }
                      if (isPrintComplete == false) {
                        _printAgain(context);
                      } else {
                        if (kDebugMode) {
                          print("Comes in another block");
                        }
                      }
                    }
                  }
                });
              },
              text: 'Print',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      )
          : Column(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(
                10.0,
              ),
              child: Text(
                'Select Printer',
                style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(items[index].macAdress,
                          style: const TextStyle(
                            fontSize: 10,
                          )),
                    ],
                  ),
                  trailing: (selectedIndex == (index))
                      ? const Icon(Icons.check,
                      color: Colors.green) // Check mark icon
                      : null,
                  onTap: isConnectionComplete
                      ? () async {
                    if (connected) {
                      await disconnect();
                    }
                    await SharedprefHelper.deleteUserData(
                        "printer");

                    setState(() {
                      _progress = true;
                      isConnectionComplete =
                      false; // Disable the list during connection
                    });

                    _printerMacAddress = items[index].macAdress;

                    final bool result =
                    await PrintBluetoothThermal.connect(
                        macPrinterAddress:
                        items[index].macAdress);

                    if (result) {
                      setState(() {
                        _progress = false;
                        _msj =
                        "Connected with ${items[index].name}";
                        connected = true;
                        selectedIndex = index;
                      });

                      await SharedprefHelper.saveUserData(
                          "printer", _printerMacAddress!);

                      _retrieveAndPrint();
                    } else {
                      setState(() {
                        _progress = false;
                        _msj =
                        "Could not connect with ${items[index].name}";
                        connected = false;
                        selectedIndex = -1;
                      });
                    }

                    setState(() {
                      isConnectionComplete =
                      true; // Re-enable the list after connection
                    });
                  }
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(
                10.0,
              ),
              child: Text(
                _msj,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor)  ,
              ),
            ),
          ),
          if(_msj == "Go to settings & check in settings that the permission of nearby devices is 'Allowed'." && Platform.isAndroid)
            ElevatedButton(
              onPressed: () async {
                AppSettingsHelper.openAppInfo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // ✅ Set border radius
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // ✅ Add padding
              ),
              child: Text("Open Settings",style:  TextStyle(color: Colors.white),),
            ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _progress,
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Please Wait..",
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomElevatedButton(
                onPressed: () {

                  if(Platform.isAndroid) {
                    if (status!.isDenied || status!.isPermanentlyDenied) {
                      setState(() {
                        _msj =
                        "Go to settings & check in settings that the permission of nearby devices is 'Allowed'.";
                      });
                    } else {
                      setState(() {
                        checkPermissions();
                        initPlatformState();
                        getBluetoots();
                      });
                    }
                  }else if(Platform.isIOS){
                    getBluetoots();

                  }

                },
                text: 'Search Printer',
              ),
              CustomElevatedButton(
                onPressed: () async {
                  try {
                    if (connected) {
                      await SharedprefHelper.deleteUserData("printer");
                      await disconnect();
                    }
                  } catch (e) {
                    print(e.toString());
                  }
                },
                text: 'Disconnect',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 200,
            height: 50,
            child: CustomElevatedButton(
              onPressed: () {
                setState(() {
                  print(
                      "Conntected Status $connected  ${SharedprefHelper.getUserData("printer").toString()}");

                  if (connected) {
                    if (count == 0) {
                      printTicket1();
                      count++;
                    } else {
                      if (Platform.isIOS) {
                        if (isPrintComplete == false) {
                          _printAgain(context);
                        } else {
                          if (kDebugMode) {
                            print("Comes in another block");
                          }
                        }
                      }
                      if (Platform.isAndroid) {
                        if (isPrintComplete == true) {
                          _printAgain(context);
                        } else {
                          if (kDebugMode) {
                            print("Comes in another block");
                          }
                        }
                      }

                      if (isPrintComplete == false) {
                        _printAgain(context);
                      } else {
                        if (kDebugMode) {
                          print("Comes in another block");
                        }
                      }
                    }
                  }
                });
              },
              text: 'Print',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _printAgain(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text("Confirm Print")),
          content: const Text("Do you want to print again?",
              style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          actions: [
            TextButton(
              child: const Text(
                "No",
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Yes",
              ),
              onPressed: () {
                Navigator.of(context).pop();
                printTicket1();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> changePrinter(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              "Change Printer",
            ),
          ),
          content: const Text(
            "Printer not found. Please select a different printer.",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                "No",
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Yes",
              ),
              onPressed: () {
                setState(() {
                  isPrintComplete = false;
                });
                getBluetoots();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<ui.Image> generateBitmapFromText(
      String text, {
        double fontSize = 80.0,
        Color textColor = Colors.black,
        Color backgroundColor = Colors.white,
        int width = 400,
        int height = 300, // Increased height to accommodate multiple lines of text
      }) async {
    // Create a picture recorder to start drawing
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Paint for background
    final Paint backgroundPaint = Paint()..color = backgroundColor;

    // Draw the background
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        backgroundPaint);

    // Create a paragraph style with center alignment
    final ui.ParagraphStyle paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
    );

    // Adjust font size to fit the content within the provided width and height
    double currentFontSize = fontSize;
    ui.Paragraph paragraph;

    do {
      // Create bold text style with the current font size
      final TextStyle textStyle = TextStyle(
        color: textColor,
        fontSize: currentFontSize,
        fontWeight: FontWeight.bold,
      );

      // Build the paragraph with the current text style
      final ui.ParagraphBuilder paragraphBuilder =
      ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle.getTextStyle())
        ..addText(text);

      paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width.toDouble()));

      // Decrease the font size if the paragraph height exceeds the canvas height
      if (paragraph.height > height) {
        currentFontSize -= 1;
      }
    } while (paragraph.height > height);

    // Calculate the center position for the text horizontally
    final double textCenterX = (width - paragraph.width) / 2;
    // Calculate the center position for the text vertically
    final double textCenterY = (height - paragraph.height) / 2;

    // Draw the text at the center
    canvas.drawParagraph(paragraph, Offset(textCenterX, textCenterY));

    // End recording and create an image
    final ui.Image image =
    await pictureRecorder.endRecording().toImage(width, height);

    return image;
  }

  Future<ui.Image> textToImage(String text, double width,
      {TextStyle? textStyle, Color backgroundColor = Colors.white}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Render the text with layout
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle ?? const TextStyle(color: Colors.black, fontSize: 40),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: width);

    double textHeight = textPainter.height;

    // Enforce max height constraint of 300
    if (textHeight > 300) {
      textHeight = 300;
    }

    // Draw the background with dynamic height
    final Paint paint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, textHeight), paint);

    // Center text vertically and horizontally
    final double offsetX = (width - textPainter.width) / 2;
    final double offsetY = (textHeight - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));

    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), textHeight.toInt());

    return image;
  }

  Future<Uint8List?> convertTextToBitmap(String text, double width,
      {TextStyle? textStyle, Color backgroundColor = Colors.white}) async {
    final ui.Image image = await textToImage(
      text,
      width,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
    );

    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  Future<void> _generateImage() async {
    final Uint8List? bitmap = await convertTextToBitmap(
      "${DataSingleton().scale_name.toString()}\n\n${DataSingleton().Score.toString()}\n${DataSingleton().Interpretation.toString()}\n",
      300,
      textStyle: const TextStyle(
          fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      backgroundColor: Colors.white, // Set the desired background color here
    );
    setState(() {
      _bitmap = bitmap;
    });
  }

  Future<void> printBottomTicket() async {
    List<int> ticket = await printBottomBanner();
    bool result2 = await PrintBluetoothThermal.writeBytes(ticket);

    if (!result2) {
      if (kDebugMode) {
        print(
          "Failed to print the second ticket.",
        );
      }
    } else {}
  }

  Future<List<int>> printBottomBanner() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    if (DataSingleton().Disclaimer != null) {
      bytes += generator.text(
        'Disclaimer :',
        styles: const PosStyles(
          fontType: PosFontType.fontB,
        ),
      );

      bytes += generator.text(
        '${DataSingleton().Disclaimer}',
        styles: const PosStyles(
          fontType: PosFontType.fontB,
        ),
      );
      bytes += generator.feed(2);
    }

    String base64String = DataSingleton().bottom_logo?.replaceAll(
      "data:image/png;base64,",
      "",
    ) ??
        "";

    if (DataSingleton().bottom_logo != null) {
      bytesImg = base64.decode(base64String);
      img.Image? image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image.width ~/ 1.5,
          height: image.height ~/ 1.6,
          interpolation: img.Interpolation.linear,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }

      if (Platform.isAndroid) {
        final resizedImage = img.copyResize(
          image!,
          width: 300,
          height: 80,
          interpolation: img.Interpolation.cubic,
        );
        final bytesimg = Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
          ),
        );
        image = img.decodeImage(
          bytesimg,
        );
      }

      if (image != null) {
        bytes += generator.imageRaster(
          image,
        );
        bytes += generator.feed(2);
      }
    }

    bytes += generator.text('******THANK YOU******',
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(
      '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
      styles: const PosStyles(
        align: PosAlign.center,
      ),
    );

    String checkPlatformAPPVersion = Platform.version;
    print('checkkkkkkkkkkkk $checkPlatformAPPVersion');
    String versionShortform = "";

    if(checkPlatformAPPVersion.contains("android")){
      versionShortform = "A";
    }else{
      versionShortform = "I";
    }


    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;

    bytes += generator.text('v.$versionShortform-$appVersion',
        styles: const PosStyles(align: PosAlign.right,fontType: PosFontType.fontB,));

    bytes += generator.feed(4);

    return bytes;
  }
}
