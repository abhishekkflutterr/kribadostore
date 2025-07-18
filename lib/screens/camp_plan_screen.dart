import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/DatabaseHelper.dart';
import 'package:kribadostore/custom_widgets/customappbar.dart';
import 'package:kribadostore/custom_widgets/elevated_button.dart';
import 'package:kribadostore/screens/camp_list_screen.dart';

import '../constants/ColorConstants.dart';
import '../controllers/login_controller.dart';
import '../models/CampPlan.dart';

class CampPlanScreen extends StatefulWidget {
  @override
  State<CampPlanScreen> createState() => _CampPlanScreenState();
}

class _CampPlanScreenState extends State<CampPlanScreen> {
  List<Map<String, dynamic>> doctors = [];
  String selectedDoctorId = "No"; // Initial value as an empty string
  String? selectedPrescriberType; // Added for prescriber_type dropdown
  DateTime selectedDate = DateTime.now();
  String selectedDoctorName = "Select Doctor"; // Default display text

  final LoginController loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    await databaseHelper.initializeDatabase();
    List<Map<String, dynamic>> resources = await databaseHelper.getAllDivisiondetail();

    List<Map<String, dynamic>> allDoctors = [];

    for (var resource in resources) {
      if (resource.containsKey('division_detail') && resource['division_detail'] != null) {
        Map<String, dynamic> divisionDetail = json.decode(resource['division_detail']);
        List<dynamic> doctorsList = divisionDetail['data']['user']['doctors'];
        doctorsList..sort((a, b) => a['name'].compareTo(b['name']));
        allDoctors.addAll(List<Map<String, dynamic>>.from(doctorsList));
      } else {
        print('Division detail not available');
      }
    }

    if (allDoctors.isNotEmpty) {
      setState(() {
        doctors = allDoctors;
        selectedDoctorId = "No"; // Default doctor selection
      });
    } else {
      print('No doctors found.');
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd'); // Format date as 'yyyy-MM-dd'
    final String formattedDate = formatter.format(selectedDate);

    return WillPopScope(
      onWillPop: () async {
        // Handle back button pressDataSingleton().division_id
        // For example, navigate to a specific screen
        Get.off(CampListScreen());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: "Camp Plan",
          showKebabMenu: true,
          showBackButton: true,
          showHome: true,
          destinationScreen: CampListScreen(),
          pageNavigationTime: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Doctor Selection Field with Autocomplete
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0,0,18,1),
                child: Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return  doctors;
                    } else {
                      return doctors.where((doctor) => doctor['name']
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    }
                  },
                  displayStringForOption: (Map<String, dynamic> doctor) => doctor['name'],
                  onSelected: (Map<String, dynamic> selectedDoctor) {
                    setState(() {
                      selectedDoctorName = selectedDoctor['name'];
                      selectedDoctorId = selectedDoctor['id'];
                    });
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      autofocus: false,
                      controller: textEditingController,
                      focusNode: focusNode,
                      onChanged: (String value) {
                        selectedDoctorId = value;
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Select Doctor',
                        hintStyle: TextStyle(color: Colors.black, fontFamily: 'Quicksand', fontWeight: FontWeight.bold, fontSize: 16.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(color: ColorConstants.colorR11),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5.0)),
                            borderSide: BorderSide(color: Colors.black, width: 0.9)),
                        suffixIcon: Icon(
                          Icons.keyboard_arrow_down, // You can change this to the icon you want
                          color: Colors.black, // You can change the color of the icon
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<Map<String, dynamic>> onSelected,
                      Iterable<Map<String, dynamic>> options) {
                    return Material(
                      child: Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option['name']),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 10),


              // New Prescriber Type Dropdown
              Container(
                margin: EdgeInsets.fromLTRB(18, 0, 18, 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0),
                  child: DropdownButton<String>(
                    value: selectedPrescriberType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPrescriberType = newValue;
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Prescriber Type'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Prescriber',
                        child: Text('Prescriber'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Non Prescriber',
                        child: Text('Non Prescriber'),
                      ),
                    ],
                    icon: Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.black),
                    underline: SizedBox(),
                    isExpanded: true,
                  ),
                ),
              ),


              // Date Selector
              TextButton(
                onPressed: _selectDate,
                child: Container(
                  margin: EdgeInsets.fromLTRB(5, 0, 5, 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 15.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '    Select Date: $formattedDate',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 5),

              // Submit Button
              CustomElevatedButton(
                onPressed: () async {
                  if (selectedDoctorId == "No" || selectedDoctorId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a doctor')),
                    );
                    return;
                  }

                  if (selectedPrescriberType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a prescriber type')),
                    );
                    return;
                  }



                  CampPlan campPlanRequest = CampPlan(
                    doctorId: selectedDoctorId,
                    prescriberType: selectedPrescriberType!,
                    planDate: selectedDate,
                  );

                  String divisionId = DataSingleton().division_encoded_Plan ?? '';

                  print('@@@@@@@divisonidcapmplan $divisionId');

                  await loginController.SendCampPlan(context, divisionId, campPlanRequest);


                },
                text: 'Submit',
                horizontalPadding: 132,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
