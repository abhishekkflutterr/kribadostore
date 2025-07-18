import 'package:flutter/material.dart';
import 'package:kribadostore/constants/ColorConstants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? errorText;

  const CustomTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      elevation: 3.0,
      shadowColor: Colors.grey,
      child: TextField(

        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: ColorConstants.cultured,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon,color: ColorConstants.cyanCornflowerBlueColor,) : null,
          errorText: errorText?.isNotEmpty == true ? errorText : null,
          errorStyle: TextStyle(
            fontSize: 16.0,
            fontFamily: 'Quicksand-SemiBold',
            fontWeight: FontWeight.bold,// Set your desired font size for errorText
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(
              color: ColorConstants.lightGrey, // Use primary color for the border
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(
              color: ColorConstants.lightGrey.withOpacity(0.5), // Adjust opacity if needed
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(
              color: ColorConstants.lightGrey,
            ),
          ),
          hintStyle: TextStyle(
            color: ColorConstants.cyanCornflowerBlueColor,
            fontFamily: 'Quicksand-SemiBold',
            fontWeight: FontWeight.bold,// Adjust opacity if needed
          ),

        ),
      ),
    );
  }
}
