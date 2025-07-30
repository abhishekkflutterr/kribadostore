import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../DataSingleton.dart';
import '../custom_widgets/customappbar.dart';
import '../screens/scales_navigator_screen.dart';

class LocaleSelectionScreen extends StatelessWidget {
  final Map<String, dynamic> arguments;

  LocaleSelectionScreen({super.key, required this.arguments});

  @override
  Widget build(BuildContext context) {
    String _selectedLanguage = "";
   // String keys="";
   // String language;



    // Accessing arguments
    List<dynamic> _languages = arguments['tTokenList'];


    // print("fsfsfjsfjsjzcnzcn $_languages");
    late Map<String, dynamic> scale_Json = arguments['data'];

  /*  Map<String, dynamic> _languagesToDisply = scale_Json['F'];
    print("_languagesToDisply $_languagesToDisply");*/

    //languages to display
    // Accessing and decoding  languages
    Map<String, dynamic> scaleLanguagesToDisplay = scale_Json['languages'];
    Map<String, dynamic> decodedScaleLanguagesToDisplay = {};
    scaleLanguagesToDisplay.forEach((key, value) {
      decodedScaleLanguagesToDisplay[key] = value;
    });

    List myList = decodedScaleLanguagesToDisplay.values.toList();
    List myListkeys = decodedScaleLanguagesToDisplay.keys.toList();

    // Printing decoded scale languages
    print("dcodeLanguage $decodedScaleLanguagesToDisplay");
    String? languageTitle;


   // print("languages $_languagesToDisply");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Select a Language',
        showBackButton: false,
        showKebabMenu: false,
        pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: decodedScaleLanguagesToDisplay.length,
                itemBuilder: (context, index) {

                   final keys=myListkeys[index];
                    final language = myList[index] ;
                  print("entered1 $keys");
                  print("entered1 $language");
                  return GestureDetector(

                    onTap: () {
                      // Check if the radio button is not selected
                      if (_selectedLanguage != keys) {
                        // Update the selected language and navigate to the next screen
                        _selectedLanguage = keys;
                        DataSingleton().locale = _selectedLanguage;
                        print("_selectedLanguage title :$_selectedLanguage ");
                        _navigateToNextScreen(context);
                      }
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  print("entered2 :  $keys");
                                  _selectedLanguage = keys.toString();
                                  print("_selectedLanguage Button:$_selectedLanguage ");
                                  DataSingleton().locale = _selectedLanguage;

                                  // Accessing and decoding scale languages
                                  Map<String, dynamic> scaleLanguages = scale_Json['scale_languages'];
                                  Map<String, dynamic> decodedScaleLanguages = {};
                                  scaleLanguages.forEach((key, value) {
                                    decodedScaleLanguages[key] = value;
                                  });

                                  // Printing decoded scale languages
                                  print("xvxvdgdgcvcvvsawss $decodedScaleLanguages");

                                  String? scaleTitle;

                                  if (scaleLanguages != null) {
                                    // Check if the selected language is available in scaleLanguages
                                    if (scaleLanguages.containsKey(_selectedLanguage)) {
                                      // Set the scaleTitle to the corresponding language title
                                      scaleTitle = scaleLanguages[_selectedLanguage];
                                    } else {
                                      // Default to English if the selected language is not found
                                      scaleTitle = scaleLanguages['en']; // Assuming 'en' is always available
                                    }
                                  } else {
                                    // Default to a generic title if scaleLanguages is not available
                                    scaleTitle = "Scale"; // You can customize this according to your needs
                                  }

                                  // Printing the scale title
                                  print("Scale TitleLocallee: $scaleTitle");

                                  DataSingleton().localeTitle = scaleTitle;

                                  _navigateToNextScreen(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: _selectedLanguage == keys.toString() ? Colors.blue : Colors.white,
                                    border: Border.all(
                                      color: _selectedLanguage == keys.toString() ? Colors.blue : Colors.grey,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Icon(
                                    _selectedLanguage == keys.toString()
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: _selectedLanguage == keys.toString() ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0), // Space between the icon and the text
                              Text(
                                language,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),



                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    Get.off(Test());
  }
}
