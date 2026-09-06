import 'package:campuslink/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  final String userType;
  const LoginScreen({super.key, required this.userType});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;
  String? _selectedInstitution; // For guest login institution selection

  // List of institutions for the dropdown
  final List<String> institutions = [
    'ebenezer',
    'CCSIT PERAMANGALAM',
    'ccsit',
    // Add more institutions as needed
  ];

  bool get _isAdminLogin => widget.userType.toLowerCase() == 'admin';
  bool get _isGuestLogin => widget.userType.toLowerCase() == 'guest';

  // Function to update FCM token in the database
  Future<void> updateFcmToken(String userId) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      return;
    }

    try {
      await ApiClient.post('/api/auth/fcm-token', body: {
        "username": userId,
        "fcm_token": fcmToken,
      });
    } catch (e) {
      debugPrint("Error updating FCM Token: $e");
    }
  }

  Future<void> _validateAndLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();

      if (username.isEmpty) {
        throw 'Please enter a username';
      }

      if (_isGuestLogin && _selectedInstitution == null) {
        throw 'Please select an institution';
      }

      if (!_isGuestLogin && _institutionController.text.trim().isEmpty) {
        throw 'Please enter your institution';
      }

      if (!_isGuestLogin && _passwordController.text.isEmpty) {
        throw 'Please enter a password';
      }

      final result = await ApiClient.post('/api/auth/login', body: {
        'username': username,
        'institution': _isGuestLogin
            ? _selectedInstitution
            : _institutionController.text.trim(),
        'userType': widget.userType.toLowerCase(),
        if (!_isGuestLogin) 'password': _passwordController.text,
      });

      if (result is Map && result['status'] == 'success') {
        final user = result['user'] as Map<String, dynamic>;
        final userId = user['user_id']?.toString() ?? '';
        final displayUsername = user['username']?.toString() ?? userId;
        final email = user['email']?.toString() ?? '';
        final userType = widget.userType;
        final institution = user['institution']?.toString() ?? '';
        final token = result['token']?.toString() ?? '';

        // Persist session (token + basic profile)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authToken', token);
        await prefs.setString('userId', userId);
        await prefs.setString('username', displayUsername);
        await prefs.setString('userType', userType);
        await prefs.setString('institution', institution);
        if (email.isNotEmpty) await prefs.setString('email', email);

        // Update FCM token after successful login (non-fatal on failure)
        try {
          await updateFcmToken(userId);
        } catch (_) {}

        if (!mounted) return;

        // Navigate to the main screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
          arguments: {
            'userType': userType,
            'userId': userId,
            'institution': institution,
          },
        );
      } else {
        throw 'Login failed';
      }
      
          } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 32),
                Text(
                  '${widget.userType} Login',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back to CampusLink',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_rounded,
                ),
                if (_isGuestLogin) ...[
                  const SizedBox(height: 24),
                  _buildInstitutionDropdown(), // Institution dropdown for guest login
                ],
                if (!_isGuestLogin) ...[
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _institutionController,
                    label: 'Institution',
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                if (_isAdminLogin) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Implement forgot password functionality
                      },
                      child: Text('Forgot Password?'),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndLogin,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            _isGuestLogin ? 'Continue as Guest' : 'Login',
                          ),
                  ),
                ),
                if (_isAdminLogin) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/adminSignup');
                        },
                        child: Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedInstitution,
      hint: Text('Select Institution'),
      onChanged: (String? newValue) {
        setState(() {
          _selectedInstitution = newValue;
        });
      },
      items: institutions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText! ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}