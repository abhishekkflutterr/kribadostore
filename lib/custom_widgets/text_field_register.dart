import 'package:flutter/material.dart';
import 'package:kribadostore/constants/ColorConstants.dart';

class CustomTextFieldRegister extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final bool isGender;
  final String? errorText;
  final List<String>? genderOptions;
  final String? selectedGender;
  final void Function(String?)? onGenderChanged;
  final String hintText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final VoidCallback? onClearCacheAndRefresh;
  final List<String>? radioValues;

  const CustomTextFieldRegister({
    Key? key,
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.isGender = false,
    this.errorText,
    this.genderOptions,
    this.selectedGender,
    this.onGenderChanged, required this.hintText, this.prefixIcon, required this.keyboardType,this.onClearCacheAndRefresh, this.radioValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isGender) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Quicksand-SemiBold',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: genderOptions?.map((gender) {
              final bool isSelected = controller.text == gender;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.text = gender;
                    if (onGenderChanged != null) onGenderChanged!(gender);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ColorConstants.lightGrey),
                    ),
                    child: Center(
                      child: Text(
                        gender,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList() ??
                [],
          ),
          // Removed manual error text here
        ],
      );
    } else if (label == 'Age') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: label,
                    filled: true,
                    fillColor: ColorConstants.colorR8,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    errorText: errorText?.isNotEmpty == true ? errorText : null, // Error handling via InputDecoration
                    errorStyle: TextStyle(
                      fontSize: 18, // Increase the error text size here
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: ColorConstants.colorR9),
                onPressed: () {
                  int value = int.tryParse(controller.text) ?? 0;
                  if (value > 0) controller.text = '${value - 1}';
                },
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: ColorConstants.colorR9),
                onPressed: () {
                  int value = int.tryParse(controller.text) ?? 0;
                  controller.text = '${value + 1}';
                },
              ),
            ],
          ),
          // No need for manual error text here
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: ColorConstants.cultured.withOpacity(0.1),
              errorText: errorText?.isNotEmpty == true ? errorText : null, // Error handling via InputDecoration
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              errorStyle: TextStyle(
                fontSize: 12, // Increase the error text size here
                color: Colors.red,
              ),
            ),
          ),
          // No manual error text here either
        ],
      );
    }
  }
}
