import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void showErrorSnackbar({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.transparent,
      // Adjust the margin to add top spacing manually
        snackPosition: SnackPosition.BOTTOM
      // snackPosition: SnackPosition.BOTTOM, // You can remove or keep this line based on your preference
    );
  }



// You can add more methods for different types of Snackbars if needed
}



