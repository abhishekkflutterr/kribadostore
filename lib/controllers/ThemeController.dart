import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/constants/ColorConstants.dart';

class ThemeController extends GetxController {
  // Define an observable for the theme
  var theme = ThemeData(
    primaryColor: ColorConstants.colorR9,
    primaryTextTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Quicksand',
        color: Colors.blue,
      ),
      bodyMedium: TextStyle(
        fontSize: 5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Quicksand',
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Quicksand',
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Quicksand',
        color: Colors.white,
      ),
    ),
  ).obs;

  // Method to update the primary color
  void updatePrimaryColor(Color newColor) {
    theme.value = ThemeData(
      primaryColor: newColor,
      colorScheme: ColorScheme.fromSeed(seedColor: newColor),
      useMaterial3: true,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: 'Quicksand',
          color: newColor,
        ),
        bodySmall: TextStyle(
          fontSize: 5,
          fontWeight: FontWeight.bold,
          fontFamily: 'Quicksand',
          color: Colors.white,
        ),
        bodyLarge : TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Quicksand',
          color: newColor,
        )
      ),
    );
  }

  // Method to update the primary text theme color
  void updatePrimaryTextColor(Color newColor) {
    theme.value = ThemeData(
      primaryColor: theme.value.primaryColor,
      primaryTextTheme: theme.value.primaryTextTheme.copyWith(
        bodyLarge: theme.value.primaryTextTheme.bodyLarge?.copyWith(
          color: Colors.black,
        ),
        bodyMedium: theme.value.primaryTextTheme.bodyMedium?.copyWith(
          color: Colors.black,
        ),
      ),
      colorScheme: theme.value.colorScheme,
      useMaterial3: true,
      textTheme: theme.value.textTheme.copyWith(
        bodyMedium: theme.value.textTheme.bodyMedium?.copyWith(
          color: newColor,
        ),
      ),
    );
  }
}
