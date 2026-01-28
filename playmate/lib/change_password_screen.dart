import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final Color themeColor = const Color(0xFF2E7D32);

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isChangingPassword = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  Future<void> _changePassword() async {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasError = false;

    if (currentPassword.isEmpty) {
      setState(() => _currentPasswordError = 'Current password is required');
      hasError = true;
    }

    if (newPassword.isEmpty) {
      setState(() => _newPasswordError = 'New password is required');
      hasError = true;
    } else if (newPassword.length < 6) {
      setState(
        () => _newPasswordError = 'Password must be at least 6 characters',
      );
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      hasError = true;
    } else if (newPassword != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    final base = dotenv.env['BASE_URL'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // DEBUG: Print token to verify it exists and is correct
    debugPrint('Change Password - Auth Token: $token');

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final uri = Uri.parse('$base/auth/change-password');

    final email = prefs.getString('user_email') ?? '';

    // Trying 'user_password' as it matches the Login/Register schema
    final bodyMap = {
      'user_email': email,
      'currentPassword': currentPassword, // Matches login flow
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };

    debugPrint('Change Password Req Body: ${jsonEncode(bodyMap)}');

    setState(() => _isChangingPassword = true);

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      debugPrint('Change password response body: ${resp.body}');

      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else if (resp.statusCode == 401) {
        debugPrint('401 Unauthorized - Token might be invalid or expired.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please logout and login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          await prefs.remove('auth_token');
        }
      } else {
        try {
          final errorData = jsonDecode(resp.body);
          final errorMessage =
              errorData['message'] ??
              'Failed to change password: ${resp.statusCode}';

          // Handle validation errors - checking variants
          if (errorData['errors'] != null && errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            setState(() {
              // Check user_password_error as well since we are using that key
              _currentPasswordError =
                  errors['user_password_error']?.toString() ??
                  errors['current_password_error']?.toString() ??
                  errors['currentPasswordError']?.toString();

              _newPasswordError =
                  errors['new_password_error']?.toString() ??
                  errors['newPasswordError']?.toString() ??
                  errors['password_error']?.toString();

              _confirmPasswordError =
                  errors['confirm_password_error']?.toString() ??
                  errors['confirmPasswordError']?.toString();
            });
            // If we found specific errors, don't show the snackbar
            if (_currentPasswordError != null ||
                _newPasswordError != null ||
                _confirmPasswordError != null) {
              return;
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage), // Show server message
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          // If JSON decode fails, show raw body (truncated) to help debugging
          final rawMsg = resp.body.length > 100
              ? resp.body.substring(0, 100)
              : resp.body;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error ${resp.statusCode}: $rawMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? errorText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: !isVisible,
          decoration: InputDecoration(
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[600],
              ),
              onPressed: onToggleVisibility,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red.shade300
                    : Colors.green.shade200,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : themeColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: themeColor.withOpacity(0.1),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your password must be at least 6 characters long',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildPasswordField(
                label: 'Current Password',
                controller: _currentPasswordController,
                isVisible: _isCurrentPasswordVisible,
                onToggleVisibility: () {
                  setState(
                    () =>
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible,
                  );
                },
                errorText: _currentPasswordError,
                enabled: !_isChangingPassword,
              ),

              const SizedBox(height: 20),

              _buildPasswordField(
                label: 'New Password',
                controller: _newPasswordController,
                isVisible: _isNewPasswordVisible,
                onToggleVisibility: () {
                  setState(
                    () => _isNewPasswordVisible = !_isNewPasswordVisible,
                  );
                },
                errorText: _newPasswordError,
                enabled: !_isChangingPassword,
              ),

              const SizedBox(height: 20),

              _buildPasswordField(
                label: 'Confirm New Password',
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                onToggleVisibility: () {
                  setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  );
                },
                errorText: _confirmPasswordError,
                enabled: !_isChangingPassword,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChangingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Change Password',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
