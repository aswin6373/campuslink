/// Persists non-sensitive session fields.
/// NOTE: passwords are never stored locally — auth uses the JWT token.
Future<void> saveUserData(
    String userId, String email, String userType, String institution) async {
  // Session state is written by the login/signup screens (shared_preferences).
  // Kept as a hook for future migration to secure storage.
}
