import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/profile_services.dart';
import '../services/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  bool _obscurePassword = true;
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  // User data fetched from SharedPreferences
  Map<String, String> userData = {
    'name': '',
    'institution': '',
    'password': '',
    'email': '',
    'studentId': '',
    'profile_image': '',
  };

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');

    if (storedUserId != null) {
      final fetchedUserData = await _profileService.fetchUserProfile(storedUserId);

      if (fetchedUserData.isNotEmpty && mounted) {
        setState(() {
          userData = fetchedUserData;
          final rawImage = userData['profile_image']?.isNotEmpty == true
              ? userData['profile_image']
              : null;
          _profileImagePath =
              rawImage != null ? ApiClient.absoluteUrl(rawImage) : null;
        });
      }
    }
  }


  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/homeScreen',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  void _initializeControllers() {
    _emailController.text = userData['email'] ?? '';
    _institutionController.text = userData['institution'] ?? '';
    _passwordController.text = '';  // Keep password empty for security
  }

  Future<void> _toggleEditMode() async {
  if (_isEditing) {
    final prefs = await SharedPreferences.getInstance();
    final String? storedUserId = prefs.getString('userId');

    if (storedUserId == null || storedUserId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID not found. Please log in again.')),
      );
      return;
    }

    // Capture updated values
    final String updatedPassword = _passwordController.text.trim();
    final String updatedEmail = _emailController.text.trim();
    final String updatedInstitution = _institutionController.text.trim();

    // Call API to update profile
    final success = await _profileService.updateProfile(
      userId: storedUserId,
      password: updatedPassword.isNotEmpty ? updatedPassword : null,
      email: updatedEmail.isNotEmpty ? updatedEmail : null,
      institution: updatedInstitution.isNotEmpty ? updatedInstitution : null,
      profileImage: (_profileImagePath != null && !_profileImagePath!.startsWith('http'))
          ? File(_profileImagePath!)
          : null, // Only upload local images
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      await loadUserData(); // Refresh profile data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  } else {
    _initializeControllers();
  }

  if (!mounted) return;
  setState(() {
    _isEditing = !_isEditing;
  });
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text('Logout'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          logout();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Image Section
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
  child: _profileImagePath != null && _profileImagePath!.isNotEmpty
      ? (_profileImagePath!.startsWith('http')
          ? Image.network(
              _profileImagePath!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,  // Improve rendering quality
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, size: 80, color: Theme.of(context).colorScheme.primary);
              },
            )

          : Image.file(
              File(_profileImagePath!),
              fit: BoxFit.cover,
            ))
      : Icon(
          Icons.person,
          size: 80,
          color: theme.colorScheme.primary,
        ),
),

                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // User Details Section
            ..._buildDetailCards(theme),

            // Edit/Save Profile Button
            Container(
              margin: EdgeInsets.all(20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleEditMode,
                child: Text(
                  _isEditing ? 'Save Profile' : 'Edit Profile',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update _buildDetailCards method to include editable fields
  List<Widget> _buildDetailCards(ThemeData theme) {
  final List<Map<String, dynamic>> details = [
    {
      'icon': Icons.person,
      'title': 'User ID',
      'value': userData['name'] ?? '',
      'readonly': true,  // Explicitly setting default
      'isPassword': false,
    },
    {
      'icon': Icons.lock,
      'title': 'Password',
      'value': userData['password'] ?? '',
      'isPassword': true,
      'controller': _passwordController,
    },
    {
      'icon': Icons.school,
      'title': 'Institution',
      'value': userData['institution'] ?? '',
      'isPassword': false,
      'controller': _institutionController,
    },
    {
      'icon': Icons.email,
      'title': 'Email',
      'value': userData['email'] ?? '',
      'isPassword': false,
      'controller': _emailController,
    },
  ];

  return details.map((detail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              detail['icon'] as IconData,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail['title'] as String,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 5),
                if (_isEditing && !(detail['readonly'] ?? false)) // Ensure `readonly` is never null
                  TextField(
                    controller: detail.containsKey('controller') ? detail['controller'] : null,
                    obscureText: (detail['isPassword'] ?? false) && _obscurePassword, // Ensure `isPassword` is never null
                    decoration: InputDecoration(
                      hintText: 'Enter new ${detail['title']}',
                      suffixIcon: (detail['isPassword'] ?? false)
                          ? IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            )
                          : null,
                    ),
                  )
                else
                  Text(
                    detail['value'] ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }).toList();
}


  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    super.dispose();
  }
}