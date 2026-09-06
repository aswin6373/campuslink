import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:campuslink/services/media_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:campuslink/services/upload_media.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuslink/data/config.dart';

class CommunityPost extends StatefulWidget {
  final String username;

  const CommunityPost({super.key, required this.username});

  @override
  _CommunityPostState createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;
  File? _selectedMedia;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isUploadSectionVisible = true;
  double _previousScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<MediaProvider>(context, listen: false).loadPosts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    double currentScroll = _scrollController.position.pixels;
    if (currentScroll > _previousScrollOffset) {
      // Scrolling down
      if (_isUploadSectionVisible) {
        setState(() {
          _isUploadSectionVisible = false;
        });
      }
    } else if (currentScroll < _previousScrollOffset) {
      // Scrolling up
      if (!_isUploadSectionVisible) {
        setState(() {
          _isUploadSectionVisible = true;
        });
      }
    }
    _previousScrollOffset = currentScroll;
  }

  Future<void> _handleAddPost() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userId');
    final content = _postController.text.trim();

    if (!mounted) return;

    if (userName == null || userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found. Please log in again.")),
      );
      return;
    }

    if (content.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add some content or media")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      String? mediaUrl;
      if (_selectedMedia != null) {
        // Upload the media and get the URL
        mediaUrl = await uploadFile(
          _selectedMedia!.path,
          '${Config.baseUrl}/clink/api/community/upload_media.php',
        );

        if (mediaUrl == null) {
          throw Exception("Media upload failed");
        }
      }

      // Send post data including media URL if available
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/clink/api/community/add_post.php'),
        body: {
          'user_id': userName,
          'content': content,
          'media_url': mediaUrl ?? '',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Request timed out");
      });

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post added successfully!")),
        );
        _postController.clear();
        setState(() {
          _selectedMedia = null;
        });
        Provider.of<MediaProvider>(context, listen: false).loadPosts();
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add post: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _pickMedia() async {
    try {
      final XFile? media = await _picker.pickImage(source: ImageSource.gallery);
      if (media != null) {
        setState(() {
          _selectedMedia = File(media.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick media: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaProvider = Provider.of<MediaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text('Community Post', style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file, color: theme.colorScheme.onPrimary),
            onPressed: _isPosting ? null : _handleAddPost,
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: theme.colorScheme.onPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: mediaProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : mediaProvider.postList.isEmpty
                        ? Center(
                            child: Text(
                              'No posts yet.\nBe the first to share something!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: mediaProvider.postList.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              final post = mediaProvider.postList[index];
                              return PostCard(
                                username: post.username,
                                content: post.content,
                                imageUrl: post.mediaUrl,
                                likes: post.likesCount.toString(),
                                theme: theme,
                              );
                            },
                          ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            top: _isUploadSectionVisible ? 16 : -300, // Moves out of view when hidden
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _postController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write something...",
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedMedia != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedMedia!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(() => _selectedMedia = null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.photo_library),
                          onPressed: _pickMedia,
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: Icon(Icons.send),
                          label: Text('Post'),
                          onPressed: _isPosting ? null : _handleAddPost,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String username;
  final String content;
  final String? imageUrl;
  final String likes;
  final ThemeData theme;

  const PostCard({
    super.key,
    required this.username,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
            ),
            title: Text(username, style: theme.textTheme.titleMedium),
            trailing: IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                placeholder: (context, url) {
                  return Container(
                    height: 200,
                    color: theme.colorScheme.surface,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorWidget: (context, url, error) {
                  return Container(
                    height: 200,
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Text("Image not available",
                          style: theme.textTheme.bodyLarge),
                    ),
                  );
                },
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Text(content, style: theme.textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.favorite, color: const Color.fromARGB(255, 235, 16, 0)),
                const SizedBox(width: 8),
                Text(likes, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}