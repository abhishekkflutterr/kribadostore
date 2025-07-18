import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/controllers/login_controller.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/models/FilterByDateCountResponse.dart';
import 'package:kribadostore/models/user_login_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DataSingleton.dart';
import '../models/DateRangeFilterCount.dart';
import '../DatabaseHelper.dart';

class CampReportScreen extends StatefulWidget {
  final LoginController loginController = Get.find<LoginController>();
  late LoginResponse loginResponse;
  late String divisionId;

  @override
  State<CampReportScreen> createState() => _CampReportScreenState();
}

class _CampReportScreenState extends State<CampReportScreen> {
  DateTime? startDateTime;
  DateTime? endDateTime;
  FilterByDateCountResponse? filterByDateCountResponse;

  List<Scales> scales = [];
  String? selectedScale = 'None';

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != (isStartDate ? startDateTime : endDateTime)) {
      setState(() {
        if (isStartDate) {
          startDateTime = pickedDate;
        } else {
          endDateTime = pickedDate;
        }
      });
    }
  }

  Future<void> _fetchScales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginJson = prefs.getString('loginjson');
      String? data = DataSingleton().userLoginOffline ?? loginJson;

      if (data != null) {
        Map<String, dynamic> jsonResponse = jsonDecode(data);

        // Extract the scales array
        List<dynamic> scalesJson = jsonResponse['data']['user']['divisions'][0]['scales'];
        if (scalesJson != null && scalesJson.isNotEmpty) {
          setState(() {
            scales = scalesJson.map<Scales>((scaleData) {
              return Scales(
                name: scaleData['name'],
                displayName: scaleData['display_name'],
                s3Url: scaleData['s3_url'],
              );
            }).toList();
          });
        } else {
          // If scales are empty or null, fetch from the database
          await _fetchScalesFromDatabase();
        }
      } else {
        // If no data from DataSingleton, fetch from the database
        await _fetchScalesFromDatabase();
      }
    } catch (e) {
      print('Error fetching scales data: $e');
      // Handle any errors
      await _fetchScalesFromDatabase(); // Fallback to database fetch
    }
  }

  Future<void> _fetchScalesFromDatabase() async {
    try {
      DatabaseHelper databaseHelper = DatabaseHelper.instance;
      await databaseHelper.initializeDatabase();

      List<Map<String, dynamic>> resources = await databaseHelper.getAllDivisiondetail();
      List<Scales> tempScales = [];

      for (var resource in resources) {
        if (resource.containsKey('scales_list') && resource['scales_list'] != null) {
          Map<String, dynamic> scalesDetail = json.decode(resource['scales_list']);
          tempScales = decodeScalesFromJson(scalesDetail);
        }
      }

      setState(() {
        scales = tempScales;
      });
    } catch (e) {
      print('Error fetching scales from database: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchScales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Camp Report",
        showKebabMenu: true,
        showHome: true,
        showLogout: true,
        showBackButton: true,
        pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.fromLTRB(18.0,0,18.0,0),
                child: Container(

                  padding: EdgeInsets.fromLTRB(21.0,21,21,15), // Optional: Add padding inside the border
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.tealAccent, // Border color
                      width: 0.5, // Border width
                    ),
                    borderRadius: BorderRadius.circular(4.0), // O
                    color: ColorConstants.whiteCmap// ptional: Round the corners
                  ),
              child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures the text is on the left and icon is on the right
                children: [
                      Text(
                        "Start Date ${startDateTime != null ? startDateTime.toString().split(' ')[0]  : ' :'}",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black),
                    ],
                  ),


                    ),
              )
              ,
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.fromLTRB(18.0,0,18.0,0),
                child: Container(
                  padding: EdgeInsets.fromLTRB(21.0,21,21,15), // Optional: Add padding inside the border
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.tealAccent, // Border color
                      width: 0.5, // Border width
                  ),
                    borderRadius: BorderRadius.circular(4.0), // Optional: Round the corners
                    color: ColorConstants.whiteCmap,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align text and icon at opposite ends
                    children: [
                      Text(
                        "End Date ${endDateTime != null ? endDateTime.toString().split(' ')[0] : ' :'}",
                        style: TextStyle(
                          fontSize: 16.0, // Adjust font size as needed
                          color: Colors.black, // Optional: Adjust text color
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black), // Calendar icon at the end
                    ],
                  ),
              ),
            ),

              onTap: () => _selectDate(context, false),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(32.0,0,42.0,0),
              child:Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.tealAccent, // Border color
                    width: 0.5, // Border width
                  ),
                  borderRadius: BorderRadius.circular(4.0), // Round the corners
                  color: ColorConstants.whiteCmap, // Background color
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0), // Horizontal padding to prevent clipping
              child: DropdownButton<String>(
                    value: selectedScale,
                onChanged: (String? newValue) {
                  setState(() {
                        selectedScale = newValue;
                  });
                },
                items: [
                  DropdownMenuItem<String>(
                        value: 'None',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'All',
                                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                              ),
                            ),
                            Divider(
                              color: Colors.grey,
                              thickness: 0.4,
                            ),
                          ],
                        ),
                      ),
                      ...scales.map<DropdownMenuItem<String>>((Scales scale) {
                        return DropdownMenuItem<String>(
                          value: scale.name,
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: scales.indexOf(scale) == 0
                                      ? Colors.transparent
                                      : Colors.grey,
                                  width: 0.4,
                                ),
                  ),
                  ),
                            child: Text(scale.displayName,style: TextStyle(fontWeight: FontWeight.normal,fontSize: 14),),
                  ),
                        );
                      }).toList(),
                ],

                    icon: Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.black), // Make sure the icon is visible
                    underline: SizedBox(), // Optional: Remove the underline if it's interfering
                    isExpanded: true, // Optional: Expands the dropdown to full width
              ),
            ),
              )

            ),
            SizedBox(height: 20),
            Center(
              child: CustomElevatedButton(
                onPressed: () async {
                  String divisionId = Get.arguments?['divisionId'] ?? '';

                  if (startDateTime != null && endDateTime != null) {
                    DateRangeFilterCount date = DateRangeFilterCount(
                      fromDate: startDateTime!,
                      toDate: endDateTime!,
                      scaleId: selectedScale == 'None' ? '' : selectedScale!, // Handle 'None'
                    );
                    var response = await widget.loginController.RetrieveCampCount(context, date, divisionId);
                    if (response != null) {
                      setState(() {
                        filterByDateCountResponse = response;
                      });
                    } else {
                      Get.snackbar('Failed !!!', 'Failed to retrieve data',
                          snackPosition: SnackPosition.BOTTOM, colorText: Colors.black);
                    }
                  } else {
                    Get.snackbar('No Data Found !!!', 'Please select start and end date',
                        snackPosition: SnackPosition.BOTTOM, colorText: Colors.black);
                  }
                },
                text: 'View',
                backgroundColor: Theme.of(context).primaryColor,
                horizontalPadding: 126,
                icon: Icon(Icons.my_library_books_outlined),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Padding(
                padding:  EdgeInsets.symmetric(vertical: 18.0,horizontal: 30),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9, // Adjust width to match the design
                    padding: const EdgeInsets.all(16.0), // Padding inside the container
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor, // Blue background color to match design
                      borderRadius: BorderRadius.circular(12.0), // Rounded corners
                      boxShadow: [ // Adding shadow to give depth to the container
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Center align the text
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Camp Report Details',
                            style: TextStyle(
                              color: Colors.white, // White text color
                              fontSize: 20.0, // Adjust font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.0), // Space between the title and stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('Total Patients', filterByDateCountResponse?.data?.patCount ?? 0),
                            _buildVerticalDivider(), // Divider between the stats
                            _buildStatCard('Total Camps', filterByDateCountResponse?.data?.campCount ?? 0),

                            // Using a ternary operator to conditionally display the divider and the stat card
                            filterByDateCountResponse?.data?.showPres == true
                                ? Row(
                              children: [
                                _buildVerticalDivider(), // Divider between the stats
                                _buildStatCard('Total Prescriptions', filterByDateCountResponse?.data?.prescriptionCount ?? 0),
                              ],
                            )
                                : Container(), // Empty container if showPres is not true
                          ],
                        )



          ],
        ),

                  ),
                ),

              ),
            ),

            filterByDateCountResponse?.data.showPres==true?Padding(
              padding: const EdgeInsets.fromLTRB(28.0,1.0,29.0,18.0),
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConstants.colorR6, // Blue background color to match design
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                  boxShadow: [ // Adding shadow to give depth to the container
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15.0,6.0,12.0,0.0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                ' Brands Report :',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Quicksand-SemiBold',
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8), // Adds space between the title and the list
                          filterByDateCountResponse != null
                              ? ListView.builder(
                            shrinkWrap: true, // To prevent the ListView from expanding infinitely
                            physics: NeverScrollableScrollPhysics(), // To prevent scrolling inside the ListView
                            itemCount: filterByDateCountResponse!.data.prescriptionTotalCounts.brands.length,
                            itemBuilder: (context, index) {
                              String brandName = filterByDateCountResponse!.data.prescriptionTotalCounts.brands.keys.elementAt(index);
                              int brandCount = filterByDateCountResponse!.data.prescriptionTotalCounts.brands[brandName]!;
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(35.0,0.0,12.0,0.0),
                                child: Text(
                                  '$brandName: $brandCount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Quicksand-SemiBold',
                                    color: Colors.white,
                                  ),
      ),
                              );
        },
                          )
                              : Text(
                            'No data available',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Quicksand-SemiBold',
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16), // Adds space before the total
                          Padding(
                            padding: const EdgeInsets.fromLTRB(35.0,0.0,12.0,5.0),
                            child: Text(
                              'Total: ${filterByDateCountResponse?.data.prescriptionTotalCounts.total ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Quicksand-SemiBold',
                                color: Colors.white,
                                fontSize: 18,
      ),
                            ),
                          ),
                        ],
                      ),
                    )

                  ],
                ),
              ),
            ):Container(),

          ],
        ),
      ),
    );
  }



  List<Scales> decodeScalesFromJson(Map<String, dynamic> screenDetail) {
    try {
      List<dynamic> scalesJson = screenDetail['data']['scales'];
      return scalesJson.map<Scales>((scaleData) {
        return Scales(
          name: scaleData['name'],
          displayName: scaleData['display_name'],
          s3Url: scaleData['s3_url'],
        );
      }).toList();
    } catch (e) {
      print('Error decoding scales: $e');
      return [];
    }
  }
}

class Scales {
  final String name;
  final String displayName;
  final String s3Url;

  Scales({
    required this.name,
    required this.displayName,
    required this.s3Url,
  });

  factory Scales.fromJson(Map<String, dynamic> json) {
    return Scales(
      name: json['name'],
      displayName: json['display_name'],
      s3Url: json['s3_url'],
    );
  }
}

// Helper method to build each stat card
Widget _buildStatCard(String title, int count) {
  return Column(
    children: [
      Text(
        count.toString(),
        style: TextStyle(
          color: Colors.white, // White text color
          fontSize: 30.0, // Larger font size for emphasis
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 4.0), // Space between number and label
      Text(
        title.replaceAll(' ', '\n'), // Replaces spaces with new lines to force wrapping
        style: TextStyle(
          color: Colors.white, // White text color
          fontSize: 14.0, // Adjust font size
          fontWeight: FontWeight.normal
        ),
        textAlign: TextAlign.center, // Center-align the text
        softWrap: true, // Allow text to wrap to the next line
        maxLines: 2, // Limit the number of lines (adjust as needed)
        overflow: TextOverflow.visible, // Show the full content without cutting it off
      ),
    ],
  );
}

// Helper method to build vertical divider
Widget _buildVerticalDivider() {
  return Container(
    height: 80.0, // Height of the divider
    width: 1.0, // Thickness of the divider
    color: Colors.white.withOpacity(0.6), // White color with some transparency
    margin: const EdgeInsets.symmetric(horizontal: 16.0), // Space around the divider
  );
}