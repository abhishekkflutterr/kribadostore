import 'package:get/get.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<pw.Text>> addDocAndPatientInfo() async {
  String? patientName = DataSingleton().Patient_name;
  String? age = DataSingleton().Patient_age;
  String? gender = DataSingleton().Patient_gender;
  String? doctor = DataSingleton().doc_name;

  String patientInfo = "", doctorInfo = "";

  if (patientName!.isNotEmpty) {
    patientInfo += 'Name: ${patientName.toString().capitalize}\n';
  }

  if (age != null) {
    patientInfo += 'Age: $age\n';
  }

  if (gender != null) {
    patientInfo += 'Gender: ${gender.toString().capitalize}\n';
  }

  if (doctor != null) {
    doctorInfo += 'Name: $doctor\n';
  }

  List<pw.Text> patinetAndDoctor = [
    if (doctor != null) ...[
      //Doctor Information
      pw.Text(
        "Doctor Information",
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontWeight: pw.FontWeight.bold,
          fontSize: PdfComponents().titleFontSize,
        ),
      ),
      pw.Text(
        doctorInfo,
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontSize: PdfComponents().subtitleFontSize,
        ),
      ),
    ],

    if (patientInfo != null || patientInfo.isNotEmpty) ...[
      pw.Text(
        "\nPatient Information",
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontWeight: pw.FontWeight.bold,
          fontSize: PdfComponents().titleFontSize,
        ),
      ),
      pw.Text(
        "$patientInfo \n\n",
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontSize: PdfComponents().subtitleFontSize,
        ),
      ),
    ],
    //Patient Info
  ];
  return patinetAndDoctor;
}
