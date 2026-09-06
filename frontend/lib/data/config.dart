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

  /// Base URL of the CampusLink backend (no trailing slash).
  /// Local backend:  http://10.0.2.2:3000 (Android emulator)
  /// Render:         https://campuslink-api.onrender.com
  static String get baseUrl => _get('API_BASE_URL', 'http://10.0.2.2:3000');

  /// Kept for backward compatibility — the NodeMCU now talks to the backend
  /// directly, so the app never needs the device URL anymore.
  static String get nodeUrl => _get('NODE_URL', '');
}
