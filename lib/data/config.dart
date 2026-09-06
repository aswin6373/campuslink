import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central app configuration.
///
/// Values are loaded from the `.env` file so they can be changed per
/// environment (dev / staging / production) without touching the code.
/// Falls back to safe defaults when dotenv is unavailable (e.g. tests).
class Config {
  static String _get(String key, String fallback) {
    try {
      final value = dotenv.maybeGet(key);
      return (value == null || value.isEmpty) ? fallback : value;
    } catch (_) {
      return fallback;
    }
  }

  /// Base URL of the CampusLink PHP backend (no trailing slash).
  /// Android emulator: use http://10.0.2.2 to reach the host machine.
  static String get baseUrl => _get('API_BASE_URL', 'http://10.0.2.2');

  /// Base URL of the fingerprint (NodeMCU) device server.
  static String get nodeUrl => _get('NODE_URL', 'http://192.168.1.77');
}
