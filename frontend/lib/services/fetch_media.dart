import 'package:campuslink/services/api_client.dart';

/// Media model returned by GET /api/posts (media served via /api/posts/media/:id).
class Media {
  final String id;
  final String fileName;
  final String fileUrl;

  Media({required this.id, required this.fileName, required this.fileUrl});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
    );
  }
}

Future<List<Media>> fetchMedia() async {
  final responseBody = await ApiClient.get('/api/posts');
  final List<dynamic> postsJson = (responseBody['data'] as List<dynamic>?) ?? [];
  return postsJson
      .where((post) => post['media_url'] != null)
      .map((post) => Media(
            id: post['media_url'].toString().split('/').last,
            fileName: post['media_url'].toString().split('/').last,
            fileUrl: ApiClient.absoluteUrl(post['media_url'].toString()),
          ))
      .toList();
}
