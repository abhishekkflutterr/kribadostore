import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/screens/pdf/doctor_patient.dart';
import 'package:kribadostore/screens/pdf/question_answer.dart';
import 'package:kribadostore/screens/pdf/reference_disclaimer.dart';
import 'package:kribadostore/screens/pdf/score_interpretation.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfComponents {
  dynamic ttf;
  dynamic doc;
  double titleFontSize = 25;
  double subtitleFontSize = 20;
  double disclaimerFontSize = 20;
  Directory? directory;
  Uint8List? bottomLogo;
  Uint8List? topLogo;
  Uint8List? selectedImageAnswer;

  String versionShortform = "";

  String appVersion = "";

  Future<void> initializePdf() async {
    final ByteData fontData =
        await rootBundle.load('fonts/Quicksand-Regular.ttf');
    ttf = pw.Font.ttf(fontData);
    doc = pw.Document();
  }

  Future<void> initializeSingleTonLogos() async {
    String? bottomlogoBase64 = DataSingleton().bottom_logo?.replaceAll(
          "data:image/png;base64,",
          "",
        );

    String? topLogoBase64 = DataSingleton().top_logo?.replaceAll(
          "data:image/png;base64,",
          "",
        );

    String? selectedImageAnswerBase64 =
        DataSingleton().option_selected_logo?.replaceAll(
                  "data:image/png;base64,",
                  "",
                ) ??
            "";

    bottomLogo =
        bottomlogoBase64 != null ? base64Decode(bottomlogoBase64) : null;

    topLogo = topLogoBase64 != null ? base64Decode(topLogoBase64) : null;

    selectedImageAnswer = selectedImageAnswerBase64 != null
        ? base64Decode(selectedImageAnswerBase64)
        : null;
  }

  pw.Image? logo(Uint8List logoName) {
    return pw.Image(
      pw.MemoryImage(logoName),
      fit: pw.BoxFit.contain,
      width: 300,
      height: 300,
    );
  }

  Future<void> generatePdf(
      BuildContext context, String score, String interpretation) async {
    await initializePdf();
    await initializeSingleTonLogos();

    String checkPlatformAPPVersion = Platform.version;
    print('checkkkkkkkkkkkk $checkPlatformAPPVersion');

    if (checkPlatformAPPVersion.contains("android")) {
      versionShortform = "A";
    } else {
      versionShortform = "I";
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    // Defensive null check for addDocAndPatientInfo
    List<pw.Text> doctorAndPatient = [];
    try {
      final docPatient = await addDocAndPatientInfo();
      if (docPatient != null) {
        doctorAndPatient = docPatient;
      }
    } catch (e) {
      print("Error in addDocAndPatientInfo: $e");
    }

    List<pw.Text> referenceAndDisclaimer = await disclaimerAndReference();
    List<pw.Text> scoreAndInterpreation =
        await scoreAndInterpreatation(score, interpretation);

    List<pw.Text> questionAndAnswer = await getQuestionAndAnswer();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          MediaQuery.of(context).size.width + 100,
          double.infinity,
          marginAll: 25,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              //TopLogo
              if (topLogo != null)
                pw.Center(
                  child: logo(
                    topLogo!,
                  ),
                ),
              pw.SizedBox(height: 10),

              //Doctor & Patient Info
              ...doctorAndPatient,
              pw.SizedBox(
                height: 5,
              ),

              // Score & Interpretation
              ...scoreAndInterpreation,

              pw.SizedBox(
                height: 5,
              ),

              // Selected Image Answer
              if (DataSingleton().option_selected_logo != null &&
                  DataSingleton().option_selected_logo!.isNotEmpty) ...[
                pw.Center(
                  child: logo(selectedImageAnswer!),
                ),
              ],

              //Question & Answer
              if (DataSingleton().questionAndAnswers == "True") ...[
                ...questionAndAnswer,
                pw.SizedBox(
                  height: 10,
                ),
              ],

              //Reference & Discalimer
              ...referenceAndDisclaimer,
              pw.SizedBox(
                height: 10,
              ),

              //BottomLogo
              if (bottomLogo != null)
                pw.Center(
                  child: logo(
                    bottomLogo!,
                  ),
                ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'v.$versionShortform-$appVersion',
                    style: pw.TextStyle(font: ttf),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> downloadPdf(
      BuildContext context, String score, String interpretation) async {
    await generatePdf(context, score, interpretation);
    try {
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

      String path = directory!.path;
      String myFile =
          '$path/${DataSingleton().pat_name}_${DataSingleton().getCurrentDateTimeInIST()}.pdf';
      final file = File(myFile);

      await file.writeAsBytes(await doc.save());
      OpenFile.open(myFile);
    } catch (e) {
      CustomSnackbar.showErrorSnackbar(
        title: 'Error',
        message: 'Failed to save or open the PDF: $e',
      );
    }
  }
}
