import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/helper/calculations/frax_helper.dart';
import 'package:kribadostore/screens/result_chart_screen.dart';
import 'package:kribadostore/screens/result_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../DataSingleton.dart';
import '../Camp.dart';
import '../DatabaseHelper.dart';
import '../NetworkHelper.dart';
import '../constants/ColorConstants.dart';
import 'dart:math';
import '../custom_widgets/customappbar2.dart';
import '../custom_widgets/elevated_button_color.dart';

void main() {
  runApp(Test());
}

class Test extends StatefulWidget {


  @override
  State<Test> createState() => _TestState();
}

// ASCII code for greater-than symbol
int greaterThanCode = 62;

// ASCII code for equal sign
int equalSignCode = 61;


// Combine ASCII codes to form the greater-than-or-equal-to symbol
String greaterThanOrEqualToSymbol =
    String.fromCharCode(greaterThanCode) + String.fromCharCode(equalSignCode);


List<Map<String, dynamic>> seekbarChildFormat = [];
List<Map<String, dynamic>> finalMergedList = [];
String? _errorTextIBSkribado;


void addOrUpdateResult({
  required int questionId,
  required double score,
  required String answer,
  required int childId,
}) {
  // Remove any existing entries with the same question_id
  seekbarChildFormat.removeWhere((element) => element['question_id'] == questionId);

  // Add the new entry
  seekbarChildFormat.add({
    "question_id": questionId,
    "score": score,
    "answer": answer,
    "child_id": childId,
  });
}

bool numChild = false;


bool isChild = false;
String childAnswer ="";
String globalScaleid = "";
String hintText = "Enter value";

double rangeCheck = 0.0;

class _TestState extends State<Test> {

  late int _curr;
  int? groupValue;
  DataSingleton dataSingleton = DataSingleton();
  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;

  void _handleNextButtonPressed() {
    List<int> unansweredQuestions = [];

    // Check if there are unanswered questions
    for (int i = 0; i < jsonData['inputs'].length; i++) {
      if (!selectedValues.containsKey(i)) {
        unansweredQuestions.add(i + 1);
      }
    }

    if (unansweredQuestions.isNotEmpty) {
      // Show an error message with unanswered questions index
      CustomSnackbar.showErrorSnackbar(
        title: "Unanswered Questions",
        message:
        "Please answer all questions before submitting. Unanswered questions: $unansweredQuestions",
      );
    } else {
      // Proceed with submission
      // Update the evaluation data for the current question

      if(globalScaleid == "SFAR.kribado"){

      }else {
        _updateEvaluationData(_curr, selectedValues[_curr]);
      }

      // Call the method to calculate and interpret results
      calculateAndInterpretResults(totalScore);

      //Chnage by tanvir for 2 time result screen.
      // Check if the title is "kscalegeneric"
      if (jsonData['type'] == 'kscale_generic') {
        // Navigate to the new screen
        // _navigateToNewScreen();
      }
    }
  }

// Method to navigate to the new screen
  void _navigateToNewScreen() {
    // Replace the following line with your navigation code
    // For example, you can use Get.to() or Navigator.push()
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultChartScreen(),
      ), // Replace YourNewScreen with your actual screen
    );
  }

  String getTitleFromResponse(Map<String, dynamic> jsonData) {
    // Check if the response type is "kscale_custom"
    if (jsonData['type'] == 'kscale_custom') {
      // Extracting title from the nested object
      String title = DataSingleton().localeTitle ?? jsonData['title'];
      // If both localeTitle and jsonData['title'] are null, return a default title
      return title ?? "Default Title";
    } else if (jsonData['type'] == 'kscale_generic') {
      String title = jsonData['title'];
      return title ??
          "Default Title"; // Return a default title if title is null
    } else {
      // Handle the case where the response type is not as expected
      return "Default Title";
    }
  }

  Map<String, dynamic> jsonData = {}; // Initialize with an empty map
  late double result;
  String Rinterpretation = "";
  String Dinterpretation = "";
  double sysBp = 0.0;
  double dysBp = 0.0;
  double heartRateBp = 0.0;


  Map<int, int?> selectedValues = {};
  Map<double, double?> selectedValuesNum = {};
  Map<int, Map<String, dynamic>> evaluationDataMap = {};
  num totalScore = 0; // Updated to int
  bool isLoading = true;

  // Variables to store cumulative scores
  num score1to5 = 0;
  num score6and7 = 0;
  num scoreBeyond7 = 0;

  DatabaseHelper? _databaseHelper;

  @override
  void initState() {
    super.initState();
    sharedPrefsData();
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();
    _curr = 0;
    DataSingleton().childQuestion = "";
    DataSingleton().option_selected_logo = "";
    _fetchs3Offline();
    seekbarChildFormat.clear();

  }


  Future<void> sharedPrefsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriber_id = prefs.getString('subscriber_id');
    mr_id = prefs.getString('mr_id');
  }


  Future<void> fetchs3data() async {
    String? scaleUrl = DataSingleton().scaleS3Url;
    var api = '${scaleUrl!}';
    var uri = Uri.parse(api);
    var res = await http.get(uri);
    DataSingleton().s3jsonOffline = res.body.toString();
    String reference = jsonDecode(res.body)["references"];
    // print('references$reference');
    DataSingleton().References = reference;
    setState(() {
      jsonData = jsonDecode(res.body);
      isLoading = false;
    });
  }

  Future<void> _fetchs3Offline() async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    await databaseHelper.initializeDatabase();

    List<Map<String, dynamic>> resources1 =
    await databaseHelper.getAllDivisiondetail();
    Map<String, dynamic> screenDetail, division_detail;
    for (var resource in resources1) {
      if (resource.containsKey('scales_list') &&
          resource['scales_list'] != null) {
        screenDetail = json.decode(resource['scales_list']);
        division_detail = json.decode(resource['division_detail']);

        List<dynamic> metaList = [];
        if (screenDetail.containsKey('data')) {
          Map<String, dynamic> data = screenDetail['data'];
          if (data.containsKey('scales')) {
            metaList = data['scales'];
            for (var meta in metaList) {
              var name = meta['name'];
              Map<String, dynamic> data = meta['scale_json'];
              globalScaleid = DataSingleton().scale_id!;
              if (DataSingleton().scale_id.toString() == name) {
                String refer = data['references'];
                DataSingleton().References = refer;
                Map<String, dynamic> userData = division_detail['data']['user'];
                int mrid = userData['mr_id'];
                // DataSingleton().subscriber_id = mrid;
                setState(() {
                  jsonData = data;
                  isLoading = false;
                });
              }
            }
          }
        }
      }
    }
  }

  Future<void> _insertData(double final_result) async {
    try {
      int divNumeric = DataSingleton().division_id;
      await _databaseHelper?.insertCamp(Camp(
          camp_id: dataSingleton
              .generateMd5(
              "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DataSingleton().dr_id}_${DataSingleton().scale_name}_${DataSingleton().division_id}_$subscriber_id")
              .toString(),
          camp_date: camp_date.toString(),
          test_date: test_date.toString(),
          test_start_time: test_start_time.toString(),
          test_end_time: dataSingleton.getCurrentDateTimeInIST(),
          created_at: dataSingleton.getCurrentDateTimeInIST(),
          scale_id: scale_id.toString(),
          test_score: final_result,
          interpretation: '$Rinterpretation\n$Dinterpretation',
          language: "en",
          pat_age: pat_age,
          pat_gender: pat_gender,
          pat_email: "NA",
          pat_mobile: "NA",
          pat_name: pat_name.toString(),
          pat_id: pat_id.toString(),
          answers: DataSingleton().resultDataformat.toString(),
          division_id: divNumeric,
          subscriber_id: subscriber_id.toString(),
          doc_speciality: DataSingleton().doc_speciality.toString(),
          mr_code: mr_id.toString(),
          dr_consent: DataSingleton().dr_consent,
          patient_consent: DataSingleton().patient_consent,
          country_code: DataSingleton().country_code.toString(),
          state_code: DataSingleton().state_code.toString(),
          city_code: DataSingleton().city_code.toString(),
          area_code: DataSingleton().area_code.toString(),
          doc_code: DataSingleton().doc_code.toString(),
          doc_name: DataSingleton().doc_name.toString(),
          dr_id: DataSingleton().dr_id.toString(),
          doctor_meta: DataSingleton().doctor_meta.toString(),
          patient_meta: DataSingleton().patient_meta.toString()));
      setState(() {});
      print("Database success Camp");
    } catch (e) {
      print("ERROR on scaeNav: $e");
    }
  }

  String pat_id = DataSingleton().pat_id ?? '';
  String camp_date = DataSingleton().camp_date ?? '';
  String test_date = DataSingleton().test_date ?? '';
  String test_start_time = DataSingleton().test_start_time ?? '';
  String pat_age = DataSingleton().pat_age ?? '';
  String pat_name = DataSingleton().pat_name ?? '';
  String pat_gender = DataSingleton().pat_gender ?? '';
  String? scale_id = DataSingleton().scale_id;
  Map<double, double?> numTypeInputsOnly ={} ;
  bool type = false;
  late List<Widget> _list;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Add a delay of 500ms before rendering
      future: Future.delayed(Duration(milliseconds: 500), () => jsonData),
      builder: (context, snapshot) {

        // Check if jsonData or inputs are null after the delay
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!['inputs'] == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                '',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          );
        }

        // Extract data and inputs after the delay
        final jsonData = snapshot.data!;
        String title = getTitleFromResponse(jsonData);
        List<dynamic> inputs = jsonData['inputs'];

        // Generate the list of widgets
        List<Widget> _list = List.generate(inputs.length, (index) {
          return ScalesTestScreen(
            index,
            jsonData,
            selectedValues,
            _handleOptionSelected,
            _handleEvaluationSubmitted,
            updateSelectedCheckboxes,
            updateTextbox,
            updateChild,
            updateParent,
            updateTextType,
            _handleOptionSelectedNum,


          );
        });
        // Extracting title from jsonData

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: MyHomePage(
              _curr,
              _list,
              selectedValues, // Pass selectedValues here
              inputs,
              title: title, // Replace with your actual title
              onNextButtonPressed: _handleNextButtonPressed,
            ),
          ),
        );
      },
    );
  }

  void _handleOptionSelected(int? value, int questionIndex) {



    // Update the selected option immediately
    setState(() {
      selectedValues[questionIndex] = value;
    });

    // Update the evaluation data
    _updateEvaluationData(questionIndex, value);
  }



  void _handleOptionSelectedNum(double value, int questionIndex) {
    // Update the selected option immediately
    int incrementedIndex = questionIndex + 1;
    setState(() {
      rangeCheck = value;
      selectedValuesNum[incrementedIndex.toDouble()] = value;
      numTypeInputsOnly = selectedValuesNum;
    });
  }

  String selectedCheckboxes = "";
  int  selectedCheckboxesScore = 0;
  void updateSelectedCheckboxes(String checkboxes,int score) {
    // Update the selected checkboxes list
    this.selectedCheckboxes = checkboxes;
    this.selectedCheckboxesScore = score;
  }

  String text = "";
  String textType = "";
  void updateTextType(String textType) {
    this.textType = textType;
  }
  void updateTextbox(String text) {
    this.text = text;
  }

  String child = "";
  num childScore = 0;
  String childAnswer = "";
  num childId = 0;
  num parentScore = 0;
  String parentAnswer = "";
  String? subscriber_id;
  String? mr_id;


  void updateChild(
      String child, num childScore, String childAnswer, num childId) {
    this.child = child;
    this.childScore = childScore;
    this.childAnswer = childAnswer;
    this.childId = childId;
  }

  void updateParent(num parentScore,String parentAnswer ) {
    this.parentScore = parentScore;
    this.parentAnswer = parentAnswer;
  }

  void _updateEvaluationData(int questionIndex, int? selectedValue) {
    // Check if an option is selected
    if (selectedValue != null) {
      // Handle the case where the input type is "NUM"
      if (jsonData['inputs'][questionIndex]['type'] == 'NUM') {

        type = true;
        double? numericValue1 = 0.0;
        Map<double, double?> numTypeInputsOnlyNewMap = numTypeInputsOnly;
        // Iterate using forEach
        numTypeInputsOnly.forEach((key, value) {
          // Compare using a double
          if (key == questionIndex.toDouble()) {
            numericValue1 = value;
          }
        });


        int numericValue = selectedValue;
        // Update the evaluation data for the current question
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': numericValue,
            // Set the score as the entered numeric value
            'value': "$numericValue1",
            // Include the numeric value in the result data
          };
        });
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'MS' || jsonData['inputs'][questionIndex]['type'] == 'AON') {
        // Get the entered numeric value
        int numericValue = selectedValue;
        String stringValue = selectedValue.toString().split('').join('|');
        // Update the evaluation data for the current question
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': selectedCheckboxesScore,
            // Set the score as the entered numeric value
            'value': selectedCheckboxes,
            // Include the numeric value in the result data
          };
        });
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'TXT') {
        // Get the entered numeric value
        int numericValue = selectedValue;

        // Update the evaluation data for the current question
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': numericValue, // Set the score as the entered numeric value
            'value': text, // Include the numeric value in the result data
          };
        });
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'SEEK') {
        // Get the entered numeric value
        int numericValue = selectedValue;

        // Update the evaluation data for the current question
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': numericValue,
            // Set the score as the entered numeric value
            'value': "$numericValue",
            // Include the numeric value in the result data
          };
        });
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'SS') {
        String chiltext = child;
        if (chiltext.isEmpty){
          // Get the score of the selected option
          num score = jsonData['inputs'][questionIndex]['options'][selectedValue]['score'];
          // Get the option text
          String optionText = jsonData['inputs'][questionIndex]['options']
          [selectedValue]['title'];
          // Update the evaluation data for the current question
          setState(() {
            evaluationDataMap[questionIndex] = {
              'id': jsonData['inputs'][questionIndex]['id'],
              'score': score,
              'value': optionText, // Include the option text in the result data
            };
          });
        }

        if (chiltext == "childAvailable" ) {
          print('@@@@@@@@@@@@@@@@@@@insideSSchild');
          setState(() {
            print('@@@@@@childansewer $childAnswer');
            evaluationDataMap[questionIndex] = {
              'id': jsonData['inputs'][questionIndex]['id'],
              'score': childScore,
              'value': childAnswer,
              // Include the option text in the result data
              'child_id': childId,
              // Include the option text in the result data
            };
          });
        } else  if (chiltext == "childAvailable"){
          // Get the score of the selected option
          num score = jsonData['inputs'][questionIndex]['options'][selectedValue]['score'];
          // Get the option text
          String optionText = jsonData['inputs'][questionIndex]['options'][selectedValue]['title'];
          // Update the evaluation data for the current question
          setState(() {
            evaluationDataMap[questionIndex] = {
              'id': jsonData['inputs'][questionIndex]['id'],
              'score': score,
              'value': optionText, // Include the option text in the result data
            };
          });
        }
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'DD') {
        // Get the score of the selected option
        int score = jsonData['inputs'][questionIndex]['options'][selectedValue]['score'];
        // Get the option text
        String optionText = jsonData['inputs'][questionIndex]['options'][selectedValue]['title'];
        // Update the evaluation data for the current question
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': score,
            'value': optionText, // Include the option text in the result data
          };
        });
      }
    } else {
      // Handle the case where no option is selected
      if (jsonData['inputs'][questionIndex]['type'] == 'NUM') {
        // If it's a numeric input and no option is selected, set the score and value as the entered numeric value
        int numericValue = int.parse(jsonData['inputs'][questionIndex]
        ['options'][0]['title']); // Assuming index 0 is the numeric input
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': numericValue,
            'value': numericValue.toString(),
          };
        });
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'TXT') {
        // If it's a numeric input and no option is selected, set the score and value as the entered numeric value
        // int numericValue = int.parse(jsonData['inputs'][questionIndex]['options'][0]['title']); // Assuming index 0 is the numeric input
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': 3,
            'value': "numericValue.toString()",
          };
        });
      }

      if (jsonData['inputs'][questionIndex]['type'] == 'SEEK') {
        // If it's a numeric input and no option is selected, set the score and value as the entered numeric value
        int numericValue = 0; // Assuming index 0 is the numeric input
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': 3,
            'value': 3,
          };
        });
      } else {
        // If no option is selected for other types, add the question with a blank answer
        setState(() {
          evaluationDataMap[questionIndex] = {
            'id': jsonData['inputs'][questionIndex]['id'],
            'score': 0, // Set a default score for skipped questions
            'value': '', // Include an empty value for other types
          };
        });
      }
    }

    // Calculate the total score by iterating through the evaluation data
    totalScore = 0;

    // Variables to store cumulative scores
    score1to5 = 0;
    score6and7 = 0;
    scoreBeyond7 = 0;

    for (int i = 0; i < jsonData['inputs'].length; i++) {
      if (evaluationDataMap.containsKey(i)) {
        totalScore += evaluationDataMap[i]!['score'] ?? 0;

        // Calculate cumulative scores based on question numbers
        if (i >= 0 && i < 5) {
          score1to5 += evaluationDataMap[i]!['score'] ?? 0;
        } else if (i >= 5 && i < 7) {
          score6and7 += evaluationDataMap[i]!['score'] ?? 0;
        } else {
          scoreBeyond7 += evaluationDataMap[i]!['score'] ?? 0;
        }

        DataSingleton().score1to5 = score1to5;
        DataSingleton().score6and7 = score6and7;
        DataSingleton().scoreBeyond7 = scoreBeyond7;
      }
    }

    // Update resultDataformat
    List<Map<String, dynamic>> resultDataformat = [];

    for (int i = 0; i < jsonData['inputs'].length; i++) {
      int id = jsonData['inputs'][i]['id'];
      int score = evaluationDataMap[i]?['score'] ?? 0;
      String value = evaluationDataMap[i]?['value'] ?? '';
      int child_id = evaluationDataMap[i]?['child_id'] ?? 0;

      if(child == "childAvailable"){
        resultDataformat.add({
          "question_id": id,
          "score": parentScore,
          "answer": parentAnswer,
        });

        if (child == "childAvailable") {
          int id = jsonData['inputs'][i]['id'];
          int score = evaluationDataMap[i]?['score'] ?? 0;
          String value = evaluationDataMap[i]?['value'] ?? '';
          resultDataformat.add({
            "question_id": id,
            "score": childScore,
            "answer": childAnswer,
            "child_id": child_id
          });
        }
      } else {
        resultDataformat.add({
          "question_id": id,
          "score": score,
          "answer": value,
        });
      }
    }

    for (var i = 0; i < resultDataformat.length; i++) {
      var questionId = resultDataformat[i]['question_id'];
      // Check if there's a matching entry in numTypeInputsOnly based on the questionId (index)
      if (numTypeInputsOnly.containsKey(questionId.toDouble())) {
        double newScore = numTypeInputsOnly[questionId.toDouble()]!;
        // Update score and answer with the new value
        resultDataformat[i]['answer'] = "$newScore";
      }
    }

    if(scale_id == 'FRAX.osteocalc.kribado'){
      // Process `question_id: 10` before printing
      resultDataformat = processQuestion10(resultDataformat);
      DataSingleton().resultDataformat = resultDataformat;
      // Print the updated resultDataformat
      print('eitetiefdkfkfdkfskfskfskfsk ${jsonEncode(resultDataformat)}');
    } else if(scale_id == 'IBS.kribado'){

      // Print the updated resultDataformat
      print('eitetiefdkfkfdkfskfskfskfsk ${jsonEncode(resultDataformat)}');
      print('dfdtrtrtretrtertetetetetete $seekbarChildFormat');

      finalMergedList = mergeResults(resultDataformat, seekbarChildFormat);
      print('Merged result: ${jsonEncode(finalMergedList)}');
      DataSingleton().resultDataformat = finalMergedList;


    } else {
      // Print the accumulated evaluation data in the desired format
      DataSingleton().resultDataformat = resultDataformat;

      print('kfjfhjxncmxncxmcnxfeufh $resultDataformat');
    }




  }

  List<Map<String, dynamic>> mergeResults(
      List<Map<String, dynamic>> parentList,
      List<Map<String, dynamic>> childList,
      ) {
    List<Map<String, dynamic>> mergedList = [];

    for (var parent in parentList) {
      int qid = parent['question_id'];
      String answer = parent['answer'].toString();

      // Always add the parent entry
      mergedList.add(parent);

      // Skip merging child entries only if question_id is 2 and answer is "No"
      if (qid == 2 && answer.toLowerCase() == 'no') {
        continue;
      }

      // Otherwise, add matching child entries
      mergedList.addAll(
        childList.where((child) => child['question_id'] == qid),
      );
    }

    return mergedList;
  }



  List<Map<String, dynamic>> processQuestion10(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> modifiedData = [];

    for (var entry in data) {
      if (entry["question_id"] == 10) {
        if (DataSingleton().fraxOptionTitle == "Yes") {
          modifiedData.add({"question_id": 10, "score": 1, "answer": "Yes"});
          modifiedData.add({"question_id": 10, "score": DataSingleton().fraxAnswer10, "answer": DataSingleton().fraxAnswer10, "child_id": DataSingleton().fraxchilId});
        } else {
          modifiedData.add({"question_id": 10, "score": 0, "answer": "No"});
        }
      } else {
        modifiedData.add(entry);
      }
    }
    return modifiedData;
  }

  Future<void> calculateAndInterpretResults(num totalScore) async {
    double totalScoreAsInt = totalScore.toDouble(); // Explicitly cast to int
    if (jsonData['scale_code'] == "GERDQ.kribado") {
      if (totalScoreAsInt >= 0 && totalScoreAsInt <= 2) {
        Rinterpretation = "0 % likelihood of GERD";
      }
      if (totalScoreAsInt >= 3 && totalScoreAsInt <= 7) {
        Rinterpretation = "50 % likelihood of GERD";
      }
      if (totalScoreAsInt >= 8 && totalScoreAsInt <= 10) {
        Rinterpretation = "79 % likelihood of GERD";
      }
      if (totalScoreAsInt >= 11 && totalScoreAsInt <= 18) {
        Rinterpretation = "89 % likelihood of GERD";
      }
      result = totalScoreAsInt;
      // print('@@##result navigator screen $result');
      DataSingleton().TotalScore = result;

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == "FSSG.kribado") {
      double dyspeptic = (totalScoreAsInt ~/ 100).toDouble();
      double reflux = totalScoreAsInt % 100;

      double tempResult = dyspeptic + reflux;
      result = tempResult;

      DataSingleton().TotalScore = result;

      if (reflux < 7 && dyspeptic < 6) {
        Rinterpretation = "Acid Reflux- No symptoms found";
        Dinterpretation = "Dyspeptic- No symptoms found";
      } else {
        if (reflux < 7) {
          Rinterpretation = "Acid Reflux- No symptoms found";
        } else if (reflux >= 7) {
          Rinterpretation =
          "Acid Reflux score ${greaterThanOrEqualToSymbol}7 indicates a requirement PCAB maintenance therapy.";
        }

        if (dyspeptic < 6) {
          Dinterpretation = "Dyspeptic- No symptoms found";
        } else if (dyspeptic >= 6) {
          Dinterpretation =
          "Dyspeptic Symptom score ${greaterThanOrEqualToSymbol}6 indicates the need for Prokinetics along with PCAB.";
        } else {
          Dinterpretation = "Dyspeptic- No symptoms found";

        }
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation' "\n" '$Dinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == "FSSG.kribado.IN") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result >= 8) {
        Rinterpretation = "severe symptoms";
      } else {
        Rinterpretation = "mild symptoms";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == 'MTOQ.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      // Determine the interpretation based on the score
      if (score >= 0 && score <= 0) {
        Rinterpretation = "Very poor treatment efficacy";
      } else if (score >= 1 && score <= 5) {
        Rinterpretation = "Poor treatment efficacy";
      } else if (score >= 6 && score <= 7) {
        Rinterpretation = "Moderate treatment efficacy";
      } else {
        Rinterpretation = "Maximum treatment efficacy";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'DAS28.ESR.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      var resultvar = DataSingleton().resultDataformat;
      int tender = 0;
      int swollen = 0;
      int esr = 1;
      int patienGloabalHealth = 0;

      // print("cskskj $resultvar");

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;
        if (questionid == 1) {
          tender = item['score'] ?? 0;
        }
        if (questionid == 2) {
          swollen = item['score'] ?? 0;
        }
        if (questionid == 3) {
          esr = item['score'] ?? 0;
        }

        if (questionid == 4) {
          patienGloabalHealth = item['score'] ?? "";
        }
      }


      // Calculate DAS28(4) score
      double das28ScoreESR = 0.56 * sqrt(tender) +
          0.28 * sqrt(swollen) +
          0.70 * log(esr) +
          0.014 * patienGloabalHealth;

      double roundedDas28ScoreESR =
      double.parse(das28ScoreESR.toStringAsFixed(2));

      // Determine the interpretation based on the score for ESR
      if (roundedDas28ScoreESR >= 0 && roundedDas28ScoreESR <= 2.5) {
        Rinterpretation = "Remission Disease Activity";
      } else if (roundedDas28ScoreESR >= 2.6 && roundedDas28ScoreESR <= 3.1) {
        Rinterpretation = "Low Disease Activity";
      } else if (roundedDas28ScoreESR >= 3.2 && roundedDas28ScoreESR <= 5.1) {
        Rinterpretation = "Moderate Disease Activity";
      } else if (roundedDas28ScoreESR >= 5.2) {
        Rinterpretation = "High Disease Activity";
      } else {
        Rinterpretation = "Unknown Disease Activity";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$roundedDas28ScoreESR',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(das28ScoreESR);
    } else if (jsonData['scale_code'] == 'DAS28.CRP.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      var resultvar = DataSingleton().resultDataformat;
      int tender = 0;
      int swollen = 0;
      int crp = 0;
      int patienGloabalHealth = 0;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;
        if (questionid == 1) {
          tender = item['score'] ?? 0;
        }
        if (questionid == 2) {
          swollen = item['score'] ?? 0;
        }
        if (questionid == 3) {
          crp = item['score'] ?? "";
        }

        if (questionid == 4) {
          patienGloabalHealth = item['score'] ?? "";
        }
      }


      // Calculate DAS28(4) score
      double das28ScoreCRP = 0.56 * sqrt(tender) +
          0.28 * sqrt(swollen) +
          0.36 * log(crp + 1) +
          0.014 * patienGloabalHealth +
          0.96;


      double roundedDas28ScoreCRP =
      double.parse(das28ScoreCRP.toStringAsFixed(2));

      // Determine the interpretation based on the score for CRP
      if (roundedDas28ScoreCRP >= 0 && roundedDas28ScoreCRP <= 2.5) {
        Rinterpretation = "Remission Disease Activity";
      } else if (roundedDas28ScoreCRP >= 2.6 && roundedDas28ScoreCRP <= 3.1) {
        Rinterpretation = "Low Disease Activity";
      } else if (roundedDas28ScoreCRP >= 3.2 && roundedDas28ScoreCRP <= 5.1) {
        Rinterpretation = "Moderate Disease Activity";
      } else if (roundedDas28ScoreCRP >= 5.2) {
        Rinterpretation = "High Disease Activity";
      } else {
        Rinterpretation = "Unknown Disease Activity";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$roundedDas28ScoreCRP',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(das28ScoreCRP);
    } else if (jsonData['scale_code'] == 'DEQ5.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 5) {
        Rinterpretation = "No Dry Eye";
      } else if (score >= 6 && score <= 11) {
        Rinterpretation = "Suspect Dry Eye";
      } else if (score >= 12 && score <= 100) {
        Rinterpretation = "Suspect Sjogren's Syndrome";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }


    else if (jsonData['scale_code'] == 'MRS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      var resultvar = DataSingleton().resultDataformat;

      //Somatic Subscale
      int questionidCount1= 0;
      int questionidCount2= 0;
      int questionidCount3= 0;
      int questionidCount11= 0;
      //Psychological Subscale
      int questionidCount4= 0;
      int questionidCount5= 0;
      int questionidCount6= 0;
      int questionidCount7= 0;
      //Urogenital Subscale
      int questionidCount8= 0;
      int questionidCount9= 0;
      int questionidCount10= 0;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          int answer = item['score'];
          questionidCount1 = answer;
        } else  if (questionid == 2) {
          int answer = item['score'];
          questionidCount2 = answer;
        }else  if (questionid == 3) {
          int answer = item['score'];
          questionidCount3 = answer;
        }else  if (questionid == 4) {
          int answer = item['score'];
          questionidCount4 = answer;
        }else  if (questionid == 5) {
          int answer = item['score'];
          questionidCount5 = answer;
        }else  if (questionid == 6) {
          int answer = item['score'];
          questionidCount6 = answer;
        }else  if (questionid == 7) {
          int answer = item['score'];
          questionidCount7 = answer;
        }else  if (questionid == 8) {
          int answer = item['score'];
          questionidCount8 = answer;
        }else  if (questionid == 9) {
          int answer = item['score'];
          questionidCount9 = answer;
        }else  if (questionid == 10) {
          int answer = item['score'];
          questionidCount10 = answer;
        }else  if (questionid == 11) {
          int answer = item['score'];
          questionidCount11 = answer;
        }

      }

      //Somatic Subscale
      int somaticCount = questionidCount1 + questionidCount2 + questionidCount3 + questionidCount11;
      //Psychological Subscale
      int psychologicalCount = questionidCount4 + questionidCount5 + questionidCount6 + questionidCount7;
      //Urogenital Subscale
      int urogenital = questionidCount8 + questionidCount9 + questionidCount10;

      print('@@@@@@@@@@@@@@menopause Somatic $somaticCount');
      print('@@@@@@@@@@@@@@menopause Psychological $psychologicalCount');
      print('@@@@@@@@@@@@@@menopause Urogenital $urogenital');




      if (score >= 0 && score <= 4) {
        Rinterpretation = "No or minimal symptoms";
      } else if (score >= 5 && score <= 8) {
        Rinterpretation = "Mild symptoms";
      } else if (score >= 9 && score <= 16) {
        Rinterpretation = "Moderate symptoms";
      } else if (score >= 17 && score <= 100) {
        Rinterpretation = "Severe symptoms";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }






    else if (jsonData['scale_code'] == 'testing1.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 5) {
        Rinterpretation = "No Dry Eye";
      } else if (score >= 6 && score <= 11) {
        Rinterpretation = "Suspect Dry Eye";
      } else if (score >= 12 && score <= 100) {
        Rinterpretation = "Suspect Sjogren's Syndrome";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }

    else if (jsonData['scale_code'] == 'HbA1c.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }

    else if (jsonData['scale_code'] == "Short.Womac.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      String tag = "Total Score for Short Womac";
      String scoreOutof = '$result out of 28';


      //default interpretation
      Rinterpretation = "Higher scores on the WOMAC indicate worse pain, stiffness, and/or functional limitations";


      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$tag' "\n" ' $scoreOutof' "\n" '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }

//RQLQ
    else if (jsonData['scale_code'] == 'RQLQ.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;
          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;
          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] ?? 0;
          print("questionId6  $questionId6");
        }
      }


      double NHS = (questionId1.toDouble() + questionId2.toDouble() + questionId3.toDouble()) / 3;
      String formattedNHS = NHS.toStringAsFixed(2);
      double PP = (questionId4.toDouble() + questionId5.toDouble() + questionId6.toDouble()) / 3;
      String formattedPP = PP.toStringAsFixed(2);
      print("formattedNHS $formattedNHS");
      print("formattedPP $formattedPP");

      score  = double.parse(formattedNHS) + double.parse(formattedPP);

      if (NHS ==0) {
        Rinterpretation = "Patient score for non-hay fever \nsymptoms:$formattedNHS\nNot troubled\n";
      } else if (NHS>=1 && NHS<2) {
        Rinterpretation =
        "Patient score for non-hay fever \nsymptoms:$formattedNHS\nHardly troubled at all\n";
      }else if(NHS>=2 && NHS<3){
        Rinterpretation="Patient score for non-hay fever \nsymptoms:$formattedNHS\nSomewhat troubled\n";
      }else if(NHS>=3 && NHS<4){
        Rinterpretation="Patient score for non-hay fever \nsymptoms:$formattedNHS\nModerately troubled\n";
      }else if(NHS>=4 && NHS<5){
        Rinterpretation="Patient score for non-hay fever \nsymptoms:$formattedNHS\nQuite a bit troubled\n";
      }else if(NHS>=5 && NHS<6){
        Rinterpretation="Patient score for non-hay fever \nsymptoms:$formattedNHS\nVery troubled\n";
      }else if(NHS==6){
        Rinterpretation="Patient score for non-hay fever \nsymptoms:$formattedNHS\nExtremely troubled\n";
      }

      if (PP ==0) {
        Dinterpretation = "Patient score for practical \nproblems:$formattedPP\nNot troubled\n";
      } else if (PP>=1 && PP<2) {
        Dinterpretation =
        "Patient score for practical \nproblems:$formattedPP\nHardly troubled at all\n";
      }else if(PP>=2 && PP<3){
        Dinterpretation="Patient score for practical \nproblems:$formattedPP\nSomewhat troubled\n";
      }else if(PP>=3 && PP<4){
        Dinterpretation="Patient score for practical \nproblems:$formattedPP\nModerately troubled\n";
      }else if(PP>=4 && PP<5){
        Dinterpretation="Patient score for practical \nproblems:$formattedPP\nQuite a bit troubled\n";
      }else if(PP>=5 && PP<6){
        Dinterpretation="Patient score for practical \nproblems:$formattedPP\nVery troubled\n";
      }else if(PP==6){
        Dinterpretation="Patient score for practical \nproblems:$formattedPP\nExtremely troubled\n";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          '$Rinterpretation' "\n" '$Dinterpretation',
          pat_name,
          pat_age,
          pat_gender,
        ),
      );
      _insertData(score);
    }

    else if (jsonData['scale_code'] == "BP.Monitoring.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      var resultvar = DataSingleton().resultDataformat;


      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          sysBp = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 2) {
          dysBp = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 3) {
          heartRateBp = double.tryParse(item['answer'].toString()) ?? 0;
        }
      }

      String formatDecimal(double value) {
        if (value == value.toInt()) {
          return value.toInt().toString();
        } else {
          return value.toString();
        }
      }

      // Calculating parameters using the given formulas
      double pulsePressure = sysBp - dysBp;
      double meanArterialPressure = dysBp + (1 / 3 * (sysBp - dysBp));
      double cardiacOutput = (pulsePressure / (sysBp + dysBp)) * heartRateBp;
      double systemicVascularResistance = cardiacOutput != 0 ? meanArterialPressure / cardiacOutput : 0;

      Rinterpretation =
      "Systolic Blood Pressure: ${formatDecimal(sysBp)} mmHg \n"
          "Diastolic Blood Pressure: ${formatDecimal(dysBp)} mmHg \n"
          "Heart Rate: ${formatDecimal(heartRateBp)} bpm \n\n"
          "Pulse Pressure (PP): ${formatDecimal(pulsePressure)} mmHg \n"
          "Mean Arterial Pressure (MAP): ${meanArterialPressure.toStringAsFixed(2)} mmHg \n"
          "Cardiac Output (CO): ${cardiacOutput.toStringAsFixed(2)} L/min \n"
          "Systemic Vascular Resistance (SVR): ${systemicVascularResistance.toStringAsFixed(2)} mmHg/L/min";

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '0',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(0);
    }

    else if (jsonData['scale_code'] == "LipidProfile.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      var resultvar = DataSingleton().resultDataformat;

      double answer1 = 0.0;
      double answer2 = 0.0;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          answer1 = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 2) {
          answer2 = double.tryParse(item['answer'].toString()) ?? 0;
        }
      }

      double finalResult = answer1 / answer2;
      double roundedResult = double.parse(finalResult.toStringAsFixed(1));
      print('TC/HDL Ratio = $roundedResult'); // Output: TC/HDL Ratio = 3.2



      if(pat_gender == 'male'){
        if (roundedResult >= 0 && roundedResult <= 3.4) {
          Rinterpretation = "A very low risk";
        } else if (roundedResult >= 3.5 && roundedResult <= 4.5) {
          Rinterpretation = "Low risk";
        } else if (roundedResult >= 4.5 && roundedResult <= 7.2) {
          Rinterpretation = "Average risk";
        } else if (roundedResult >= 7.2 && roundedResult <= 16.5) {
          Rinterpretation = "Moderate risk";
        } else if (roundedResult >= 16.6 && roundedResult <= 100) {
          Rinterpretation = "High risk";
        }
      }else {
        if (roundedResult >= 0 && roundedResult <= 3.3) {
          Rinterpretation = "A very low risk";
        } else if (roundedResult >= 3.4 && roundedResult <= 4.1) {
          Rinterpretation = "Low risk";
        } else if (roundedResult >= 4.2 && roundedResult <= 5.7) {
          Rinterpretation = "Average risk";
        } else if (roundedResult >= 9.1 && roundedResult <= 100) {
          Rinterpretation = "High risk";
        }
      }



      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$roundedResult',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(roundedResult);
    }

    else if (jsonData['scale_code'] == "FRAX.osteocalc.kribado") {
////////
      double result = totalScoreAsInt;
      DataSingleton().TotalScore = result;


      var resultvar = DataSingleton().resultDataformat;
      // print('@@@@@@@@@@@fraxResult $resultvar');

      double weight = 0; // in kg
      double height = 0; // in cm
      int score3 = 0;
      int score4 = 0;
      int score5 = 0;
      int score6 = 0;
      int score7 = 0;
      int score8 = 0;
      int score9 = 0;
      String tScore = '';


      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          weight = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 2) {
          height = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 3) {
          score3 = item['score'] ?? 0;
        }
        if (questionid == 4) {
          score4 = item['score'] ?? 0;
        }
        if (questionid == 5) {
          score5 = item['score'] ?? 0;
        }
        if (questionid == 6) {
          score6 = item['score'] ?? 0;
        }
        if (questionid == 7) {
          score7 = item['score'] ?? 0;
        }
        if (questionid == 8) {
          score8 = item['score'] ?? 0;
        }
        if (questionid == 9) {
          score9 = item['score'] ?? 0;
        }
        if (questionid == 10) {
          tScore = item['answer'].toString();
        }
      }

      print('ruewrksdjskdjdknzxmzn $tScore');
      String parameter = '';
      String scoreParameter = '';

      print('@@@@@@frax weight and height : $weight  $height');
      double bmi = FraxHelper.calculateBMI(weight, height);
      print('@@@@@@frax Your BMI is: $bmi');

      int bmiRound = FraxHelper.roundToNearestFive(bmi.toInt());
      print('@@@@@@frax Your BMIround is: $bmiRound');

      if (DataSingleton().fraxOptionTitle == "No") {
        parameter = 'BMI';
        scoreParameter = '$bmiRound';
      } else  if (DataSingleton().fraxOptionTitle == "Yes") {
        double? tscoreDouble = double.tryParse(tScore);
        if (tscoreDouble != null) {
          double tscoreRound = FraxHelper.roundToNearestIntervalTsore(tscoreDouble);
          print('@@@@@@frax tscoreRound $tscoreRound');

          parameter = 'BMD';
          scoreParameter = '$tscoreRound';
        }
      }


      print('finallllllllparamenter $parameter');
      print('finallllllllscoreParameter $scoreParameter');

      if(parameter == 'BMI'){
        DataSingleton().fraxHeader = 'BMI (without BMD)';
      }else {
        DataSingleton().fraxHeader = 'BMI (with BMD)';
      }



      // crf
      int sumofCrfs = score3 + score4 + score5 + score6 + score7 + score8 + score9;
      int crf = (sumofCrfs == 0) ? sumofCrfs : sumofCrfs - 1;
      print('@@@@@@frax crf  $crf');
      print('@@@@@@frax gender $pat_gender');
      DataSingleton().fraxBmiRound = bmiRound;
      print('@@@@@@frax age $pat_age');

      //age round to nearest
      int patAgeInt = int.parse(pat_age);
      int ageRound = FraxHelper.roundToNearestFiveAge(patAgeInt);
      print('hjsfhjsfhcnzm $ageRound');

      FraxHelper helper = FraxHelper();
      // String OsteoporoticFracture = helper.getTenYearOsteoporoticFracture("$pat_gender", "Osteoporotic", "BMD", "$crf", "$tscoreRound","$pat_age");
      String OsteoporoticFracture = helper.getTenYearOsteoporoticFracture("$pat_gender", "Osteoporotic", "$parameter", "$crf", "$scoreParameter","$ageRound");
      print('@@@@@@frax  getAgeByIdAndName $OsteoporoticFracture');


      String HipFracture = helper.getTenYearHipFracture("$pat_gender", "Hip Fracture", "$parameter", "$crf", "$scoreParameter","$ageRound");
      print('@@@@@@frax  getAgeByIdAndNameHip $HipFracture');




      //default interpretation
      String tag = "THE TEN-YEAR PROBABILITY OF FRACTURE";
      Rinterpretation = 'Major osteoporotic : $OsteoporoticFracture %';
      Dinterpretation  = 'Hip Fracture : $HipFracture %';


      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$bmiRound',
          '$tag' "\n" ' $Rinterpretation' "\n" '$Dinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(bmiRound.toDouble());
    }

    else if (jsonData['scale_code'] == 'SFAR.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      // Determine the interpretation based on the score
      if (score >= 0 && score <= 7) {
        Rinterpretation = "Less likely to have allergic rhinitis";
      } else if (score >= 8 && score <= 100) {
        Rinterpretation = "Suggests the presence of Allergic Rhinitis";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }


    else if (jsonData['scale_code'] == "BP.Monitoring.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      var resultvar = DataSingleton().resultDataformat;


      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          sysBp = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 2) {
          dysBp = double.tryParse(item['answer'].toString()) ?? 0;
        }
        if (questionid == 3) {
          heartRateBp = double.tryParse(item['answer'].toString()) ?? 0;
        }
      }


      Rinterpretation = "Systolic Blood Pressure: $sysBp mmHg \nDiastolic Blood Pressure: $dysBp mmHg \nHeart Rate: $heartRateBp bpm";


      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '0',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(0);
    }




    else if (jsonData['scale_code'] == 'OSDI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      var resultvar = DataSingleton().resultDataformat;

      int questionid1Count = 1;
      int questionid2Count = 1;
      int questionid3Count = 1;
      int questionid4Count = 1;
      int questionid5Count = 1;
      int questionid6Count = 0;
      int questionid7Count = 0;
      int questionid8Count = 0;
      int questionid9Count = 0;
      int questionid10Count = 0;
      int questionid11Count = 0;
      int questionid12Count = 0;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 6) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid6Count = -1;
          } else {
            questionid6Count = 1;
          }
        }
        if (questionid == 7) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid7Count = -1;
          } else {
            questionid7Count = 1;
          }
        }
        if (questionid == 8) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid8Count = -1;
          } else {
            questionid8Count = 1;
          }
        }
        if (questionid == 9) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid9Count = -1;
          } else {
            questionid9Count = 1;
          }
        }
        if (questionid == 10) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid10Count = -1;
          } else {
            questionid10Count = 1;
          }
        }
        if (questionid == 11) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid11Count = -1;
          } else {
            questionid11Count = 1;
          }
        }
        if (questionid == 12) {
          String answer = item['answer'];
          if (answer == "Not applicable") {
            questionid12Count = -1;
          } else {
            questionid12Count = 1;
          }
        }
      }

      int totalQuestions = 12;

// Calculating the number of answered questions
      int addAnsweredQuestions = totalQuestions;
      if (questionid6Count == -1) {
        addAnsweredQuestions -= 1;
      }
      if (questionid7Count == -1) {
        addAnsweredQuestions -= 1;
      }
      if (questionid8Count == -1) {
        addAnsweredQuestions -= 1;
      }
      if (questionid9Count == -1) {
        addAnsweredQuestions -= 1;
      }
      if (questionid10Count == -1) {
        addAnsweredQuestions -= 1;
      }
      if (questionid11Count == -1) {
        addAnsweredQuestions -= 1;
      }
      if (questionid12Count == -1) {
        addAnsweredQuestions -= 1;
      }


      double adjustedScore = (score / addAnsweredQuestions) * 25.round();


      // Round the adjusted score to the nearest whole number
      int roundedAdjustedScore = adjustedScore.round();


      // Determine the interpretation based on the score for CRP
      if (roundedAdjustedScore >= 0 && roundedAdjustedScore <= 12) {
        Rinterpretation = "Normal";
      } else if (roundedAdjustedScore >= 13 && roundedAdjustedScore <= 22) {
        Rinterpretation = "Mild dry eye disease";
      } else if (roundedAdjustedScore >= 23 && roundedAdjustedScore <= 32) {
        Rinterpretation = "Moderate dry eye disease";
      } else if (roundedAdjustedScore >= 33 && roundedAdjustedScore <= 100) {
        Rinterpretation = "Severe dry eye disease";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$roundedAdjustedScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(roundedAdjustedScore.toDouble());
    } else if (jsonData['scale_code'] == 'DEEP.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      // Determine the interpretation based on the score
      if (score >= 0 && score <= 41) {
        Rinterpretation = "No Evidence of Dry Eye";
      } else if (score >= 42 && score <= 100) {
        Rinterpretation = "Dry Eye is Present";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } //Zesta FSSG Score
    else if (jsonData['scale_code'] == 'FSSG.Score.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      int questionId7 = 0;
      int questionId8 = 0;
      int questionId9 = 0;
      int questionId10 = 0;
      int questionId11 = 0;
      int questionId12 = 0;

      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionI3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;
          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;
          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] ?? 0;
          print("questionId6  $questionId6");
        }
        if (questionid == 7) {
          questionId7 = item['score'] ?? 0;

          print("questionId7  $questionId7");
        }
        if (questionid == 8) {
          questionId8 = item['score'] ?? 0;

          print("questionId8  $questionId8");
        }
        if (questionid == 9) {
          questionId9 = item['score'] ?? 0;

          print("questionId9  $questionId9");
        }
        if (questionid == 10) {
          questionId10 = item['score'] ?? 0;
          print("questionId10  $questionId10");
        }
        if (questionid == 11) {
          questionId11 = item['score'] ?? 0;
          print("questionId11  $questionId11");
        }
        if (questionid == 12) {
          questionId12 = item['score'] ?? 0;
          print("questionId12  $questionId12");
        }
      }

      double reflux = (questionId1 + questionId4 + questionId6 + questionId7 + questionId9 + questionId10 + questionId12).toDouble();
      print("refluxScore $reflux");

      double  dyspeptic =(questionId2 + questionId3 + questionId5 + questionId8 + questionId11).toDouble();
      print("dyspepticScore $dyspeptic");

      print("Total Score:- $score");

      if (score >= 0 && score <= 48) {
        Rinterpretation =
        "FSSG score >= 8 was considered  to indicate probable GERD \n\n Acid reflux related \nsymptom:- ${reflux} \n\n Dyspeptic (Dysmotility) \nsymptom:- ${dyspeptic}";


      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] ==
        'Allergic.Rhinitis.Calculator.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      // var resultvar = DataSingleton().resultDataformat;

      // Determine the interpretation based on the score
      if (score >= 0 && score <= 6) {
        Rinterpretation = "No presence of Allergic Rhinitis";
      } else if (score >= 7) {
        Rinterpretation = "Suggest the presence of Allergic Rhinitis";
      }


      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == "FSSG.Regional.kribado") {
      // print('@@## FSSGGScaleID entered else');

      double dyspeptic = (totalScoreAsInt ~/ 100).toDouble();
      double reflux = totalScoreAsInt % 100;

      DataSingleton().reflux_score_only = reflux;
      DataSingleton().dyspeptic_score_only = dyspeptic;

      double tempResult = dyspeptic + reflux;
      result = tempResult;

      DataSingleton().TotalScore = result;

      if (reflux < 7 && dyspeptic < 6) {
        Rinterpretation = "Acid Reflux- No symptoms found";
        Dinterpretation = "Dyspeptic- No symptoms found";
      } else {
        if (reflux < 7) {
          Rinterpretation = "Acid Reflux- No symptoms found";
        } else if (reflux >= 7) {
          Rinterpretation =
          "Acid Reflux score ${greaterThanOrEqualToSymbol}7 indicates a requirement PCAB maintenance therapy.";
        }

        if (dyspeptic < 6) {
          Dinterpretation = "Dyspeptic- No symptoms found";
        } else if (dyspeptic >= 6) {
          Dinterpretation =
          "Dyspeptic Symptom score ${greaterThanOrEqualToSymbol}6 indicates the need for Prokinetics along with PCAB.";
        }else {
          Dinterpretation = "Dyspeptic- No symptoms found";

        }
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation' "\n" '$Dinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }

    else if (jsonData['scale_code'] == "FSSG.Bangladesh.kribado") {
      // print('@@## FSSGGScaleID entered else');

      double dyspeptic = (totalScoreAsInt ~/ 100).toDouble();
      double reflux = totalScoreAsInt % 100;

      DataSingleton().reflux_score_only = reflux;
      DataSingleton().dyspeptic_score_only = dyspeptic;

      double tempResult = dyspeptic + reflux;
      result = tempResult;

      DataSingleton().TotalScore = result;

      if (reflux < 7 && dyspeptic < 6) {
        Rinterpretation = "Acid Reflux- No symptoms found";
        Dinterpretation = "Dyspeptic- No symptoms found";
      } else {
        if (reflux < 7) {
          Rinterpretation = "Acid Reflux- No symptoms found";
        } else if (reflux >= 7) {
          Rinterpretation =
          "Acid Reflux score ${greaterThanOrEqualToSymbol}7 indicates a requirement PPI maintenance therapy.";
        }

        if (dyspeptic < 6) {
          Dinterpretation = "Dyspeptic- No symptoms found";
        } else if (dyspeptic >= 6) {
          Dinterpretation =
          "Dyspeptic Symptom score ${greaterThanOrEqualToSymbol}6 indicates the need for Prokinetics along with PPI.";
        }else {
          Dinterpretation = "Dyspeptic- No symptoms found";

        }
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation' "\n" '$Dinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }


    else if (jsonData['scale_code'] == "FSSG.Scale.kribado") {
      double dyspeptic = (totalScoreAsInt ~/ 100).toDouble();
      double reflux = totalScoreAsInt % 100;
      DataSingleton().reflux_score_only = reflux;
      DataSingleton().dyspeptic_score_only = dyspeptic;
      double tempResult = dyspeptic + reflux;
      result = tempResult;
      DataSingleton().TotalScore = result;

      if (reflux < 7 && dyspeptic < 6) {
        Rinterpretation = "Acid Reflux- No symptoms found";
        Dinterpretation = "Dyspeptic- No symptoms found";
      } else {
        if (reflux < 7) {
          Rinterpretation = "Acid Reflux- No symptoms found";
        } else if (reflux >= 7) {
          Rinterpretation =
          "Acid Reflux score ${greaterThanOrEqualToSymbol}7 indicates a requirement PPI maintenance therapy.";
        }
        if (dyspeptic < 6) {
          Dinterpretation = "Dyspeptic- No symptoms found";
        } else if (dyspeptic >= 6) {
          Dinterpretation =
          "Dyspeptic Symptom score ${greaterThanOrEqualToSymbol}6 indicates the need for Prokinetics along with PPI.";
        }else {
          Dinterpretation = "Dyspeptic- No symptoms found";

        }
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation' "\n" '$Dinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }


    else if (jsonData['scale_code'] == "ASCVD.Custom.kribado") {

      var resultvar = DataSingleton().resultDataformat;

      int race = 0;
      String totalCholesterol = "";
      String hdlCholesterol = "";
      int hypertensionTreatment = 0;
      String systolicBloodPressure = "";
      int smoker = 0;
      int diabetes = 0;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 2) {        // 2
          race = item['score'] ?? 0;
        }
        if (questionid == 3) {  // 3
          systolicBloodPressure = item['answer'] ?? 0;
        }
        if (questionid == 5) {  //5
          totalCholesterol = item['answer'] ?? 0;
        }
        if (questionid == 6) { // 6
          hdlCholesterol = item['answer'] ?? 0;
        }
        if (questionid == 8) { // 8
          diabetes = item['score'] ?? 0;
        }
        if (questionid == 9) { // 9
          smoker = item['score'] ?? 0;
        }
        if (questionid == 10) { //  10
          hypertensionTreatment = item['score'] ?? 0;
        }
      }

      // print("@@## " + systolicBloodPressure.toString());

      // result= tenYearCalculator(1.0,"Female",20.0,150.0,40.0,1.0,100.0,1.0,1.0);
      result = tenYearCalculator(
          race.toDouble(),
          pat_gender,
          double.parse(pat_age),
          double.parse(totalCholesterol),
          double.parse(hdlCholesterol),
          hypertensionTreatment.toDouble(),
          double.parse(systolicBloodPressure),
          smoker.toDouble(),
          diabetes.toDouble());
      DataSingleton().TotalScore = result;

      if (result >= 0 && result <= 4.9) {
        Rinterpretation =
        "Low Risk";
      } else if (result >= 5 && result < 7.4) {
        Rinterpretation =
        "Borderline Risk";
      } else if (result >= 7.5 && result < 19.9) {
        Rinterpretation =
        "Intermediate Risk";
      } else if (result >= 20){
        Rinterpretation =
        "High Risk";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }





    else if (jsonData['scale_code'] == "GERDQ.kribado.IN") {
      // print("@@##Total " + totalScoreAsInt.toString());

      var resultvar = DataSingleton().resultDataformat;
      // print("@@##Total " + resultvar.toString());
      int combinescore5and6 = 0;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;
        int score = item['score'] ?? 0;
        if (questionid == 5 || questionid == 6) {
          combinescore5and6 = combinescore5and6 + score;
        }
      }

      // print("@@##Total C " + combinescore5and6.toString());
      if (totalScoreAsInt >= 0 && totalScoreAsInt < 8) {
        Rinterpretation = "Low probability for GERD";
      } else if (totalScoreAsInt >= 8 && combinescore5and6 <= 3) {
        Rinterpretation = "GERD with low impact on daily life";
      } else if (totalScoreAsInt >= 8 && combinescore5and6 > 3) {
        Rinterpretation = "GERD with high impact on daily life";
      }

      result = totalScoreAsInt;
      // print('@@##result navigator screen $result');
      DataSingleton().TotalScore = result;

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'].contains("WOMAC.kribado")) {
      result = totalScoreAsInt;
      // print('@@##result navigator screen $totalScoreAsInt');
      DataSingleton().TotalScore = totalScoreAsInt;
      Rinterpretation =
      "Higher scores on the WOMAC indicate worse pain, stiffness, and/or functional limitations.";
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }
    else if (jsonData['scale_code'].contains("iap.growthchart.kribado")) {
      // _insertData(result);

      // print('@@## FSSGGkscale_generic');
      Get.off(
        ResultChartScreen(),
        arguments: {
          'pat_id': pat_id,
          'camp_date': camp_date,
          'test_date': test_date,
          'test_start_time': test_start_time,
          'pat_age': pat_age,
          'pat_name': pat_name,
          'pat_gender': pat_gender
        },
      );
    } else if (jsonData['scale_code'].contains('testing.kribado')) {
      // _insertData(result);

      // print('@@## FSSGGkscale_generic');
      Get.off(result_screen("TESTING", "TESTING", '22', '$Rinterpretation',
          pat_name, pat_age, pat_gender));

      _insertData(22);
    } else if (jsonData['scale_code'] == "PASI.kribado") {
      result = totalScoreAsInt;

      var resultvar = DataSingleton().resultDataformat;
      int questionScore1 = 0;
      int questionScore2 = 0;
      int questionScore3 = 0;
      int questionScore4 = 0;
      int questionScore5 = 0;
      int questionScore6 = 0;
      int questionScore7 = 0;
      int questionScore8 = 0;
      int questionScore9 = 0;
      int questionScore10 = 0;
      int questionScore11 = 0;
      int questionScore12 = 0;
      int questionScore13 = 0;
      int questionScore14 = 0;
      int questionScore15 = 0;
      int questionScore16 = 0;
      int gH = 0;
      double questionScoreD2 = 0.0;
      double questionScoreD3 = 0.0;
      double questionScoreD4 = 0.0;
      int gA = 0;
      double questionScoreD6 = 0.0;
      double questionScoreD7 = 0.0;
      double questionScoreD8 = 0.0;
      int gT = 0;
      double questionScoreD10 = 0.0;
      double questionScoreD11 = 0.0;
      double questionScoreD12 = 0.0;
      int gL = 0;
      double questionScoreD14 = 0.0;
      double questionScoreD15 = 0.0;
      double questionScoreD16 = 0.0;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionScore1 = item['score'] ?? 0;
          gH = questionScore1;

          // print("bvbcfyfhdfsfsfssfs $gH");
        }
        if (questionid == 2) {
          questionScore2 = item['score'] ?? 0;
        }
        if (questionid == 3) {
          questionScore3 = item['score'] ?? 0;
        }
        if (questionid == 4) {
          questionScore4 = item['score'] ?? 0;
        }
        if (questionid == 5) {
          questionScore5 = item['score'] ?? 0;
          gA = questionScore5;

          // print("xvxvxgdgdg $gA");
        }
        if (questionid == 6) {
          questionScore6 = item['score'] ?? 0;
        }
        if (questionid == 7) {
          questionScore7 = item['score'] ?? 0;
        }
        if (questionid == 8) {
          questionScore8 = item['score'] ?? 0;
        }
        if (questionid == 9) {
          questionScore9 = item['score'] ?? 0;
          gT = questionScore9;

          // print("xvxvxgdgdg $gT");
        }
        if (questionid == 10) {
          questionScore10 = item['score'] ?? 0;
        }
        if (questionid == 11) {
          questionScore11 = item['score'] ?? 0;
        }
        if (questionid == 12) {
          questionScore12 = item['score'] ?? 0;
        }
        if (questionid == 13) {
          questionScore13 = item['score'] ?? 0;
          gL = questionScore13;

          // print("iyoyoyoyo $gL");
        }
        if (questionid == 14) {
          questionScore14 = item['score'] ?? 0;
        }
        if (questionid == 15) {
          questionScore15 = item['score'] ?? 0;
        }
        if (questionid == 16) {
          questionScore16 = item['score'] ?? 0;
        }
      }


      int head = ((questionScore2 + questionScore3 + questionScore4) * gH);
      // print("##head : $head");

      int arms = ((questionScore6 + questionScore7 + questionScore8) * gA);
      // print("##arms : $arms");

      int trunk = ((questionScore10 + questionScore11 + questionScore12) * gT);
      // print("##trunk : $trunk");

      int legs = ((questionScore14 + questionScore15 + questionScore16) * gL);
      // print("##legs : $legs");

      // Calculate PASI formula
      double PASI =
          (0.1 * (head)) + (0.2 * (arms)) + (0.3 * (trunk)) + (0.4 * (legs));

      // print('PASI: $PASI');

      DataSingleton().TotalScore = double.parse(PASI.toStringAsFixed(1));

      double totalScore = 22.0;


      if (PASI > 0 && PASI <= 72) {
        Rinterpretation =
        "Higher PASI scores indicate higher severity of psoriasis; scores range from 0 (no disease) to 72 (maximal disease severity";
      } else {
        Rinterpretation = "";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$PASI',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(PASI);
    } else if (jsonData['scale_code'] == "SALT.kribado") {
      result = totalScoreAsInt;

      var resultvar = DataSingleton().resultDataformat;
      int questionScore1 = 0;
      int questionScore2 = 0;
      int questionScore3 = 0;
      int questionScore4 = 0;
      double questionScore11 = 0.0;
      double questionScore22 = 0.0;
      double questionScore33 = 0.0;
      double questionScore44 = 0.0;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionScore1 = item['score'] ?? 0;
          questionScore11 =
              (questionScore1 * 18) / 100; // Multiply by 18 and divide by 100
        }
        if (questionid == 2) {
          questionScore2 = item['score'] ?? 0;
          questionScore22 =
              (questionScore2 * 18) / 100; // Multiply by 20 and divide by 100
        }
        if (questionid == 3) {
          questionScore3 = item['score'] ?? 0;
          questionScore33 =
              (questionScore3 * 40) / 100; // Multiply by 40 and divide by 100
        }
        if (questionid == 4) {
          questionScore4 = item['score'] ?? 0;
          questionScore44 =
              (questionScore4 * 24) / 100; // Multiply by 32 and divide by 100
        }
      }

      double totalScore =
          questionScore11 + questionScore22 + questionScore33 + questionScore44;

      DataSingleton().TotalScore = double.parse(totalScore.toStringAsFixed(1));

      if (totalScore == 0) {
        Rinterpretation = "No symptom for hair loss";
      } else if (totalScore > 0 && totalScore <= 25) {
        Rinterpretation = "Mild hair loss";
      } else if (totalScore >= 26 && totalScore <= 50) {
        Rinterpretation = "Moderate hair loss";
      } else if (totalScore >= 51 && totalScore <= 75) {
        Rinterpretation = "Severe hair loss";
      } else if (totalScore >= 76 && totalScore <= 100) {
        Rinterpretation = "Very severe hair loss";
      } else {
        Rinterpretation = "";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '${DataSingleton().TotalScore}',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(double.parse(totalScore.toStringAsFixed(1)));
    } else if (jsonData['scale_code'] == 'UAS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 0) {
        Rinterpretation =
        "No Symptoms: No wheals or itching, indicating no discomfort";
      } else if (score >= 1 && score <= 1) {
        Rinterpretation =
        "Minimal Symptoms: Minimal wheals or itching, with very little discomfort";
      } else if (score >= 2 && score <= 3) {
        Rinterpretation =
        "Mild Symptoms: Mild wheals or itching present, with manageable discomfort that does not significantly interfere with daily activities";
      } else if (score == 4) {
        Rinterpretation =
        "Moderate Symptoms: Noticeable wheals or itching that may cause some discomfort but generally does not interfere with normal daily activities";
      } else if (score == 5) {
        Rinterpretation =
        "Moderate to Severe Symptoms: Higher level of discomfort with wheals and itching that may begin to interfere with daily activities and/or sleep";
      } else if (score == 6) {
        Rinterpretation =
        "Severe Symptoms: Intense wheals and itching causing significant discomfort, potentially interfering with daily activities and sleep";
      } else {
        Rinterpretation = ""; // Default case if score does not match any range
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'HAS.BLED.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score == 0) {
        Rinterpretation =
        "This score indicates a 1.10% risk of major bleeding within 1 year in patients with atrial fibrillation. The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }
      if (score == 1) {
        Rinterpretation =
        "This score indicates a 3.40% risk of major bleeding within 1 year in patients with atrial fibrillation. The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }
      if (score == 2) {
        Rinterpretation =
        "This score indicates a 4.10% risk of major bleeding within 1 year in patients with atrial fibrillation. The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }
      if (score == 3) {
        Rinterpretation =
        "This score indicates a 5.80% risk of major bleeding within 1 year in patients with atrial fibrillation. The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }
      if (score == 4) {
        Rinterpretation =
        "This score indicates a 8.90% risk of major bleeding within 1 year in patients with atrial fibrillation. The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }
      if (score == 5) {
        Rinterpretation =
        " This score indicates a 9.10% risk of major bleeding within 1 year in patients with atrial fibrillation. The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }
      if (score >= 6) {
        Rinterpretation =
            "This is a very rarely met score, so rarely met that is not often considered in studies and its major bleeding risk is not accounted for in research. However, it is considered to be above the HAS BLED score 5 risk percentage i.e. 9.10%.\n" +
                "The score should be taken in consideration when initiating oral anticoagulation therapy or aspirin intake.";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'UAS7.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 0) {
        Rinterpretation =
        "No Symptoms: No wheals or itching, indicating no discomfort";
      } else if (score >= 1 && score <= 1) {
        Rinterpretation =
        "Minimal Symptoms: Minimal wheals or itching, with very little discomfort";
      } else if (score >= 2 && score <= 3) {
        Rinterpretation =
        "Mild Symptoms: Mild wheals or itching present, with manageable discomfort that does not significantly interfere with daily activities";
      } else if (score == 4) {
        Rinterpretation =
        "Moderate Symptoms: Noticeable wheals or itching that may cause some discomfort but generally does not interfere with normal daily activities";
      } else if (score == 5) {
        Rinterpretation =
        "Moderate to Severe Symptoms: Higher level of discomfort with wheals and itching that may begin to interfere with daily activities and/or sleep";
      } else if (score == 6) {
        Rinterpretation =
        "Severe Symptoms: Intense wheals and itching causing significant discomfort, potentially interfering with daily activities and sleep";
      } else {
        Rinterpretation = ""; // Default case if score does not match any range
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'Antifungal.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 0) {
        Rinterpretation = "";
      } else if (score >= 1 && score <= 1) {
        Rinterpretation =
        "Minimal Symptoms: Minimal wheals or itching, with very little discomfort";
      } else if (score >= 2 && score <= 3) {
        Rinterpretation =
        "Mild Symptoms: Mild wheals or itching present, with manageable discomfort that does not significantly interfere with daily activities";
      } else if (score == 4) {
        Rinterpretation =
        "Moderate Symptoms: Noticeable wheals or itching that may cause some discomfort but generally does not interfere with normal daily activities";
      } else if (score == 5) {
        Rinterpretation =
        "Moderate to Severe Symptoms: Higher level of discomfort with wheals and itching that may begin to interfere with daily activities and/or sleep";
      } else if (score == 6) {
        Rinterpretation =
        "Severe Symptoms: Intense wheals and itching causing significant discomfort, potentially interfering with daily activities and sleep";
      } else {
        Rinterpretation = ""; // Default case if score does not match any range
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'AcneChecklist.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == "ASCVD.risk.kribado") {
      var resultvar = DataSingleton().resultDataformat;

      int race = 0;
      String totalCholesterol = "";
      String hdlCholesterol = "";
      int hypertensionTreatment = 0;
      String systolicBloodPressure = "";
      int smoker = 0;
      int diabetes = 0;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          race = item['score'] ?? 0;
        }
        if (questionid == 2) {
          systolicBloodPressure = item['answer'] ?? 0;
        }
        if (questionid == 4) {
          totalCholesterol = item['answer'] ?? 0;
        }
        if (questionid == 5) {
          hdlCholesterol = item['answer'] ?? 0;
        }
        if (questionid == 7) {
          diabetes = item['score'] ?? 0;
        }
        if (questionid == 8) {
          smoker = item['score'] ?? 0;
        }
        if (questionid == 9) {
          hypertensionTreatment = item['score'] ?? 0;
        }
      }

      // print("@@## " + systolicBloodPressure.toString());

      // result= tenYearCalculator(1.0,"Female",20.0,150.0,40.0,1.0,100.0,1.0,1.0);
      result = tenYearCalculator(
          race.toDouble(),
          pat_gender,
          double.parse(pat_age),
          double.parse(totalCholesterol),
          double.parse(hdlCholesterol),
          hypertensionTreatment.toDouble(),
          double.parse(systolicBloodPressure),
          smoker.toDouble(),
          diabetes.toDouble());
      DataSingleton().TotalScore = result;

      if (result < 5) {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is less than 5%. Indicating Low risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      } else if (result >= 5 && result < 7.5) {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is between 5% - 7.4%. Indicating Borderline risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      } else if (result >= 7.5 && result < 20) {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is between 7.5% - 19.99%, Indicating Intermediate risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      } else {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is greater than 19.99%, Indicating High risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == "ASCVD.risk.estimator.kribado") {
      var resultvar = DataSingleton().resultDataformat;

      // print('@@## ' + resultvar.toString());
      int race = 0;
      String totalCholesterol = "";
      String hdlCholesterol = "";
      int hypertensionTreatment = 0;
      String systolicBloodPressure = "";
      int smoker = 0;
      int diabetes = 0;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          race = item['score'] ?? 0;
        }
        if (questionid == 2) {
          systolicBloodPressure = item['answer'] ?? 0;
        }
        if (questionid == 4) {
          totalCholesterol = item['answer'] ?? 0;
        }
        if (questionid == 5) {
          hdlCholesterol = item['answer'] ?? 0;
        }
        if (questionid == 6) {
          diabetes = item['score'] ?? 0;
        }
        if (questionid == 7) {
          smoker = item['score'] ?? 0;
        }
        if (questionid == 8) {
          hypertensionTreatment = item['score'] ?? 0;
        }
      }

      // print("@@## " + systolicBloodPressure.toString());

      // result= tenYearCalculator(1.0,"Female",20.0,150.0,40.0,1.0,100.0,1.0,1.0);
      result = tenYearCalculator(
          race.toDouble(),
          pat_gender,
          double.parse(pat_age),
          double.parse(totalCholesterol),
          double.parse(hdlCholesterol),
          hypertensionTreatment.toDouble(),
          double.parse(systolicBloodPressure),
          smoker.toDouble(),
          diabetes.toDouble());
      DataSingleton().TotalScore = result;

      if (result < 5) {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is less than 5%. Indicating Low risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      } else if (result >= 5 && result < 7.5) {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is between 5% - 7.4%. Indicating Borderline risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      } else if (result >= 7.5 && result < 20) {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is between 7.5% - 19.99%, Indicating Intermediate risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      } else {
        Rinterpretation =
        "The 10-year ASCVD calculated risk is greater than 19.99%, Indicating High risk.Kindly consult your doctor for appropriate guidance and timely treatment interventions.";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == 'Asthma.kribado') {
      // _insertData(result);
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score < 4) {
        Rinterpretation = "No asthma";
      } else {
        Rinterpretation = "Asthma";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender));

      _insertData(score);
    } else if (jsonData['scale_code'] == 'COPD.kribado') {
      // _insertData(result);
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 10) {
        Rinterpretation =
        "Low: Indicates mild to minimal impact of COPD on daily life";
      } else if (score >= 11 && score <= 20) {
        Rinterpretation =
        "Medium: Suggests a moderate impact of COPD on daily life";
      } else if (score >= 21 && score <= 30) {
        Rinterpretation = "High: Indicates a high impact of COPD on daily life";
      } else if (score >= 31 && score <= 40) {
        Rinterpretation =
        "Very high: Suggests a very high impact of COPD on daily life";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender));

      _insertData(score);
    } else if (jsonData['scale_code'] == 'AcneGrading.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] * 2 ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] * 2 ?? 0;

          print("questionId1  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] * 2 ?? 0;

          print("questionId3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;
          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;
          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] * 3 ?? 0;
          print("questionId6  $questionId6");
        }
      }

      int totalScore = (questionId1 +
          questionId2 +
          questionId3 +
          questionId4 +
          questionId5 +
          questionId6);
      print("TotalScore $totalScore");
      if (totalScore == 0) {
        Rinterpretation =
        "The patient is suffering from Grade 0 acne.The patient has clear skin with no visible signs of acne";
      } else if (totalScore >= 1 && totalScore <= 18) {
        Rinterpretation = "The patient is suffering from Grade I acne (Mild)";
      } else if (totalScore >= 19 && totalScore <= 30) {
        Rinterpretation =
        "The patient is suffering from Grade II acne (Moderate)";
      } else if (totalScore >= 31 && totalScore <= 38) {
        Rinterpretation =
        "The patient is suffering from Grade III acne (Severe)";
      } else if (totalScore >= 39 && totalScore <= 100) {
        Rinterpretation =
        "The patient is suffering from Grade IV acne (Very Severe)";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$totalScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'Melasma.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      double newScore = 0;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      int questionId7 = 0;
      int questionId8 = 0;
      int questionId9 = 0;
      int questionId10 = 0;
      int questionId11 = 0;
      int questionId12 = 0;
      double forehead = 0, rMelar = 0, lMelar = 0, chin = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionI3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;
          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;
          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] ?? 0;
          print("questionId6  $questionId6");
        }
        if (questionid == 7) {
          questionId7 = item['score'] ?? 0;

          print("questionId7  $questionId7");
        }
        if (questionid == 8) {
          questionId8 = item['score'] ?? 0;

          print("questionId8  $questionId8");
        }
        if (questionid == 9) {
          questionId9 = item['score'] ?? 0;

          print("questionId9  $questionId9");
        }
        if (questionid == 10) {
          questionId10 = item['score'] ?? 0;
          print("questionId10  $questionId10");
        }
        if (questionid == 11) {
          questionId11 = item['score'] ?? 0;
          print("questionId11  $questionId11");
        }
        if (questionid == 12) {
          questionId12 = item['score'] ?? 0;
          print("questionId12  $questionId12");
        }
      }
      forehead = 0.3 * questionId1 * (questionId5 + questionId9);

      rMelar = 0.3 * questionId2 * (questionId6 + questionId10);

      lMelar = 0.3 * questionId3 * (questionId7 + questionId11);

      chin = 0.1 * questionId4 * (questionId8 + questionId12);


      newScore = forehead + rMelar + lMelar + chin;

      if (newScore >= 0 && newScore <= 16.9) {
        Rinterpretation = "The patient is suffering from Mild Melasma";
      } else if (newScore >= 17 && newScore <= 32.9) {
        Rinterpretation = "The patient is suffering from Moderate Melasma";
      } else if (newScore >= 33 && newScore <= 48) {
        Rinterpretation = "The patient is suffering from Severe Melasma";
      }
// Assuming `decfor` is a DecimalFormat object in Java
// In Dart, you can use `String.format` or just round to a specific number of decimal places
      newScore = double.parse(
          newScore.toStringAsFixed(2)); // Format to 2 decimal places
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$newScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(newScore);
    } else if (jsonData['scale_code'] == 'PANSS.kribado') {
      // _insertData(result);
      double panssScore = totalScoreAsInt;
      DataSingleton().TotalScore = panssScore;

      if (panssScore <= 57) {
        Rinterpretation = "Not ill";
      } else if (panssScore >= 58 && panssScore <= 74) {
        Rinterpretation = "Mildly ill";
      } else if (panssScore >= 75 && panssScore <= 94) {
        Rinterpretation = "Moderately ill";
      } else if (panssScore >= 95 && panssScore <= 115) {
        Rinterpretation = "Markedly ill";
      } else if (panssScore >= 116) {
        Rinterpretation = "Severely ill";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$panssScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender));

      _insertData(panssScore);
    }


    else if (jsonData['scale_code'] == 'COPD.risk.kribado') {
      // _insertData(result);
      double pedisScore = totalScoreAsInt;
      DataSingleton().TotalScore = pedisScore;

      if (pedisScore >= 0 && pedisScore <= 6) {
        Rinterpretation = "Low risk for COPD";
      } else if (pedisScore >= 7 && pedisScore <= 12) {
        Rinterpretation = "Moderate risk for COPD";
      } else if (pedisScore >= 13) {
        Rinterpretation = "High risk for COPD seek further evaluation or spirometry testing.";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$pedisScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender));

      _insertData(pedisScore);
    }






    else if (jsonData['scale_code'] == 'PedisScore.kribado') {
      // _insertData(result);
      double pedisScore = totalScoreAsInt;
      DataSingleton().TotalScore = pedisScore;

      if (pedisScore >= 0 && pedisScore <= 6) {
        Rinterpretation = "Low Risk";
      } else if (pedisScore >= 7 && pedisScore <= 15) {
        Rinterpretation = "High Risk";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$pedisScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender));

      _insertData(pedisScore);
    } else if (jsonData['scale_code'] == 'YBOCS.kribado') {
      double yobcScore = totalScoreAsInt;
      DataSingleton().TotalScore = yobcScore;

      if (yobcScore >= 0 && yobcScore <= 7) {
        Rinterpretation = "Subclinical. Few, if any, symptoms of OCD.";
      } else if (yobcScore >= 8 && yobcScore <= 15) {
        Rinterpretation =
        "Mild. OCD symptoms are present but manageable; they do not dominate the person's daily functioning.";
      } else if (yobcScore >= 16 && yobcScore <= 23) {
        Rinterpretation =
        "Moderate. OCD symptoms are easily noticeable and pose a significant challenge, interfering regularly with functioning.";
      } else if (yobcScore >= 24 && yobcScore <= 31) {
        Rinterpretation =
        "Severe. OCD symptoms are pervasive and very distressing, substantially interfering with daily functioning.";
      } else if (yobcScore >= 32 && yobcScore <= 40) {
        Rinterpretation =
        "Extreme. OCD symptoms are incapacitating, dominating the individual's functioning.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$yobcScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(yobcScore);
    } else if (jsonData['scale_code'] == 'HDRS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 7) {
        Rinterpretation = "Normal";
      } else if (score >= 8 && score <= 13) {
        Rinterpretation = "Mild depression";
      } else if (score >= 14 && score <= 18) {
        Rinterpretation = "Moderate depression";
      } else if (score >= 19 && score <= 22) {
        Rinterpretation = "Severe depression";
      } else if (score >= 23) {
        Rinterpretation = "Very severe depression";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'WatchDm.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 7) {
        Rinterpretation =
        "5-year risk of heart failure is very low, with a risk of only 1.1%";
      } else if (score >= 8 && score <= 9) {
        Rinterpretation =
        "5-year risk of heart failure is low, with a risk of only 3.6%";
      } else if (score >= 10 && score <= 10) {
        Rinterpretation =
        "5-year risk of heart failure is average, with a risk of only 4.7%";
      } else if (score >= 11 && score <= 13) {
        Rinterpretation =
        "5-year risk of heart failure is high, with a risk of only 9.2%";
      } else if (score >= 14 && score <= 35) {
        Rinterpretation =
        "5-year risk of heart failure is very high, with a risk of only 17.4%";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'Allevia.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 20) {
        Rinterpretation = "Inflammatory Back Pain (IBP)";
      } else if (score >= 21 && score <= 30) {
        Rinterpretation = "Suspect Inflammatory Back Pain (IBP)";
      } else if (score >= 31 && score <= 40) {
        Rinterpretation = "Suspect Chronic Mechanical Back Pain (MBP)";
      } else if (score >= 41 && score <= 100) {
        Rinterpretation =
        "5-year risk of heart failure is high, with a risk of only 9.2%";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'UrologyAUAScore.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if ((score >= 0) && (score <= 7)) {
        Rinterpretation = "Mild BPH";
      } else if ((score >= 8) && (score <= 19)) {
        Rinterpretation = "Moderate BPH";
      } else if ((score >= 20) && (score <= 35)) {
        Rinterpretation = "Severe BPH";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'CHESS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score == 0) {
        Rinterpretation = "You are not suffering";
      } else if (score >= 1 && score <= 3) {
        Rinterpretation =
        "You are suffering from Covert HE (Hepatic Encephalopathy). Kindly consult your doctor for further details";
      } else if (score >= 4 && score <= 100) {
        Rinterpretation =
        "You are suffering from Overt HE (Hepatic Encephalopathy ). Kindly consult your doctor for further details";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    //RADAI.kribado
    else if (jsonData['scale_code'] == 'RADAI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;

          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;

          print("questionId5  $questionId5");
        }
      }
      int sumOFall=questionId1+questionId2+questionId3+questionId4+questionId5;
      score=sumOFall/5;
      if (score >= 0 && score <= 1.4) {
        Rinterpretation = "A remission-like state";
      } else if (score >= 1.5 && score <= 3.0) {
        Rinterpretation =
        "Mild disease activity";
      } else if (score >= 3.1 && score <= 5.4) {
        Rinterpretation =
        "Moderate disease activity";
      }else if (score >= 5.5 && score <= 10.0) {
        Rinterpretation =
        "High disease activity";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    //  HCG.kribado
    else if (jsonData['scale_code'] == 'HCG.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
      }
      // Calculate the absolute difference and cast to double
      int absoluteDifference = (questionId2 - questionId1);
      print('Absolute difference: $absoluteDifference'"mlU/ml");
      // Calculate percentage difference
      double Percentagedifference = (absoluteDifference / questionId1) * 100;
      Percentagedifference = double.parse(Percentagedifference.toStringAsFixed(2));
      print("Percentage difference: ${Percentagedifference.toStringAsFixed(2)} %");
      // Log base 2 calculation
      double log2(double x) => log(x) / log(2);
      // Doubling time calculation
      double doublingTime = questionId3 / log2(questionId2 / questionId1);
      doublingTime = double.parse(doublingTime.toStringAsFixed(1));
      print('Doubling time: ${doublingTime.toStringAsFixed(1)} hours');
      // One-Day Increase Calculation
      double exponent = 24 / doublingTime;
      double oneDayIncrease = (pow(2, exponent) - 1) * 100;
      oneDayIncrease = double.parse(oneDayIncrease.toStringAsFixed(2));
      print("One-Day Increase: ${oneDayIncrease.toStringAsFixed(2)}%");
      // Two-Day Increase Calculation
      double exponent1 = 48 / doublingTime;
      double twoDayIncrease = (pow(2, exponent1) - 1) * 100;
      twoDayIncrease = double.parse(twoDayIncrease.toStringAsFixed(2));
      print("Two-Day Increase: ${twoDayIncrease.toStringAsFixed(2)}%");
      DataSingleton().absoluteDifference = absoluteDifference;
      DataSingleton().Percentagedifference = Percentagedifference;
      DataSingleton().doublingTime = doublingTime;
      DataSingleton().oneDayIncrease = oneDayIncrease;
      DataSingleton().twoDayIncrease = twoDayIncrease;
      if (DataSingleton().scale_id == "HCG.kribado") {
        Rinterpretation=
        "\nAbsolute Difference: ${DataSingleton().absoluteDifference}"'mlU/ml'
            '\n\n' "\nPercentage difference: ${DataSingleton()
            .Percentagedifference}"'%'
            '\n\n'"\nDoubling time: ${DataSingleton().doublingTime}"'hours'
            '\n\n' "\nOne-day increase: ${DataSingleton().oneDayIncrease}" '%'
            '\n\n'"\nTwo-day increase : ${DataSingleton().twoDayIncrease}"'%';
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '0',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );
      _insertData(0);
    }
    //MDQ
    else if (jsonData['scale_code'] == 'MDQ.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      int questionId7 = 0;
      int questionId8 = 0;
      int questionId9 = 0;
      int questionId10 = 0;
      int questionId11 = 0;
      int questionId12 = 0;
      int questionId13 = 0;
      int questionId14 = 0;
      int questionId15 = 0;
      int questionId16= 0;
      int questionId17= 0;
      var resultvar = DataSingleton().resultDataformat;

      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;

          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;

          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] ?? 0;

          print("questionId6  $questionId6");
        }
        if (questionid == 7) {
          questionId7 = item['score'] ?? 0;

          print("questionId7  $questionId7");
        }
        if (questionid == 8) {
          questionId8 = item['score'] ?? 0;

          print("questionId8  $questionId8");
        }
        if (questionid == 9) {
          questionId9 = item['score'] ?? 0;

          print("questionId9  $questionId9");
        }
        if (questionid == 10) {
          questionId10 = item['score'] ?? 0;

          print("questionId10  $questionId10");
        }
        if (questionid == 11) {
          questionId11 = item['score'] ?? 0;

          print("questionId11  $questionId11");
        }
        if (questionid == 12) {
          questionId12 = item['score'] ?? 0;
          print("questionId12  $questionId12");
        }
        if (questionid == 13) {
          questionId13 = item['score'] ?? 0;

          print("questionId13  $questionId13");
        }
        if (questionid == 14) {
          questionId14 = item['score'] ?? 0;

          print("questionId14  $questionId14");
        }
        if (questionid == 15) {
          questionId15 = item['score'] ?? 0;

          print("questionId15  $questionId15");
        }
        if (questionid == 16) {
          questionId16 = item['score'] ?? 0;

          print("questionId16  $questionId16");
        }
        if (questionid == 17) {
          questionId17 = item['score'] ?? 0;

          print("questionId17  $questionId17");
        }
      }
      int count=questionId1+questionId2+questionId3+questionId4+questionId5+questionId6+questionId7+questionId8+questionId9+questionId10+questionId11+questionId12+questionId13;
      print("Count $count");
      print("questionId14 $questionId14");
      print("questionId15 $questionId15");
      if (count >= 7 && questionId14==1 && (questionId15==2 || questionId15==3)) {
        Rinterpretation = "Further medical assessment for bipolar\n" +
            "disorder is clearly warranted";
      } else {
        Rinterpretation = "No further assessment needed for bipolar disorder";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '0',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );
      _insertData(score);
    }
    //PregnancyWeight
    else if (jsonData['scale_code'] == 'PregnancyWeight.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
      }
      //For BMI Calculation
      double  height=questionId2/100;
      double bmi=questionId1/(height*height);
      String formattedBmi = bmi.toStringAsFixed(2);
      score = double.parse(formattedBmi);

      if(questionId3==1) {
        if (score >= 0 && score <= 18.4) {
          Rinterpretation = "Underweight\nYou need to put on 13-18 kgs.";
        } else if (score >= 18.5 && score < 25) {
          Rinterpretation =
          "Normal Weight\nYou need to put on 17-25 kgs.";
        } else if (score >= 25 && score <= 29) {
          Rinterpretation =
          "Overweight\nYou need to put on 14-23 kgs";
        }
        else if (score >= 30 && score <= 100) {
          Rinterpretation =
          "Obese\nYou need to put on 11-19 kgs.";
        }
      }else{
        if (score >= 0 && score <= 18.4) {
          Rinterpretation = "Underweight\nYou need to put on 13-18 kgs.";
        } else if (score >= 18.5 && score < 25) {
          Rinterpretation =
          "Normal Weight\nYou need to put on 11-16 kgs.";
        } else if (score >= 25 && score <= 29) {
          Rinterpretation =
          "Overweight\nYou need to put on 7-11 kgs.";
        }
        else if (score >= 30 && score <= 100) {
          Rinterpretation =
          "Obese\nYou need to put on 5-9 kgs.";
        }
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    else if (jsonData['scale_code'] == 'GCSI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score == 0) {
        Rinterpretation = "You are not suffering";
      } else if (score >= 1 && score <= 3) {
        Rinterpretation =
        "You are suffering from Covert HE (Hepatic Encephalopathy). Kindly consult your doctor for further details";
      } else if (score >= 4 && score <= 100) {
        Rinterpretation =
        "You are suffering from Overt HE (Hepatic Encephalopathy ). Kindly consult your doctor for further details";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    // else if (jsonData['scale_code'] == 'RMQ.kribado') {
    //   double score = totalScoreAsInt;
    //   DataSingleton().TotalScore = score;
    //   Get.off(
    //     result_screen(
    //       DataSingleton().scale_name,
    //       DataSingleton().scale_name,
    //       '$score',
    //       Rinterpretation,
    //       pat_name,
    //       pat_age,
    //       pat_gender,
    //     ),
    //   );
    //
    //   _insertData(score);
    // }
    else if (jsonData['scale_code'] == 'HLSS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 5) {
        Rinterpretation =
        "Minimal or no hair loss. Monitoring suggested; no immediate interventions needed.";
      } else if (score >= 6 && score <= 10) {
        Rinterpretation =
        "Mild hair loss. Cosmetic treatments or preventive measures may be considered.";
      } else if (score >= 11 && score <= 15) {
        Rinterpretation =
        "Moderate hair loss. Medical intervention is recommended, which might include topical treatments or consultations for potential therapies.";
      } else if (score >= 16 && score <= 20) {
        Rinterpretation =
        "Severe hair loss with significant impact on life. Aggressive treatment strategies such as medication, hair transplantation, or comprehensive dermatological evaluation are recommended.";
      } else if (score >= 21 && score <= 100) {
        Rinterpretation =
        "Extremely severe condition, potentially indicative of underlying health issues. Urgent medical evaluation and treatment are necessary, possibly including detailed hormonal and nutritional assessments.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    else if (jsonData['scale_code'] == 'HbA1c.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '0',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    else if (jsonData['scale_code'] == 'RCAT.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score >= 0 && score <= 17) {
        Rinterpretation = "Patient has poorly controlled rhinitis symptoms";
      } else if (score >= 18 && score <= 100) {
        Rinterpretation = "Patient's rhinitis symptoms are controlled";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'CAD.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score < 4) {
        Rinterpretation = "Low-risk group";
      } else {
        if (score > 6) {
          Rinterpretation = "High-risk group";
        } else {
          Rinterpretation = "Intermediate-risk group";
        }
        Get.off(
          result_screen(
            DataSingleton().scale_name,
            DataSingleton().scale_name,
            '$score',
            Rinterpretation,
            pat_name,
            pat_age,
            pat_gender,
          ),
        );

        _insertData(score);
      }
    } else if (jsonData['scale_code'] == 'OABSS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score >= 0 && score <= 1) {
        Rinterpretation = "No Risk";
      } else if (score >= 2 && score <= 7) {
        Rinterpretation = "Mild Risk";
      } else if (score >= 8 && score <= 12) {
        Rinterpretation = "Moderate Risk";
      } else if (score >= 13 && score <= 15) {
        Rinterpretation = "Severe Risk";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'IronDeficiency.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score > 1) {
        Rinterpretation =
        "The symptoms are likely due to Iron deficiency. Please Consult a doctor for diagnosis.";
      } else {
        Rinterpretation =
        "The symptom is likely due to other underlying issue.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }

    // else if (jsonData['scale_code'] == 'DepressionAnxietyStress.kribado') {
    //   double score = totalScoreAsInt;
    //   DataSingleton().TotalScore = score;
    //   int depressionScore = 0;
    //   int anxietyScore = 0;
    //   int stressScore = 0;
    //   String depressionInterpretation = "";
    //   String anxietyInterpretation = "";
    //   String stressInterpretation = "";
    //   String interpretation = "";
    //   String question="";
    //   for (var q in questions) {
    //     if (q.category == "Depression") {
    //       depressionScore += q.point.toInt();
    //     } else if (q.category == "Anxiety") {
    //       anxietyScore += q.point.toInt();
    //     } else {
    //       stressScore += q.point.toInt();
    //     }
    //   }
    //
    //   if(score >= 0 && score <=5)
    //   {
    //     Rinterpretation="Minimal or no hair loss. Monitoring suggested; no immediate interventions needed.";
    //   }
    //   else if(score >= 6 && score <=10)
    //   {
    //     Rinterpretation="Mild hair loss. Cosmetic treatments or preventive measures may be considered.";
    //   }
    //   else if (score >= 11 && score <=15)
    //   {
    //     Rinterpretation="Moderate hair loss. Medical intervention is recommended, which might include topical treatments or consultations for potential therapies.";
    //   }
    //   else if (score >= 16 && score <=20)
    //   {
    //     Rinterpretation="Severe hair loss with significant impact on life. Aggressive treatment strategies such as medication, hair transplantation, or comprehensive dermatological evaluation are recommended.";
    //   }else if (score >=21 && score<=100)
    //   {
    //     Rinterpretation="Extremely severe condition, potentially indicative of underlying health issues. Urgent medical evaluation and treatment are necessary, possibly including detailed hormonal and nutritional assessments.";
    //   }
    //   Get.off(
    //     result_screen(
    //       DataSingleton().scale_name,
    //       DataSingleton().scale_name,
    //       '$score',
    //       Rinterpretation,
    //       pat_name,
    //       pat_age,
    //       pat_gender,
    //     ),
    //   );
    //
    //   _insertData(score);
    // }
    else if (jsonData['scale_code'] == 'DEQ5.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 6) {
        Rinterpretation = "Suspect Dry Eye";
      } else if (score >= 7 && score <= 25) {
        Rinterpretation = "Suspect Sjogren's Syndrome";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'Cataract.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score == 0) {
        Rinterpretation =
        "You don't seem to be suffering from cataract. Kindly consult your doctor for further evaluation";
      } else if (score >= 1 && score <= 100) {
        Rinterpretation =
        "You might be at risk of developing cataract. Kindly consult your doctor for further evalution.";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }
    else if (jsonData['scale_code'] == 'DLQI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      var questions;
      for (var question in questions) {
        if (question.id == 7) {
          score++;
        }
      }
      if (score <= 1) {
        Rinterpretation = "No effect at all on patient's life";
      } else if (score <= 5) {
        Rinterpretation = "Small effect on patient's life";
      } else if (score <= 10) {
        Rinterpretation = "Moderate effect on patient's life";
      } else if (score <= 20) {
        Rinterpretation = "Very large effect on patient's life";
      } else {
        Rinterpretation = "Extremely large effect on patient's life";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'Hexangin.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 1) {
        Rinterpretation =
        "Further investigation is not required.Consult your physician for more information";
      } else if (score >= 2 && score <= 100) {
        Rinterpretation = "Require further evaluation by the physician";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'Eunykta.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 1) {
        Rinterpretation =
        "Indicates no sleep impairment and physician evaluation not required";
      } else if (score >= 2 && score <= 10) {
        Rinterpretation =
        "Indicates a likelihood of sleep impairment and need for a physician evaluation";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );
      _insertData(score);
    } else if (jsonData['scale_code'] == 'OxidativeStress.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 1) {
        Rinterpretation = "Risk factors associated with oxidative stress";
      } else if (score >= 2 && score <= 5) {
        Rinterpretation = "Risk factor is not associated with oxidative stress";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'TIMIRiskHFDiabetes.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score == 0) {
        Rinterpretation =
        "Incidence rate of hospitalization for heart failure 2.4 (per 1000 patient-years)";
      } else if (score == 1) {
        Rinterpretation =
        "Incidence rate of hospitalization for heart failure 4.4 (per 1000 patient-years)";
      } else if (score == 2) {
        Rinterpretation =
        "Incidence rate of hospitalization for heart failure 13.1 (per 1000 patient-years)";
      } else if (score == 3) {
        Rinterpretation =
        "Incidence rate of hospitalization for heart failure 28.7 (per 1000 patient-years)";
      } else if (score >= 4 && score <= 100) {
        Rinterpretation =
        "Incidence rate of hospitalization for heart failure 56.1 (per 1000 patient-years)";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'TIMISTEMI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      if (score == 0) {
        Rinterpretation =
        "This score indicates 0.8% mortality risk in 30 days.";
      } else if (score == 1) {
        Rinterpretation =
        "This score indicates 1.6% mortality risk in 30 days.";
      } else if (score == 2) {
        Rinterpretation =
        "This score indicates 2.2% mortality risk in 30 days.";
      } else if (score == 3) {
        Rinterpretation =
        "This score indicates 4.4% mortality risk in 30 days.";
      } else if (score == 4) {
        Rinterpretation =
        "This score indicates 7.3% mortality risk in 30 days.";
      } else if (score == 5) {
        Rinterpretation =
        "This score indicates 12.4% mortality risk in 30 days.";
      } else if (score == 6) {
        Rinterpretation =
        "This score indicates 16.1% mortality risk in 30 days.";
      } else if (score == 7) {
        Rinterpretation =
        "This score indicates 23.4% mortality risk in 30 days.";
      } else if (score == 8) {
        Rinterpretation =
        "This score indicates 26.8% mortality risk in 30 days.";
      } else {
        Rinterpretation = "This score indicates 36% mortality risk in 30 days.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'TIMINSTEMI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 1) {
        Rinterpretation =
        "This score indicates a mortality and major cardiac event risk of 5% in the first 2 weeks.";
      } else if (score == 2) {
        Rinterpretation =
        "This score indicates a mortality and major cardiac event risk of 8% in the first 2 weeks.";
      } else if (score == 3) {
        Rinterpretation =
        "This score indicates a mortality and major cardiac event risk of 13% in the first 2 weeks.";
      } else if (score == 4) {
        Rinterpretation =
        "This score indicates a mortality and major cardiac event risk of 20% in the first 2 weeks.";
      } else if (score == 5) {
        Rinterpretation =
        "This score indicates a mortality and major cardiac event risk of 26% in the first 2 weeks.";
      } else if (score >= 6 && score <= 7) {
        Rinterpretation =
        "This score indicates a mortality and major cardiac event risk of 41% in the first 2 weeks.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'AllergicRhinitisCustom.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      int questionId7 = 0;
      int questionId8 = 0;
      int questionId9 = 0;
      int questionId10 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId1  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;
          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;
          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] ?? 0;
          print("questionId6  $questionId6");
        }
        if (questionid == 7) {
          questionId7 = item['score'] ?? 0;

          print("questionId7  $questionId7");
        }
        if (questionid == 8) {
          questionId8 = item['score'] ?? 0;
          print("questionId8  $questionId8");
        }
        if (questionid == 9) {
          questionId9 = item['score'] ?? 0;
          print("questionId9  $questionId9");
        }
        if (questionid == 10) {
          questionId10 = item['score'] ?? 0;
          print("questionId10  $questionId10");
        }
      }

      int totalScore = (questionId1 +
          questionId2 +
          questionId3 +
          questionId4 +
          questionId5 +
          questionId6 +
          questionId7 +
          questionId8 +
          questionId9 +
          questionId10);
      print("TotalScore $totalScore");
      if (totalScore >= 0 && totalScore <= 5) {
        Rinterpretation = "Normal";
      } else if (totalScore >= 6 && totalScore <= 13) {
        Rinterpretation = "Mild";
      } else if (totalScore >= 14 && totalScore <= 22) {
        Rinterpretation = "Moderate";
      } else if (totalScore >= 23 && totalScore <= 31) {
        Rinterpretation = "Severe";
      } else if (totalScore >= 32) {
        Rinterpretation = "Very Severe";
      } else {
        Rinterpretation = "";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$totalScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(totalScore.toDouble());
    } else if (jsonData['scale_code'] == 'BASDAI.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;
      int questionId1 = 0;
      int questionId2 = 0;
      int questionId3 = 0;
      int questionId4 = 0;
      int questionId5 = 0;
      int questionId6 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId1  $questionId2");
        }
        if (questionid == 3) {
          questionId3 = item['score'] ?? 0;

          print("questionId3  $questionId3");
        }
        if (questionid == 4) {
          questionId4 = item['score'] ?? 0;
          print("questionId4  $questionId4");
        }
        if (questionid == 5) {
          questionId5 = item['score'] ?? 0;
          print("questionId5  $questionId5");
        }
        if (questionid == 6) {
          questionId6 = item['score'] ?? 0;
          print("questionId6  $questionId6");
        }
      }

      double totalScore = (questionId1 +
          questionId2 +
          questionId3 +
          questionId4 +
          ((questionId5 + questionId6) / 2)) /
          5;

      print("TotalScore $totalScore");
      if (totalScore >= 0 && totalScore <= 500) {
        Rinterpretation =
        "BASDAI scores of 4 or greater suggest suboptimal control of disease. These patients may be candidates for new medical therapy or enrolment in clinical trials.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$totalScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(totalScore);
    } else if (jsonData['scale_code'] == 'VaginalDryness.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      Rinterpretation = "Higher the score, more the chances of vaginal dryness";

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == 'VAS.kribado') {
      double vasScore = totalScoreAsInt;
      DataSingleton().TotalScore = vasScore;

      // Determine the interpretation based on the score
      if (vasScore >= 0 && vasScore <= 19) {
        Rinterpretation = "Well-controlled Allergic Rhinitis";
      } else if (vasScore >= 20 && vasScore <= 49) {
        Rinterpretation = "Partially controlled Allergic Rhinitis";
      } else if (vasScore >= 50 && vasScore <= 100) {
        Rinterpretation = "Uncontrolled Allergic Rhinitis";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$vasScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(vasScore);
    } else if (jsonData['scale_code'] == "TNSS.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result == 0) {
        Rinterpretation =
        "You have no nasal symptoms, indicating good nasal health.";
      } else if (result >= 1 && result < 6) {
        Rinterpretation =
        "Your nasal symptoms are considered mild. It is advisable to monitor your symptoms and consult your doctor if they persist or worsen.";
      } else if (result >= 6 && result <= 9) {
        Rinterpretation =
        "Your nasal symptoms are considered moderate. Consulting your doctor for possible treatments could help manage your symptoms more effectively.";
      } else if (result > 9) {
        Rinterpretation =
        "Your nasal symptoms are considered severe. It is recommended to consult your doctor for a thorough evaluation and potential treatment options to improve your quality of life.";
      } else {
        Rinterpretation = "";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }

    //IBS scale for child parent scale
    else if (jsonData['scale_code'] == "IBS.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      var resultvar = DataSingleton().resultDataformat;
      print('eiteiteoitkfkfskfn $resultvar');
      Map<int, double> finalScores = {};
      bool isQ1AnswerNo = false;

      for (var item in resultvar) {
        int questionId = item['question_id'];
        double score = (item['score'] as num).toDouble();
        bool isChild = item.containsKey('child_id');
        var answer = item['answer'];

        // Store only child score if it exists; overwrite parent
        if (isChild || !finalScores.containsKey(questionId)) {
          finalScores[questionId] = score;
          if (questionId == 1 && answer.toString().toLowerCase() == 'no' || questionId==2 && answer.toString().toLowerCase()== 'yes') {
            isQ1AnswerNo = true;
          }
        }
      }
      // Now access them
      double questionId1 = finalScores[1] ?? 0;
      double questionId2 = finalScores[2] ?? 0;
      double questionId3 = finalScores[3] ?? 0;
      double questionId4 = finalScores[4] ?? 0;
      // print('q1No: $q1No'); // 50.0
      // double questionId1 = finalScores[1] ?? 0;
      if (isQ1AnswerNo) {
        print('About to multiply questionId1: $questionId1');
        questionId1 = questionId1 * 100;
        print('multipliedValue: $questionId1');
      }
      print('Q1: $questionId1'); // 50.0
      print('Q2: $questionId2'); // 75.0
      print('Q3: $questionId3'); // 67.0
      print('Q4: $questionId4'); // 100.0
      result=questionId1+questionId2+questionId3+questionId4;
      if (result==0) {
        Rinterpretation = "No IBS";
      } else if (result>=75 && result<175) {
        Rinterpretation =
        "Mild";
      }else if(result>=176 && result<=300){
        Rinterpretation="Moderate";
      }else if(result>300){
        Rinterpretation="Severe";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }






    else if (jsonData['scale_code'] == "CSI.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;
      if (result >= 0 && result <= 30) {
        Rinterpretation = "Normal";
      } else if (result >= 31 && result <= 100) {
        Rinterpretation = "Your cough may be impacting on your quality of life";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == "Allergic.Rhinitis.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result >= 0 && result <= 23) {
        Rinterpretation =
        "Your score for allergic rhinitis is considered Mild.The symptoms have a minimal impact on your quality of life.";
      } else if (result >= 24 && result <= 46) {
        Rinterpretation =
        "Your score for allergic rhinitis is considered Moderate. The symptoms moderately affect your daily activities and quality of life. It is recommended to consult a healthcare provider to explore treatment options that could improve your condition";
      } else if (result >= 47 && result <= 69) {
        Rinterpretation =
        "Your score for allergic rhinitis is considered Severe. The symptoms significantly disrupt your daily activities and quality of life. Consultation with a healthcare provider is strongly recommended. You may need specific treatments to manage your symptoms effectively";
      } else if (result >= 70 && result <= 92) {
        Rinterpretation =
        "Your score for allergic rhinitis is considered Very Severe. The symptoms have a severe impact on your daily functioning and quality of life. Immediate consultation with a healthcare provider is essential. Intensive treatment may be necessary to manage your condition";
      } else {
        Rinterpretation = "";
      }

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == 'MMSE.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score >= 0 && score <= 10) {
        Rinterpretation =
        "Severe\nPatient not likely to be testable.Likely to require 24-hour supervision and assistance with ADL";
      } else if (score >= 11 && score <= 20) {
        Rinterpretation =
        "Moderate\nFormal assessment may be helpful if there are specific clinical indications.May require 24-hour supervision.";
      } else if (score >= 21 && score <= 25) {
        Rinterpretation =
        "Mild\n Formal assessment may be helpful to better determine pattern and extent ofdeficits.May require somesupervision, support and assistance.";
      } else if (score >= 26 && score <= 30) {
        Rinterpretation =
        "Questionably significant \nIf clinical signs of cognitive impairment are present, formal assessment of cognition may be valuable. May have clinically significant but mild deficits. Likely to affect only most demanding activities of daily living";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }


    //For Division  Vitabiotic
    else if (jsonData['scale_code'] == "MNA.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;
      int questionId1 = 0;
      int questionId2 = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 1) {
          questionId1 = item['score'] ?? 0;

          print("questionId1  $questionId1");
        }
        if (questionid == 2) {
          questionId2 = item['score'] ?? 0;

          print("questionId2  $questionId2");
        }
      }
      print("resultbefore $result");
      //Changes for removal of Height and Weight score.
      result=result-(questionId1+questionId2);
      print("resultafter $result");
      if (result >= 12 && result <= 14) {
        Rinterpretation =
        "Normal nutritional status.";
      } else if (result >= 8 && result <= 11) {
        Rinterpretation =
        "At risk of malnutrition.";
      } else if (result >= 0 && result <= 7) {
        Rinterpretation =
        "Malnourished";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }
    else if (jsonData['scale_code'] == "PMS.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result >= 0 && result <= 14) {
        Rinterpretation =
        "Minimal symptoms.";
      } else if (result >= 15 && result <= 28) {
        Rinterpretation =
        "Mild symptoms.";
      } else if (result >= 29 && result <= 42) {
        Rinterpretation =
        "Moderate symptoms (may require lifestyle adjustments)";
      }else if (result >= 43 && result <= 56) {
        Rinterpretation =
        "Moderate symptoms(consultation with a healthcare provider recommended)";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }
    else if (jsonData['scale_code'] == "Skin.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result >= 11 && result <= 16) {
        Rinterpretation =
        "You are a dry skin and D skin type.";
      } else if (result >= 17 && result <= 26) {
        Rinterpretation =
        "You have slightly dry skin and D skin type.";
      } else if (result >= 27 && result <= 33) {
        Rinterpretation =
        "You have slightly oily skin and O skin type";
      }else if (result >= 34 && result <= 44) {
        Rinterpretation =
        "You have very oily skin and O skin type";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }
    //For Division  Suprakare
    else if (jsonData['scale_code'] == "SIBO.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;
      if (result >= 0 && result <= 10) {
        Rinterpretation =
        "Minimal symptoms, not suggestive of SIBO.";
      } else if (result >= 11 && result <= 20) {
        Rinterpretation =
        "Mild symptoms, consider monitoring and dietary modifications.";
      } else if (result >= 21 && result <= 30) {
        Rinterpretation =
        "Moderate symptoms, further evaluation with a healthcare professional is warranted. Consider a hydrogen/methane breath test for SIBO.";
      } else if (result >= 31 && result <= 100) {
        Rinterpretation =
        "Severe symptoms, likely indicative of SIBO or another gastrointestinal condition. Immediate intervention, diagnostic testing, and treatment are recommended.";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }
    else if (jsonData['scale_code'] == "Diverticulitis.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result >= 0 && result <= 10) {
        Rinterpretation =
        "Mild Diverticulitis.";
      } else if (result >= 11 && result <= 20) {
        Rinterpretation =
        "Moderate Diverticulitis.";
      } else if (result >= 21 && result <= 32) {
        Rinterpretation =
        "Severe Diverticulitis.";
      } else if (result >= 32 && result <= 100) {
        Rinterpretation =
        "Complicated Diverticulitis.";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }
    else if (jsonData['scale_code'] == "HBI.kribado") {
      result = totalScoreAsInt;
      DataSingleton().TotalScore = result;

      if (result >= 0 && result <= 4) {
        Rinterpretation =
        "Remission.";
      } else if (result >= 5 && result <= 7) {
        Rinterpretation =
        "Mild disease.";
      } else if (result >= 8 && result <= 16) {
        Rinterpretation =
        "Moderate disease.";
      } else if (result >= 16 && result <= 100) {
        Rinterpretation =
        "Severe disease.";
      }
      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    }


    else if (jsonData['scale_code'] == 'Ludwig.Scales') {
      double score = totalScoreAsInt;
      // Rinterpretation = "Patient is suffering from baldness pattern";
      DataSingleton().TotalScore = score;
      List<Map<String, dynamic>> data = DataSingleton().resultDataformat;
      String optionText = "";

      if (data.isNotEmpty) {
        print('zzzzxxxxxx ${data[0]['answer']}');
        optionText = data[0]['answer'];
      }

      if(optionText == "Type 1"){

        Rinterpretation = "Mild thinning, slight widening of part line (Grade I)";


      } else if (optionText == "Type 2"){

        Rinterpretation = "Moderate thinning with noticeable scalp visibility (Grade II)";

      }else if (optionText == "Type 3"){
        Rinterpretation = "Severe thinning with significant scalp exposure (Grade III)";

      }else if (optionText == "Frontal"){
        Rinterpretation =
        "Recession at the hairline with crown thinning";

      }else if (optionText == "Advanced"){
        Rinterpretation = "Complete baldness on the crown";

      }


      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }

    /*else if (jsonData['scale_code'] == 'SleepScore.kribado') {
      double Score = totalScoreAsInt;
      DataSingleton().TotalScore = Score;
      // Determine the interpretation based on the score
      if (Score>=0 && Score<=4) {
        Rinterpretation = "No Insomnia";
      } else if (Score>=5 && Score<=10) {
        Rinterpretation = "Mild Insomnia";
      } else if (Score>=11 && Score<=20) {
        Rinterpretation = "Moderate Insomnia";
      }else if(Score>=21 && Score<=30){
        Rinterpretation="Severe Insomnia";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$Score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(Score.toDouble());
    }*/


    else if (jsonData['scale_code'] == 'hamilton.kribado') {
      double Score = totalScoreAsInt;
      DataSingleton().TotalScore = Score;


      // Determine the interpretation based on the score
      if (Score==1) {
        Rinterpretation = "Patient falls under Type I category hence no hair loss";
      } else if (Score==2) {
        Rinterpretation = "Patient is suffering from Type II baldness pattern and shows minor recession of the frontal hairline";
      } else if (Score==3) {
        Rinterpretation = "Patient is suffering from Type III baldness pattern and shows further frontal loss and is considered cosmetically significant";
      }else if(Score==4){
        Rinterpretation="Patient is suffering from Type III vertex baldness pattern and shows significant frontal recession coupled with hair loss from the vertex region of the scalp";
      }else if(Score==5){
        Rinterpretation="Patient is suffering from Type IV - VI baldness pattern and shows further frontal and vertex loss";
      }else if(Score==6){
        Rinterpretation="Patient is suffering from Type VII baldness pattern and shows only the occipital scalp region maintains significant amounts of hair";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$Score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(Score);
    }

    else if (jsonData['scale_code'] == 'IPSS.kribado') {
      double IPSSScore = totalScoreAsInt;
      DataSingleton().TotalScore = IPSSScore;

      // Determine the interpretation based on the score
      if (IPSSScore >= 0 && IPSSScore <= 7) {
        Rinterpretation = "Mild BPH";
      } else if (IPSSScore >= 8 && IPSSScore <= 19) {
        Rinterpretation = "Moderate BPH";
      } else if (IPSSScore >= 20 && IPSSScore <= 35) {
        Rinterpretation = "Severe BPH";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$IPSSScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(IPSSScore);
    }

    //GUM HEALTH SURVEY
    else if (jsonData['scale_code'] == 'GHS.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      // Determine the interpretation based on the score
      if (score==0) {
        Rinterpretation = "Your gum health is good ,Please consult your dentist for further information.";
      } else if (score >= 1 && score <= 2) {
        Rinterpretation = "You may be at risk for developing gum disease. Please consult your dentist for further information.";
      } else if (score >= 3 && score <= 8) {
        Rinterpretation = "You may be at high risk for developing gum disease. Please consult your dentist for further information.";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    }


    else if (jsonData['scale_code'] == 'VAS.pain.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      // String interpretation;

      if (score == 0) {
        Rinterpretation = "I feel no discomfort or pain";
      } else if (score == 1) {
        Rinterpretation = "Minor pain, easy to ignore";
      } else if (score == 2) {
        Rinterpretation =
        "Noticeable pain, but does not interfere with any activities";
      } else if (score == 3) {
        Rinterpretation =
        "Pain is bothersome but manageable, slightly affects my day-to-day activities";
      } else if (score == 4) {
        Rinterpretation = "Daily activities are moderately affected";
      } else if (score == 5) {
        Rinterpretation =
        "Strong pain that interferes with concentration and affects physical activity";
      } else if (score == 6) {
        Rinterpretation =
        "Pain that dominates my senses and significantly limits my ability to perform daily activities";
      } else if (score == 7) {
        Rinterpretation =
        "Intense pain that begins to take over, affecting my ability to engage in social activities and hobbies";
      } else if (score == 8) {
        Rinterpretation =
        "Gripping or cramping pain so severe that it can hold my attention";
      } else if (score == 9) {
        Rinterpretation =
        "Very intense pain. I can barely move or talk because of the pain";
      } else if (score == 10) {
        Rinterpretation =
        "Pain as bad as it could possibly be, completely incapacitating";
      } else {
        Rinterpretation = "Invalid pain score";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );
      _insertData(score);
    } else if (jsonData['scale_code'] == 'NIHSS.kribado') {
      double strokeScore = totalScoreAsInt;
      DataSingleton().TotalScore = strokeScore;

      // Determine the interpretation based on the score
      if (strokeScore >= 0 && strokeScore <= 0) {
        Rinterpretation = "Indicates no stroke symptoms.";
      } else if (strokeScore >= 1 && strokeScore <= 5) {
        Rinterpretation = "Minor stroke.";
      } else if (strokeScore >= 6 && strokeScore <= 13) {
        Rinterpretation = "Moderate stroke.";
      } else if (strokeScore >= 14 && strokeScore <= 42) {
        Rinterpretation = "Severe stroke.";
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$strokeScore',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(strokeScore);
    } else if (jsonData['scale_code'] == "WURSS.kribado") {
      // print('@@## FSSGG ScaleID entered if');
      if (totalScoreAsInt == 0) {
        Rinterpretation = "No Symptom";
      } else if (totalScoreAsInt >= 1 && totalScoreAsInt <= 10) {
        Rinterpretation = "Very Mild";
      }
      if (totalScoreAsInt >= 11 && totalScoreAsInt <= 30) {
        Rinterpretation = "Mild";
      }
      if (totalScoreAsInt >= 31 && totalScoreAsInt <= 50) {
        Rinterpretation = "Moderate";
      }
      if (totalScoreAsInt >= 51 && totalScoreAsInt <= 70) {
        Rinterpretation = "Severe";
      }
      result = totalScoreAsInt;
      // print('@@##result navigator screen $result');
      DataSingleton().TotalScore = result;

      Get.off(result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$result',
          '$Rinterpretation',
          pat_name,
          pat_age,
          pat_gender));

      _insertData(result);
    } else if (jsonData['scale_code'] == 'WOMAC.SCORES.kribado') {
      double score = totalScoreAsInt;
      DataSingleton().TotalScore = score;

      if (score == 0) {
        Rinterpretation = "No Impact -Indicates no impact on daily activities.";
      } else if (score >= 1 && score <= 15) {
        Rinterpretation =
        "Mild Impact- Indicates minimal impact on daily activities.";
      } else if (score >= 16 && score <= 30) {
        Rinterpretation =
        "Moderate Impact- Suggests moderate difficulty in performing daily activities.";
      } else if (score >= 31 && score <= 45) {
        Rinterpretation =
        "Severe Impact - Signifies severe impairment in daily activities and significant pain.";
      } else if (score >= 46 && score <= 60) {
        Rinterpretation =
        "Extreme Impact - Indicates extreme difficulties and potentially debilitating pain, significantly affecting daily life.";
      } else {
        Rinterpretation = ""; // Default case if score does not match any range
      }

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(score);
    } else if (jsonData['scale_code'] == "IPSSCustom.kribado") {
      double IPSSScore = totalScoreAsInt;
      DataSingleton().TotalScore = IPSSScore;

      // Determine the interpretation based on the score
      if (IPSSScore >= 0 && IPSSScore <= 7) {
        Rinterpretation = "Mild BPH";
      } else if (IPSSScore >= 8 && IPSSScore <= 19) {
        Rinterpretation = "Moderate BPH";
      } else if (IPSSScore >= 20 && IPSSScore <= 41) {
        Rinterpretation = "Severe BPH";
      }

      int Q2 = 0;
      int Q4 = 0;
      int Q7 = 0;
      int Q8 = 0;

      int Q1 = 0;
      int Q3 = 0;
      int Q5 = 0;
      int Q6 = 0;

      int Voiding_Sub_Score = 0;
      int Storage_Sub_Scor = 0;
      var resultvar = DataSingleton().resultDataformat;
      for (var item in resultvar) {
        int questionid = item['question_id'] ?? 0;

        if (questionid == 2) {
          Q2 = item['score'] ?? 0;
        }
        if (questionid == 4) {
          Q4 = item['score'] ?? 0;
        }
        if (questionid == 7) {
          Q7 = item['score'] ?? 0;
        }

        if (questionid == 8) {
          Q8 = item['score'] ?? 0;
        }

        if (questionid == 1) {
          Q1 = item['score'] ?? 0;
        }
        if (questionid == 3) {
          Q3 = item['score'] ?? 0;
        }
        if (questionid == 5) {
          Q5 = item['score'] ?? 0;
        }

        if (questionid == 6) {
          Q6 = item['score'] ?? 0;
        }
      }

      Storage_Sub_Scor = Q2 + Q4 + Q7 + Q8;
      Voiding_Sub_Score = Q1 + Q3 + Q5 + Q6;

      String Interpretation_Details =
          "\nInterpretation:\n0-7: Mildly Symptomatic\n8-19: Moderately Symptomatic\n20-41: Severely Symptomatic";

      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$IPSSScore',
          Rinterpretation +
              "\n\n" +
              "Storage Sub Score(AVG)" +
              "\n" +
              (Storage_Sub_Scor / 4).toString() +
              "\n" +
              "Voiding Sub Score (Avg)" +
              "\n" +
              (Voiding_Sub_Score / 4).toString() +
              Interpretation_Details,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(IPSSScore);
    }else if (jsonData['scale_code'] == 'SleepScore.kribado') {
      double Score = totalScoreAsInt;
      DataSingleton().TotalScore = Score;
      // Determine the interpretation based on the score
      if (Score>=0 && Score<=4) {
        Rinterpretation = "No Insomnia";
      } else if (Score>=5 && Score<=10) {
        Rinterpretation = "Mild Insomnia";
      } else if (Score>=11 && Score<=20) {
        Rinterpretation = "Moderate Insomnia";
      }else if(Score>=21 && Score<=30){
        Rinterpretation="Severe Insomnia";
      }
      Get.off(
        result_screen(
          DataSingleton().scale_name,
          DataSingleton().scale_name,
          '$Score',
          Rinterpretation,
          pat_name,
          pat_age,
          pat_gender,
        ),
      );

      _insertData(Score.toDouble());
    } else {
      print("Not Matching with any of the scale");
    }
  }

  void _handleEvaluationSubmitted(
      int questionIndex, Map<String, dynamic> evaluationData) {
    // Print the total score on button click
    // print('@@## FSSGG Total sss $totalScore');
    calculateAndInterpretResults(totalScore);
  }

  double tenYearCalculator(
      double race,
      String genderString,
      double age,
      double totalCholesterol,
      double hdlCholesterol,
      double hypertensionTreatment,
      double systolicBloodPressure,
      double smoker,
      double diabetes) {
    double finalResult = 0;

    if (race == 1 || race == -1) {
      if (genderString == "female") {
        double ageCoefficient = -29.799;
        double ageSquaredCoefficient = 4.884;
        double totalCholesterolCoefficient = 13.540;
        double ageTotalCholesterolCoefficient = -3.114;
        double hdlCholesterolCoefficient = -13.578;
        double ageHDLCholesterolCoefficient = 3.149;
        double systolicBloodPressureCoefficient =
        hypertensionTreatment == 0 ? 1.957 : 2.019;
        double smokingCoefficient = 7.574;
        double ageSmokingCoefficient = -1.665;
        double diabetesCoefficient = 0.661;

        double ln_age = log(age);
        final ln_age_squared = pow(ln_age, 2);
        double ln_totalCholesterol = log(totalCholesterol);
        double ln_ageTotalCholesterol = ln_age * ln_totalCholesterol;
        double ln_hdlCholesterol = log(hdlCholesterol);
        double ln_ageHDLCholesterol = ln_age * ln_hdlCholesterol;
        double ln_systolicBloodPressure = log(systolicBloodPressure);
        double ln_ageSmoking = ln_age * smoker;

        double ageCV = ageCoefficient * ln_age;
        double ageSquaredCV = ageSquaredCoefficient * ln_age_squared;
        double totalCholesterolCV =
            totalCholesterolCoefficient * ln_totalCholesterol;
        double ageTotalCholesterolCV =
            ageTotalCholesterolCoefficient * ln_ageTotalCholesterol;
        double hdlCholesterolCV = hdlCholesterolCoefficient * ln_hdlCholesterol;
        double ageHDLCholesterolCV =
            ageHDLCholesterolCoefficient * ln_ageHDLCholesterol;
        double systolicBloodPressureCV =
            systolicBloodPressureCoefficient * ln_systolicBloodPressure;
        double smokingCV = smokingCoefficient * smoker;
        double ageSmokingCV = ageSmokingCoefficient * ln_ageSmoking;
        double diabetesCV = diabetesCoefficient * diabetes;

        double individualSum = ageCV +
            ageSquaredCV +
            totalCholesterolCV +
            ageTotalCholesterolCV +
            hdlCholesterolCV +
            ageHDLCholesterolCV +
            systolicBloodPressureCV +
            smokingCV +
            ageSmokingCV +
            diabetesCV;
        double meanValue = -29.18;

        final result = 100 * (1 - pow(0.9665, exp(individualSum - meanValue)));

        // print("result" + result.toString());
        //finalResult = Double.parseDouble(new DecimalFormat("###.#").format(result));

        String inString = result.toStringAsFixed(2);

        finalResult = double.parse(inString);
      } else {
        double ageCoefficient = 12.344;
        double totalCholesterolCoefficient = 11.853;
        double ageTotalCholesterolCoefficient = -2.664;
        double hdlCholesterolCoefficient = -7.990;
        double ageHDLCholesterolCoefficient = 1.769;
        double systolicBloodPressureCoefficient =
        hypertensionTreatment == 0 ? 1.764 : 1.797;
        double smokingCoefficient = 7.837;
        double ageSmokingCoefficient = -1.795;
        double diabetesCoefficient = 0.658;

        double ln_age = log(age);
        double ln_totalCholesterol = log(totalCholesterol);
        double ln_ageTotalCholesterol = ln_age * ln_totalCholesterol;
        double ln_hdlCholesterol = log(hdlCholesterol);
        double ln_ageHDLCholesterol = ln_age * ln_hdlCholesterol;
        double ln_systolicBloodPressure = log(systolicBloodPressure);
        double ln_ageSmoking = ln_age * smoker;

        double ageCV = ageCoefficient * ln_age;
        double totalCholesterolCV =
            totalCholesterolCoefficient * ln_totalCholesterol;
        double ageTotalCholesterolCV =
            ageTotalCholesterolCoefficient * ln_ageTotalCholesterol;
        double hdlCholesterolCV = hdlCholesterolCoefficient * ln_hdlCholesterol;
        double ageHDLCholesterolCV =
            ageHDLCholesterolCoefficient * ln_ageHDLCholesterol;
        double systolicBloodPressureCV =
            systolicBloodPressureCoefficient * ln_systolicBloodPressure;
        double smokingCV = smokingCoefficient * smoker;
        double ageSmokingCV = ageSmokingCoefficient * ln_ageSmoking;
        double diabetesCV = diabetesCoefficient * diabetes;

        double individualSum = ageCV +
            totalCholesterolCV +
            ageTotalCholesterolCV +
            hdlCholesterolCV +
            ageHDLCholesterolCV +
            systolicBloodPressureCV +
            smokingCV +
            ageSmokingCV +
            diabetesCV;
        double meanValue = 61.18;

        final result = 100 * (1 - pow(0.9144, exp(individualSum - meanValue)));
        // finalResult = Double.parseDouble(new DecimalFormat("###.#").format(result));
        String inString = result.toStringAsFixed(2);

        finalResult = double.parse(inString);
      }
    }

    if (race == 0) {
      if (genderString == "female") {
        double ageCoefficient = 17.114;
        double totalCholesterolCoefficient = 0.940;
        double hdlCholesterolCoefficient = -18.920;
        double ageHDLCholesterolCoefficient = 4.475;
        double systolicBloodPressureCoefficient =
        hypertensionTreatment == 0 ? 27.820 : 29.291;
        double ageSystolicBloodPressureCoefficient =
        hypertensionTreatment == 0 ? -6.087 : -6.432;
        double smokingCoefficient = 0.691;
        double diabetesCoefficient = 0.874;

        double ln_age = log(age);
        double ln_totalCholesterol = log(totalCholesterol);
        double ln_hdlCholesterol = log(hdlCholesterol);
        double ln_ageHDLCholesterol = ln_age * ln_hdlCholesterol;
        double ln_systolicBloodPressure = log(systolicBloodPressure);
        double ln_ageSystolicBloodPressure = ln_age * ln_systolicBloodPressure;

        double ageCV = ageCoefficient * ln_age;
        double totalCholesterolCV =
            totalCholesterolCoefficient * ln_totalCholesterol;
        double hdlCholesterolCV = hdlCholesterolCoefficient * ln_hdlCholesterol;
        double ageHDLCholesterolCV =
            ageHDLCholesterolCoefficient * ln_ageHDLCholesterol;
        double systolicBloodPressureCV =
            systolicBloodPressureCoefficient * ln_systolicBloodPressure;
        double ageSystolicBloodPressureCV =
            ageSystolicBloodPressureCoefficient * ln_ageSystolicBloodPressure;
        double smokingCV = smokingCoefficient * smoker;
        double diabetesCV = diabetesCoefficient * diabetes;

        double individualSum = ageCV +
            totalCholesterolCV +
            hdlCholesterolCV +
            ageHDLCholesterolCV +
            systolicBloodPressureCV +
            ageSystolicBloodPressureCV +
            smokingCV +
            diabetesCV;
        double meanValue = 86.61;

        final result = 100 * (1 - pow(0.9533, exp(individualSum - meanValue)));
        //Log.wtf("RESULT", result + "");
        String inString = result.toStringAsFixed(2);

        finalResult = double.parse(inString);
      } else {
        double ageCoefficient = 2.469;
        double totalCholesterolCoefficient = 0.302;
        double hdlCholesterolCoefficient = -0.307;
        double systolicBloodPressureCoefficient =
        hypertensionTreatment == 0 ? 1.809 : 1.916;
        double smokingCoefficient = 0.549;
        double diabetesCoefficient = 0.645;

        double ln_age = log(age);
        double ln_totalCholesterol = log(totalCholesterol);
        double ln_hdlCholesterol = log(hdlCholesterol);
        double ln_systolicBloodPressure = log(systolicBloodPressure);

        double ageCV = ageCoefficient * ln_age;
        double totalCholesterolCV =
            totalCholesterolCoefficient * ln_totalCholesterol;
        double hdlCholesterolCV = hdlCholesterolCoefficient * ln_hdlCholesterol;
        double systolicBloodPressureCV =
            systolicBloodPressureCoefficient * ln_systolicBloodPressure;
        double smokingCV = smokingCoefficient * smoker;
        double diabetesCV = diabetesCoefficient * diabetes;

        double individualSum = ageCV +
            totalCholesterolCV +
            hdlCholesterolCV +
            systolicBloodPressureCV +
            smokingCV +
            diabetesCV;
        double meanValue = 19.54;

        final result = 100 * (1 - pow(0.8954, exp(individualSum - meanValue)));

        String inString = result.toStringAsFixed(2);

        finalResult = double.parse(inString);
      }
    }

    return finalResult;
  }
}

//cahnges ny abhishek point

class MyHomePage extends StatefulWidget {
  final int _curr;
  final List<Widget> _list;
  final Map<int, int?> selectedValues; // Add this line

  final String title; // Add this line to receive the title
  final Function onNextButtonPressed; // Add this line
  List<dynamic> inputs;

  MyHomePage(this._curr, this._list, this.selectedValues, this.inputs,
      {required this.title, required this.onNextButtonPressed, Key? key})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState(_curr, _list, inputs);
}

class _MyHomePageState extends State<MyHomePage> {
  int _curr;
  List<Widget> _list;
  List<dynamic> inputs;

  _MyHomePageState(this._curr, this._list, this.inputs);

  PageController controller = PageController();

  void _showFinishTestSnackbar() {
    final snackBar = SnackBar(
      content: Text(
        'Finish the test before leaving',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showOptionRequiredSnackbar() {
    final snackBar = SnackBar(
      content: Text(
        'Please select atleast one option',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showRequiredSnackbar() {
    final snackBar = SnackBar(
      content: Text(
        'Please Enter Number',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showOptionRequiredSnackbarRange(int min, int max) {
    final snackBar = SnackBar(
      content: Text(
        'Please enter between ' + min.toString() + " to " + max.toString(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar2(
        title: "${widget.title}\n${_curr + 1}/${_list.length}",
        pageNavigationTime:
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
        actions: <Widget>[
          // Text(
          //   "${_curr + 1}/${_list.length}",
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     fontFamily: 'Quicksand',
          //     fontSize: 18,
          //     color: Colors.black,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // Add more widgets if needed
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.73, // Adjust the percentage as needed
              child: PageView(
                physics: new NeverScrollableScrollPhysics(),
                children: _list,
                scrollDirection: Axis.horizontal,
                controller: controller,
                onPageChanged: (num) {
                  setState(() {
                    _curr = num;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Visibility(
                    visible: _curr != 0,
                    child: CustomElevatedButton1(
                      onPressed: () {
                        if (_curr != 0) {
                          controller.jumpToPage(_curr - 1);
                        }
                      },
                      text: 'Back',
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  CustomElevatedButton(
                    onPressed: () {
                      // Check if an option is selected for the current question


                      print('itortirotirotirogkdjvodj $numChild');

                      if (DataSingleton().scale_id == 'IBS.kribado' && numChild == false) {
                        showOptionRequiredSnackbar();
                        return; // <-- This blocks going to next question
                      }


                      if (inputs[_curr]['type'] == "SEEK") {
                        if (widget.selectedValues[_curr].toString() == null) {
                          widget.selectedValues[_curr] = 0;
                        }
                      }

                      if (inputs[_curr]['type'] == "NUM") {
                        //rangecheck
                        double min = inputs[_curr]['min'] is double ? inputs[_curr]['min'] : inputs[_curr]['min'].toDouble();
                        double max = inputs[_curr]['max'] is double ? inputs[_curr]['max'] : inputs[_curr]['max'].toDouble();
                        // If an option is selected, navigate to the next question if not the last one [ its will call on on next pressed ]
                        if (_curr != _list.length - 1) {
                          // Check if rangeCheck is within the range
                          if (rangeCheck >= min && rangeCheck <= max) {
                            controller.jumpToPage(_curr + 1);
                          } else {
                            showOptionRequiredSnackbarRange(inputs[_curr]['min'], inputs[_curr]['max']);
                          }
                        } else {
                          // it will call only on submit pressed
                          // Check if rangeCheck is within the range
                          if (rangeCheck >= min && rangeCheck <= max) {
                            widget.onNextButtonPressed();
                          } else {
                            showOptionRequiredSnackbarRange(inputs[_curr]['min'], inputs[_curr]['max']);
                            // showOptionRequiredSnackbar();
                          }
                          // If it's the last question, call the onNextButtonPressed method
                        }
                        // If no option is selected, show a message or perform an action
                        // For example, you can show a snackbar indicating that an option must be selected
                      }
                      else {
                        if (widget.selectedValues[_curr] != null) {
                          // If an option is selected, navigate to the next question if not the last one
                          if(_curr ==_list.length - 1 )
                            if(isChild == true){
                              if(childAnswer.isEmpty){
                                showRequiredSnackbar();
                                return;
                              }
                            }
                          if (_curr != _list.length - 1) {
                            controller.jumpToPage(_curr + 1);
                            // print('onnextNext');
                          } else {
                            // If it's the last question, call the onNextButtonPressed method
                            // print('onsubmitsubmit');
                            widget.onNextButtonPressed();
                            childAnswer="";
                          }
                        } else {
                          // If no option is selected, show a message or perform an action
                          // For example, you can show a snackbar indicating that an option must be selected
                          showOptionRequiredSnackbar();
                        }
                      }
                    },
                    text: _curr != _list.length - 1 ? 'Next' : 'Submit',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScalesTestScreen extends StatefulWidget {
  final int _curr;
  final Map<String, dynamic> jsonData;
  final Map<int, int?> selectedValues;
  final Function(int?, int) onOptionSelected;
  final Function(double, int) onOptionSelectedNum;
  final Function(int, Map<String, dynamic>) onEvaluationSubmitted;

  final Function(String checkboxes, int score) updateSelectedCheckboxes;
  final Function(String text) updateTextbox;
  final Function(String text) OnCheckType;
  final Function(String child, num childScore, String childAnswer, num childId) updateChild;
  final Function(num parentScore,String parentAnswer) updateParent;

  ScalesTestScreen(
      this._curr,
      this.jsonData,
      this.selectedValues,
      this.onOptionSelected,
      this.onEvaluationSubmitted,
      this.updateSelectedCheckboxes,
      this.updateTextbox,
      this.updateChild,
      this.updateParent,
      this.OnCheckType, this.onOptionSelectedNum);

  @override
  _ScalesTestScreenState createState() => _ScalesTestScreenState();
}

class _ScalesTestScreenState extends State<ScalesTestScreen> {
  int? _groupValue;
  int? groupValuewithoutIndexInt;
  int selectedChildId= 0;
  TextEditingController? _textEditingController; // Add this line
  String? _selectedDropdownValue; // Define selected dropdown value
  List<bool> _checkedList = []; // Initialize the list of checkbox states
  List<int> _selectedCheckboxes = [];
  List<String> _selectedTitles = [];
  num _sliderValue = 0;
  String textType = "sample";

  int finalcheckbox = 0;

  late num idofCurrentValue = 0;
  double _fontSize = 16.0;

  bool showChildText = false;




  //abhishek checkbox score wise case done....

  void _toggleCheckbox(int index, String title,int score) {
    // Increment index by 1 to start indexing from 1 instead of 0
    index += 0;
    int totalScore=0;
    setState(() {
      // If "None" is selected, uncheck all other options and only check "None"
      if (title == "None") {
        _selectedCheckboxes.clear();
        _selectedTitles.clear();
        _selectedCheckboxes.add(index);
        _selectedTitles.add(title);

        // Uncheck all checkboxes except for the one with "None"
        for (int i = 0; i < _checkedList.length; i++) {
          _checkedList[i] = (i == index - 1);
        }
      }


      Map<String, dynamic> currentQuestion = widget.jsonData['inputs'][widget._curr];

      // Find index for "None" and "All of the Above"
      int noneIndex = currentQuestion['options'].indexWhere((opt) => opt['title'] == 'None');
      int allOfTheAboveIndex = currentQuestion['options'].indexWhere((opt) => opt['title'] == 'All of the Above');

      if (title == "All of above") {
        // Check all options except "None"
        for (int i = 0; i < _checkedList.length; i++) {
          if (i != noneIndex) {
            _checkedList[i] = true;  // Check all options except "None"
            // Add the title if not already present
            if (!_selectedCheckboxes.contains(i)) {
              _selectedCheckboxes.add(i);  // Add to selected options
              _selectedTitles.add(currentQuestion['options'][i]['title']);  // Add the title
            }
          }
        }

        // Implicitly handle "None" by clearing its selection if "All of the Above" is selected
        _checkedList[noneIndex] = false;  // Ensure "None" is unchecked in the UI
        _selectedCheckboxes.remove(noneIndex);  // Ensure "None" is not in the selected checkboxes
        _selectedTitles.remove('None');  // Ensure "None" is removed from the selected titles
      }

      // For any other option
      else {
        // Uncheck "None" and "All of the Above" if any other option is selected
        if (_selectedCheckboxes.contains(noneIndex)) {
          _selectedCheckboxes.remove(noneIndex);
          _selectedTitles.remove('None');
          _checkedList[noneIndex] = false;  // Uncheck "None"
        }

        if (_selectedCheckboxes.contains(allOfTheAboveIndex)) {
          _selectedCheckboxes.remove(allOfTheAboveIndex);
          _selectedTitles.remove('All of the Above');
          _checkedList[allOfTheAboveIndex] = true;  // Uncheck "All of the Above"
        }

        // Toggle the current option
        if (_selectedCheckboxes.contains(index)) {
          _selectedCheckboxes.remove(index);
          _selectedTitles.remove(title);
          _checkedList[index] = false;  // Uncheck current checkbox
        } else {
          _selectedCheckboxes.add(index);
          _selectedTitles.add(title);
          _checkedList[index] = true;  // Check current checkbox
        }
      }

      // Map to store title-score pairs
      Map<String, int> titleScoreMap = {};

      // Replace selected titles with corresponding scores and create a map
      for (String selectedTitle in _selectedTitles) {
        int titleIndex = currentQuestion['options'].indexWhere((opt) => opt['title'] == selectedTitle);
        if (titleIndex != -1) {
          int selectedScore = currentQuestion['options'][titleIndex]['score'];
          titleScoreMap[selectedTitle] = selectedScore;
        }
      }
      //add up and also show one value for all of the above special case
      // Initialize total score
      int totalScore = 0;

// Check if "All of the Above" is selected and handle accordingly
      if (titleScoreMap.containsKey("All of above")) {
        if (titleScoreMap["All of above"] == 1) {
          // If "All of the Above" has a value of 1, only consider its score
          totalScore = titleScoreMap["All of above"] ?? 0;
        } else {
          // If "All of the Above" has a value of 0, sum up all the scores
          titleScoreMap.forEach((key, value) {
            totalScore += value;
          });
        }
      } else {
        // If "All of the Above" is not selected, sum up all the scores
        titleScoreMap.forEach((key, value) {
          totalScore += value;
        });
      }

      // Update selected titles into a formatted string
      String formattedTitles = _selectedTitles.join(' | ');
      widget.updateSelectedCheckboxes(formattedTitles,totalScore);
    });
  }

  bool _isChecked(int index) {
    return _checkedList[index]; // Check if the checkbox at the given index is checked
  }


  @override
  void initState() {
    super.initState();
    _groupValue = widget.selectedValues[widget._curr];
    _textEditingController = TextEditingController(); // Add this line
    _textEditingController!.text =
        widget.selectedValues[widget._curr]?.toString() ?? ''; // Add this line
    _selectedDropdownValue = null; // Initialize selected dropdown value
    _initializeCheckedList(); // Initialize the checkbox list
    _dynamicFontSize();



    List<dynamic> inputs = widget.jsonData['inputs'];
    Map<String, dynamic> currentQuestion = inputs[widget._curr];
    String type = currentQuestion['type'];


    if (type == "SEEK") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Initial Slider Value: $_sliderValue');
        widget.onOptionSelected(
            _sliderValue.toInt(),
            widget
                ._curr); // Pass int value to callback for seek bar default set
      });
    }
  }

  void _initializeCheckedList() {
    List<dynamic> inputs = widget.jsonData['inputs'];
    Map<String, dynamic> currentQuestion = inputs[widget._curr];
    if (currentQuestion['type'] == 'MS' || currentQuestion['type'] == 'AON') {
      // If the current question type is 'MS' (multiple selection), initialize the checked list
      _checkedList = List.filled(currentQuestion['options'].length, false);
    }
  }

  Future<void> _dynamicFontSize() async {
    setState(() {
      _fontSize = DataSingleton().font_size; // Decrease font size by 2
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> inputs = widget.jsonData['inputs'];
    Map<String, dynamic> currentQuestion = inputs[widget._curr];



    if (widget._curr <= 1 && globalScaleid == "iap.growthchart.kribado") {
      hintText = "Please do not enter a decimal number.";
    } else {
      hintText = "Enter value";
    }

    DataSingleton().inputs = inputs;

    String? lang = DataSingleton().locale;
    /////////////////////////////////////////to set title of scale

    // Accessing and decoding scale languages
    Map<String, dynamic>? scaleLanguages = widget.jsonData['scale_languages'];
    Map<String, dynamic> decodedScaleLanguages = {};
    if (scaleLanguages != null) {
      scaleLanguages.forEach((key, value) {
        decodedScaleLanguages[key] = value;
      });
    } else {
      print(
          "Scale languages not found."); // Handle the case where scaleLanguages is null
    }

    String? scaleTitle;

    if (scaleLanguages != null) {
      // Check if the selected language is available in scaleLanguages
      if (scaleLanguages.containsKey(lang)) {
        // Set the scaleTitle to the corresponding language title
        scaleTitle = scaleLanguages[lang];
      } else {
        // Default to English if the selected language is not found
        scaleTitle =
        scaleLanguages['English']; // Assuming 'en' is always available
      }
    } else {
      // Default to a generic title if scaleLanguages is not available
      scaleTitle = "Scale"; // You can customize this according to your needs
    }


    //////////////////////////////////////////
    List<String> tTokens = List<String>.from(currentQuestion['t_token'] ?? []);
    List<String?> filteredTokens =
    tTokens.where((token) => token!.startsWith(lang!)).toList();
    //uptil here changes as per lang string changes filterend from ttokens
    String filteredTokensString = filteredTokens.join(', ');
// Step 3: Split the tokens string to get individual tokens
    List<String> splitTokens = filteredTokensString.split(', ');
    // print("splitttoekns $splitTokens");

// Step 4: Assign first and last tokens to separate strings
    String firstTokenTitleLocale = splitTokens.first;
    String lastTokenCategoryLocale = splitTokens.last;

    // print("First token: $firstTokenTitleLocale");
    // print("Last token: $lastTokenCategoryLocale");

    String categoryToken = '';
    for (String token in splitTokens) {
      if (token.contains('category')) {
        categoryToken = token;
        break;
      }
    }

    String finalLocaleTitle = "";
    String finalLocaleTitle1 = "";
    String finalLocaleCategory = "";
    Map<String, dynamic>? localeJson = widget.jsonData['locale']?[lang];
    localeJson?.forEach((key, value) {
      if (firstTokenTitleLocale == key) {
        finalLocaleTitle = value;
      }
      if (categoryToken == key) {
        finalLocaleCategory = value;
      }
    });
    ///for options locale
    Map<String, dynamic> currentQuestionOption = inputs[widget._curr];
    List<dynamic>? subtitles =
    currentQuestion['subtitles']; // Get subtitles from JSON data

    List<dynamic>? ranges = currentQuestion['ranges']; // get ranges from json
    List<dynamic>? rangess = currentQuestion['childrens'] != null &&
        currentQuestion['childrens'] is List &&
        (currentQuestion['childrens'] as List).isNotEmpty
        ? currentQuestion['childrens'][0]['ranges']
        : null;
    print('fjkdfjskfmskcmc $rangess');
    List<dynamic>? subtitless;

    final children = currentQuestion['childrens'];
    if (children != null && children is List && children.isNotEmpty) {
      final firstChild = children[0];
      if (firstChild != null && firstChild is Map && firstChild['subtitles'] != null) {
        final subtitlesData = firstChild['subtitles'];
        if (subtitlesData is List) {
          subtitless = subtitlesData;
        } else {
          print('subtitles is not a List');
        }
      } else {
        print('firstChild is null or subtitles missing');
      }
    } else {
      print('children is null or empty');
    }
    print('fskfjkfkxcmxcm $subtitless');
    List<Map<String, dynamic>> localeList = [];

    if (currentQuestionOption['options'] != null) {
      List<dynamic> options = currentQuestionOption['options'];
      for (var option in options) {
        List<String> tTokens = List<String>.from(option['t_token']);

        List<String?> filteredTokens =
        tTokens.where((token) => token!.startsWith(lang!)).toList();
        String filteredTokensString = filteredTokens.join(', ');
        Map<String, dynamic>? localeJson = widget.jsonData['locale']?[lang];
        localeJson?.forEach((key, value) {
          if (filteredTokensString == key) {
            finalLocaleTitle1 = value;
            // Create a map with the value as the sole element and add it to the list
            Map<String, dynamic> map = {"title": value};
            localeList.add(map);
          }
        });
      }
    }

    final childrens = currentQuestion['childrens'];


    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      // Adjust the value as needed
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              (finalLocaleCategory?.isNotEmpty == true)
                                  ? finalLocaleCategory
                                  : (currentQuestion['category']?.isNotEmpty ==
                                  true)
                                  ? currentQuestion['category']
                                  : "",
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              finalLocaleTitle.isNotEmpty
                                  ? finalLocaleTitle
                                  : currentQuestion['title'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _fontSize,
                                  color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            if (currentQuestion['b64data'] != null &&
                                currentQuestion['b64data'].isNotEmpty)
                              Image.memory(
                                base64Decode(
                                    currentQuestion['b64data'].split(',').last),
                                height: 120,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
//suppose to put
              SizedBox(height: 15.0),
              if (currentQuestion['type'] == 'NUM') // Add this condition
                Expanded(
                  child: GestureDetector(
                    onVerticalDragStart: (details) {
                      FocusScopeNode currentFocus = FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: TextFormField(
                      controller: _textEditingController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (text) {
                        if (widget._curr == 0) {
                          // If valid and not a whole number, save it in the singleton
                          DataSingleton().hbA1c = text!;
                        }
                        // Validate the entered valueut
                        int enteredValue = int.tryParse(text) ?? 0;
                        double? t = double.tryParse(text);
                        widget.onOptionSelected(enteredValue, widget._curr);
                        widget.onOptionSelectedNum(t!,widget._curr);
                      },
                      decoration: InputDecoration(
                        labelText:
                        '$hintText (${currentQuestion['min']} - ${currentQuestion['max']})',
                        border: OutlineInputBorder(),
                        errorText: _textEditingController!.text.isEmpty
                            ? ' '
                            : null, // Set error text based on the error state
                      ),
                    ),
                  ),
                ),
              if (currentQuestion['type'] == 'TXT') // Add this condition
                Expanded(
                  child: GestureDetector(
                    onVerticalDragStart: (details) {
                      FocusScopeNode currentFocus = FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: TextFormField(
                      controller: _textEditingController,
                      keyboardType: TextInputType.text,
                      onChanged: (text) {
                        widget.updateTextbox(text);
                        // dynamic enteredValue = text;
                        int enteredValue = int.tryParse(text) ?? 0;
                        // Update the entered value in the map
                        widget.onOptionSelected(enteredValue, widget._curr);
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter value ',
                        border: OutlineInputBorder(),
                        errorText: _textEditingController!.text.isEmpty
                            ? ' '
                            : null, // Set error text based on the error state
                      ),
                    ),
                  ),
                ),
              if (currentQuestion['type'] == 'MS')
                Column(
                  children: List<Widget>.generate(
                    currentQuestion['options'].length,
                        (index) {
                      Map<String, dynamic> option =
                      currentQuestion['options'][index];
                      // Access the title from each item in localeList
                      String title =
                      localeList.isNotEmpty && index < localeList.length
                          ? localeList[index]['title']
                          : option['title'];
                      Widget imageWidget = option['imageData'] != null
                          ? Image.memory(
                        base64Decode(option['imageData']),
                        height: 45,
                      )
                          : Container();
                      return CheckboxListTile(
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                width: 30,
                              ),
                              imageWidget,
                            ],
                          ),
                        ),
                        value: _isChecked(index),
                        onChanged: (bool? value) {
                          setState(() {
                            _toggleCheckbox(index, option["title"],option['score']);
                            widget.onOptionSelected(
                                finalcheckbox, widget._curr);
                          });
                        },
                      );
                    },
                  ),
                ),
              if (currentQuestion['type'] == 'AON')
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 400,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Scrollbar(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: currentQuestion['options'].length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> option =
                                currentQuestion['options'][index];
                                // Access the title from each item in localeList
                                String title = localeList.isNotEmpty &&
                                    index < localeList.length
                                    ? localeList[index]['title']
                                    : option['title'];
                                Widget imageWidget =
                                option['imageData'] != null
                                    ? Image.memory(
                                  base64Decode(option['imageData']),
                                  height: 45,
                                )
                                    : Container();

                                return CheckboxListTile(
                                  title: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines:
                                            1, // Limit text to one line
                                          ),
                                        ),
                                        SizedBox(width: 30),
                                        imageWidget,
                                      ],
                                    ),
                                  ),
                                  value: _isChecked(index),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _toggleCheckbox(index, option["title"],option['score']);
                                      widget.onOptionSelected(finalcheckbox, widget._curr);
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (currentQuestion['type'] == 'DD')
                Expanded(
                  child: DropdownButtonFormField(
                    value: _selectedDropdownValue,
                    items: List<DropdownMenuItem<String>>.generate(
                      currentQuestion['options'].length,
                          (index) {
                        Map<String, dynamic> option =
                        currentQuestion['options'][index];

                        // Access the title from localeList if available, otherwise fallback to option['title']
                        String title =
                        localeList.isNotEmpty && index < localeList.length
                            ? localeList[index]['title']
                            : option['title'];

                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(title),
                        );
                      },
                    ),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedDropdownValue = value;

                        // Find the index of the selected option
                        int selectedOptionIndex = currentQuestion['options']
                            .indexWhere((option) => option['value'] == value);

                        // Pass the selected index and value to the callback function
                        widget.onOptionSelected(
                            selectedOptionIndex, widget._curr);
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select an option',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              if (currentQuestion['type'] == 'SS')
////

                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 400),
                    child: Column(
                      children: [
                        // First ListView for options
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            thickness: 10,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: currentQuestion['options'].length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> option =
                                currentQuestion['options'][index];

                                // Access the title from the current option
                                String title = localeList.isNotEmpty &&
                                    index < localeList.length
                                    ? localeList[index]['title']
                                    : option['title'];



                                bool isSelected = _groupValue == index;




                                return GestureDetector(
                                  onTap: () {
                                    // Update the selected value
                                    print('dgjdkgjdkgjdgjdnx');



                                    setState(() {
                                      _groupValue = index;
                                      String? groupValuewithoutIndex = currentQuestion['options'][index]['value'].toString();
                                      print('jfkdfjdkfjskfjskfncn ${option['title']}');
                                      print('dgiggkggksgkksksksks ${widget._curr}');
                                      if(widget._curr == 0 && DataSingleton().scale_id == 'IBS.kribado'){
                                        numChild =false;
                                      }

                                      if(widget._curr == 1 &&  option['title'] == 'No' && DataSingleton().scale_id == 'IBS.kribado'){
                                        numChild =true;
                                      }

                                      if(widget._curr == 1 &&  option['title'] == 'Yes' && DataSingleton().scale_id == 'IBS.kribado'){
                                        numChild =false;
                                      }

                                      DataSingleton().fraxOptionTitle = groupValuewithoutIndex;
                                      print('djfkdjfksjfksfjksfjskfj $groupValuewithoutIndex');
                                      // Check if the string can be parsed as an integer
                                      if (int.tryParse(groupValuewithoutIndex) != null) {
                                        groupValuewithoutIndexInt = int.parse(groupValuewithoutIndex);
                                      } else {
                                        // Handle the case where it cannot be parsed as an integer
                                      }
                                      DataSingleton().option_selected_logo = option['b64data'].split(',').last;
                                      if(showChildText /*&& groupValuewithoutIndexInt != -1 && currentQuestion['childrens'].length > _groupValue*/){
                                        print('Children data is available');
                                        // widget.updateChild("childAvailable",0,"",0);
                                      }else {
                                        print('no children available');
                                        // widget.updateChild("NochildAvailable",0,"",0);
                                      }
                                      widget.onOptionSelected(index, widget._curr);
                                      widget.updateChild("",0,"",0);
                                    });
                                    widget.updateParent(option['score'],option['title']);

                                    isChild = false;// Toggle to
                                    // Check if the current option has children and display them if available
                                    if ( currentQuestion['childrens'].length > _groupValue) {
                                      setState(() {
                                        widget.updateChild("childAvailable",0,"",0);
                                        showChildText = true; //
                                        isChild = true;// Toggle to
                                        // widget.onOptionSelected(null,0);// show text
                                      });
                                    }
                                    else{
                                      setState(() {
                                        widget.updateChild("",0,"",0);
                                        isChild = false;// Toggle to
                                      });
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 16.0),
                                    padding: EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: title.isEmpty
                                        ? Center(
                                      child: option['b64data'].isNotEmpty
                                          ? Image.memory(
                                        base64Decode(option['b64data'].split(',').last),
                                      )
                                          : SizedBox.shrink(), // Handle case when image is also empty
                                    )
                                        : Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: _fontSize,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 10,
                                          ),
                                        ),
                                        if (option['b64data'].isNotEmpty)
                                          SizedBox(width: 10),
                                        if (option['b64data'].isNotEmpty)
                                          Image.memory(
                                            base64Decode(option['b64data'].split(',').last),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Header displayed between the two ListViews


                        if (showChildText &&
                            groupValuewithoutIndexInt != -1 &&
                            (childrens == null ||
                                (childrens is List && childrens.isEmpty) ||
                                (childrens is List &&
                                    _groupValue! < childrens.length &&
                                    currentQuestion['childrens'][_groupValue]['type'] != null &&
                                    currentQuestion['childrens'][_groupValue]['type'] == 'SEEK')))
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Conditionally show title only if it's not null or empty

                                if (currentQuestion['childrens'][_groupValue]['title']?.toString().trim().isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${currentQuestion['childrens'][_groupValue]['title']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                // Main card
                                Card(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: ColorConstants.lightGrey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.grey,
                                  color: ColorConstants.cultured,
                                  surfaceTintColor: ColorConstants.cultured,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Text(
                                        "Value : $_sliderValue",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Slider(
                                        value: _sliderValue.toDouble(),
                                        min: currentQuestion['childrens'][_groupValue]['min'].toDouble(),
                                        max: currentQuestion['childrens'][_groupValue]['max'].toDouble(),
                                        divisions: currentQuestion['childrens'][_groupValue]['step'],
                                        onChanged: (double value) {
                                          setState(() {
                                            _sliderValue = value.round();
                                            idofCurrentValue = _sliderValue;
                                            numChild =true;
                                            isChild = false;
                                            childAnswer = '$_sliderValue';
                                            widget.updateChild("", 0, "", 0);
                                            addOrUpdateResult(
                                              questionId: currentQuestion['id'],
                                              score: _sliderValue.toDouble(),
                                              answer: rangess!.firstWhere(
                                                    (rangess) => rangess['score'] == idofCurrentValue,
                                                orElse: () => {'title': 'No Label Found'},
                                              )['title'].toString(),
                                              childId: currentQuestion['childrens'][_groupValue]['id'],
                                            );
                                          });
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Text(
                                                subtitless!.first['key'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.start,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Text(
                                                subtitless!.last['key'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.end,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            rangess!
                                                .firstWhere(
                                                  (rangess) => rangess['score'] == idofCurrentValue,
                                              orElse: () => {'title': 'No Label Found'},
                                            )['title']
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (showChildText && groupValuewithoutIndexInt != -1 && currentQuestion['childrens'].length > _groupValue  && currentQuestion['childrens'][_groupValue]['type'] == 'NUM')
                          Expanded(
                            child: GestureDetector(
                              onVerticalDragStart: (details) {
                                FocusScopeNode currentFocus = FocusScope.of(context);
                                if (!currentFocus.hasPrimaryFocus) {
                                  currentFocus.unfocus();
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12.0),
                                    margin: const EdgeInsets.fromLTRB(4, 8, 0, 8),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${currentQuestion['childrens'][_groupValue]['title']}',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      inputDecorationTheme: InputDecorationTheme(
                                        errorStyle: TextStyle(
                                          fontSize: 10, // 👈 change this to your desired size
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _textEditingController,
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (text) {
                                        double? enteredValue = double.tryParse(text);

                                        setState(() {
                                          _errorTextIBSkribado = null;
                                        });

                                        if (DataSingleton().scale_id == 'IBS.kribado') {
                                          if (enteredValue == null || enteredValue < 1 || enteredValue > 10) {
                                            setState(() {
                                              _errorTextIBSkribado = 'Please enter a value between 1 and 10';
                                              numChild = false;
                                            });
                                            return;
                                          }
                                          numChild = true;
                                        }

                                        print('suhsufhsfhsjfhsfjshjfjshf ${DataSingleton().fraxOptionTitle}');

                                        if (DataSingleton().fraxOptionTitle == 'No') {
                                          widget.onOptionSelectedNum(1234567890, widget._curr);
                                          print('daldslfklcxfdfkdgkegkg');
                                        } else if (DataSingleton().fraxOptionTitle == 'Yes') {
                                          widget.onOptionSelectedNum(enteredValue!, widget._curr);
                                          print('troyiroieoyieoyieoietoeitoeit');
                                          DataSingleton().fraxAnswer10 = "$enteredValue";
                                          DataSingleton().fraxchilId = '1';
                                        }

                                        if (DataSingleton().scale_id == 'IBS.kribado') {
                                          addOrUpdateResult(
                                            questionId: currentQuestion['id'],
                                            score: enteredValue!.toDouble(),
                                            answer: '$enteredValue',
                                            childId: currentQuestion['childrens'][_groupValue]['id'],
                                          );
                                        }

                                        isChild = false;
                                        childAnswer = 's';
                                        widget.updateChild("", 0, "", 0);

                                        setState(() {});
                                      },
                                      decoration: InputDecoration(
                                        labelText: DataSingleton().scale_id == 'IBS.kribado'
                                            ? 'Enter from 1 to 10'
                                            : 'Enter a number',
                                        border: OutlineInputBorder(),
                                        errorText: DataSingleton().scale_id == 'IBS.kribado'
                                            ? _errorTextIBSkribado
                                            : null,
                                      ),
                                    ),
                                  ),




                                ],
                              ),
                            ),
                          ),

                        // Second ListView for child options
                        if (showChildText && groupValuewithoutIndexInt != -1 && currentQuestion['childrens'].length > _groupValue && currentQuestion['childrens'][_groupValue]['type'] == 'SS')
                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: currentQuestion['childrens'][_groupValue]['options'].length,
                                itemBuilder: (context, index) {
                                  // Access child options
                                  Map<String, dynamic> childOption = currentQuestion['childrens'][_groupValue]['options'][index];

                                  bool isChildSelected = selectedChildId == childOption['id']; // Use selectedChildId instead





                                  return GestureDetector(
                                    onTap: () {
                                      DataSingleton().childQuestion = currentQuestion['childrens'][_groupValue]['title'];
                                      DataSingleton().childGroupValue = _groupValue;
                                      setState(() {
                                        selectedChildId = childOption['id'];
                                        widget.onOptionSelected(index, widget._curr);
                                        childAnswer = childOption['title'];
                                      });
                                      widget.updateChild("childAvailable", childOption['score'], childOption['title'], childOption['id']);
                                      DataSingleton().option_selected_logo = childOption['b64data']
                                          .split(',')
                                          .last;
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.fromLTRB(55,10,10,10),
                                      padding: EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: isChildSelected ? Theme.of(context).primaryColor : Colors.white,
                                        border: Border.all(
                                          color: isChildSelected ? Theme.of(context).primaryColor : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              childOption['title'],
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                color: isChildSelected ? Colors.white : Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 10,
                                            ),
                                          ),
                                          if (childOption['b64data'].isNotEmpty)
                                            SizedBox(width: 10),
                                          if (childOption['b64data'].isNotEmpty)
                                            Image.memory(
                                              base64Decode(childOption['b64data'].split(',').last),
                                              height: 70,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              if (currentQuestion['type'] == 'SEEK')
                Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: ColorConstants.lightGrey,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 3,
                  shadowColor: Colors.grey,
                  color: ColorConstants.cultured,
                  surfaceTintColor: ColorConstants.cultured,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        "Value : " + _sliderValue.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Slider(
                        value: _sliderValue.toDouble(),
                        min: currentQuestion['min'].toDouble(),
                        max: currentQuestion['max'].toDouble(),
                        divisions: currentQuestion['step'],
                        onChanged: (double value) {
                          setState(() {
                            _sliderValue = value.round();
                            idofCurrentValue = _sliderValue;
                          });
                          widget.onOptionSelected(
                              _sliderValue.toInt(), widget._curr);
                          widget.OnCheckType("aaaaa");
                          widget.updateTextbox("update");
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display the start subtitle
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                subtitles!.first['key'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                          // Display the end subtitle
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                subtitles!.last['key'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Dynamically display the label
                          Text(
                            ranges!
                                .firstWhere(
                                  (range) => range['score'] == idofCurrentValue,
                              orElse: () => {'title': 'No Label Found'},
                            )['title']
                                .toString(),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

