import 'dart:convert';
import 'dart:io';
import 'package:campuslink/services/api_client.dart';

class ProfileService {
  /// Fetches the logged-in user's profile from the backend.
  Future<Map<String, String>> fetchUserProfile(String userId) async {
    try {
      final result = await ApiClient.get('/api/profile');
      final user = result['data'];
      if (user is Map) {
        return {
          'userId': user['user_id']?.toString() ?? '',
          'name': user['user_id']?.toString() ?? '',
          'institution': user['institution']?.toString() ?? '',
          'password': '••••••••',
          'email': user['email']?.toString() ?? '',
          'profile_image': user['profile_image']?.toString() ?? '',
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Updates profile fields. [profileImage] is a local file to upload.
  Future<bool> updateProfile({
    required String userId,
    String? password,
    String? email,
    String? institution,
    File? profileImage,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (institution != null && institution.isNotEmpty) {
        body['institution'] = institution;
      }
      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();
        body['avatar_base64'] = base64Encode(bytes);
        body['avatar_name'] = profileImage.path.split('/').last;
        body['avatar_type'] = 'image/jpeg';
      }

      final result = await ApiClient.post('/api/profile', body: body);
      return result is Map && result['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
