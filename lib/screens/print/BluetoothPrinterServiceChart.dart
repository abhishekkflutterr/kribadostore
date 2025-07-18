import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:kribadostore/DataSingleton.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'dart:async';
import 'dart:convert';

class Bluetoothprinterservicechart {
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
        List<int> ticket = await charTicket();
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

  Future<List<int>> charTicket() async {
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
        bytes += generator.text("\n");
      }
    }

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

    patientName = DataSingleton().Patient_namechart;
    age = DataSingleton().Patient_agechart;
    gender = DataSingleton().pat_gender;

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
        interpolation: img.Interpolation.cubic,
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

    bytes += generator.feed(1);

    bytes += generator.text('Height: ' "${DataSingleton().heightinter}" '\n',
        styles: const PosStyles(align: PosAlign.center));

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
        interpolation: img.Interpolation.cubic,
      );

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

    bytes += generator.feed(1);

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

    String base64String2 = DataSingleton().bottom_logo?.replaceAll(
              "data:image/png;base64,",
              "",
            ) ??
        "";

    if (DataSingleton().bottom_logo != null) {
      bytesImg = base64.decode(base64String2);
      img.Image? image = img.decodeImage(bytesImg);

      if (Platform.isIOS) {
        final resizedImage = img.copyResize(
          image!,
          width: image.width ~/ 1.3,
          height: image.height ~/ 1.2,
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

    return bytes;
  }
}
