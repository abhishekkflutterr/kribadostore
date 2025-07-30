import 'package:flutter/material.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart';
import 'package:get/get.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/controllers/login_controller.dart';

import '../custom_widgets/text_field.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  LoginController loginController = Get.find<LoginController>();

  String selectedCompany = "";
  String selectedCompanyId = "";
  String selectedDivision = "";
  String selectedDivisionId = "";

  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController emp_codeController = TextEditingController();
  TextEditingController mobile_numberController = TextEditingController();
  TextEditingController designationController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController hqController = TextEditingController();
  TextEditingController regionController = TextEditingController();
  TextEditingController zoneController = TextEditingController();
  TextEditingController managerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loginController.getCompanies(); // Fetch company list initially
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(35,0,35,0),
        child: Obx(() {
          if (loginController.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          List<String> companyNames = loginController.companies.map((company) => company['name'].toString()).toList();
          Map<String, String> companyIdToNameMap = {
            for (var company in loginController.companies) company['id'].toString(): company['name'].toString()
          };

          List<String> divisionNames = loginController.divisionDetails.map((division) => division['name'].toString()).toList();
          Map<String, String> divisionIdToNameMap = {
            for (var division in loginController.divisionDetails) division['id'].toString(): division['name'].toString()
          };

          return Form(
            key: _formKey,
            child: ListView(
              children: [
                // **Company Dropdown**
                Text("Select Company", style: TextStyle(color: Colors.black)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ColorConstants.hB1, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: SearchableDropdown.single(
                            items: companyNames.map((String company) {
                              return DropdownMenuItem<String>(
                                value: company,
                                child: Text(company, style: TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            closeButton: "Close",
                            onClear: () {
                              setState(() {
                                selectedCompany = "";
                                selectedCompanyId = "";
                                selectedDivision = "";
                                selectedDivisionId = "";
                                loginController.divisionDetails.clear();
                              });
                            },
                            value: selectedCompany.isEmpty ? null : selectedCompany,
                            hint: "Select Company",
                            style: TextStyle(fontSize: 12, color: Colors.black),
                            searchHint: Text('Search Company', style: TextStyle(color: Colors.black)),
                            onChanged: (String? value) {
                              setState(() {
                                selectedCompany = value ?? '';
                                selectedCompanyId = companyIdToNameMap.keys.firstWhere(
                                      (key) => companyIdToNameMap[key] == selectedCompany,
                                  orElse: () => '',
                                );
                                selectedDivision = "";
                                selectedDivisionId = "";
                                loginController.divisionDetails.clear();
                              });

                              if (selectedCompanyId.isNotEmpty) {
                                loginController.divisionDetailsApi(selectedCompanyId);
                              }
                            },
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // **Division Dropdown**
                if (selectedCompanyId.isNotEmpty && loginController.divisionDetails.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text("Select Division", style: TextStyle(color: Colors.black)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ColorConstants.hB1, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: SearchableDropdown.single(
                              items: divisionNames.map((String division) {
                                return DropdownMenuItem<String>(
                                  value: division,
                                  child: Text(division, style: TextStyle(color: Colors.black)),
                                );
                              }).toList(),
                              closeButton: "Close",
                              onClear: () {
                                setState(() {
                                  selectedDivision = "";
                                  selectedDivisionId = "";
                                });
                              },
                              value: selectedDivision.isEmpty ? null : selectedDivision,
                              hint: "Select Division",
                              style: TextStyle(fontSize: 12, color: Colors.black),
                              searchHint: Text('Search Division', style: TextStyle(color: Colors.black)),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedDivision = value ?? '';
                                  selectedDivisionId = divisionIdToNameMap.keys.firstWhere(
                                        (key) => divisionIdToNameMap[key] == selectedDivision,
                                    orElse: () => '',
                                  );
                                });

                                print('Selected Division: $selectedDivision (ID: $selectedDivisionId)');
                              },
                              isExpanded: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                CustomTextField(controller: nameController, hintText: 'Name',),
                SizedBox(height: 16),
                CustomTextField(controller: usernameController, hintText: 'Username'),
                SizedBox(height: 16),
                CustomTextField(controller: emailController, hintText: 'Email'),
                SizedBox(height: 16),
                CustomTextField(controller: emp_codeController, hintText: 'Employee code'),
                SizedBox(height: 16),
                CustomTextField(controller: mobile_numberController, hintText: 'Mobile no.'),
                SizedBox(height: 16),
                CustomTextField(controller: designationController, hintText: 'Designation'),
                SizedBox(height: 16),
                CustomTextField(controller: areaController, hintText: 'Area'),
                SizedBox(height: 16),
                CustomTextField(controller: hqController, hintText: 'Headquarter'),
                SizedBox(height: 16),
                CustomTextField(controller: regionController, hintText: 'Region'),
                SizedBox(height: 16),
                CustomTextField(controller: zoneController, hintText: 'Zone'),
                SizedBox(height: 16),
                CustomTextField(controller: managerController, hintText: 'Manager'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0,5,0,5),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (selectedCompanyId.isEmpty) {
                          Get.snackbar("Error", "Please select a company");
                          return;
                        }
                        if (selectedDivisionId.isEmpty) {
                          Get.snackbar("Error", "Please select a division");
                          return;
                        }

                        // Collecting all the required information
                        Map<String, dynamic> requestData = {
                          "name": nameController.text.trim(),
                          "username": usernameController.text.trim(),
                          "email": emailController.text.trim(),
                          "emp_code": emp_codeController.text.trim(),
                          "mobile_number": mobile_numberController.text.trim(),
                          "designation": designationController.text.trim(),
                          "area": areaController.text.trim(),
                          "hq": hqController.text.trim(),
                          "region": regionController.text.trim(),
                          "zone": zoneController.text.trim(),
                          "manager": managerController.text.trim(),
                          "company_id": selectedCompanyId,
                          "division_id": selectedDivisionId,
                        };

                        print('Form Data: $requestData');

                        // Call the API
                        loginController.registerUser(requestData,selectedDivisionId);
                      }
                    },
                    child: Text('Register'),
                  ),
                ),

              ],
            ),
          );
        }),
      ),
    );
  }
}
