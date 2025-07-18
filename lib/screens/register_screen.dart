import 'package:flutter/material.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart';
import 'package:get/get.dart';
import 'package:kribadostore/constants/ColorConstants.dart';
import 'package:kribadostore/controllers/login_controller.dart';
import 'package:kribadostore/custom_widgets/text_field_register.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  LoginController loginController = Get.find<LoginController>();

  String selectedCompany = "";
  String selectedCompanyId = "";
  String selectedDivision = "";
  String selectedDivisionId = "";

  String? companyErrorText;
  String? divisionErrorText;

  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController empCodeController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController designationController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController hqController = TextEditingController();
  TextEditingController regionController = TextEditingController();
  TextEditingController zoneController = TextEditingController();
  TextEditingController managerController = TextEditingController();

  // Error messages for fields
  String? nameError;
  String? usernameError;
  String? emailError;
  String? empCodeError;
  String? mobileError;
  String? designationError;
  String? areaError;
  String? hqError;
  String? regionError;
  String? zoneError;
  String? managerError;

  @override
  void initState() {
    super.initState();
    loginController.getCompanies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Sign up'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
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

          return ListView(
            children: [
              Text("Select Company", style: TextStyle(color: Colors.black)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: ColorConstants.hB1, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              companyErrorText = null;
                              divisionErrorText = null;
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
                              companyErrorText = null;
                              divisionErrorText = null;
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
              if (companyErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 5, bottom: 10),
                  child: Text(companyErrorText!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              if (selectedCompanyId.isNotEmpty && loginController.divisionDetails.isNotEmpty) ...[
                SizedBox(height: 16),
                Text("Select Division", style: TextStyle(color: Colors.black)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ColorConstants.hB1, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                divisionErrorText = null;
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
                                divisionErrorText = null;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (divisionErrorText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 10),
                    child: Text(divisionErrorText!, style: TextStyle(color: Colors.red, fontSize: 15)),
                  ),
              ],

              SizedBox(height: 16),
              CustomTextFieldRegister(controller: nameController, hintText: 'Name', label: 'Name', errorText: nameError,keyboardType: TextInputType.text,),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: usernameController, hintText: 'Username', label: 'Username', errorText: usernameError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: emailController, hintText: 'Email', label: 'Email', errorText: emailError,keyboardType: TextInputType.emailAddress),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: empCodeController, hintText: 'Employee Code', label: 'Employee Code', errorText: empCodeError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: mobileController, hintText: 'Mobile No.', label: 'Mobile No.', errorText: mobileError,keyboardType: TextInputType.number),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: designationController, hintText: 'Designation', label: 'Designation', errorText: designationError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: areaController, hintText: 'Area', label: 'Area', errorText: areaError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: hqController, hintText: 'Headquarter', label: 'Headquarter', errorText: hqError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: regionController, hintText: 'Region', label: 'Region', errorText: regionError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: zoneController, hintText: 'Zone', label: 'Zone', errorText: zoneError,keyboardType: TextInputType.text),
              SizedBox(height: 16),
              CustomTextFieldRegister(controller: managerController, hintText: 'Manager', label: 'Manager', errorText: managerError,keyboardType: TextInputType.text),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    // Manual validation
                    setState(() {
                      companyErrorText = selectedCompanyId.isEmpty ? 'Please select a company' : null;
                      divisionErrorText = selectedDivisionId.isEmpty ? 'Please select a division' : null;
                      nameError = nameController.text.trim().isEmpty ? 'Name is required' : null;
                      usernameError = usernameController.text.trim().isEmpty ? 'Username is required' : null;
                      // Email validation using RegExp
                      String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                      bool isEmailValid = RegExp(emailPattern).hasMatch(emailController.text.trim());

                      emailError = emailController.text.trim().isEmpty
                          ? 'Email is required'
                          : (!isEmailValid ? 'Enter a valid email address' : null);

// Mobile number validation: must be 10 digits
                      String mobileText = mobileController.text.trim();
                      bool isMobileValid = RegExp(r'^\d{10}$').hasMatch(mobileText);

                      mobileError = mobileText.isEmpty
                          ? 'Mobile number is required'
                          : (!isMobileValid ? 'Mobile number must be 10 digits' : null);

                      empCodeError = empCodeController.text.trim().isEmpty ? 'Employee Code is required' : null;
                      // mobileError = mobileController.text.trim().isEmpty ? 'Mobile number is required' : null;
                      designationError = designationController.text.trim().isEmpty ? 'Designation is required' : null;
                      areaError = areaController.text.trim().isEmpty ? 'Area is required' : null;
                      hqError = hqController.text.trim().isEmpty ? 'Headquarter is required' : null;
                      regionError = regionController.text.trim().isEmpty ? 'Region is required' : null;
                      zoneError = zoneController.text.trim().isEmpty ? 'Zone is required' : null;
                      managerError = managerController.text.trim().isEmpty ? 'Manager is required' : null;
                    });

                    if ([
                      companyErrorText,
                      divisionErrorText,
                      nameError,
                      usernameError,
                      emailError,
                      empCodeError,
                      mobileError,
                      designationError,
                      areaError,
                      hqError,
                      regionError,
                      zoneError,
                      managerError
                    ].any((error) => error != null)) {
                      return;
                    }

                    Map<String, dynamic> requestData = {
                      "name": nameController.text.trim(),
                      "username": usernameController.text.trim(),
                      "email": emailController.text.trim(),
                      "emp_code": empCodeController.text.trim(),
                      "mobile_number": mobileController.text.trim(),
                      "designation": designationController.text.trim(),
                      "area": areaController.text.trim(),
                      "hq": hqController.text.trim(),
                      "region": regionController.text.trim(),
                      "zone": zoneController.text.trim(),
                      "manager": managerController.text.trim(),
                      "company_id": selectedCompanyId,
                      "division_id": selectedDivisionId,
                    };

                    loginController.registerUser(requestData, selectedDivisionId);
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
