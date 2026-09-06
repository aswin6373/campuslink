import 'package:campuslink/services/api_client.dart';
import 'package:campuslink/widgets/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:campuslink/app_theme.dart';

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

  bool get _isAdminLogin => widget.userType.toLowerCase() == 'admin';
  bool get _isGuestLogin => widget.userType.toLowerCase() == 'guest';
  bool get _canRegister =>
      _isAdminLogin ||
      widget.userType.toLowerCase() == 'teacher' ||
      widget.userType.toLowerCase() == 'student';

  Color get _roleColor {
    switch (widget.userType.toLowerCase()) {
      case 'admin':
        return AppTheme.adminColor;
      case 'teacher':
        return AppTheme.teacherColor;
      case 'student':
        return AppTheme.studentColor;
      default:
        return AppTheme.guestColor;
    }
  }

  IconData get _roleIcon {
    switch (widget.userType.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'teacher':
        return Icons.person_rounded;
      case 'student':
        return Icons.school_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

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

      if (_institutionController.text.trim().isEmpty) {
        throw 'Please enter your institution';
      }

      if (!_isGuestLogin && _passwordController.text.isEmpty) {
        throw 'Please enter a password';
      }

      final result = await ApiClient.post('/api/auth/login', body: {
        'username': username,
        'institution': _isGuestLogin
            ? _institutionController.text.trim()
            : _institutionController.text.trim(),
        'userType': widget.userType.toLowerCase(),
        if (!_isGuestLogin) 'password': _passwordController.text,
      });

      if (result is Map && result['status'] == 'success') {
        final user = result['user'] as Map<String, dynamic>;
        final userId = user['user_id']?.toString() ?? '';
        final displayUsername = user['username']?.toString() ?? userId;
        final email = user['email']?.toString() ?? '';
        // Normalize the role so navigation and role checks always match
        final userType = MainPage.normalizeRole(widget.userType);
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
        _errorMessage = e is ApiException ? e.message : e.toString();
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(),
                  const SizedBox(height: 20),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _roleColor,
                        Color.lerp(_roleColor, Colors.black, 0.25)!
                      ]),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.softShadow(_roleColor, dark: isDark),
                    ),
                    child:
                        Icon(_roleIcon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 20),

                  Text('${widget.userType} Login',
                      style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    _isGuestLogin
                        ? 'Explore CampusLink without an account'
                        : 'Welcome back to CampusLink',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          (isDark ? Colors.white : Colors.black).withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card with the form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardBox(theme, radius: AppTheme.radiusL),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _institutionController,
                          label: _isGuestLogin
                              ? 'Institution (browse as guest)'
                              : 'Institution',
                          icon: Icons.business_rounded,
                        ),
                        if (!_isGuestLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                  color:
                                      theme.colorScheme.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: theme.colorScheme.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _validateAndLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isGuestLogin
                                  ? AppTheme.guestColor
                                  : AppTheme.brandIndigo,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isGuestLogin
                                        ? 'Continue as Guest'
                                        : 'Login',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_canRegister) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.55),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/${widget.userType.toLowerCase()}Signup',
                              );
                            },
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 21),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 21,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        labelStyle: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.lightBorder,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
