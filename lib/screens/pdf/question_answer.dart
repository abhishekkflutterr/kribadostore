import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<pw.Text>> getQuestionAndAnswer() async {
  List<pw.Text> questionAndAnswer = [];
  final Map<String, String>? questionAnsFormting =
      DataSingleton().questionAnsFormting;

  questionAndAnswer.add(
    pw.Text(
      "Question & Answer",
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        font: PdfComponents().ttf,
        fontSize: PdfComponents().titleFontSize,
      ),
    ),
  );

  List<dynamic> inputsScale = DataSingleton().inputs;
  Map<int, String> questionTitleMap = {};
  for (var input in inputsScale) {
    questionTitleMap[input['id']] = input['title'];
  }

  List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;
  List<Map<String, dynamic>> transformedResponses = [];

  if (DataSingleton().childQuestion != null &&
      DataSingleton().childQuestion!.isNotEmpty) {
    for (var response in questions) {
      int questionId = response['question_id'];
      String? title = questionTitleMap[questionId];
      transformedResponses.add({
        'title': title,
        'score': response['score'],
        'answer': response['answer']
      });
    }

    if (transformedResponses.length > 1) {
      transformedResponses[1]['title'] = DataSingleton().childQuestion;
    }

    DataSingleton().tranformedRepsonsesParentChild = transformedResponses;

    int questionNumber = 1;

    for (var question in transformedResponses) {
      String symbol;
      if (questionAnsFormting?["question_symbol"] == "Q1") {
        symbol = "Q$questionNumber.";
      } else if (questionAnsFormting?["question_symbol"] == "1") {
        symbol = "$questionNumber.";
      } else {
        symbol = questionAnsFormting?["question_symbol"] ?? "";
      }
      String answerSymbol = questionAnsFormting?["answer_symbol"] ?? "Ans:-";

      questionAndAnswer.addAll([
        pw.Text(
          "$symbol ${question['title']}",
          style: pw.TextStyle(
            font: PdfComponents().ttf,
            fontSize: PdfComponents().subtitleFontSize,
          ),
        ),
        pw.Text(
          "$answerSymbol ${question['answer']}",
          style: pw.TextStyle(
            font: PdfComponents().ttf,
            fontSize: PdfComponents().subtitleFontSize,
          ),
        ),
      ]);
      questionNumber++;
    }
  } else {
    int questionNumber = 1;
    for (var response in questions) {
      int questionId = response['question_id'];
      String? title = questionTitleMap[questionId];
      transformedResponses.add({
        'title': title,
        'score': response['score'],
        'answer': response['answer']
      });

      // ...determine symbol and answer label...
      String symbol;
      if (questionAnsFormting?["question_symbol"] == "Q1") {
        symbol = "Q$questionNumber.";
      } else if (questionAnsFormting?["question_symbol"] == "1") {
        symbol = "$questionNumber.";
      } else {
        symbol = questionAnsFormting?["question_symbol"] ?? "";
      }
      String answerSymbol = questionAnsFormting?["answer_symbol"] ?? "Ans:-";

      questionAndAnswer.addAll([
        pw.Text(
          "$symbol ${title ?? ''}",
          style: pw.TextStyle(
            font: PdfComponents().ttf,
            fontSize: PdfComponents().subtitleFontSize,
          ),
        ),
        pw.Text(
          "$answerSymbol ${response['answer']}",
          style: pw.TextStyle(
            font: PdfComponents().ttf,
            fontSize: PdfComponents().subtitleFontSize,
          ),
        ),
      ]);
      questionNumber++;
    }
  }

  return questionAndAnswer;
}
