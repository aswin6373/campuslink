import 'package:campuslink/data/data_provider.dart';
import 'package:campuslink/screens/authentication/pending_approval_screen.dart';
import 'package:campuslink/services/api_client.dart';
import 'package:campuslink/widgets/main_page.dart';
import 'package:campuslink/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  final String userType;
  const SignupScreen({super.key, required this.userType});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  Color get _roleColor {
    switch (widget.userType.toLowerCase()) {
      case 'admin':
        return AppTheme.adminColor;
      case 'teacher':
        return AppTheme.teacherColor;
      default:
        return AppTheme.studentColor;
    }
  }

  IconData get _roleIcon {
    switch (widget.userType.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'teacher':
        return Icons.person_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responseData = await ApiClient.post('/api/auth/signup', body: {
        'user_id': _nameController.text,
        'institution': _institutionController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'user_type': widget.userType.toLowerCase(),
      });

      if (!mounted) return;

      if (responseData is Map && responseData['success'] == true) {
        // Accounts created through public signup need admin approval
        // before they can log in (first admin of a college is instant).
        if (responseData['pending'] == true || responseData['token'] == null) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PendingApprovalScreen(
              userType: MainPage.normalizeRole(widget.userType),
              institution:
                  responseData['institution']?.toString() ?? widget.userType,
              email: responseData['email']?.toString(),
            ),
          ));
          return;
        }

        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        dataProvider.currentInstitution = responseData['institution'];

        // Persist basic login state before navigating
        final prefs = await SharedPreferences.getInstance();
        final normalizedType = MainPage.normalizeRole(widget.userType);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authToken', responseData['token']?.toString() ?? '');
        await prefs.setString('userId', responseData['user_id']?.toString() ?? '');
        await prefs.setString('username', responseData['username']?.toString() ?? '');
        await prefs.setString('userType', normalizedType);
        await prefs.setString('institution', responseData['institution']?.toString() ?? '');
        final signupEmail = responseData['email']?.toString() ?? '';
        if (signupEmail.isNotEmpty) await prefs.setString('email', signupEmail);

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
          arguments: {
            'userType': normalizedType,
            'userId': responseData['user_id'],
          },
        );
      } else {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error occurred: $e';
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
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isApprovalNeeded = widget.userType.toLowerCase() != 'admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackButton(),
                    const SizedBox(height: 20),

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
                      child: Icon(_roleIcon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 20),

                    Text('Create Account',
                        style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Join CampusLink as a ${widget.userType}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            (isDark ? Colors.white : Colors.black).withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (isApprovalNeeded)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                              color:
                                  AppTheme.warningColor.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                color: AppTheme.warningColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your account will need approval from your institution admin before you can log in.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration:
                          AppTheme.cardBox(theme, radius: AppTheme.radiusL),
                      child: Column(
                        children: [
                          _field(
                            controller: _nameController,
                            label: 'Username',
                            icon: Icons.person_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _institutionController,
                            label: 'Institution',
                            icon: Icons.business_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your institution'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email';
                              }
                              if (!RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                  .hasMatch(value)) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.error.withOpacity(0.08),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusM),
                                border: Border.all(
                                    color: theme.colorScheme.error
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: theme.colorScheme.error,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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
                                  _isLoading ? null : _registerUser,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 21),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText!
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 21,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
      validator: validator,
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
