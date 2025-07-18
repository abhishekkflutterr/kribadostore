import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:kribadostore/DataSingleton.dart';

Future<List<pw.Text>> scoreAndInterpreatation(
    String score, String interpretation) async {
  List<pw.Text> scoreAndInterpreation = [
    pw.Text(
      "Score ",
      style: pw.TextStyle(
        font: PdfComponents().ttf,
        fontSize: PdfComponents().titleFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
    pw.Text(
      score,
      style: pw.TextStyle(
        font: PdfComponents().ttf,
        fontSize: PdfComponents().titleFontSize,
      ),
    ),
    if (interpretation.isNotEmpty) ...[
      pw.Text(
        "\n\nInterpretation ",
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontSize: PdfComponents().titleFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Text(
        interpretation + "\n\n",
        style: pw.TextStyle(
          font: PdfComponents().ttf,
          fontSize: PdfComponents().subtitleFontSize,
        ),
      ),
    ],
    if (DataSingleton().scale_id == "TNSS.kribado")
      pw.Text(
        '''
• None = 0 : You have no nasal symptoms, indicating good nasal health.
• If your score is less than 6 : Your nasal symptoms are considered mild. It is advisable to monitor
your symptoms and consult your doctor if they persist or worsen.
• If your score is between 6 and 9 : Your nasal symptoms are considered moderate. Consulting
your doctor for possible treatments could help manage your symptoms more effectively.
• If your score is greater than 9 : Your nasal symptoms are considered severe. It is recommended
to consult your doctor for a thorough evaluation and potential treatment options to improve
your quality of life.\n
                       ''',
        style: pw.TextStyle(font: PdfComponents().ttf, fontSize: 18),
      ),
  ];

  return scoreAndInterpreation;
}
