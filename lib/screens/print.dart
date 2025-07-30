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

class _PrintChartScreenState extends State<PrintScreen>
    with WidgetsBindingObserver {
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

  // --- DUMMY DATA FOR LOCAL TESTING OF TICKET SECTIONS ---
  // Each entry represents a different ticket with a different order

  // -------------------------------------------------------

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
        print("comiing in IOS automatic print");
        _retrieveAndConnectPrinter();
        print("comiing in IOS automatic print after retrieve and connect");
        Future.delayed(const Duration(seconds: 10), () {
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
            Future.delayed(const Duration(milliseconds: 2800), () {
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
        print("Connected to printer with MAC: $mac");
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
      Future.delayed(const Duration(milliseconds: 9500), () {
        setState(
          () {
            Navigator.of(context).pop();
          },
        );
      });
    }
  }

  Future<List<int>> generateBasicTicket() async {
    final Map<String, int>? headerSectionOrder =
        DataSingleton().headerSectionOrder;
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    bytes += generator.reset();

    // Sort sections by order
    final sortedSections = headerSectionOrder!.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (var section in sortedSections) {
      switch (section.key) {
        case "TOP_LOGO":
          final topLogo = DataSingleton().top_logo;
          if (topLogo != null) {
            final base64String =
                topLogo.replaceAll("data:image/png;base64,", "");
            final bytesImg = base64.decode(base64String);
            img.Image? image = img.decodeImage(bytesImg);

            if (Platform.isIOS) {
              final resized = img.copyResize(image!,
                  width: image.width ~/ 1.5,
                  height: image.height ~/ 1.6,
                  interpolation: img.Interpolation.linear);
              image =
                  img.decodeImage(Uint8List.fromList(img.encodeJpg(resized)));
            } else if (Platform.isAndroid) {
              final resized = img.copyResize(image!, width: 300, height: 80);
              image =
                  img.decodeImage(Uint8List.fromList(img.encodeJpg(resized)));
            }

            if (image != null) {
              Platform.isIOS
                  ? bytes += generator.image(image)
                  : bytes += generator.image(image);
            }
          }
          break;

        case "DOCTOR_NAME":
          String? docName = DataSingleton().doc_name;
          if (docName != null && docName.isNotEmpty) {
            String name =
                docName[0].toUpperCase() + docName.substring(1).toLowerCase();
            if (!name.toLowerCase().startsWith("dr.")) {
              name = "Dr. $name";
            }
            bytes += generator.feed(2);
            bytes += generator.text("Doctor Name - $name",
                styles: const PosStyles(align: PosAlign.center));
          }
          break;

        case "PATIENT_DETAILS":
          final name = DataSingleton().pat_name;
          final age = DataSingleton().pat_age;
          final gender = DataSingleton().pat_gender;

          String info = "";
          if (name != null && name.isNotEmpty) info += '\nName: $name';
          if (age != null && age.isNotEmpty) info += '\nAge: $age';
          if (gender != null && gender.isNotEmpty)
            info += '\nGender: $gender\n';

          if (info.isNotEmpty) {
            bytes += generator.text('- - - - - - - - - - - - - - - - ',
                styles: const PosStyles(align: PosAlign.center));
            bytes += generator.text("Patient Information",
                styles: const PosStyles(align: PosAlign.center));
            bytes += generator.text(info,
                styles: const PosStyles(align: PosAlign.center));
            bytes += generator.text('- - - - - - - - - - - - - - - - ',
                styles: const PosStyles(align: PosAlign.center));
          }
          break;
      }
    }

    return bytes;
  }

  Future<void> printTicket1() async {
    try {
      isPrintComplete = false;

      showPrintingDialog(context);
      bool? result;
      if (Platform.isIOS) {
        if (scale_id.toString().contains('Regional')) {
          // This likely prints the second ticket
          regionalPrintFirstTicket();
          Future.delayed(const Duration(milliseconds: 1600), () {
            regionalPrintsecondTicketIOS();
          });

          Future.delayed(const Duration(milliseconds: 800), () {
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
          print("Comes in Android Regional Print");
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

      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      if (kDebugMode) {
        print("E Strig$e");
      }
    }
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    bytes += generator.reset();

    final headerOrder = DataSingleton().headerSectionOrder ?? {};
    final detailOrder = DataSingleton().detailSectionOrder ?? {};
    final questionAnsFormting = DataSingleton().questionAnsFormting ?? {};

    final Map<String, Future<void> Function()> allSections = {
      "TOP_LOGO": () async {
        final base64String = DataSingleton()
                .top_logo
                ?.replaceAll("data:image/png;base64,", "") ??
            "";
        if (base64String.isNotEmpty) {
          Uint8List bytesImg = base64.decode(base64String);
          img.Image? image = img.decodeImage(bytesImg);
          if (image != null) {
            if (Platform.isIOS) {
              image = img.decodeImage(Uint8List.fromList(img.encodeJpg(
                img.copyResize(image,
                    width: image.width ~/ 1.6,
                    height: image.height ~/ 1.8,
                    interpolation: img.Interpolation.linear),
              )));
            } else {
              image = img.decodeImage(Uint8List.fromList(img.encodeJpg(
                img.copyResize(image,
                    width: 300,
                    height: 80,
                    interpolation: img.Interpolation.cubic),
              )));
            }
            if (image != null) bytes += generator.image(image);
          }
        }
      },
      "DOCTOR_NAME": () async {
        String? name = DataSingleton().doc_name;
        if (name != null && name.isNotEmpty) {
          name = name[0].toUpperCase() + name.substring(1);
          if (!name.toLowerCase().startsWith("dr.")) name = "Dr. $name";
          bytes += generator.feed(2);
          bytes += generator.text("Doctor Name - $name",
              styles: const PosStyles(align: PosAlign.center));
        }
      },
      "PATIENT_DETAILS": () async {
        String? name = DataSingleton().pat_name;
        String? age = DataSingleton().pat_age;
        String? gender = DataSingleton().pat_gender;
        String info = "";
        if (name != null && name.isNotEmpty)
          info += "\nName: ${name[0].toUpperCase()}${name.substring(1)}";
        if (age != null) info += "\nAge: $age";
        if (gender != null && gender.isNotEmpty)
          info +=
              "\nGender: ${gender[0].toUpperCase()}${gender.substring(1)}\n";

        if (info.isNotEmpty) {
          bytes += generator.text("- - - - - - - - - - - - - - - -",
              styles: const PosStyles(align: PosAlign.center));
          bytes += generator.text("Patient Information",
              styles: const PosStyles(align: PosAlign.center));
          bytes += generator.text(info,
              styles: const PosStyles(align: PosAlign.center));
          bytes += generator.text("- - - - - - - - - - - - - - - -",
              styles: const PosStyles(align: PosAlign.center));
        }
      },
      "RegionalImage": () async {
        if (scale_id.toString().contains('Regional')) {
          ui.Image image = await generateBitmapFromText(
            "${DataSingleton().scale_name}\n"
            "Score: ${DataSingleton().Score}\n"
            "${DataSingleton().Interpretation}\n\n",
            fontSize: 80.0,
            textColor: Colors.black,
            backgroundColor: Colors.white,
            width: 400,
            height: 300,
          );
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          final Uint8List imageBytes = byteData!.buffer.asUint8List();
          img.Image? image3 = img.decodeImage(imageBytes);

          if (_bitmap != null) {
            image3 = img.decodeImage(_bitmap!);
          }

          final resizedImage = img.copyResize(
            image3!,
            width: 300,
            height: Platform.isIOS ? 210 : 300,
            interpolation: Platform.isIOS
                ? img.Interpolation.linear
                : img.Interpolation.cubic,
          );
          final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
          final rasterImage = img.decodeImage(bytesimg);

          if (rasterImage != null) {
            Platform.isIOS
                ? bytes += generator.image(rasterImage)
                : bytes += generator.image(rasterImage);
          }
        }
      },
      "Scale_Name": () async {
        bytes += generator.text("${DataSingleton().scale_name}\n",
            styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                fontType: PosFontType.fontA));
      },
      "Score": () async {
        bytes += generator.text("Score: ${DataSingleton().Score}\n",
            styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                fontType: PosFontType.fontA));
      },
      "Interpretation": () async {
        bytes += generator.text("${DataSingleton().Interpretation}\n",
            styles: const PosStyles(align: PosAlign.center));
      },
      "QuestionsAnswer": () async {
        if (DataSingleton().questionAndAnswers == "True") {
          final inputs = DataSingleton().inputs;
          final responses = DataSingleton().resultDataformat;

          final titleMap = {for (var item in inputs) item['id']: item['title']};

          int i = 1;
          for (var r in responses) {
            final title = titleMap[r['question_id']] ?? '';
            final answer = r['answer'];
            final qSymbol = questionAnsFormting["question_symbol"] == "Q1"
                ? "Q$i."
                : questionAnsFormting["question_symbol"] == "1"
                    ? "$i."
                    : questionAnsFormting["question_symbol"] ?? '';
            final aSymbol = questionAnsFormting["answer_symbol"] ?? "Ans:-";

            bytes += generator.text("$qSymbol $title",
                styles: const PosStyles(align: PosAlign.left));
            bytes += generator.text("$aSymbol $answer\n",
                styles: const PosStyles(align: PosAlign.left));

            i++;
          }
        }
      },
      "SelectedOptionImage": () async {
        final base64String = DataSingleton()
                .option_selected_logo
                ?.replaceAll("data:image/png;base64,", "") ??
            "";
        if (base64String.isNotEmpty) {
          final bytesImg = base64.decode(base64String);
          img.Image? image = img.decodeImage(bytesImg);

          if (image != null) {
            if (Platform.isIOS) {
              image = img.decodeImage(Uint8List.fromList(img.encodeJpg(
                img.copyResize(image,
                    width: image.width ~/ 1.5,
                    height: image.height ~/ 1.6,
                    interpolation: img.Interpolation.linear),
              )));
            } else {
              image = img.decodeImage(Uint8List.fromList(img.encodeJpg(
                img.copyResize(image,
                    width: 300,
                    height: 300,
                    interpolation: img.Interpolation.cubic),
              )));
            }

            if (image != null) {
              bytes += Platform.isIOS
                  ? generator.image(image)
                  : generator.image(image);
              bytes += generator.feed(2);
            }
          }
        }
      },
      "Reference": () async {
        if (DataSingleton().References != null &&
            DataSingleton().References!.isNotEmpty) {
          bytes += generator.text("Reference : \n${DataSingleton().References}",
              styles: const PosStyles(
                  align: PosAlign.left, fontType: PosFontType.fontB));
        }
      },
    };

    final combinedOrder = <String, int>{};
    combinedOrder.addAll(headerOrder);
    detailOrder.forEach((key, value) => combinedOrder[key] = value + 100);

    final sortedKeys = combinedOrder.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final section in sortedKeys) {
      final func = allSections[section.key];
      if (func != null) await func();
    }

    bytes += generator.feed(1);
    bytes += generator.text('======================================',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    return bytes;
  }

  Future<List<int>> generateDetailedTicket() async {
    final Map<String, int>? detailSectionOrder =
        DataSingleton().detailSectionOrder;
    final Map<String, String>? questionAnsFormting =
        DataSingleton().questionAnsFormting;

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    Map<String, FutureOr<void> Function()> sections = {
      "RegionalImage": () async {
        if (!scale_id.toString().contains('Regional')) return;

        ui.Image image = await generateBitmapFromText(
          "${DataSingleton().scale_name}\n"
          "Score: ${DataSingleton().Score}\n"
          "${DataSingleton().Interpretation}\n\n",
          fontSize: 80.0,
          textColor: Colors.black,
          backgroundColor: Colors.white,
          width: 400,
          height: 300,
        );

        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List imageBytes = byteData!.buffer.asUint8List();
        img.Image? image3 = img.decodeImage(imageBytes);

        if (_bitmap != null) {
          image3 = img.decodeImage(_bitmap!);
        }

        final resizedImage = img.copyResize(
          image3!,
          width: 300,
          height: Platform.isIOS ? 210 : 300,
          interpolation: Platform.isIOS
              ? img.Interpolation.cubic
              : img.Interpolation.cubic,
        );

        final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
        final rasterImage = img.decodeImage(bytesimg);

        if (rasterImage != null) {
          Platform.isIOS
              ? bytes += generator.image(
                  rasterImage,
                )
              : bytes += generator.image(rasterImage);
        }
      },
      "Scale_Name": () async {
        if (scale_id.toString().contains('Regional')) return;
        bytes += generator.text(
          '${DataSingleton().scale_name}\n',
          styles: const PosStyles(
              align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
        );
      },
      "Score": () async {
        if (!scale_id.toString().contains('Regional')) {
          bytes += generator.text(
            'Score: ${DataSingleton().Score}\n',
            styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                fontType: PosFontType.fontA),
          );
        }
      },
      "Interpretation": () async {
        if (scale_id.toString().contains('Regional')) return;

        bytes += generator.text(
          '${DataSingleton().Interpretation}\n',
          styles: const PosStyles(align: PosAlign.center),
        );
      },
      "Reference": () async {
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
      },
      "QuestionsAnswer": () async {
        if (DataSingleton().questionAndAnswers == "True") {
          List<dynamic> inputsScale = DataSingleton().inputs;
          Map<int, String> questionTitleMap = {
            for (var input in inputsScale) input['id']: input['title']
          };
          List<Map<String, dynamic>> questions =
              DataSingleton().resultDataformat;

          int a = 0;
          for (var response in questions) {
            String? title = questionTitleMap[response['question_id']];
            String answer = response['answer'];
            a++;

            // Determine question symbol format
            String symbol;
            if (questionAnsFormting?["question_symbol"] == "Q1") {
              symbol = "Q$a.";
            } else if (questionAnsFormting?["question_symbol"] == "1") {
              symbol = "$a.";
            } else {
              symbol = questionAnsFormting?["question_symbol"] ?? "";
            }

            // Answer label
            String answerSymbol =
                questionAnsFormting?["answer_symbol"] ?? "Ans:-";

            bytes += generator.text(
              "$symbol $title\n$answerSymbol $answer\n",
              styles: const PosStyles(align: PosAlign.left),
            );
          }
        }
      },
      "SelectedOptionImage": () async {
        if (DataSingleton().option_selected_logo != null &&
            DataSingleton().option_selected_logo!.isNotEmpty) {
          String base64String = DataSingleton()
              .option_selected_logo!
              .replaceAll("data:image/png;base64,", "");
          Uint8List bytesImg = base64.decode(base64String);
          img.Image? image = img.decodeImage(bytesImg);

          final resizedImage = img.copyResize(
            image!,
            width: 300,
            height: 300,
            interpolation: img.Interpolation.linear,
          );
          image =
              img.decodeImage(Uint8List.fromList(img.encodeJpg(resizedImage)));

          if (image != null) {
            bytes += generator.image(image);
          }
        }
      },
    };

    final sortedKeys = detailSectionOrder!.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in sortedKeys) {
      final sectionFunction = sections[entry.key];
      if (sectionFunction != null) {
        await sectionFunction();
      }
    }

    // Divider and footer
    bytes += generator.text(
      '===================================',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(1);

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
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                if (_msj ==
                        "Go to settings & check in settings that the permission of nearby devices is 'Allowed'." &&
                    Platform.isAndroid)
                  ElevatedButton(
                    onPressed: () async {
                      AppSettingsHelper.openAppInfo();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // ✅ Set border radius
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12), // ✅ Add padding
                    ),
                    child: Text(
                      "Open Settings",
                      style: TextStyle(color: Colors.white),
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
                        if (Platform.isAndroid) {
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
                        } else if (Platform.isIOS) {
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
        Platform.isIOS
            ? bytes += generator.image(
                image,
              )
            : bytes += generator.image(
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

    if (checkPlatformAPPVersion.contains("android")) {
      versionShortform = "A";
    } else {
      versionShortform = "I";
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;

    bytes += generator.text('v.$versionShortform-$appVersion',
        styles: const PosStyles(
          align: PosAlign.right,
          fontType: PosFontType.fontB,
        ));

    bytes += generator.feed(4);

    return bytes;
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
}
