import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
// import 'package:http/http.dart' as http;
import 'package:kribadostore/Camp.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/DatabaseHelper.dart';
import 'package:kribadostore/helper/sharedpref_helper.dart';
import 'package:kribadostore/screens/BrandsPrescription_screen.dart';
import 'package:kribadostore/screens/patient_details_screen.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:kribadostore/screens/print.dart';
import 'package:kribadostore/screens/print/BluetoothPrinterService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  const WebViewPage({super.key, required this.url});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  late final WebViewController _controller;
  bool isLoading = true;
  final BluetoothPrinterService printerService = BluetoothPrinterService();

  List<BluetoothInfo> items = [];
  String _msj = '';
  int printcount = 0;

  DataSingleton dataSingleton = DataSingleton();

  late DatabaseHelper _databaseHelper;
  bool _progress = false;

  String doctorName = "";
  List<Map<String, dynamic>> resources = [];

  final Map<String, dynamic> dataMap = {
    'doctorName': DataSingleton().doc_name ?? '',
    'patientName': DataSingleton().pat_name ?? '',
    'patientAge': DataSingleton().pat_age ?? '',
    'patientGender': DataSingleton().pat_gender ?? '',
    'meta': DataSingleton().meta ?? '',
  };






  @override
  void initState() {
    super.initState();

    _databaseHelper = DatabaseHelper.instance;
    fetchDoctors();


    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('Received JavaScript message: ${message.message}');
          _handleJavaScriptMessage(message.message);
        },
      )

      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) => _onPageFinished(),
        onWebResourceError: (error) {
          setState(() {
            _errorMessage = 'WebView error: ${error.description}';
            _isLoading = false;

            print("Data map before encoding: $dataMap");
            var encoedData = jsonEncode(dataMap);
            print("Data Map: $encoedData");
            try {
              _controller.runJavaScript('getDataFromApp($encoedData)');
            } catch (e) {
              print("Error in onPageFinished: $e");
            }

          });
        },
      ));
    _loadHtml();
  }

  Future<void> fetchDoctors() async {
    final List<Map<String, dynamic>> doctors =
    await _databaseHelper.getAlldoctors();

    print(' docotrs result screen  $doctors');

    if (doctors.isNotEmpty) {
      String docName = doctors.first['doc_name'];
      print('Doctor Name: $docName');
      setState(() {
        DataSingleton().doc_name = docName;
      });
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



  Future<void> _handleJavaScriptMessage(String message) async {
    try {
      final data = jsonDecode(message);

      String? action;
      dynamic payloadRaw;
      String? scaleName;

      if (data is String) {
        final nestedData = jsonDecode(data);
        action = nestedData['action'];
        payloadRaw = nestedData['payload'];
        scaleName = nestedData['scale_name'];
      } else {
        action = data['action'];
        payloadRaw = data['payload'];
        scaleName = data['scale_name'];
      }

      dynamic payload;
      if (payloadRaw is String) {
        payload = jsonDecode(payloadRaw);
        if (scaleName == null && payload['scale_name'] != null) {
          scaleName = payload['scale_name'];
        }
      } else {
        payload = payloadRaw;
      }

      if (payload != null && payload['printConfig'] != null) {
        final printConfig = payload['printConfig'];
        if (printConfig is String) {
          loadPrintingConfig(printConfig);
        } else if (printConfig is Map) {
          loadPrintingConfig(jsonEncode(printConfig));
        }
      }

      if (payload != null &&
          payload['results'] != null &&
          payload['results']['qna'] != null) {
        var qnaData = payload['results']['qna'];
        List<Map<String, dynamic>> formattedQA = [];
        List<Map<String, dynamic>> formattedInputs = [];
        qnaData.forEach((key, value) {
          formattedQA.add({
            'question_id': int.tryParse(value['question_id'].toString()) ?? 0,
            'title': value['title'],
            'answer': value['answer'],
            'score': value['score']
          });
          formattedInputs.add({
            'id': int.tryParse(value['question_id'].toString()) ?? 0,
            'title': value['title']
          });
        });
        DataSingleton().questionAndAnswers = "True";
        DataSingleton().resultDataformat = formattedQA;
        DataSingleton().inputs = formattedInputs;
      }

      print("Scale Name from message: $scaleName");

      String? interpretation;
      String? score;
      String? reference;
      print("Scale Name $scaleName");
      DataSingleton().scale_name = scaleName;

      if (payload != null &&
          payload['results'] != null &&
          payload['results']['interpretation'] != null) {
        interpretation = payload['results']['interpretation']
        ['finalInterpretation']
            ?.toString();
        score = payload['results']['interpretation']['finalResult']?.toString();
      } else if (payload != null && payload['interpretation'] != null) {
        interpretation =
            payload['interpretation']['finalInterpretation']?.toString();
        score = payload['interpretation']['finalResult']?.toString();
      }

      if (payload != null && payload['references'] != null) {
        reference = payload['references'];
      } else if (payload != null &&
          payload['results'] != null &&
          payload['results']['references'] != null) {
        reference = payload['results']['references'];
      }

      print('Score: $score');
      print('Reference: $reference');
      print('Interpretation: $interpretation');

      String asciiInterpretation = (interpretation ?? "")
          .replaceAll(RegExp(r'<br\s*/?>|&nbsp;'), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+\n'), '\n')
          .replaceAll(RegExp(r'\n+'), '\n')
          .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
          .trim();
      String asciiReference = (reference ?? "")
          .replaceAll(RegExp(r'<br\s*/?>|&nbsp;'), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+\n'), '\n')
          .replaceAll(RegExp(r'\n+'), '\n')
          .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
          .trim();

      DataSingleton().Interpretation = asciiInterpretation;
      DataSingleton().Score = score;
      DataSingleton().References = asciiReference;
      DataSingleton().scale_name = scaleName;

      if (action == 'submit') {
        _insertData(double.parse(score ?? '0'));
      }

      switch (action) {
        case 'submit':
          print("Submit action received with payload: $payload");
          break;

        case 'patient':
          Get.off(const PatientsDetailsScreen());
          break;
        case 'endcamp':
          Get.to(const BrandsPrescription());
          break;
        case 'print':
          try {
            String? deviceName = await getDeviceName();
            print("Device name: $deviceName");
            print("Print Count $printcount");

            if (["Alps Q1", "Alps JICAI Q1", "Q1", "JICAI Q2", "Z91"]
                .contains(deviceName)) {
              bool isBluetoothEnabled =
              await PrintBluetoothThermal.bluetoothEnabled;
              int batteryLevel = await PrintBluetoothThermal.batteryLevel;

              if (!isBluetoothEnabled) {
                Fluttertoast.showToast(msg: "Please Turn On Bluetooth");
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
                String printerType =
                deviceName == "Z91" ? "bluetoothprint" : "iposprinter";
                await handlePrinterSelection(context, printerType);
              } else {
                await handlePrinterConnection(context, bluetoothmac);
              }
            } else {
              String? mac = await SharedprefHelper.getUserData("printer");
              print("Mac address from shared preferences: $mac");
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
          } catch (e) {
            print("Error in print action: $e");
            Fluttertoast.showToast(msg: "Error connecting to printer");
          }
          break;
        case 'download':
          print(
              'download action received! DataSingleton().doc_name = ${DataSingleton().doc_name}');
          print("Download action received with payload: $payload");
          try {
            PdfComponents pdfComponents = PdfComponents();
            pdfComponents.downloadPdf(
              context,
              score ?? "",
              (interpretation ?? "")
                  .replaceAll(RegExp(r'<br\s*/?>|&nbsp;'), '\n')
                  .replaceAll(RegExp(r'<[^>]*>'), '')
                  .replaceAll(RegExp(r'\s+\n'), '\n')
                  .replaceAll(RegExp(r'\n+'), '\n')
                  .trim(),
            );
          } catch (e) {
            print("Getting $e while performing pdf operation");
          }
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unknown action: $action')),
          );
      }
    } catch (e) {
      print('Error handling JavaScript message: $e');
    }
  }


  Future<String?> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return null;
  }

  Future<void> handlePrinterSelection(
      BuildContext context, String printername) async {
    try {
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
      _showErrorDialog(context, e.toString());
      print("Error finding printer: $e");
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
        Navigator.of(dialogContext).pop();
      });
    } else {
      Fluttertoast.showToast(msg: "Unable to connect to printer");
      Navigator.of(dialogContext).pop();
    }
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

  void loadPrintingConfig(String jsonString) {
    final Map<String, dynamic> config = json.decode(jsonString);

    // Assigning to DataSingleton
    if (config['headerSectionOrder'] != null) {
      DataSingleton().headerSectionOrder =
      Map<String, int>.from(config['headerSectionOrder']);
    }
    if (config['detailSectionOrder'] != null) {
      DataSingleton().detailSectionOrder =
      Map<String, int>.from(config['detailSectionOrder']);
    }
    if (config['questionAnsFormting'] != null) {
      DataSingleton().questionAnsFormting =
      Map<String, String>.from(config['questionAnsFormting']);
    }
  }



  Future<void> _insertData(double final_result) async {
    String pat_id = DataSingleton().pat_id ?? '';
    String camp_date = DataSingleton().camp_date ?? '';
    String test_date = DataSingleton().test_date ?? '';
    String test_start_time = DataSingleton().test_start_time ?? '';
    String pat_age = DataSingleton().pat_age ?? '';
    String pat_name = DataSingleton().pat_name ?? '';
    String pat_gender = DataSingleton().pat_gender ?? '';
    String? scale_id = DataSingleton().scale_id;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final subscriber_id = prefs.getString('subscriber_id');
    final mr_id = prefs.getString('mr_id');

    try {
      int divNumeric = DataSingleton().division_id;
      await _databaseHelper?.insertCamp(Camp(
          camp_id: dataSingleton
              .generateMd5(
              "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}_${DataSingleton().division_id}_$subscriber_id")
              .toString(),
          camp_date: camp_date.toString(),
          test_date: test_date.toString(),
          test_start_time: test_start_time.toString(),
          test_end_time: dataSingleton.getCurrentDateTimeInIST(),
          created_at: dataSingleton.getCurrentDateTimeInIST(),
          scale_id: scale_id.toString(),
          test_score: final_result,
          interpretation: '${DataSingleton().Interpretation}',
          language: "en",
          pat_age: pat_age,
          pat_gender: pat_gender,
          pat_email: "NA",
          pat_mobile: "NA",
          pat_name: pat_name.toString(),
          pat_id: pat_id.toString(),
          answers: DataSingleton().resultDataformat.toString(),
          division_id: divNumeric,
          subscriber_id: subscriber_id.toString(),
          doc_speciality: DataSingleton().doc_speciality.toString(),
          mr_code: mr_id.toString(),
          dr_consent: DataSingleton().dr_consent,
          patient_consent: DataSingleton().patient_consent,
          country_code: DataSingleton().country_code.toString(),
          state_code: DataSingleton().state_code.toString(),
          city_code: DataSingleton().city_code.toString(),
          area_code: DataSingleton().area_code.toString(),
          doc_code: DataSingleton().doc_code.toString(),
          doc_name: DataSingleton().doc_name.toString(),
          dr_id: DataSingleton().dr_id.toString(),
          doctor_meta: DataSingleton().doctor_meta.toString(),
          patient_meta: DataSingleton().patient_meta.toString()));
      setState(() {});
      print("Database success Camp");
    } catch (e) {
      print("ERROR on scaeNav: $e");
    }
  }





  Future<void> _loadHtml() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final scaleId = DataSingleton().scale_id;
      print('fkjsksjfksfj $scaleId');

      if (scaleId == null || scaleId.isEmpty) {
        throw Exception('scale_id is not set.');
      }

      final fileName = 'scale_$scaleId.html';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);


     /* if (!await file.exists()) {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode == 200) {
          await file.writeAsString(response.body).then((_) async {
            print('✅ File saved. Now loading it...');
            await _controller.loadFile(file.path);
            setState(() => _isLoading = false);
          });
          return; // exit early so nothing runs below
        } else {
          throw Exception('Failed to download HTML for $scaleId');
        }
      }*/

      print('📄 Loading file: $filePath');
      await _controller.loadFile(file.path);
    } catch (e) {
      setState(() => _errorMessage = 'Error loading HTML: $e');
      print('❌ $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _onPageFinished() async {
    final jsonMap = {
      "title": "FSSG Form",
      "questions": [
        {"id": 1, "text": "How are you today?", "type": "text"}
      ]
    };
    final jsonStr = jsonEncode(jsonMap).replaceAll("'", r"\'");
    final jsCode = "generateForm('single', 'en', $jsonStr);";

    try {
      await _controller.runJavaScript(jsCode);
      debugPrint("✅ JS executed");
    } catch (e) {
      debugPrint("❌ JS error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Form')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : WebViewWidget(controller: _controller),
    );
  }
}

