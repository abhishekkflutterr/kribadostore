import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/controllers/login_controller.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/models/CampPlanList.dart';
import 'package:kribadostore/models/FilterByDateCountResponse.dart';
import 'package:kribadostore/models/PlannedCampsResponse.dart';
import 'package:kribadostore/models/user_login_response.dart';
import 'package:kribadostore/screens/camp_plan_screen.dart';
import 'package:kribadostore/screens/scales_screen_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DataSingleton.dart';
import '../models/DateRangeFilterCount.dart';
import '../DatabaseHelper.dart';

class CampListScreen extends StatefulWidget {
  final LoginController loginController = Get.find<LoginController>();
  late LoginResponse loginResponse;
  late String divisionId;


  @override
  State<CampListScreen> createState() => _CampListScreenState();
}

class _CampListScreenState extends State<CampListScreen> {
  DateTime? startDateTime;
  DateTime? endDateTime;
  String? formattedStartDate;
  String? formattedEndDate;
  FilterByDateCountResponse? filterByDateCountResponse;
  PlannedCampsResponse? plannedCampsResponse;
  LoginController loginController = Get.find<LoginController>();

  String? selectedScale = 'None';

  var selectedPrescriberType;
  var divisionId = DataSingleton().division_encoded_Plan ?? '';

  late DatabaseHelper _databaseHelper;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          startDateTime = pickedDate;
          formattedStartDate = DateFormat('dd/MM/yy').format(startDateTime!); // Format start date
        } else {
          endDateTime = pickedDate;
          formattedEndDate = DateFormat('dd/MM/yy').format(endDateTime!); // Format end date
        }
      });
    }
  }


  @override
  void initState() {
    super.initState();

    print('@@@@@@camp plan list');
    _databaseHelper = DatabaseHelper.instance;
    fetchCampPlanListFromDB();
    getCamp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Camp Planned",
        showKebabMenu: true,
        showLogout: true,
        showHome: true,
        showBackButton: true,
        pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start Date
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Clock image for Start Date
                        Icon(
                          Icons.access_time, // Use a clock icon from Flutter's icon set
                          size: 30,
                          color: Colors.black,
                        ),
                        SizedBox(height: 5),
                        // Start Date text
                        Text(
                          "Start Date: ${formattedStartDate != null ? formattedStartDate.toString().split(' ')[0] : ''}",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // End Date
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Clock image for End Date
                        Icon(
                          Icons.access_time, // Same clock icon for End Date
                          size: 30,
                          color: Colors.black,
                        ),
                        SizedBox(height: 5),
                        // End Date text
                        Text(
                          "End Date: ${formattedEndDate != null ? formattedEndDate.toString().split(' ')[0] : ''}",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
            ,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24,2,24,2),
            child: Container(
              margin: EdgeInsets.fromLTRB(18,0,18,5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Set the border color to black
                  width: 1.0,         // Set the border width to 1 for a thin line
                ),
                borderRadius: BorderRadius.circular(5), // Optional: Add rounded corners
              ),
              // New Prescriber Type Dropdown
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButton<String>(
                  value: selectedPrescriberType,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPrescriberType = newValue;
                    });
                  },
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Select Status : '),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Planned',
                      child: Text('Planned'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Executed',
                      child: Text('Executed'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Not Executed',
                      child: Text('Not Executed'),
                    ),
                  ],
                  icon: Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.black),
                  underline: SizedBox(),
                  isExpanded: true,
                ),
              ),),
          ),
          const SizedBox(height: 10),
          Center(
            child: CustomElevatedButton(
              onPressed: () async {

                getCamp();


              },
              text: 'View',
              backgroundColor: Theme.of(context).primaryColor,
              horizontalPadding: 122,
              icon: Icon(Icons.my_library_books_outlined),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: plannedCampsResponse != null && plannedCampsResponse!.data.isNotEmpty
                ? ListView.builder(
              itemCount: plannedCampsResponse!.data.length,
              itemBuilder: (context, index) {
                var camp = plannedCampsResponse!.data[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(35,0,35,0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15,6,15,6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor Name: ${camp.doctorName}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                          Text('Date: ${camp.date}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                          Text('Prescriber Type: ${camp.prescriberType}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                          Text('Status: ${camp.status}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                          Align(
                            alignment: Alignment.centerRight,
                            child:

                            camp.status == "Planned" ?
                            CustomElevatedButton(

                              onPressed: () {
                                _fetchDivisionsOffline();
                                if (loginController.divisionsoff.length > 0)
                                {
                                  DataSingleton().division_id = loginController
                                      .divisionsoff[0].divisionIdInt;
                                  Get.to(
                                    ScalesScreenList(),
                                    arguments: {
                                      'divisionId': loginController
                                          .divisionsoff[0].divisionId,
                                      'subscriptionCode': loginController
                                          .divisionsoff[0].subscriptionCode,
                                      'division_id_numeric':
                                      loginController.divisionsoff[0].id,
                                      'doctorCode':
                                      camp.doctorCode,
                                      'doctorName':
                                      camp.doctorName,

                                    },
                                  );
                                } else {
                                  Get.snackbar('Please Wait',
                                      'Please wait data is loading....',
                                      snackPosition: SnackPosition.BOTTOM);
                                }

                              },
                              text: 'Start Camp',
                              icon: Icon(Icons.add_circle_outline),
                              horizontalPadding: 16,
                              backgroundColor: Theme.of(context).primaryColor,
                            ) : Container(),
                          )
                          ,
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: Text('${plannedCampsResponse?.message.toString() ?? "Select filters and press on view."}', style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: CustomElevatedButton(
        onPressed: () {
          Get.off(CampPlanScreen(), arguments: {
            'divisionId': divisionId,
          });
        },
        text: 'Add Camp',
        icon: Icon(Icons.add_circle_outline),
        horizontalPadding: 16,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future<void> getCamp() async {
    if(startDateTime==null){


      DateTime now = DateTime.now();
      String savedDateString = DateFormat('yyyy-MM-dd').format(now)+" 00:00:00.000";
      startDateTime = new DateFormat("yyyy-MM-dd hh:mm:ss").parse(savedDateString);

      print('@@## '+"Start Time null"+startDateTime.toString());
    }

    if(endDateTime==null){


      DateTime now = DateTime.now();
      String savedDateString = DateFormat('yyyy-MM-dd').format(now)+" 00:00:00.000";
      endDateTime = new DateFormat("yyyy-MM-dd hh:mm:ss").parse(savedDateString);

      print('@@## '+"End Time null"+endDateTime.toString());

    }
    if(selectedPrescriberType==null){

      selectedPrescriberType="Planned";
      print('@@## '+"selectedPrescriberType null"+selectedPrescriberType);
    }

    if (startDateTime != null && endDateTime != null && selectedPrescriberType != null) {

      CampPlanList date = CampPlanList(
        from_date: startDateTime!,
        to_date: endDateTime!,
        prescriberType: selectedPrescriberType == 'None'
            ? ''
            : selectedPrescriberType!,
      );

      print('@@@@#####fsfwksfsfk $divisionId');

      var response = await widget.loginController.CampPlanListData(context, divisionId, date);
      if (response != null) {
        setState(() {
          plannedCampsResponse = response;
        });
      } else {
        Get.snackbar('Failed !!!', 'Failed to retrieve data',
            snackPosition: SnackPosition.BOTTOM, colorText: Colors.black);
      }
    }
    else {

      if (startDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a start date')),
        );
        return;
      }

      if (selectedPrescriberType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a status')),
        );
        return;
      }

      if (endDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select end date')),
        );
        return;
      }



    }
  }



  Future<void> fetchCampPlanListFromDB() async {
    List<Map<String, dynamic>> dbCampPlanList = await _databaseHelper.getAllCampPlanListData();

    if (dbCampPlanList.isNotEmpty) {
      // Extract the stored JSON string
      String campPlanDataString = dbCampPlanList.first['camp_plan_data'];

      print('Raw camp_plan_data from DB: $campPlanDataString'); // DEBUG PRINT

      try {
        // First decoding
        var decodedData = json.decode(campPlanDataString);

        // If it's still a String, decode again
        if (decodedData is String) {
          print('Double Encoded JSON detected! Decoding again...');
          decodedData = json.decode(decodedData);
        }

        // Ensure it's a Map
        if (decodedData is Map<String, dynamic>) {
          setState(() {
            plannedCampsResponse = PlannedCampsResponse.fromJson(decodedData);
          });
        } else {
          print('Decoded data is not in the expected format.');
        }
      } catch (e) {
        print('Error decoding camp plan data: $e');
      }
    } else {
      print('No data found in the database.');
    }
  }


  Future<void> _fetchDivisionsOffline() async {




    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    await databaseHelper.initializeDatabase();
    List<Map<String, dynamic>> resources =
    await databaseHelper.getAllDivisiondetail();



    List<Map<String, dynamic>> allDoctors = []; // List to hold all doctors
    for (var resource in resources) {

      if (resource.containsKey('division_detail') &&
          resource['division_detail'] != null) {

        Map<String, dynamic> divisionDetail =
        json.decode(resource['division_detail']);


        List<Division> divisionsoff1 =
        (divisionDetail['data']['user']['divisions'] as List<dynamic>)
            .map((dynamic divisionData) => Division.fromJson(divisionData))
            .toList();


        loginController.changeJobListData(divisionsoff1);



      } else {
        print('Division detail not available');
      }


    }

  }
}


