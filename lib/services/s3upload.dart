import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/custom_widgets/customsnackbar.dart';
import 'package:aws_client/cloud_front_2016_11_25.dart';
import 'package:aws_client/s3_2006_03_01.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DatabaseHelper.dart';

class S3Upload {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> campsData = [];
  Map<String, dynamic> resultData = {};
  // final LoginController loginController = Get.find<LoginController>();
  // var mrCodedb;
  bool showSyncedSnackbar = false;
  String? subscriber_id;
  String? mr_id;


  S3Upload() {
    _databaseHelper = DatabaseHelper.instance;
  }

  Future<void> initializeAndFetchDivisionDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    subscriber_id = prefs.getString('subscriber_id');
    mr_id = prefs.getString('mr_id');

    await _databaseHelper.initializeDatabase();
    campsData = await _databaseHelper.getAllcamps();
    print('campssdatas33333uploaddd $campsData');

    /////////////////////////////////////////////////////////////////////////////////////for setting up aws creds - working
    final List<Map<String, dynamic>> resourcesDataOffline = await _databaseHelper.getAllDivisiondetail();
    if (resourcesDataOffline.isNotEmpty) {
      String divisionDetail = resourcesDataOffline[0]["division_detail"];
      Map<String, dynamic> responseJson = json.decode(divisionDetail);
      try {
        Map<String, dynamic> awsCreds = responseJson['data']['aws_creds'];
        DataSingleton().accessKeyId = awsCreds['AWS_ACCESS_KEY_ID'];
        print('sssssssss33333acceskeyid ${DataSingleton().accessKeyId}');
        DataSingleton().secretAccessKey = awsCreds['AWS_SECRET_ACCESS_KEY'];
        DataSingleton().bucket = awsCreds['AWS_BUCKET'];
        DataSingleton().bucketFolder = awsCreds['AWS_BUCKET_FOLDER'];
      } catch (e) {
        print('Error accessing AWS credentials: $e');
      }
    } else {
      print('No offline data available');
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// building up jsondata
    // Static device data
    final Map<String, dynamic> deviceData = {
      "appVersion": DataSingleton().appversion.toString(),
      "dataType": "4G",
      "lastused": "",
      "mobileData": "False",
      "networkType": "5G",
      "signalStrength": "Poor",
      "simCountryId": "platformVersion",
      "simId": "mobileNumber",
      "totalDisk": "totalSpace",
      "totalRam": "totalRam",
      "usedDisk": "diskSpace",
      "usedRam": "usedRam",
      "wifi": "False",
      "device_serial_number": DataSingleton().device_serial_number,
      "device_brand": "deviceInfo+deviceInfo2",
      "device_os": "deviceInfo3",
      "channel": DataSingleton().device_serial_number==""?"App":"Device",
    };

    // Structure data array with nested "answers" field
    final List<Map<String, dynamic>> dataArray = [];
    for (final doctor in campsData) {
      final String answersString = doctor["answers"];
      List<Map<String, dynamic>> answersList;
      try {
        // Replace single quotes with double quotes and add double quotes around keys
        final formattedString = answersString
            .replaceAll("'", "\"")
            .replaceAll("question_id", "\"question_id\"")
            .replaceAll("score", "\"score\"")
            .replaceAll("answer", "\"answer\"")
            .replaceAll("child_id", "\"child_id\"")
            .replaceAllMapped(
            RegExp(r'"answer":\s*([^,}\]]+)', multiLine: true),
                (match) => '"answer": "${match.group(1)}"');
        // Decode the formatted string
        answersList =
        List<Map<String, dynamic>>.from(json.decode(formattedString));
      } catch (e) {
        print("Error decoding answersString: $e");
        answersList = [];
      }

      final Map<String, dynamic> doctorData = {
        "pat_id": doctor["pat_id"],
        "pat_consent": doctor["patient_consent"],
        "answers": answersList, // Add your answers data here
        "camp_id": doctor["camp_id"],
        "camp_date": doctor["camp_date"],
        "division_id": doctor["division_id"],
        "test_date": doctor["test_date"],
        "test_start_time": doctor["test_start_time"],
        "test_end_time": doctor["test_end_time"],
        "created_at": doctor["created_at"],
        "scale_id": doctor["scale_id"],
        "test_score": doctor["test_score"],
        "interpretation": doctor["interpretation"],
        "language": doctor["language"],
        "mr_code": doctor["mr_code"],
        "country_code": doctor["country_code"],
        "doc_consent": doctor["dr_consent"],
        "doc_code": doctor["doc_code"],
        "dr_id": doctor["dr_id"],
        "subscriber_id": doctor["subscriber_id"],
        "patient": doctor["patient_meta"].replaceAll('/\/', ""),
        "doctor": doctor["doctor_meta"]
      };
      dataArray.add(doctorData);
    }
    // Combine device and data into Fthe final result
    resultData = {
      "device": deviceData,
      "data": dataArray,
    };

    print('sss33uploadresultdata  $resultData');


  }

  Future<void> uploadJsonToS3() async {
    if (campsData == null || campsData.isEmpty) {
      // Handle the case where campsData is null or empty
      print('No data uploaded');

      if(DataSingleton().clearDoctor==true){
        print('@@@@@@@@@@clearsdoctorrrr');

        await _databaseHelper.clearDoctorsTable();
      }

      await _databaseHelper.clearDivisionDetailTable();
      await _databaseHelper.clearUsersTable();
      // setState(() {
      //   if (showSyncedSnackbar) {
      CustomSnackbar.showErrorSnackbar(
        title: 'Already Done',
        message: 'Already Synced successfully.',
      );
      //   }
      // });
      // You may show an error message or handle it as needed
      return;
    } else {
      // Proceed with uploading data only if there is an internet connection
      // final awsCreds = loginController.userLoginResponse?.data.awsCreds;
      final awsCredentials = AwsClientCredentials(
        accessKey: '${DataSingleton().accessKeyId}',
        secretKey:
        '${DataSingleton().secretAccessKey}',
      );

      final s3 = S3(region: 'ap-south-1', credentials: awsCredentials);
      String? dataName =
      ("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}_${DataSingleton().division_id}_$mr_id")
          .toString();
      final bucketName = '${DataSingleton().bucket}';
      var ok =
          '${DataSingleton().bucketFolder}/$dataName.json';
      final objectKey = '$ok';
      print('buckketnamezzz $objectKey');
      try {
        final jsonData = resultData;
        // Convert JSON data to Uint8List
        final jsonDataBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(jsonData)));
        // Upload the JSON file to S3
        await s3.putObject(
          bucket: bucketName,
          key: objectKey,
          body: jsonDataBytes,
        );
        // setState(() async {
        Get.snackbar('Success', 'Data sync successful.',
            snackPosition: SnackPosition.BOTTOM);
        await clearCampsTable();
        final prefs = await SharedPreferences.getInstance();
        String syncedNow =
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} IST";
        await prefs.setString('lastSync', syncedNow);
        // });
      } catch (e) {
        // setState(() {
        //   CustomSnackbar.showErrorSnackbar(
        //     title: 'Error',
        //     message: 'Sync error: $e',
        //   );
        // });
      } finally {
        s3.close();
      }
    }
  }


  Future<void> uploadJsonToS3ButOnlySync() async {
    if (campsData == null || campsData.isEmpty) {
      // Handle the case where campsData is null or empty
      print('No data uploaded');

      CustomSnackbar.showErrorSnackbar(
        title: 'Already Done',
        message: 'Already Synced successfully.',
      );
      return;
    } else {
      final awsCredentials = AwsClientCredentials(
        accessKey: '${DataSingleton().accessKeyId}',
        secretKey:
        '${DataSingleton().secretAccessKey}',
      );

      final s3 = S3(region: 'ap-south-1', credentials: awsCredentials);
      String? dataName =
      ("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}_${DataSingleton().division_id}_$mr_id")
          .toString();
      final bucketName = '${DataSingleton().bucket}';
      var ok =
          '${DataSingleton().bucketFolder}/$dataName.json';
      final objectKey = '$ok';
      print('buckketnamezzz $objectKey');
      try {
        final jsonData = resultData;
        // Convert JSON data to Uint8List
        final jsonDataBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(jsonData)));
        // Upload the JSON file to S3
        await s3.putObject(
          bucket: bucketName,
          key: objectKey,
          body: jsonDataBytes,
        );
        Get.snackbar('Success', 'Data sync successful.',
            snackPosition: SnackPosition.BOTTOM);
        await _databaseHelper.clearCampsTable();
        final prefs = await SharedPreferences.getInstance();
        String syncedNow =
            "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} IST";
        await prefs.setString('lastSync', syncedNow);
      } catch (e) {
        // setState(() {
        //   CustomSnackbar.showErrorSnackbar(
        //     title: 'Error',
        //     message: 'Sync error: $e',
        //   );
        // });
      } finally {
        s3.close();
      }
    }
  }


  Future<void> clearCampsTable() async {
    await _databaseHelper.clearCampsTable();
    await _databaseHelper.clearDivisionDetailTable();
    await _databaseHelper.clearUsersTable();
    print('@@@@@@@@@@checkcleardoctor ${DataSingleton().clearDoctor}');
    if(DataSingleton().clearDoctor==true){
      print('@@@@@@@@@@clearsdoctorrrr');

      await _databaseHelper.clearDoctorsTable();
    }
    final prefs = await SharedPreferences.getInstance();
    String syncedNow =
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} IST";
    await prefs.setString('lastSync', syncedNow);
  }

}