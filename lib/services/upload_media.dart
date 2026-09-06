import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:convert';

Future<String?> uploadFile(String filePath, String uploadUrl) async {
  try {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    var file = File(filePath);
    var fileStream = http.ByteStream(file.openRead());
    var fileLength = await file.length();

    var multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: basename(filePath),
    );

    request.files.add(multipartFile);

    var response = await request.send().timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);
      if (jsonResponse['success'] == true) {
        return jsonResponse['file_url'];
      } else {
        debugPrint("Upload failed: ${jsonResponse['message']}");
        return null;
      }
    } else {
      debugPrint("Error: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("Exception caught: $e");
    return null;
  }
}
