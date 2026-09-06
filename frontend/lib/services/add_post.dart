// Legacy helper kept for compatibility — community posts are now created
// through ApiClient (see community_post.dart / media_provider.dart).
import 'package:flutter/foundation.dart';

Future<bool> addPost(String userId, String content, {String? mediaUrl}) async {
  debugPrint('addPost() is deprecated — use ApiClient POST /api/posts instead');
  return false;
}
