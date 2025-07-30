import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:kribadostore/DataSingleton.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothPrinterService {
  bool _connected = false;
  String optionprinttype = "58 mm";
  bool? isPrintComplete;
  late Uint8List bytesImg;
  img.Image? image;
  Uint8List? _bitmap;
  bool second_ticket = false;

  get scale_id => DataSingleton().scale_id;

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

  /// Check printer connection status
  bool isConnected() {
    return _connected;
  }

  /// Main method for printing tickets
  Future<void> printTicket1() async {
    try {
      isPrintComplete = false;

      bool? result;

      if (Platform.isAndroid) {
        if (scale_id.toString().contains('Regional')) {
          List<int> ticket1 = await generateBasicTicket();
          result = await PrintBluetoothThermal.writeBytes(ticket1);
        } else {
          List<int> ticket1 = await testTicket();
          result = await PrintBluetoothThermal.writeBytes(ticket1);
        }
        await disconnect();
      }

      if (!result!) {
        if (kDebugMode) {
          print("Failed to print the second ticket.");
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

  /// Generates the required ticket data
  Future<List<int>> generateTicket({required bool isBasic}) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    bytes += generator.reset();

    Future<void> addImage(String? base64String, int width, int height) async {
      if (base64String != null && base64String.isNotEmpty) {
        Uint8List imgBytes = base64.decode(base64String);
        img.Image? image = img.decodeImage(imgBytes);
        if (image != null) {
          final resizedImage = img.copyResize(
            image,
            width: width,
            height: height,
            interpolation: img.Interpolation.cubic,
          );
          bytes += generator.image(resizedImage);
        }
      }
    }

    // ---- HEADER SECTIONS ----
    final sortedHeader = DataSingleton().headerSectionOrder!.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (var section in sortedHeader) {
      switch (section.key) {
        case "TOP_LOGO":
          await addImage(
            DataSingleton().top_logo?.replaceAll("data:image/png;base64,", ""),
            Platform.isIOS ? 200 : 300,
            Platform.isIOS ? 60 : 80,
          );
          break;

        case "DOCTOR_NAME":
          String? name = DataSingleton().doc_name;
          if (name != null && name.isNotEmpty) {
            String formatted = name[0].toUpperCase() + name.substring(1);
            if (!formatted.toLowerCase().startsWith("dr")) {
              formatted = "Dr. $formatted";
            }
            bytes += generator.text(
              "Doctor Name - $formatted",
              styles: const PosStyles(align: PosAlign.center),
            );
          }
          break;

        case "PATIENT_DETAILS":
          String? pname = DataSingleton().pat_name;
          String? age = DataSingleton().pat_age;
          String? gender = DataSingleton().pat_gender;

          String patientInfo = '';
          if (pname != null && pname.isNotEmpty) {
            patientInfo += '\n\nName: $pname';
          }
          if (age != null) patientInfo += '\nAge: $age';
          if (gender != null) patientInfo += '\nGender: $gender';

          if (patientInfo.isNotEmpty) {
            bytes += generator.text(
              '- - - - - - - - - - - - - - - -',
              styles: const PosStyles(align: PosAlign.center, bold: true),
            );
            bytes += generator.text(
              "Patient Information",
              styles: const PosStyles(align: PosAlign.center),
            );
            bytes += generator.text(
              patientInfo,
              styles: const PosStyles(align: PosAlign.center),
            );
          }
          break;
      }
    }

    // ---- DETAIL SECTIONS ----
    final sortedDetail = DataSingleton().detailSectionOrder!.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (var section in sortedDetail) {
      switch (section.key) {
        case "RegionalImage":
          if (scale_id.toString().contains('Regional')) {
            ui.Image regionalImageData = await generateBitmapFromText(
              "${DataSingleton().scale_name}\n${DataSingleton().Score}\n${DataSingleton().Interpretation}\n",
              fontSize: 80.0,
              textColor: Colors.black,
              backgroundColor: Colors.white,
              width: 400,
              height: 300,
            );
            final ByteData? byteData = await regionalImageData.toByteData(
                format: ui.ImageByteFormat.png);
            final Uint8List imageBytes = byteData!.buffer.asUint8List();
            img.Image? regionalImage = img.decodeImage(imageBytes);
            if (_bitmap != null) {
              regionalImage = img.decodeImage(_bitmap!);
            }
            if (regionalImage != null) {
              final resizedImage = img.copyResize(
                regionalImage,
                width: 300,
                height: Platform.isIOS ? 210 : 300,
                interpolation: img.Interpolation.cubic,
              );
              bytes += generator.image(resizedImage);
            }
          }
          break;

        case "Scale_Name":
          bytes += generator.text("\n${DataSingleton().scale_name}\n",
              styles: const PosStyles(align: PosAlign.center, bold: true));
          break;

        case "Score":
          if (!scale_id.toString().contains('Regional')) {
            bytes += generator.text(
              'Score: ${DataSingleton().Score}\n',
              styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  fontType: PosFontType.fontA),
            );
          }

          break;

        case "Interpretation":
          bytes += generator.text("\n${DataSingleton().Interpretation}\n",
              styles: const PosStyles(align: PosAlign.center));
          break;

        case "QuestionsAnswer":
          if (DataSingleton().questionAndAnswers == "True") {
            final Map<String, String>? questionAnsFormting =
                DataSingleton().questionAnsFormting;

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
          ;

          break;

        case "SelectedOptionImage":
          await addImage(
            DataSingleton()
                .option_selected_logo
                ?.replaceAll("data:image/png;base64,", ""),
            300,
            300,
          );
          break;

        case "Reference":
          if (DataSingleton().References != null) {
            bytes += generator.text(
              'Reference :\n${DataSingleton().References}',
              styles: const PosStyles(
                align: PosAlign.left,
                fontType: PosFontType.fontB,
              ),
            );
          }
          break;
      }
    }

    // ---- DISCLAIMER & FOOTER ----
    if (DataSingleton().Disclaimer != null) {
      bytes += generator.text(
        '\n\nDisclaimer :',
        styles: const PosStyles(fontType: PosFontType.fontB),
      );
      bytes += generator.text(
        '${DataSingleton().Disclaimer}',
        styles: const PosStyles(fontType: PosFontType.fontB),
      );
    }

    bytes += generator.feed(2);

    await addImage(
      DataSingleton().bottom_logo?.replaceAll("data:image/png;base64,", ""),
      300,
      80,
    );

    bytes += generator.text(
      '******THANK YOU******',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '${DateTime.now().day}-'
      '${DateTime.now().month}-'
      '${DateTime.now().year} '
      '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);

    return bytes;
  }

  /// Public method for basic tickets
  Future<List<int>> generateBasicTicket() async {
    return await generateTicket(isBasic: true);
  }

  /// Public method for test tickets
  Future<List<int>> testTicket() async {
    return await generateTicket(isBasic: false);
  }

  /// Create an image from text
  Future<ui.Image> generateBitmapFromText(
    String text, {
    double fontSize = 80.0,
    Color textColor = Colors.black,
    Color backgroundColor = Colors.white,
    int width = 400,
    int height = 300,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint backgroundPaint = Paint()..color = backgroundColor;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      backgroundPaint,
    );

    final ui.ParagraphStyle paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
    );
    double currentFontSize = fontSize;

    ui.Paragraph paragraph;

    do {
      final TextStyle textStyle = TextStyle(
        color: textColor,
        fontSize: currentFontSize,
        fontWeight: FontWeight.bold,
      );
      final ui.ParagraphBuilder paragraphBuilder =
          ui.ParagraphBuilder(paragraphStyle)
            ..pushStyle(textStyle.getTextStyle())
            ..addText(text);
      paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width.toDouble()));
      if (paragraph.height > height) {
        currentFontSize -= 1;
      }
    } while (paragraph.height > height);

    final double textCenterX = (width - paragraph.width) / 2;
    final double textCenterY = (height - paragraph.height) / 2;

    canvas.drawParagraph(paragraph, Offset(textCenterX, textCenterY));

    return await pictureRecorder.endRecording().toImage(width, height);
  }

  /// Convert plain text to an image
  Future<ui.Image> textToImage(String text, double width,
      {TextStyle? textStyle, Color backgroundColor = Colors.white}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style:
              textStyle ?? const TextStyle(color: Colors.black, fontSize: 40)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width);

    double textHeight = textPainter.height;
    if (textHeight > 300) {
      textHeight = 300;
    }

    final Paint paint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, textHeight), paint);

    final double offsetX = (width - textPainter.width) / 2;
    final double offsetY = (textHeight - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));

    return await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), textHeight.toInt());
  }

  /// Convert text to bitmap
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

  /// Generates an internal image
  Future<void> _generateImage() async {
    final Uint8List? bitmap = await convertTextToBitmap(
      "${DataSingleton().scale_name.toString()}\n\n${DataSingleton().Score.toString()}\n${DataSingleton().Interpretation.toString()}\n",
      300,
      textStyle: const TextStyle(
          fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      backgroundColor: Colors.white,
    );
    _bitmap = bitmap;
  }
}
