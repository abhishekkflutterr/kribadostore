import 'package:shared_preferences/shared_preferences.dart';

class SharedprefHelper {
  SharedprefHelper._();

  static Future<bool> saveUserData(String key, String value) async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      return await sharedPreferences.setString(key, value);
    } catch (e) {
      print('Error saving data: $e');
      return false;
    }
  }

  static Future<String?> getUserData(String key) async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      return sharedPreferences.getString(key);
    } catch (e) {
      // Handle errors here if needed
      print('Error retrieving data: $e');
      return null;
    }
  }

  // Delete data
  static Future<bool> deleteUserData(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(key);
  }
}
