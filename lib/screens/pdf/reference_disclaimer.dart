import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<pw.Text>> disclaimerAndReference() async {
  String? reference = DataSingleton().References;
  String? disclaimer = DataSingleton().Disclaimer ??
      'This is a customized service by Indigital Technologies LLP...';

  // Defensive null and empty checks
  List<pw.Text> disclaimerAndReference = [
    if (reference != null && reference.isNotEmpty) ...[
      pw.Text(
        "\nReference ",
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontWeight: pw.FontWeight.bold,
          fontSize: PdfComponents().titleFontSize,
        ),
      ),
      pw.Text(
        reference,
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontSize: PdfComponents().subtitleFontSize,
        ),
      ),
    ],
    if (disclaimer != null && disclaimer.isNotEmpty) ...[
      pw.Text(
        "\nDisclaimer ",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          font: PdfComponents().ttf,
          fontSize: PdfComponents().titleFontSize,
        ),
      ),
      pw.Text(
        disclaimer,
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontSize: PdfComponents().subtitleFontSize,
        ),
      ),
    ],
  ];

  return disclaimerAndReference;
}
