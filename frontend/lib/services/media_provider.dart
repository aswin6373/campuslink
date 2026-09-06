import 'package:flutter/material.dart';
import 'package:campuslink/services/fetch_posts.dart';

class MediaProvider with ChangeNotifier {
  List<Post> _postList = [];
  bool _isLoading = false;

  List<Post> get postList => _postList;
  bool get isLoading => _isLoading;

  Future<void> loadPosts() async {
    // Defer so listeners are never notified synchronously during build
    // (loadPosts is often called from initState).
    await Future<void>.delayed(Duration.zero);

    _isLoading = true;
    notifyListeners();

    try {
      _postList = await fetchPosts();
    } catch (e) {
      debugPrint("Failed to fetch posts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
