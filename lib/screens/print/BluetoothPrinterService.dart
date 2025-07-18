import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:kribadostore/DataSingleton.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'dart:ui' as ui;

class BluetoothPrinterService {
  bool _connected = false;
  String optionprinttype = "58 mm";
  get scale_id => DataSingleton().scale_id;
  bool? isPrintComplete;
  late Uint8List bytesImg;
  img.Image? image;
  Uint8List? _bitmap;
  bool second_ticket = false;

  /// Connect to a Bluetooth printer by MAC address
  Future<bool> connect(String mac) async {
    try {
      bool result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      _connected = result;
      return result;
    } catch (e) {
      print("Error connecting to printer: $e");
      return false;
    }
  }

  /// Disconnect from the connected Bluetooth printer
  Future<bool> disconnect() async {
    try {
      bool result = await PrintBluetoothThermal.disconnect;
      _connected = false;
      return result;
    } catch (e) {
      print("Error disconnecting: $e");
      return false;
    }
  }

  /// Print a test ticket
  Future<bool> printTest() async {
    try {
      bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
      if (connectionStatus) {
        List<int> ticket = await testTicket();
        bool result = await PrintBluetoothThermal.writeBytes(ticket);
        print("Print result: $result");
        await disconnect();
        return result;
      } else {
        print("Printer not connected");
        return false;
      }
    } catch (e) {
      print("Error during printing: $e");
      return false;
    }
  }

  /// Check connection status
  bool isConnected() {
    return _connected;
  }

  Future<void> printTicket1() async {
    try {
      isPrintComplete = false;
      bool? result;

      if (Platform.isAndroid) {
        if (scale_id.toString().contains('Regional')) {
          List<int> ticket1 = await generateBasicTicket();
          // Print the basic ticket
          bool result = await PrintBluetoothThermal.writeBytes(ticket1);
          await disconnect();
        } else {
          List<int> ticket1 = await testTicket();
          bool result = await PrintBluetoothThermal.writeBytes(ticket1);
          await disconnect();
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
      bytesImg = base64.decode(base64String!);
      img.Image? image = img.decodeImage(bytesImg);

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
        bytes += generator.imageRaster(image);
      }
    }
    
    if (DataSingleton().doc_name != null) {
      // Capitalize the first letter
      String doctorName = DataSingleton().doc_name!;
      String capitalizedDocName =
          '${(DataSingleton().doc_name ?? doctorName).substring(0, 1).toUpperCase()}${(DataSingleton().doc_name ?? doctorName).substring(1)}';

      bytes += generator.feed(2);

      print('@@### before$capitalizedDocName');

      if (capitalizedDocName.startsWith("dr") ||
          capitalizedDocName.startsWith("dr.") ||
          capitalizedDocName.startsWith("dr. ") ||
          capitalizedDocName.startsWith("DR") ||
          capitalizedDocName.startsWith("DR.") ||
          capitalizedDocName.startsWith("DR. ")) {
        capitalizedDocName = "Dr. $capitalizedDocName";
      }

      print('@@### after' + capitalizedDocName);
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

// Check if patient name is not null before adding to patientInfo
    if (patientName!.isNotEmpty) {
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
    bytes += generator.text(
      '${DataSingleton().Scale_Name}' '\n',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

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
      if (DataSingleton().scale_id != "FSSG.Nepali.Regional.kribado") {
        bytes += generator.text(
          'Score: ' "${DataSingleton().Score}" '\n',
          styles: const PosStyles(align: PosAlign.center, bold: true),
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

    if (DataSingleton().scale_id == "ASCVD.risk.kribado" ||
        DataSingleton().scale_id == "ASCVD.risk.estimator.kribado" || DataSingleton().scale_id == "LipidProfileCustom.kribado") {
      bytes += generator.text(
        "(Calculated Risk)" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }

    //Addition for Ludwig Result Image
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

    bytes += generator.text(
      "${DataSingleton().Interpretation}" '\n',
      styles: const PosStyles(
        align: PosAlign.center,
      ),
    );

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

      // Print transformed responses
      for (var transformedResponse in transformedResponses) {
        print("transformedResponse   $transformedResponse");
      }

      num a = 0;
      // Iterate through the list of questions
      for (var question in transformedResponses) {
        String questionId = question['title'];
        String answer = question['answer'];

        a++;
        // Print each question_id and answer on a new line
        bytes += generator.text(
          'Q$a: $questionId',
          styles: const PosStyles(align: PosAlign.left),
        );

        bytes += generator.text(
          '$answer',
          styles: const PosStyles(align: PosAlign.left),
        );
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
    } else {
      print("Disclaimer is null");
    }

    String base64String1 = DataSingleton().bottom_logo?.replaceAll(
              "data:image/png;base64,",
              "",
            ) ??
        "";

    if (DataSingleton().bottom_logo != null) {
      bytesImg = base64.decode(base64String1);
      img.Image? image = img.decodeImage(bytesImg);

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

    bytes += generator.feed(3);

    //bytes += generator.cut();
    return bytes;
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
          interpolation: img.Interpolation.cubic,
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
      Fluttertoast.showToast(msg: "Comes else");

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
        if (DataSingleton().scale_id != "FSSG.Nepali.Regional.kribado") {
          bytes += generator.text(
            'Score: ' "${DataSingleton().Score}" '\n',
            styles: const PosStyles(align: PosAlign.center, bold: true),
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

      bytes += generator.text(
        "${DataSingleton().Interpretation}" '\n',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );

      if (DataSingleton().questionAndAnswers == "True") {
        List<dynamic> inputsScale = DataSingleton().inputs;
        print('jsfsjfsncxnczzz $inputsScale');

        Map<int, String> questionTitleMap = {};
        for (var input in inputsScale) {
          questionTitleMap[input['id']] = input['title'];
        }

        print("fisjfkxcmxkveiejfisfjs $questionTitleMap");

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

        print("sjsnfsjgnxnvxjvn $transformedResponses");

        for (var transformedResponse in transformedResponses) {
          print("transformedResponse   $transformedResponse");
        }

        num a = 0;
        for (var question in transformedResponses) {
          String questionId = question['title'];
          String answer = question['answer'];

          a++;
          bytes += generator.text(
            "$a. $questionId: $answer",
            styles: const PosStyles(
              align: PosAlign.left,
            ),
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

    String base64String3 = DataSingleton().bottom_logo?.replaceAll(
              "data:image/png;base64,",
              "",
            ) ??
        "";

    if (DataSingleton().bottom_logo != null) {
      bytesImg = base64.decode(base64String3);
      img.Image? image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image.width ~/ 1.5,
          height: image.height ~/ 1.6,
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

    bytes += generator.feed(1);

    return bytes;
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

    _bitmap = bitmap;
  }
}
