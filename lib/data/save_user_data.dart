import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserData(String userId, String email, String password, String userType, String institution) async {
  // Example using SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
  await prefs.setString('email', email);
  await prefs.setString('password', password);
  await prefs.setString('userType', userType);
  await prefs.setString('institution', institution);
}