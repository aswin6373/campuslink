import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuslink/data/config.dart';

/// Shared REST client.
/// - Reads the base URL from Config (.env)
/// - Attaches the JWT stored at login to every request
/// - Unwraps JSON responses and surfaces server error messages
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${Config.baseUrl}$path').replace(
      queryParameters: query,
    );
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) fn,
  ) async {
    final headers = await _headers();
    try {
      final response = await fn(headers).timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty ? '{}' : response.body;
      dynamic decoded;
      try {
        decoded = json.decode(body);
      } catch (_) {
        decoded = body;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      String message = 'Request failed (${response.statusCode})';
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      } else if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded is String && decoded.isNotEmpty) {
        message = decoded;
      }
      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send((h) => http.get(_uri(path, query), headers: h));
  }

  static Future<dynamic> post(String path, {Object? body}) {
    return _send(
      (h) => http.post(_uri(path), headers: h, body: json.encode(body ?? {})),
    );
  }

  static Future<dynamic> put(String path, {Object? body}) {
    return _send(
      (h) => http.put(_uri(path), headers: h, body: json.encode(body ?? {})),
    );
  }

  static Future<dynamic> delete(String path, {Object? body}) {
    return _send(
      (h) => http.delete(_uri(path), headers: h, body: json.encode(body ?? {})),
    );
  }

  /// Resolves a relative media URL (e.g. /api/posts/media/<id>) against the
  /// API base URL so image widgets get an absolute URL.
  static String absoluteUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${Config.baseUrl}$url';
  }
}
