import 'package:campuslink/data/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:campuslink/data/config.dart';
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

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('${Config.baseUrl}/clink/api/admin_signup.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _nameController.text,
          'institution': _institutionController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'user_type': widget.userType,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && responseData['success']) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        dataProvider.currentInstitution = responseData['institution'];

        // Persist basic login state before navigating
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', responseData['user_id'] ?? '');
        await prefs.setString('userType', responseData['user_type'] ?? '');
        await prefs.setString('institution', responseData['institution'] ?? '');

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
          arguments: {
            'userType': responseData['user_type'],
            'userId': responseData['user_id'],
          },
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'An error occurred';
        });
      }
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
    
    return Scaffold(
      body: Form(
        key: _formKey,
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
                  'Create Account',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join CampusLink today',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(
                  controller: _nameController,
                  label: 'Username',
                  icon: Icons.person_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _institutionController,
                  label: 'Institution',
                  icon: Icons.business_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your institution';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_formKey.currentState!.validate()) {
                        _registerUser();
                      }
                    },
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
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
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
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
      validator: validator,
    );
  }
}