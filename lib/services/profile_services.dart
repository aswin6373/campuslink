import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuslink/data/config.dart';
import 'dart:io';

class ProfileService {

  Future<bool> updateProfile({
    required String userId,
    String? password,
    String? email,
    String? institution,
    File? profileImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/clink/api/update_profile.php'),
      );

      request.fields['user_id'] = userId;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      if (institution != null && institution.isNotEmpty) {
        request.fields['institution'] = institution;
      }
      if (profileImage != null && !profileImage.path.startsWith('http')) {
        request.files.add(await http.MultipartFile.fromPath('profile_image', profileImage.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        if (result['success'] == true) {
          // Update SharedPreferences with new values
          final prefs = await SharedPreferences.getInstance();
          if (email != null && email.isNotEmpty) {
            await prefs.setString('email', email);
          }
          if (institution != null && institution.isNotEmpty) {
            await prefs.setString('institution', institution);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>> fetchUserProfile(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/clink/api/get_profile.php?username=$userId'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final user = result['data']; // Ensure it matches the API response structure

      if (user != null) {
        return {
          'userId': user['user_id']?.toString() ?? '',
          'name': user['user_id']?.toString() ?? '',
          'institution': user['institution']?.toString() ?? '',
          'password': '••••••••',
          'email': user['email']?.toString() ?? '',
          'profile_image': user['profile_image']?.toString() ?? '',
        };
      }
    }
    return {};
  } catch (e) {
    return {};
  }
}
}