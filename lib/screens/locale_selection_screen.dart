import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../DataSingleton.dart';
import '../custom_widgets/customappbar.dart';
import '../screens/scales_navigator_screen.dart';

class LocaleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const LocaleSelectionScreen({super.key, required this.arguments});

  @override
  _LocaleSelectionScreenState createState() => _LocaleSelectionScreenState();
}

class _LocaleSelectionScreenState extends State<LocaleSelectionScreen> {
  String _selectedLanguage = "";

  @override
  Widget build(BuildContext context) {
    // Extract data from arguments
    final List<dynamic> _languages = widget.arguments['tTokenList'];
    final Map<String, dynamic> scale_Json = widget.arguments['data'];

    // Access and decode display languages
    final Map<String, dynamic> scaleLanguagesToDisplay =
    Map<String, dynamic>.from(scale_Json['languages'] ?? {});

    final List<String> myListKeys = scaleLanguagesToDisplay.keys.toList();
    final List<String> myListValues = scaleLanguagesToDisplay.values.map((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Select a Language',
        showBackButton: false,
        showKebabMenu: false,
        pageNavigationTime:
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: myListKeys.length,
                itemBuilder: (context, index) {
                  final String key = myListKeys[index];
                  final String language = myListValues[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLanguage = key;
                        DataSingleton().locale = _selectedLanguage;

                        // Safe decoding of scale_languages
                        final dynamic rawScaleLanguages = scale_Json['scale_languages'];
                        final Map<String, dynamic> decodedScaleLanguages =
                        (rawScaleLanguages != null && rawScaleLanguages is Map<String, dynamic>)
                            ? Map<String, dynamic>.from(rawScaleLanguages)
                            : {};

                        final String scaleTitle =
                            decodedScaleLanguages[_selectedLanguage] ??
                                decodedScaleLanguages['en'] ??
                                'Scale';

                        DataSingleton().localeTitle = scaleTitle;

                        print("_selectedLanguage: $_selectedLanguage");
                        print("Scale Title: $scaleTitle");

                        _navigateToNextScreen(context);
                      });
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: _selectedLanguage == key
                                  ? Colors.blue
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedLanguage == key
                                    ? Colors.blue
                                    : Colors.grey,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Icon(
                              _selectedLanguage == key
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _selectedLanguage == key
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Text(
                            language,
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.black,
                            ),
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

