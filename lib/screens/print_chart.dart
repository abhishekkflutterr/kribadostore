import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/helper/sharedpref_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../DataSingleton.dart';
import '../custom_widgets/customappbar.dart';

class PrintChartScreen extends StatefulWidget {
  const PrintChartScreen({super.key});

  @override
  _PrintChartScreenState createState() => _PrintChartScreenState();
}

class _PrintChartScreenState extends State<PrintChartScreen> {
  bool connected = false;
  List<BluetoothInfo> items = [];
  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  bool _disconnectTimerActive =
      false; // Flag to track if the disconnect timer is active

  String _msj = '';
  String? _printerMacAddress; // Store the MAC address globally
  bool _progress = false;
  int? selectedIndex;
  bool isConnectionComplete = true;
  late Uint8List bytesImg; // To track the selected index
  bool printfirstticketflag = false;
  bool printsecondticketflag = false;
  bool printthirdticketflag = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    DataSingleton().skip_reinsert_print_btn = true;

    // Call checkPermissions only for Android
    if (Platform.isAndroid) {
      checkPermissions();
    }
    _retrieveAndConnectPrinter();
  }

  Future<void> _retrieveAndConnectPrinter() async {
    String? mac = await SharedprefHelper.getUserData("printer");

    if (mac != null && mac.isNotEmpty) {
      try {
        await connect(mac); // Await the connect method as well
      } catch (e) {
        print("Not Connected Due to $e");
      }
    } else {
      print("Mac is Empty");
    }
  }

  @override
  @protected
  void dispose() async {
    super.dispose();


     if(Platform.isAndroid){
    //await disconnect();

      if(connected){
    await  disconnect();

      }
     } else {

      if(connected){
      disconnect();

      }
     }
    
  }

  get scale_id => DataSingleton().scale_id;

  Future<void> checkPermissions() async {
    await checkPermission(Permission.bluetoothConnect);
    await checkPermission(Permission.bluetoothScan);
  }

  Future<void> checkPermission(Permission permission) async {
    final status = await permission.request();
    String permissionName;
    switch (permission) {
      case Permission.bluetooth:
        permissionName = 'Bluetooth';
        break;
      default:
        permissionName = 'Unknown';
    }
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$permissionName permission is granted"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$permissionName permission is not granted",
          ),
        ),
      );
    }
  }

  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
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
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(
      () {
        connected = false;
        _msj = "";
        selectedIndex = -1;
      },
    );
    if (kDebugMode) {
      print(
        "status disconnect $status",
      );
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

        if (Platform.isAndroid) {
          await printTopTicket();
          await printTicket1();
          await printTicket2();
          await printBottomTicket();
        } else if (Platform.isIOS) {
          if (DataSingleton().top_logo != null) {
            printTopTicket();
          }

          Future.delayed(const Duration(milliseconds: 1500), () {
            printTicket1();
          });

          Future.delayed(const Duration(milliseconds: 3000), () {
            printTicket2();
          });

          Future.delayed(const Duration(milliseconds: 4500), () {
            disconnectAndPrintBottomTicket();
          });
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

  Future<void> disconnectAndPrintFirstTicket() async {
    try {
      if (Platform.isIOS) {
        try {
          // Disconnect the printer
          await disconnect();
          if (_printerMacAddress != null) {
            // Reconnect to the previously connected MAC address
            await connect(_printerMacAddress!);
            // Print the first ticket directly
            printTicket1();

            if (!_disconnectTimerActive) {
              _disconnectTimerActive = true;
              Timer(const Duration(seconds: 2), () {
                printTicket2(); // Disconnect and start printing the second ticket
                if (kDebugMode) {
                  print(
                    "Printer disconnected due to inactivity.",
                  );
                }
                _disconnectTimerActive = false; // Reset the flag
              });
            }

            // Find the index of the newly connected printer in the items list
            final connectedPrinterIndex = items
                .indexWhere((item) => item.macAdress == _printerMacAddress);
            if (connectedPrinterIndex != -1) {
              setState(() {
                selectedIndex = connectedPrinterIndex;
              });
            }
            Timer(const Duration(seconds: 10), () {
              disconnectAndPrintBottomTicket();
            });
          } else {
            if (kDebugMode) {
              print(
                "No previous printer MAC address found.",
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              "Error in disconnectAndPrintSecondTicket: $e",
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          "Error in disconnectAndPrintSecondTicket: $e",
        );
      }
    }
  }

  Future<void> disconnectAndPrintBottomTicket() async {
    try {
      if (Platform.isIOS) {
        try {
          // Disconnect the printer
          await disconnect();
          if (_printerMacAddress != null) {
            // Reconnect to the previously connected MAC address
            await connect(_printerMacAddress!);
            // Print the first ticket directly
            printBottomTicket();
          } else {
            if (kDebugMode) {
              print(
                "No previous printer MAC address found.",
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              "Error in disconnectAndPrintSecondTicket: $e",
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          "Error in disconnectAndPrintSecondTicket: $e",
        );
      }
    }
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    printfirstticketflag = false;

    bytes += generator.text(
      '${DataSingleton().scale_name}' '\n',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

    bytes += generator.text(
      '- - - - - - - - - - - - - - - - ',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    String? patientName, age, gender;

    if (DataSingleton().Patient_namechart != null) {
      patientName = '${(DataSingleton().Patient_namechart ?? patientName)?.substring(0, 1).toUpperCase()}${(DataSingleton().Patient_namechart ?? patientName)?.substring(1)}';
      gender =  '${(DataSingleton().pat_gender ?? gender)?.substring(0, 1).toUpperCase()}${(DataSingleton().pat_gender ?? gender)?.substring(1)}';

    }

    // patientName = DataSingleton().Patient_namechart;
    age = DataSingleton().Patient_agechart;
    // gender = DataSingleton().pat_gender;

    String patientInfo = "";

// Check if patient name is not null before adding to patientInfo
    if (patientName != null) {
      patientInfo += '\nPatient Name: $patientName';
    }

// Check if patient age is not null before adding to patientInfo
    if (age != null) {
      patientInfo += '\nPatient Age: $age';
    }

// Check if patient gender is not null before adding to patientInfo
    if (gender != null) {
      patientInfo += '\nPatient Gender: $gender\n';
      if (kDebugMode) {
        print("Gender$gender");
      }
    }

    if (DataSingleton().pat_height != null) {
      patientInfo += '\nPatient Height:${DataSingleton().pat_height}';
      if (kDebugMode) {
        // print("Gender$DataSingleton().pat_height");
      }
    }

    if (DataSingleton().pat_weight != null) {
      patientInfo += '\nPatient Weight:${DataSingleton().pat_weight}';
      if (kDebugMode) {
        //print("Gender$DataSingleton().pat_height");
      }
    }

    if (patientInfo.isNotEmpty) {
      bytes += generator.text(
        patientInfo,
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    if (patientName != null || age != null || gender != null) {
      bytes += generator.text(
        '- - - - - - - - - - - - - - - - \n',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );
    }

    String? base64String3 = DataSingleton().pngBytesChart1?.replaceAll(
          "data:image/png;base64,",
          "",
        );
    final Uint8List bytesImg1 = base64.decode(base64String3!);
    img.Image? image3 = img.decodeImage(
      bytesImg1,
    );

    if (Platform.isIOS) {
      // Resizes the image to half its original size and reduces the quality to 80%
      final resizedImage = img.copyResize(
        image3!,
        width: 288,
        height: 196,
        interpolation: img.Interpolation.linear,
      );

      final bytesimg = Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
        ),
      );
      image3 = img.decodeJpg(
        bytesimg,
      );
    } else if (Platform.isAndroid) {
      final resizedImage = img.copyResize(
        image3!,
        width: 420,
        height: 400,
        interpolation: img.Interpolation.cubic,
      );
      final bytesimg = Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
        ),
      );
      image3 = img.decodeImage(
        bytesimg,
      );
    }

    if (image3 != null) {
      // bytes += generator.image(image);
      bytes += generator.imageRaster(image3);
    }

    bytes += generator.feed(2);

    bytes += generator.text('Height: ' "${DataSingleton().heightinter}" '\n',
        styles: const PosStyles(align: PosAlign.center));
    printfirstticketflag = true;
    return bytes;
  }

  Future<List<int>> testTicket1() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    bytes += generator.reset();

    printsecondticketflag = false;

    String? base64String4 = DataSingleton().pngBytesChart2?.replaceAll(
          "data:image/png;base64,",
          "",
        );

    final Uint8List bytesImg4 = base64.decode(base64String4!);
    img.Image? image4 = img.decodeImage(
      bytesImg4,
    );

    if (Platform.isIOS) {
      final resizedImage = img.copyResize(
        image4!,
        width: 267,
        height: 182,
        interpolation: img.Interpolation.linear,
      );

      // Fluttertoast.showToast(
      //     msg: "Before Resizing :- \n Height:-  $height  \n Width:- $width \n\n After Resizing :-  \n Height:-  $afterHeight  \n Width:- $afterWidth \n\n ",
      //     toastLength: Toast.LENGTH_LONG,
      //     gravity: ToastGravity.CENTER,
      //     timeInSecForIosWeb: 15,
      //     backgroundColor: Colors.red,
      //     textColor: Colors.white,
      //     fontSize: 16.0
      // );

      final bytesimg = Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
        ),
      );
      image4 = img.decodeJpg(
        bytesimg,
      );
    } else if (Platform.isAndroid) {
      final resizedImage = img.copyResize(
        image4!,
        width: 420,
        height: 400,
        interpolation: img.Interpolation.cubic,
      );
      final bytesimg = Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
        ),
      );
      image4 = img.decodeImage(
        bytesimg,
      );
    }
    if (image4 != null) {
      // bytes += generator.image(image);
      bytes += generator.imageRaster(
        image4,
      );
    }

    bytes += generator.feed(2);

    bytes += generator.text(
      'Weight: ' "${DataSingleton().weightinter}" '\n',
      styles: const PosStyles(
        align: PosAlign.center,
      ),
    );

    bytes += generator.text(
      '- - - - - - - - - - - - - - - - \n',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

    // if(DataSingleton().qr_label != null) {
    //   bytes += generator.text(
    //     '${DataSingleton().qr_label!}',
    //     styles: const PosStyles(
    //       align: PosAlign.center,
    //     ),
    //   );    }

//     String base64String1 =
//         DataSingleton().bottom_logo?.replaceAll("data:image/png;base64,", "") ??
//             "";
//
//     print("bottombase64 ${DataSingleton().bottom_logo}");
//
//     if (DataSingleton().bottom_logo != null) {
// // Decoding base64 string to obtain image bytes
//       final Uint8List bytesImg2 = base64.decode(base64String1!);
//       img.Image? image2 = img.decodeImage(bytesImg2);
//       // Resizing the image to the desired width and height
//       if (Platform.isAndroid) {
//         final resizedImage = img.copyResize(image2!,
//             width: 430, height: 170, interpolation: img.Interpolation.cubic);
//         final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
//         image2 = img.decodeImage(bytesimg);
//       } else if (Platform.isIOS) {
//         final resizedImage = img.copyResize(
//           image2!,
//           width: image2.width ~/ 1.6,
//           height: image2.height ~/ 1.8,
//           interpolation: img.Interpolation.cubic,
//         );
//         final bytesimg = Uint8List.fromList(
//           img.encodeJpg(
//             resizedImage,
//           ),
//         );
//         image2 = img.decodeImage(
//           bytesimg,
//         );
//       }
//
//       if (image2 != null) {
//         // bytes += generator.image(image);
//         bytes += generator.imageRaster(image2);
//       }
//     }

    // if(Platform.isIOS) {
    //   bytes += generator.text(
    //     '${DataSingleton().ios_qr_label}',
    //     styles: const PosStyles(
    //       align: PosAlign.center,
    //     ),
    //   );
    //
    //
    //   if (DataSingleton().ios_qr_url != null) {
    //     bytes += generator.qrcode(DataSingleton().ios_qr_url!);
    //   }
    // }

    bytes += generator.text(
      'Disclaimer:\n'
      "This is a customized service by Indigital Technologies LLP Although, great care has been taken in compiling and checking the information given in this service to ensure it is accurate, the author/s, the printer/s, the publisher/s and their servant/s or agent/s and purchaser/s shall not be responsible or in any way liable for any errors, omissions or inaccuracies whether arising from negligence or otherwise howsoever or due diligence of copyrights or for any consequences arising there from. In spite of best efforts the information in this service may become outdated over time. Indigital Technologies LLP accepts no liability for the completeness or use of the information contained in this service or its update."
      '\n',
      styles:
          const PosStyles(fontType: PosFontType.fontB, align: PosAlign.left),
    );

    bytes += generator.text(
      '******THANK YOU******',
      styles: const PosStyles(
        align: PosAlign.center,
      ),
    );
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

    printsecondticketflag = true;

    return bytes;
  }

  Future<void> printTicket1() async {
    List<int> ticket1 = await testTicket();
    bool result = await PrintBluetoothThermal.writeBytes(ticket1);

    if (!result) {
      if (kDebugMode) {
        print("Failed to print the second ticket.");
      }
    }
  }

  Future<void> printTicket2() async {
    List<int> ticket2 = await testTicket1();
    bool result2 = await PrintBluetoothThermal.writeBytes(
      ticket2,
    );

    if (!result2) {
      if (kDebugMode) {
        print(
          "Failed to print the second ticket.",
        );
      }
    }
  }

  Future<void> printTopTicket() async {
    List<int> ticket = await printTopBanner();
    bool result2 = await PrintBluetoothThermal.writeBytes(ticket);

    if (!result2) {
      if (kDebugMode) {
        print(
          "Failed to print the second ticket.",
        );
      }
    }
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
    }
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

    String base64String = DataSingleton().bottom_logo?.replaceAll(
              "data:image/png;base64,",
              "",
            ) ??
        "";

    if (DataSingleton().bottom_logo != null) {
      bytesImg = base64.decode(base64String!);
      img.Image? image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image.width ~/ 1.3,
          height: image.height ~/ 1.2,
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
          width: 400,
          height: 170,
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

    bytes += generator.feed(5);

    return bytes;
  }

  Future<List<int>> printTopBanner() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
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

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image.width ~/ 1.6,
          height: image.height ~/ 1.8,
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
        bytes += generator.imageRaster(image);
      }
    }

    bytes += generator.feed(2);

    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: /*CustomAppBar(
        title: 'Print Screen',
        showBackButton: true,
        showKebabMenu: true,
        pageNavigationTime:
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),*/
          CustomAppBar(
        title: 'Print Screen',
        showBackButton: true,
        showKebabMenu: false,
        pageNavigationTime:
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: Column(
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
                          await SharedprefHelper.deleteUserData("printer");

                          setState(() {
                            _progress = true;
                            isConnectionComplete =
                                false; // Disable the list during connection
                          });

                          _printerMacAddress = items[index].macAdress;

                          final bool result =
                              await PrintBluetoothThermal.connect(
                                  macPrinterAddress: items[index].macAdress);

                          if (result) {
                            setState(() {
                              _progress = false;
                              _msj = "Connected with ${items[index].name}";
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
              padding: const EdgeInsets.all(
                10.0,
              ),
              child: Text(
                _msj,
                style: TextStyle(
                    fontSize: 20, color: Theme.of(context).primaryColor),
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
                  if (connected) {
                    await SharedprefHelper.deleteUserData("printer");
                    disconnect();
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
              onPressed: _incrementCounter,
              text: 'Print',
              enabled: _isButtonEnabled,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  int _counter = 0;
  bool _isButtonEnabled = true;

  void _incrementCounter() {
    if (_isButtonEnabled && connected) {
      // Check if the button is enabled and the connection is established
      setState(() {
        _counter++;
        _isButtonEnabled = false; // Disable the button
      });
      printTest();
      _startCountdown();
    }
  }

  void _startCountdown() {
    Timer(const Duration(seconds: 20), () {
      setState(() {
        _isButtonEnabled = true; // Enable the button after 20 seconds
      });
    });
  }
}
