import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:campuslink/data/config.dart';

// Define the Post class with a fromJson constructor.
class Post {
  final int id;
  final String userId;
  final String content;
  final String? mediaUrl; // Make mediaUrl nullable
  final String createdAt;
  final int likesCount;
  final String username;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrl, // Make mediaUrl nullable
    required this.createdAt,
    required this.likesCount,
    required this.username,
  });

  // Convert a map into a Post object.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url'], // No need to parse, can be null
      createdAt: json['created_at']?.toString() ?? '',
      likesCount: json['likes_count'] is int
          ? json['likes_count']
          : int.tryParse(json['likes_count'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
    );
  }
}

Future<List<Post>> fetchPosts() async {
  final response = await http
      .get(Uri.parse('${Config.baseUrl}/clink/api/community/fetch_post.php'))
      .timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    // Decode the JSON response into a Map.
    Map<String, dynamic> responseBody = json.decode(response.body);

    if (responseBody['status'] == 'success') {
      // Decode the data field into a List of Maps.
      List<dynamic> postsJson = responseBody['data'] ?? [];

      // Convert the List<dynamic> into a List<Post>.
      return postsJson.map((post) => Post.fromJson(post)).toList();
    } else {
      throw Exception("Failed to load posts: ${responseBody['message']}");
    }
  } else {
    throw Exception("Failed to load posts");
  }
}