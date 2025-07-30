import 'package:get/get.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<pw.Text>> addDocAndPatientInfo() async {
  String? patientName = DataSingleton().pat_name;
  String? age = DataSingleton().pat_age;
  String? gender = DataSingleton().pat_gender;
  String? doctor = DataSingleton().doc_name;

  print(
      'addDocAndPatientInfo: doctor from DataSingleton = $doctor'); // Debug print

  String patientInfo = "", doctorInfo = "";

  if (patientName != null && patientName.isNotEmpty) {
    patientInfo += 'Name: ${patientName.toString().capitalize}\n';
  }

  if (age != null && age.isNotEmpty) {
    patientInfo += 'Age: $age\n';
  }

  if (gender != null && gender.isNotEmpty) {
    patientInfo += 'Gender: ${gender.toString().capitalize}\n';
  }

  if (doctor != null && doctor.isNotEmpty) {
    doctorInfo += 'Name: $doctor\n';
  }

  List<pw.Text> patinetAndDoctor = [
    if (doctorInfo.isNotEmpty) ...[
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

    if (patientInfo.isNotEmpty) ...[
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
