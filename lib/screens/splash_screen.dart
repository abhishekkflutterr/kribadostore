import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/screens/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../AppTheme.dart';
import '../DataSingleton.dart';
import '../DatabaseHelper.dart';
import '../NetworkHelper.dart';
import '../constants/urls.dart';
import '../controllers/ThemeController.dart';
import '../controllers/login_controller.dart';
import '../models/user_login_response.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'divisions_screen.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  LoginController loginController = Get.find<LoginController>();

  late StreamSubscription<bool> _subscription;
  final ThemeController themeController = Get.put(ThemeController());
  late String appPackage;

  late String imgString = '';
  late Uint8List _bytes;
  bool _imageLoaded = false; // Track if the image is loaded
  late String androidVersion = '';
  late DatabaseHelper databaseHelper;
  late String iosVersion = ''; // Declare androidVersion variable
  late bool isredirect = true; // Declare androidVersion variable
  String versionShortform = "";
  String appVersion = "";

  void getDeviceNameAndSetScreen() async {
    String? deviceName = await getDeviceName();

    if (["Alps Q1", "Alps JICAI Q1", "Q1", "JICAI Q2"].contains(deviceName)) {
      setscreen();
    }
  }

  Future<String?> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model; // Device model name
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name; // Device name
    }
    return null; // If platform is not Android or iOS
  }

  void setscreen() async {
    await ScreenUtils.setDisplayMode("small");
  }

  @override
  void initState() {
    super.initState();

    versionName();
    DataSingleton().checkInternet();
    databaseHelper = DatabaseHelper.instance;
    //All Time Call
    themeFromDb();
    getDeviceNameAndSetScreen();
    NetworkHelper().checkInternetConnection();
    // Listen to internet connectivity changes
    // _subscription = NetworkHelper().isOnline.listen((isOnline) {
    //   if (isOnline) {
        initiateAPICall();
    //   }
    // });

    /* LoginController loginController = Get.find<LoginController>();
    if (loginController.userLoginResponse != null &&
        loginController.userLoginResponse!.data != null) {
      List<Division> divisions = loginController.userLoginResponse!.data!.user.divisions;

      for (Division division in divisions) {
        print("xxxxxxxxxx${division.divisionName}");
        print("Subscription Code: ${division.subscriptionCode}");
        print("Verified: ${division.verified}");

        imgString = division.logo ?? "";
        String base64_logo = division.base64_logo ?? "";

        print('@@##base64 ' + base64_logo);
        setState(() async {
          _bytes = await const Base64Decoder().convert(base64_logo.replaceAll("data:image/png;base64,", ""));
        });
      }
    } else {
      print("User login response is null or empty. Handle this case accordingly.");
    }*/
  }

  Future<void> versionName() async {
    String checkPlatformAPPVersion = Platform.version;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      appVersion = packageInfo.version;

      if(checkPlatformAPPVersion.contains("android")){
        versionShortform = "A";
      }else{
        versionShortform = "I";
      }
    });

  }

  Future<void> initiateAPICall() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token == "" || token.isEmpty) {
      Get.offAll(LoginScreen());
    } else {
      // Token is not present, navigate to login screen
      autoLoginapi();
    }
  }

  themeFromDb() async {
    await databaseHelper.initializeDatabase();
    List<Map<String, dynamic>> resources =
        await databaseHelper.getAllDivisiondetail();

    String itheme = "";
    String ithemeText = "";
    List<Map<String, dynamic>> themes = await databaseHelper!.getTheme();

    print('@@## themes ' + themes.length.toString());


    for (var resource in resources) {
      if (resource.containsKey('division_detail') &&
          resource['division_detail'] != null) {
        Map<String, dynamic> divisionDetail =
            json.decode(resource['division_detail']);

        List<Division> divisionsoff1 =
            (divisionDetail['data']['user']['divisions'] as List<dynamic>)
                .map((dynamic divisionData) => Division.fromJson(divisionData))
                .toList();
        if(divisionDetail.containsKey(divisionDetail['data']['user'])){

          List<Division> divisionsoff1 =
          (divisionDetail['data']['user']['divisions'] as List<dynamic>)
              .map((dynamic divisionData) => Division.fromJson(divisionData))
              .toList();

          loginController.changeJobListData(divisionsoff1);
        }

      }
    }

    if (themes != null &&
        themes.length > 0 &&
        themes[0]["theme_color"].isNotEmpty) {
      itheme = themes[0]["theme_color"];
      ithemeText = themes[0]["text_color"];

      themeController.updatePrimaryColor(hexToColor(itheme));
      themeController.updatePrimaryTextColor(hexToColor(ithemeText));


      // Add a delay to simulate the splash screen
      Timer(
        const Duration(seconds: 2), // Adjust the duration as needed
        () async {
          // Check if a token is present in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (token != null && token.isNotEmpty) {
            if (isredirect) {
              isredirect = false;
              Get.offAll(DivisionsScreen());
            }
          } else {
            // Token is not present, navigate to login screen
            if (isredirect) {
              isredirect = false;
              Get.offAll(LoginScreen());
            }
          }
        },
      );
    } else {
      // Add a delay to simulate the splash screen
      Timer(
        const Duration(seconds: 2), // Adjust the duration as needed
        () async {
          // Check if a token is present in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (token != null && token.isNotEmpty) {
            if (isredirect) {
              isredirect = false;
              Get.offAll(DivisionsScreen());
            }
          } else {
            // Token is not present, navigate to login screen
            if (isredirect) {
              isredirect = false;
              Get.offAll(LoginScreen());
            }
          }
        },
      );
    }
  }

  Future<void> autoLoginapi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final user_id = prefs.getString('user_id');

    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };

    http.Response response = await http.post(
      Uri.parse('$baseurl/auto_login'),
      body: {'username': username, 'user_id': user_id},
      headers: headers,
    );

    if (response.statusCode == 200) {
      LoginResponse userLoginResponse =
          LoginResponse.fromJson(json.decode(response.body));

      Get.find<LoginController>().setUserLoginResponse(userLoginResponse);
      Get.find<LoginController>().updateUserLoginResponse(userLoginResponse);

      String theme_color = "";
      String text_color = "";

      LoginController loginController = Get.find<LoginController>();

      // Assuming response.body.toString() contains the JSON data
      Map<String, dynamic> responseData = json.decode(response.body.toString());

      // Extract app version information
      if (responseData['data'] != null &&
          responseData['data']['app_version'] != null) {
        var appVersion = responseData['data']['app_version'];
        if (appVersion != null) {
          androidVersion = appVersion['android']['version_code'];
          String iosVersion = appVersion['ios']['version_code'];

          // appUpdate();

        } else {
        }
      } else {
      }

      if (responseData.containsKey('data') && responseData['data'] != null) {
        List<dynamic> divisions = responseData['data']['user']['divisions'];

        for (var division in divisions) {
          if (division.containsKey('meta') && division['meta'] != null) {
            List<dynamic> metaList = division['meta'];

            for (var metaItem in metaList) {
              if (metaItem['key'] == "THEME_COLOUR") {
                theme_color = metaItem['value'];
              }

              if (metaItem['key'] == "TEXT_COLOUR") {
                text_color = metaItem['value'];
              }
            }
          } else {
            print("Meta data not available for this division.");
          }
        }
      } else {
        print("Data section not found in the response.");
      }

      if (theme_color != null && theme_color.isNotEmpty) {
        themeController.updatePrimaryColor(hexToColor(theme_color));
        themeController.updatePrimaryTextColor(hexToColor(text_color));
      }

      if (theme_color != null && text_color != null) {
        // Check if a theme already exists
        bool themeExists = await databaseHelper!.themeExists();

        if (themeExists) {
          // Update the existing theme
          await databaseHelper?.updateTheme(
            AppTheme(
              theme_color: theme_color,
              text_color: text_color,
            ),
          );
        } else {
          // Insert a new theme
          await databaseHelper?.insertTheme(
            AppTheme(
              theme_color: theme_color,
              text_color: text_color,
            ),
          );
        }
      }

      DataSingleton().userLoginOffline = response.body.toString();
      // await _databaseHelper?.allDetails(
      //   AutoLoginResp(
      //     resp: response.body.toString(),
      //   ),
      // );

      themeFromDb();
    } else {
      // Get.snackbar('Failed', 'Token Expired!',
      //     snackPosition: SnackPosition.BOTTOM);
      //
      // /* Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (context) => LoginScreen(),
      //   ),
      // );*/
      //
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();
      //
      // Get.offAll(LoginScreen());
    }
  }

  Future<void> appUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appVersion = packageInfo.version;
      appPackage = packageInfo.packageName;

      String platformType = Platform.isAndroid ? androidVersion : iosVersion;

      if (compareVersionCodes(appVersion, platformType) < 0) {
        showUpdateDialog(platformType);
      } else {
        // Add a delay to simulate the splash screen
        /* Timer(
          const Duration(seconds: 2),
              () async {
            // Check if a token is present in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('token');

            if (token != null && token.isNotEmpty) {
              // Token is present, navigate to home screen
              Get.off(() => DivisionsScreen());
            } else {
              // Token is not present, navigate to login screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            }
          },
        );*/
      }
    } catch (e) {
      print('Error during app update process: $e');
    }
  }

  int compareVersionCodes(String currentVersion, String apiVersion) {
    return currentVersion.compareTo(apiVersion);
  }

  void showUpdateDialog(String newVersion) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dismissing by back button

          child: AlertDialog(
            title: Text('New Version Available'),
            content:
                Text('A new version ($newVersion) is available. Update now?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Quicksand',
                      color: Theme.of(context).primaryColor,
                    )),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  exit(0);
                },
                child: Text('Exit'),
              ),
              TextButton(
                onPressed: () {
                  launchPlayStore();
                },
                child: Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> launchPlayStore() async {
    String packageName = 'com.indigitalit.kribadostore';
    String appStoreUrl = 'https://apps.apple.com/app/$packageName';
    String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';

    if (await canLaunch(appStoreUrl) && !Platform.isAndroid) {
      await launch(appStoreUrl);
    } else if (await canLaunch(playStoreUrl) && Platform.isAndroid) {
      await launch(playStoreUrl);
    } else {
      throw 'Could not launch store';
    }
  }

  void launchPlayStore1() async {
    final Uri url = Uri.parse(
        'https://s3.ap-south-1.amazonaws.com/kribado2.0/app-release.apk');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void lauchAppStore() async {
    final Uri url =
        Uri.parse('https://apps.apple.com/in/app/kribado/id6475755271');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 140.0, // Set the height you want for your bottom bar
                width: 300, // Make sure it spans the full width of the screen
                child: Obx(
                  () => loginController.divisionsoff.length != 0 &&
                          loginController.divisionsoff[0].base64_logo
                              .trim()
                              .isNotEmpty
                      ? Image.memory(Base64Decoder().convert(loginController
                          .divisionsoff[0].base64_logo
                          .replaceAll("data:image/png;base64,", "")))
                      : const SizedBox(
                          height:
                              140.0, // Set the height you want for your bottom bar
                          width:
                              300, // Make sure it spans the full width of the screen
                        ),
                ),
              ),
/*              Image.asset(
                'assets/toplogologin.png', // Replace with your actual image asset
                height: 250,
                width: 350,
              ),*/
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    Text("POWERED BY"),
                    SizedBox(height: 20.0),
                    Image(
                      image: AssetImage('assets/logo.png'),
                      height: 36.75,
                      width: 141.75,
                    ),
                    Text('v.$versionShortform-$appVersion',style: TextStyle(fontSize: 10,color: Colors.black),)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Utility function to convert hex string to Color
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
