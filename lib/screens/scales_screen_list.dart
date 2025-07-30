import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/AppTheme.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/screens/BrandsPrescription_screen.dart';
import 'package:kribadostore/screens/doctor_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Buttons.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../MetaDetails.dart';
import '../NetworkHelper.dart';
import '../Resources.dart';
import '../UserMr.dart';
import '../constants/ColorConstants.dart';
import '../controllers/ThemeController.dart';
import '../controllers/login_controller.dart';
import '../models/division_details_response.dart';
import 'package:http/http.dart' as http;
import '../constants/urls.dart';

class ScalesScreenList extends StatefulWidget {
  @override
  State<ScalesScreenList> createState() => _ScalesScreenListState();
}

class _ScalesScreenListState extends State<ScalesScreenList> {
  final LoginController loginController = Get.find<LoginController>();
  final ThemeController themeController = Get.put(ThemeController());
  // Use the single instance of NetworkHelper
  final NetworkHelper _networkHelper = NetworkHelper();
  late StreamSubscription<bool> _subscription;
  late String divisionId;
  late int divisionIdNumeric;
  late int subscriptionCode;
  late String doctorCode;
  late String doctorName;
  late String mrCode;

  Color? primaryColor;
  Color? primaryTextColor;

  DatabaseHelper? _databaseHelper;
  Future<List<Scales>?>? _divisionDetailsFuture;

  List<Scales> scalesoff = [];

  late List<Scales> scales;
  late List<Brands> brands;
  bool show_popup = true;

  late String base64String;

  @override
  initState() {
    super.initState();
    _databaseHelper = DatabaseHelper.instance;
    _databaseHelper?.initializeDatabase();
    // fetchMeta();
    print('!!!saleslist ${DataSingleton().drConsentText}');
    _divisionDetailsFuture = divisionDetails();
    // Check internet connectivity
    _networkHelper.checkInternetConnection();
    _fetchScaleslistOffline();
    showalert();
  }

  Future<void> fetchMeta() async {
    List<Map<String, dynamic>> themes = await _databaseHelper!.getMetaData();
    // print('thjemrr: $themes');
    String i_qrl = themes[0]["qr_url"];
    // print("xvndgjujsijsfsjf $i_qrl");
    String i_qr_label = themes[0]["qr_label"];
    DataSingleton().qr_url = i_qrl;
    DataSingleton().qr_label = i_qr_label;
  }

  Future<void> _fetchScaleslistOffline() async {
    // print('@@##&& fetchScaleslistOffline');

    try {
      DatabaseHelper databaseHelper = DatabaseHelper.instance;
      await databaseHelper.initializeDatabase();

      //List<Map<String, dynamic>> resources = await databaseHelper.getAllresources();
      List<Map<String, dynamic>> resources =
          await databaseHelper.getAllDivisiondetail();

      for (var resource in resources) {
        if (resource.containsKey('scales_list') &&
            resource['scales_list'] != null) {
          Map<String, dynamic> screenDetail =
              json.decode(resource['scales_list']);
          // print('screen detail available');
          List<Scales> scales = decodeScalesFromJson(screenDetail);
          List<Brands> brands = decodeBrandsFromJson(screenDetail);

          // print("@@##brabds "+brands.length.toString());
          scalesoff = scales;
          DataSingleton().brands = brands;

          List<dynamic> metaList = [];
          if (screenDetail.containsKey('data')) {
            Map<String, dynamic> data = screenDetail['data'];
            if (data.containsKey('meta')) {
              metaList = data['meta'];

              for (var meta in metaList) {
                var key = meta['key'];
                var value = meta['value'];

                if (key == "PRINT_BTN") {
                  // DataSingleton().download_btn =  value;

                  DataSingleton().print_btn = value;
                  // print('DataSingleton().print_btn= '+value);
                }

                if (key == "DOWNLOAD_BTN") {
                  // DataSingleton().download_btn =  value;

                  DataSingleton().download_btn = value;
                }

                if (key == "DOWNLOAD_PRINT_BTN") {
                  // DataSingleton().download_print_btn =  value;
                  DataSingleton().download_print_btn = value;
                }
                if (key == "DISCLAIMER") {
                  // DataSingleton().download_print_btn =  value;
                  DataSingleton().Disclaimer = value;
                }

                if (key == "FONT_SIZE") {
                  print("FONT_SIZE@ $value");

                  DataSingleton().font_size = double.parse(value);

                  // print("FONT_SIZE@ "+DataSingleton().font_size.toString());
                }

                if (key == "THEME_COLOUR") {
                  primaryColor = hexToColor(value);
                }

                if (key == "TEXT_COLOUR") {
                  primaryTextColor = hexToColor(value);
                }
              }

              // Apply the themes after the loop
              if (primaryColor != null) {
                themeController.updatePrimaryColor(primaryColor!);
              }

              if (primaryTextColor != null) {
                themeController.updatePrimaryTextColor(primaryTextColor!);
              }
            }
          }
          // Trigger a UI update when offline data is loaded
          setState(() {});
        } else {
          print('screen detail not available');
        }
      }
    } catch (e) {
      print('Error fetching offline data: $e');
    }
  }

  List<Scales> decodeScalesFromJson(Map<String, dynamic> screenDetail) {
    try {
      List<dynamic> scalesJson = screenDetail['data']['scales'];
      scales = scalesJson.map<Scales>((scaleData) {
        return Scales(
          name: scaleData['name'],
          displayName: scaleData['display_name'],
          s3Url: scaleData['s3_url'],
        );
      }).toList();
      return scales;
    } catch (e) {
      print('Error decoding scales: $e');
      return [];
    }
  }

  List<Brands> decodeBrandsFromJson(Map<String, dynamic> screenDetail) {
    // print("@@##Call Brand");
    try {
      List<dynamic> scalesJson = screenDetail['data']['brands'];
      brands = scalesJson.map<Brands>((brandData) {
        return Brands(
          id: brandData['id'],
          name: brandData['name'],
        );
      }).toList();
      return brands;
    } catch (e) {
      print('Error decoding scales: $e');
      return [];
    }
  }

  Future<void> _insertData() async {
    await _databaseHelper
        ?.insertUser(UserMr(mr_code: mrCode, subscriber_id: subscriptionCode));

    // print("mr_codesubscriptionCode1:$subscriptionCode");
    print(
        "mr_codesubscriptionCode:${loginController.userLoginResponse!.data.user.empCode}");
    //await _databaseHelper?.insertDoctor(Doctor(country_code: "91", state_code: "22", city_code: "33", area_code: "44", doc_code: "2", doc_name: "XYZ", doc_speciality: "doc_speciality", division_id: 99));
    //await _databaseHelper?.insertCamp(Camp(camp_id: 1, camp_date: "22-12-2023", test_date: "22-12-2023", test_start_time: "22-12-2023", test_end_time: "22-12-2023", created_at: "22-12-2023", scale_id: "22-12-2023", test_score: "22-12-2023", interpretation: "interpretation", language: "language", pat_age: "23", pat_gender: "Female", pat_email: "pat_email", pat_mobile: "987654321", pat_name: "Sam", pat_id: "2"));

    // setState(() {});
    print("Database success User ");
  }

  Future<List<Scales>?> divisionDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };

    try {
      divisionId = Get.arguments?['divisionId'] ?? '';
      divisionIdNumeric = Get.arguments?['division_id_numeric'] ?? '';
      doctorCode = Get.arguments?['doctorCode'] ?? '';
      doctorName = Get.arguments?['doctorName'] ?? '';

      print('@@##doctorCode ' + doctorCode);

      subscriptionCode = loginController.userLoginResponse!.data.user.mrId;
      mrCode = loginController.userLoginResponse!.data.user.empCode;
      DataSingleton().subscriber_id = subscriptionCode;
      DataSingleton().mr_code = mrCode;

      print('@@@@@@@scalesscreen subscirerid ${DataSingleton().subscriber_id}');

      // print("check 1] mrcode: ${DataSingleton().mr_code}  subscriberid : ${DataSingleton().subscriber_id}");
      // print("check 1 subsid ${DataSingleton().subscriber_id}");

      // print('Division ID from Get.argumentsbb: $divisionId');
      var res = await http.get(
          Uri.parse('$baseurl/division_detail/$divisionId'),
          headers: headers);
      if (res.statusCode == 200) {
        DivisionDetailsResponse divisionDetailsResponse =
            DivisionDetailsResponse.fromJson(json.decode(res.body));

        // Set divisionDetailsResponse using the singleton
        DataSingleton().divisionDetailOffline = res.body.toString();
        // print('divisondetailoffline ${DataSingleton().divisionDetailOffline}');

        // String sl = jsonDecode(res.body)['scales'];
        // print('sl $sl');

        // print('@@##** '+DataSingleton().division_id.toString());
        // print('@@##** '+DataSingleton().userLoginOffline.toString());
        // print('@@##** '+DataSingleton().divisionDetailOffline.toString());
        // print('@@##** '+DataSingleton().s3jsonOffline.toString());

        DataSingleton().brands = divisionDetailsResponse.data.brands;
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('brands', res.body);

        // Check if the doctor exists
        int? doctorExists = await _databaseHelper
            ?.doesDivisionsDetailsExist(DataSingleton().division_id.toString());
        // print('@@##**E '+doctorExists.toString());

        if (doctorExists == 0) {
          // Perform database insertion
          await _databaseHelper?.insertDivisiondetail(
            Resources(
              user_id: DataSingleton().division_id.toString(),
              division_detail: DataSingleton().userLoginOffline.toString(),
              scales_list: DataSingleton().divisionDetailOffline.toString(),
              s3_json: "",
            ),
          );
        } else {
          print('@@##** Update Scales');

          // Perform database insertion
          await _databaseHelper?.updateDivisiondetailField(
              DataSingleton().division_id.toString(),
              "scales_list",
              DataSingleton().divisionDetailOffline.toString());
        }

        DivisionDetailsData divisionDetailsData = divisionDetailsResponse.data;
        /*  Future<List<Scales>?> divisionDetails() async {
          var headers = {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${loginController.userLoginResponse?.data.token ?? ''}',
          };

          try {
            divisionId = Get.arguments?['divisionId'] ?? '';
            divisionIdNumeric = Get.arguments?['division_id_numeric'] ?? '';
            subscriptionCode = Get.arguments?['subscriptionCode'] ?? '';
            mrCode = loginController.userLoginResponse!.data.user.empCode;
            // print('Division ID from Get.argumentsbb: $divisionId');



          } catch (e) {
            print(e.toString());
            return null;
          }
        }
*/

        List<Meta> meta = divisionDetailsData.meta;
        DataSingleton().mData = meta;

        String disclaimer = "";

        String print_btn = "";
        String download_btn = "";
        String download_print_btn = "";

        String ios_qr_label = "";
        String ios_qr_url = "";

        String qr_url = "";
        String qr_label = "";
        String theme_color = "";
        String text_color = "";

        for (Meta metaList in meta) {
          var key = metaList.key;
          dynamic value = metaList.value;
          // print('Keyyyytttttt: $key');

          if (key == "THEME_COLOUR") {
            theme_color = value;
          }

          if (key == "TEXT_COLOUR") {
            text_color = value;
          }

          /* if(key == "PT_CONSENT_TEXT") {
            DataSingleton().ptConsentText =  value;
          }

          if(key == "DR_CONSENT_TEXT") {
            DataSingleton().drConsentText =  value;
            print('##111drcondenttextttt ${DataSingleton().drConsentText}');
          }
*/

          if (key == "PRINT_BTN") {
            print_btn = value;
            DataSingleton().print_btn = value;
          }

          if (key == "FONT_SIZE") {
            DataSingleton().font_size = double.parse(value);
          }

          if (key == "DOWNLOAD_BTN") {
            // DataSingleton().download_btn =  value;
            download_btn = value;
            DataSingleton().download_btn = value;
          }

          if (key == "DOWNLOAD_PRINT_BTN") {
            // DataSingleton().download_print_btn =  value;
            download_print_btn = value;
            DataSingleton().download_print_btn = value;
          }

          if (key == "QR_URL") {
            qr_url = value;
            // print("qqqqqrrrurrrlllll $qr_url");
          }

          if (key == "QR_LABEL") {
            qr_label = value;
            // print("xxxxzzzzzzzzurrrlllll $qr_label");
          }

          if (key == "IOS_QR_LABEL") {
            ios_qr_label = value;
            // print("xxxxzzzzzzzzurrrlllll $qr_label");

            DataSingleton().ios_qr_label = ios_qr_label;
          }

          if (key == "IOS_QR_URL") {
            ios_qr_url = value;
            // print("xxxxzzzzzzzzurrrlllll $qr_label");
            DataSingleton().ios_qr_url = ios_qr_url;
          }

          if (key == "DISCLAIMER") {
            disclaimer = value;
            // print("qqqqqrrrurrrlllll $qr_url");

            DataSingleton().Disclaimer = disclaimer;
          }

          if (key == "END_CAMP_BTN") {
            DataSingleton().EndCampBtn = value;
          }

          // print("gdhdxvvcxvgstxvxzdfdgsgggd $qr_url");

          if (download_btn != null ||
              print_btn != null ||
              download_print_btn != null) {
            bool buttonExists = await _databaseHelper!.buttonExists();
            if (buttonExists) {
              // Update the existing theme
              await _databaseHelper?.updateButtons(
                Buttons(
                  print_btn: print_btn,
                  download_btn: download_btn,
                  print_download_btn: download_print_btn,
                ),
              );
            } else {
              // Insert a new theme
              print("dgdgrydvxvddgsgdvxvc $qr_url");
              await _databaseHelper?.insertButton(
                Buttons(
                  print_btn: print_btn,
                  download_btn: download_btn,
                  print_download_btn: download_print_btn,
                ),
              );
            }
          }

          if (qr_url != null) {
            bool metaDataExists = await _databaseHelper!.metaDataExists();
            if (metaDataExists) {
              // Update the existing theme
              await _databaseHelper?.updateMetaData(
                MetaDetails(
                  qr_url: qr_url,
                  qr_label: qr_label,
                ),
              );
            } else {
              // Insert a new theme
              print("dgdgrydvxvddgsgdvxvc $qr_url");
              await _databaseHelper?.insertMeta(
                MetaDetails(
                  qr_url: qr_url,
                  qr_label: qr_label,
                ),
              );
            }
          }

          // await _databaseHelper?.insertButton(
          //   Buttons(
          //     theme_color: theme_color,
          //     text_color: text_color,
          //   ),
          // );
        }

        String themeColor = '#ffdf00'; // Or fetch this value dynamically

        String itheme = "";
        String ithemeText = "";
        if (theme_color != null && text_color != null) {
          // Check if a theme already exists
          bool themeExists = await _databaseHelper!.themeExists();

          if (themeExists) {
            // Update the existing theme
            await _databaseHelper?.updateTheme(
              AppTheme(
                theme_color: theme_color,
                text_color: text_color,
              ),
            );
          } else {
            // Insert a new theme
            await _databaseHelper?.insertTheme(
              AppTheme(
                theme_color: theme_color,
                text_color: text_color,
              ),
            );
          }
        }

        List<Map<String, dynamic>> themes = await _databaseHelper!.getTheme();
        // print('thjemrr: $themes');

        itheme = themes[0]["theme_color"];
        ithemeText = themes[0]["text_color"];
        // print("cnvnvnvnn $itheme");

        // print('printThemeColor $theme_color');
        // themeController.updatePrimaryColor(Color(0xFFffdf00));
        // themeController.updatePrimaryColor(Colors.red);

        if (itheme.isNotEmpty && ithemeText.isNotEmpty) {
          themeController.updatePrimaryColor(hexToColor(itheme));
          themeController.updatePrimaryTextColor(hexToColor(ithemeText));
        }

        // Access scales from the deserialized models
        List<Scales> scales = divisionDetailsData.scales;

        if (scales.isNotEmpty) {
          if (mrCode.isEmpty) {
          } else {
            _insertData();
          }

          for (Scales scale in scales) {
            // print("@@##** : ${scale.s3Url}");
          }
        } else {
          print("No scales found");
          print("Scale NOTDisplay Name: ");
        }

        return scales;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Scales list',
        showBackButton: true,
        showKebabMenu: false,
        pageNavigationTime:
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/scalesScreen.png'),
              fit: BoxFit.fitWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Use FutureBuilder to display scales
              Expanded(
                child: FutureBuilder<List<Scales>?>(
                  future: Future.value(scalesoff),
                  builder: (context, snapshot) {
                    print("Is snapshot done ${snapshot.connectionState}");

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<Scales>? scales = snapshot.data;

                      if (scales == null || scales.isEmpty) {
                        print("No scales found");
                        return Text('No scales found',
                            style: Theme.of(context).textTheme.bodyMedium);
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: scales.length,
                          itemBuilder: (context, index) {
                            Scales scale = scales![index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  28.0, 5.0, 28.0, 0.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: ColorConstants.lightGrey,
                                  ),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation:
                                    2, // Slight elevation for shadow effect
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(
                                      12), // Adding padding for content inside the ListTile
                                  leading: SizedBox(
                                    width:
                                        60, // Set a fixed width for the image
                                    height:
                                        60, // Set a fixed height for the image
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: scale.b64data != null &&
                                              scale.b64data!.isNotEmpty
                                          ? Image.memory(
                                              base64Decode(scale.b64data!
                                                  .replaceAll(
                                                      "data:image/png;base64,",
                                                      "")),
                                            )
                                          : Image.asset(
                                              'assets/labtest.png',
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    scale.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      fontSize:
                                          16, // Adjust font size as per the design
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  onTap: () {
                                    print(
                                        'Selected scale: ${scale.displayName}');
                                    DataSingleton().localeTitle = null;
                                    DataSingleton().scaleS3Url = scale.s3Url;

                                    Get.to(DoctorSelectionScreen(), arguments: {
                                      'doctorCode': doctorCode,
                                      'doctorName': doctorName,
                                    });

                                    DataSingleton().scale_name =
                                        scale.displayName;
                                    DataSingleton().division_encoded =
                                        divisionId;
                                    DataSingleton().scale_id = scale.name;

                                    print(
                                        "Selected scale S3 URL: ${DataSingleton().scale_id}");
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _checkAndNavigate() async {
    show_popup = false;
    showDialog(
      context: context,
      builder: (BuildContext precontext) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(
            'Prescription is incomplete. Please proceed to complete?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              color: Theme.of(context).primaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.off(BrandsPrescription());
              },
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  showalert() async {
    final prefs = await SharedPreferences.getInstance();
    bool? prescriptionPopup = prefs.getBool('prescriptionPopup');
    if (prescriptionPopup == false) {
      if (show_popup == true) {
        _checkAndNavigate();
      }
    }
  }
}

// Utility function to convert hex string to Color
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
