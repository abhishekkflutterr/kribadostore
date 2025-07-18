import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/screens/pdf/pdf_components.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<pw.Text>> getQuestionAndAnswer() async {
  List<pw.Text> questionAndAnswer = [];

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

  if (DataSingleton().scale_id == "AllergicRhinitisCustom.kribado") {
    List<dynamic> inputsScale = DataSingleton().inputs;

    // Create a map of question_id to title
    Map<int, String> questionTitleMap = {};
    for (var input in inputsScale) {
      questionTitleMap[input['id']] = input['title'];
    }

    List<Map<String, dynamic>> questions = DataSingleton().resultDataformat;
    List<Map<String, dynamic>> transformedResponses = [];
    for (var response in questions) {
      int questionId = response['question_id'];
      String? title = questionTitleMap[questionId];
      transformedResponses.add({
        'title': title,
        'score': response['score'],
        'answer': response['answer']
      });
    }

    // Define the option to statement mapping
    Map<String, String> optionStatementMap = {
      "Suburban":
          "Suburban areas might offer a balance between urban pollution and green spaces. However, depending on proximity to highways or industrial zones, symptoms could be influenced by pollution levels. Seasonal changes in pollen counts can also impact symptoms.",
      "Village":
          "Living in a rural or village setting often exposes individuals to a variety of allergens like pollen, dust, and agricultural chemicals. Such environments may lead to increased respiratory symptoms, particularly if you are sensitive to outdoor allergens or pollutants.",
      "Urban":
          "Urban settings typically expose individuals to higher levels of pollution, including vehicle emissions and industrial pollutants. These can aggravate symptoms, especially in people with pre-existing respiratory conditions. Urban dwellers may experience more consistent symptoms due to ongoing exposure to environmental irritants.",
      "Winter":
          "In winter, symptoms may worsen due to cold air, increased indoor heating, and reduced ventilation, which can concentrate indoor allergens like dust mites. People sensitive to cold or indoor allergens may notice an increase in respiratory or allergic symptoms during this season.",
      "Summer":
          "Summer often brings high pollen counts, which can trigger allergies and worsen respiratory conditions. Heat and humidity can also exacerbate symptoms in individuals sensitive to these factors.",
      "Rainy":
          "Rainy seasons may increase mold growth and dampness, leading to higher exposure to mold spores and damp environments. This can worsen symptoms, particularly for individuals with mold allergies or asthma.",
      "Every Morning":
          "Morning symptoms could be due to overnight accumulation of indoor allergens such as dust mites or poor air quality due to closed windows. These symptoms may also relate to the body natural cortisol rhythm, which is lower in the morning, potentially worsening inflammation.",
      "Mid-day":
          "Mid-day symptoms may be associated with outdoor activities and exposure to allergens like pollen or pollution. The body exposure to allergens during the day can lead to a peak in symptoms.",
      "Late Evening":
          "Evening symptoms may arise from a combination of daily exposure to allergens and the body circadian rhythm. Fatigue and reduced activity in the evening might also make symptoms more noticeable.",
      "Mid Night":
          "Midnight symptoms can be particularly troubling and might be related to lying down, which can exacerbate respiratory conditions like asthma. Indoor allergens like dust mites in bedding or the concentration of allergens in poorly ventilated rooms could contribute to these symptoms.",
      "Market Place/Street Vendor":
          "Working in open markets exposes individuals to various pollutants, including dust, vehicle emissions, and possibly agricultural products. Such environments can exacerbate symptoms, particularly for those sensitive to outdoor allergens or pollutants.",
      "Agriculture":
          "Agricultural work often involves exposure to dust, pollen, pesticides, and other airborne particles. These can significantly aggravate symptoms, especially respiratory or skin-related conditions.",
      "Industry":
          "Industrial environments might expose workers to chemicals, dust, and fumes, which can trigger or worsen respiratory symptoms and other allergic reactions.",
      "Office/School":
          "While typically more controlled, office and school environments can still harbor indoor allergens like dust, mold, and dander, especially in poorly ventilated or damp areas. Symptoms might be less severe but could still persist due to prolonged indoor exposure.",
      "Pets":
          "Exposure to pets can lead to allergic reactions, particularly if you're sensitive to pet dander. This can worsen respiratory symptoms or skin reactions, especially if pets are allowed in sleeping areas.",
      "Dust":
          "Dust exposure is a common trigger for allergic reactions, including asthma and allergic rhinitis. Symptoms might be more severe in environments with poor air quality and frequent dust accumulation.",
      "Insects":
          "Insect exposure, particularly to cockroaches or dust mites, can exacerbate allergic reactions. Insect allergens can be potent triggers, especially in urban or poorly maintained environments.",
      "Dampened walls":
          "Damp walls are often associated with mold growth, which can significantly aggravate respiratory conditions like asthma. Long-term exposure to damp environments can lead to chronic symptoms and even the development of respiratory issues in previously healthy individuals.",
    };

    List<Map<String, dynamic>> finalResponses =
        transformedResponses.map((response) {
      String? answer = response['answer'];
      String? statement = optionStatementMap[answer];
      if (statement != null) {
        response['answer'] = statement;
      }
      return response;
    }).toList();

    int totalItems = finalResponses.length;
    int questionNumber = 1;

    for (int i = 0; i < totalItems; i += 10) {
      if (i == 0 &&
          DataSingleton().scale_id == "AllergicRhinitisCustom.kribado") {
        questionAndAnswer.add(
          pw.Text(
            "Screening Report :",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: PdfComponents().ttf,
              fontSize: PdfComponents().titleFontSize,
            ),
          ),
        );
      }

      finalResponses
          .sublist(i, (i + 10 <= totalItems) ? i + 10 : totalItems)
          .forEach((question) {
        questionAndAnswer.addAll([
          pw.Text(
            "Q${questionNumber++}: ${question['title']}",
            style: pw.TextStyle(
                font: PdfComponents().ttf,
                fontSize: PdfComponents().subtitleFontSize),
          ),
          pw.Text(
            "A: ${question['answer'].toString().trim()}",
            style: pw.TextStyle(
                font: PdfComponents().ttf,
                fontSize: PdfComponents().subtitleFontSize),
          ),
        ]);
      });
    }
  } else {
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

      transformedResponses.forEach((question) {
        questionAndAnswer.addAll([
          pw.Text(
            "Q $questionNumber: ${question['title']}",
            style: pw.TextStyle(
              font: PdfComponents().ttf,
              fontSize: PdfComponents().subtitleFontSize,
            ),
          ),
          pw.Text(
            "A: ${question['answer']}",
            style: pw.TextStyle(
              font: PdfComponents().ttf,
              fontSize: PdfComponents().subtitleFontSize,
            ),
          ),
        ]);
        questionNumber++;
      });
    } else {
      for (var response in questions) {
        int questionId = response['question_id'];
        String? title = questionTitleMap[questionId];
        transformedResponses.add({
          'title': title,
          'score': response['score'],
          'answer': response['answer']
        });
      }

      int questionNumber = 1;

      transformedResponses.forEach((question) {
        questionAndAnswer.addAll([
          pw.Text(
            "Q ${questionNumber++}: ${question['title']}",
            style: pw.TextStyle(
              font: PdfComponents().ttf,
              fontSize: PdfComponents().subtitleFontSize,
            ),
          ),
          pw.Text(
            "A: ${question['answer']}",
            style: pw.TextStyle(
              font: PdfComponents().ttf,
              fontSize: PdfComponents().subtitleFontSize,
            ),
          ),
        ]);
      });
    }
  }

  return questionAndAnswer;
}
