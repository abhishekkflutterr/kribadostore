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
        // Use the fromJson factory to ensure all fields (including b64data) are parsed
        return Scales.fromJson(scaleData as Map<String, dynamic>);
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
    final ThemeController themeController = Get.find();
    String base64String =
        "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";
    final Uint8List bytes = base64Decode(base64String);


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
                                      child: (scale.b64data != null &&
                                          scale.b64data is String &&
                                          (scale.b64data as String)
                                              .isNotEmpty)
                                          ? Image.memory(
                                        base64Decode((scale.b64data
                                        as String)
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



