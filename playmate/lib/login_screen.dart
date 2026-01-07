import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playmate/registration_screen.dart';
import 'package:playmate/home_screen.dart';
import 'package:playmate/forgot_password_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  void _validateAndLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Enter a valid email address');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (hasError) return;

    _login(email, password);
  }

  Future<void> _login(String email, String password) async {
    final base = dotenv.env['BASE_URL'] ?? '';
    final uri = Uri.parse('$base/auth/login');

    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email': email,
          'user_password': password,
        }),
      ).timeout(const Duration(seconds: 20));

      debugPrint('Login response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        String msg = 'Login successful';
        String? token;
        try {
          final data = jsonDecode(resp.body);
          token = data['token'] as String?;
          msg = (data['message'] ?? msg).toString();

          // Save user data
          final userData = data['data'];
          if (userData != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', userData['user_id']?.toString() ?? '');
            await prefs.setString('user_email', userData['user_email'] ?? '');
            await prefs.setString('first_name', userData['first_name'] ?? '');
            await prefs.setString('last_name', userData['last_name'] ?? '');
            await prefs.setString('profile_image', userData['profile_image'] ?? '');
          }
        } catch (_) {}

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        String err = 'Login failed';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? data['error'] ?? err).toString();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = const Color(0xFF2E7D32); // Beautiful Green Shade

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        shadowColor: Colors.green.withOpacity(0.2),
        title: Text(
          'Login',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),

      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "You're almost there 🌱",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ---- EMAIL ---- //
                Text(
                  "Email Address",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: themeColor),
                    hintText: "Enter your email",
                    errorText: _emailError,
                    errorStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: !_isLoading ? Colors.green.shade50 : Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColor.withOpacity(.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null ? Colors.red.shade300 : themeColor.withOpacity(.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null ? Colors.red : themeColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ---- PASSWORD ---- //
                Text(
                  "Password",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: themeColor),
                    suffixIcon: _isLoading ? null : IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    hintText: "Enter your password",
                    errorText: _passwordError,
                    errorStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: !_isLoading ? Colors.green.shade50 : Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColor.withOpacity(.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _passwordError != null ? Colors.red.shade300 : themeColor.withOpacity(.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _passwordError != null ? Colors.red : themeColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot password?",
                      style: GoogleFonts.poppins(
                        color: themeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---- BUTTON ---- //
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // ---- SIGN UP ---- //
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegistrationScreen()),
                        );
                      },
                      child: Text(
                        "Sign up",
                        style: GoogleFonts.poppins(
                          color: themeColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // ---- TERMS ---- //
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: "By continuing, you agree to our "),
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
