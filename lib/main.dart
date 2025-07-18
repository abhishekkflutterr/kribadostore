import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kribadostore/screens/splash_screen.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'controllers/ThemeController.dart';
import 'controllers/login_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the ThemeController
    final ThemeController themeController = Get.put(ThemeController());

    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return Obx(() {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kribado',
            theme: themeController.theme.value, // Use the theme from the controller
            home: SplashScreen(),
            initialBinding: BindingsBuilder(() {
              Get.put(LoginController());
            }),
          );
        });
      },
    );
  }
}
