import 'package:campuslink/services/api_client.dart';

// Post model with a fromJson constructor.
class Post {
  final int id;
  final String userId;
  final String content;
  final String? mediaUrl;
  final String createdAt;
  final int likesCount;
  final String username;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    required this.likesCount,
    required this.username,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url'],
      createdAt: json['created_at']?.toString() ?? '',
      likesCount: json['likes_count'] is int
          ? json['likes_count']
          : int.tryParse(json['likes_count'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
    );
  }
}

Future<List<Post>> fetchPosts() async {
  final responseBody = await ApiClient.get('/api/posts');
  final List<dynamic> postsJson = (responseBody['data'] as List<dynamic>?) ?? [];
  return postsJson.map((post) => Post.fromJson(post)).toList();
}
