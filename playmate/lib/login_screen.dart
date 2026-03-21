import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playmate/registration_screen.dart';
import 'package:playmate/home_screen.dart';
import 'package:playmate/forgot_password_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    // OTP step variables
    final TextEditingController _otp1Controller = TextEditingController();
    final TextEditingController _otp2Controller = TextEditingController();
    final TextEditingController _otp3Controller = TextEditingController();
    final TextEditingController _otp4Controller = TextEditingController();
    final FocusNode _otp1Focus = FocusNode();
    final FocusNode _otp2Focus = FocusNode();
    final FocusNode _otp3Focus = FocusNode();
    final FocusNode _otp4Focus = FocusNode();
    int _currentStep = 0; // 0 = login, 1 = OTP
    String? _otpError;
    String _userEmail = '';
    bool _isOtpExpired = false;
    int _remainingSeconds = 300;
    Timer? _otpTimer;
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
      _otpError = null;
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
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_email': email, 'user_password': password}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Login response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['data'] != null && data['data']['requires_2fa'] == true) {
          // OTP required
          setState(() {
            _currentStep = 1;
            _userEmail = data['data']['user_email'] ?? email;
            _remainingSeconds = data['data']['expires_in_seconds'] ?? 300;
            _isOtpExpired = false;
          });
          _startOtpTimer();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OTP sent to your email.')),
            );
          }
        } else {
          // Login successful (no OTP)
          await _handleLoginSuccess(data);
        }
      } else {
        String err = 'Login failed';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? data['error'] ?? err).toString();
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            setState(() {
              _emailError = errors['email_error']?.toString();
              _passwordError = errors['password_error']?.toString();
            });
            return;
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
      _otp1Controller.dispose();
      _otp2Controller.dispose();
      _otp3Controller.dispose();
      _otp4Controller.dispose();
      _otp1Focus.dispose();
      _otp2Focus.dispose();
      _otp3Focus.dispose();
      _otp4Focus.dispose();
      _otpTimer?.cancel();
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
        child: _currentStep == 0 ? _buildLoginForm(context) : _buildOtpForm(context),
      ),
    );

  }

  Widget _buildLoginForm(BuildContext context) {
    final Color themeColor = const Color(0xFF2E7D32);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ...existing code for login form (copy from previous build)
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
                errorMaxLines: 3,
                errorStyle: TextStyle(fontSize: 12, height: 1.3),
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
                suffixIcon: _isLoading
                    ? null
                    : IconButton(
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
                errorMaxLines: 3,
                errorStyle: TextStyle(fontSize: 12, height: 1.3),
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
                        builder: (context) => const RegistrationScreen(),
                      ),
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
                    const TextSpan(
                      text: "By continuing, you agree to our ",
                    ),
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
    );
  }

  Widget _buildOtpForm(BuildContext context) {
    final Color themeColor = const Color(0xFF2E7D32);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              'Enter OTP',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 4-digit code to $_userEmail',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _otpBox(_otp1Controller, _otp1Focus, nextFocus: _otp2Focus),
                const SizedBox(width: 10),
                _otpBox(_otp2Controller, _otp2Focus, nextFocus: _otp3Focus, prevFocus: _otp1Focus),
                const SizedBox(width: 10),
                _otpBox(_otp3Controller, _otp3Focus, nextFocus: _otp4Focus, prevFocus: _otp2Focus),
                const SizedBox(width: 10),
                _otpBox(_otp4Controller, _otp4Focus, prevFocus: _otp3Focus),
              ],
            ),
            if (_otpError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_otpError!, style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            const SizedBox(height: 18),
            Text(
              _isOtpExpired ? 'OTP expired' : 'Expires in ${_formatTime(_remainingSeconds)}',
              style: GoogleFonts.poppins(fontSize: 13, color: _isOtpExpired ? Colors.red : Colors.grey[700]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyLoginOtp,
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
                    : Text('Verify', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _isOtpExpired || _remainingSeconds <= 0 ? _resendOtp : null,
              child: Text('Resend OTP', style: GoogleFonts.poppins(color: themeColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(TextEditingController controller, FocusNode focus, {FocusNode? nextFocus, FocusNode? prevFocus}) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: controller,
        focusNode: focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.green.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (val) {
          if (val.length == 1 && nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else if (val.isEmpty && prevFocus != null) {
            FocusScope.of(context).requestFocus(prevFocus);
          }
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _remainingSeconds = 300;
      _isOtpExpired = false;
    });
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isOtpExpired = true;
        });
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP has expired. Please request a new one.'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  Future<void> _verifyLoginOtp() async {
    if (_isOtpExpired) {
      setState(() => _otpError = 'OTP has expired. Please request a new one.');
      return;
    }
    setState(() => _otpError = null);
    final otp = _otp1Controller.text + _otp2Controller.text + _otp3Controller.text + _otp4Controller.text;
    if (otp.isEmpty || otp.length < 4) {
      setState(() => _otpError = 'Please enter complete OTP');
      return;
    }
    final base = dotenv.env['BASE_URL'] ?? '';
    final uri = Uri.parse('$base/auth/verify-login-otp');
    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_email': _userEmail, 'otp': otp}),
      ).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        await _handleLoginSuccess(data);
      } else {
        String err = 'OTP verification failed';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? data['error'] ?? err).toString();
        } catch (_) {}
        setState(() => _otpError = err);
      }
    } catch (e) {
      setState(() => _otpError = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    // Re-trigger login to resend OTP
    _otp1Controller.clear();
    _otp2Controller.clear();
    _otp3Controller.clear();
    _otp4Controller.clear();
    await _login(_userEmail, _passwordController.text);
  }

  Future<void> _handleLoginSuccess(dynamic data) async {
    String msg = (data['message'] ?? 'Login successful').toString();
    String? token = data['token'] as String?;
    final userData = data['data'];
    if (userData != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userData['user_id']?.toString() ?? '');
      await prefs.setString('user_email', userData['user_email'] ?? '');
      await prefs.setString('first_name', userData['first_name'] ?? '');
      await prefs.setString('last_name', userData['last_name'] ?? '');
      await prefs.setString('profile_image', userData['profile_image'] ?? '');
    }
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
