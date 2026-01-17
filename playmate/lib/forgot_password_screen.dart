import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/login_screen.dart';
import 'dart:convert';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final Color themeColor = const Color(0xFF2E7D32);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Replace single OTP controller with 4 individual controllers
  final TextEditingController _otp1Controller = TextEditingController();
  final TextEditingController _otp2Controller = TextEditingController();
  final TextEditingController _otp3Controller = TextEditingController();
  final TextEditingController _otp4Controller = TextEditingController();

  final FocusNode _otp1Focus = FocusNode();
  final FocusNode _otp2Focus = FocusNode();
  final FocusNode _otp3Focus = FocusNode();
  final FocusNode _otp4Focus = FocusNode();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Steps: 0 = Email, 1 = OTP, 2 = New Password
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _emailError;
  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  String _userEmail = '';
  String? _receivedOtp;

  // Timer variables
  Timer? _otpTimer;
  int _remainingSeconds = 300; // 5 minutes = 300 seconds
  bool _isOtpExpired = false;

  void _startOtpTimer() {
    _remainingSeconds = 300; // Reset to 5 minutes
    _isOtpExpired = false;
    _otpTimer?.cancel(); // Cancel any existing timer

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
            const SnackBar(
              content: Text('OTP has expired. Please request a new one.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _sendResetEmail() async {
    setState(() => _emailError = null);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }

    final base = dotenv.env['BASE_URL'] ?? '';
    final uri = Uri.parse('$base/auth/reset-password-email');

    setState(() => _isLoading = true);
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_email': email}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Reset email response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        String? otpFromResponse;
        try {
          final data = jsonDecode(resp.body);
          otpFromResponse = data['data']?['resetOtp']?.toString();
          if (otpFromResponse != null) {
            debugPrint('OTP received: $otpFromResponse');
          }
        } catch (_) {}

        setState(() {
          _userEmail = email;
          _receivedOtp = otpFromResponse;
          _currentStep = 1;
        });

        // Start the 5-minute timer
        _startOtpTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                otpFromResponse != null
                    ? 'OTP sent: $otpFromResponse (Valid for 5 minutes)'
                    : 'OTP sent to your email (Valid for 5 minutes)',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        String err = 'Failed to send reset email';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? err).toString();
          
          // Handle validation errors
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            setState(() {
              _emailError = errors['email_error']?.toString();
            });
            return; // Don't show general error if we have field-specific errors
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isOtpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has expired. Please request a new one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _otpError = null);

    // Combine all 4 digits
    final otp =
        _otp1Controller.text +
        _otp2Controller.text +
        _otp3Controller.text +
        _otp4Controller.text;

    if (otp.isEmpty || otp.length < 4) {
      setState(() => _otpError = 'Please enter complete OTP');
      return;
    }

    // Verify OTP locally by comparing with received OTP
    if (_receivedOtp == null) {
      setState(() => _otpError = 'No OTP available. Please request a new one.');
      return;
    }

    if (otp != _receivedOtp) {
      setState(() => _otpError = 'Invalid OTP. Please try again.');
      return;
    }

    // OTP is valid, proceed to password reset step
    _otpTimer?.cancel(); // Cancel timer on successful verification
    setState(() => _currentStep = 2);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified successfully')),
      );
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    bool hasError = false;

    if (newPass.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (newPass.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      hasError = true;
    }

    if (confirmPass.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      hasError = true;
    } else if (newPass != confirmPass) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    final base = dotenv.env['BASE_URL'] ?? '';
    final uri = Uri.parse('$base/auth/reset-password');

    setState(() => _isLoading = true);
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_email': _userEmail,
              'new_password': newPass,
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Reset password response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successfully')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        String err = 'Failed to reset password';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? err).toString();
          
          // Handle validation errors
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            setState(() {
              _passwordError = errors['password_error']?.toString() ?? errors['new_password_error']?.toString();
              _confirmPasswordError = errors['confirm_password_error']?.toString();
            });
            return; // Don't show general error if we have field-specific errors
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _otp1Controller.dispose();
    _otp2Controller.dispose();
    _otp3Controller.dispose();
    _otp4Controller.dispose();
    _otp1Focus.dispose();
    _otp2Focus.dispose();
    _otp3Focus.dispose();
    _otp4Focus.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reset Your Password",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Enter your email to receive a password reset OTP",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 30),
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
            fillColor: !_isLoading
                ? Colors.green.shade50
                : Colors.grey.shade200,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _emailError != null
                    ? Colors.red.shade300
                    : themeColor.withOpacity(.4),
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
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
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
                    'Send OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
  ) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: (!_isLoading && !_isOtpExpired)
            ? Colors.green.shade50
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpError != null
              ? Colors.red.shade300
              : themeColor.withOpacity(.4),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        enabled: !_isLoading && !_isOtpExpired,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.0,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (value) {
          if (value.length == 1 && nextFocus != null) {
            nextFocus.requestFocus();
          }
          if (value.isEmpty && currentFocus == _otp1Focus) {
            // Stay on first field
          }
        },
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter OTP",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a 4-digit OTP to $_userEmail",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),

        // Timer Display
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isOtpExpired ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isOtpExpired ? Colors.red.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isOtpExpired ? Icons.warning_amber : Icons.timer_outlined,
                color: _isOtpExpired ? Colors.red : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isOtpExpired
                    ? 'OTP Expired'
                    : 'OTP expires in ${_formatTime(_remainingSeconds)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _isOtpExpired
                      ? Colors.red.shade700
                      : Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        if (_receivedOtp != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: themeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Test OTP: $_receivedOtp',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: themeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 30),

        // 4 OTP Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOtpBox(_otp1Controller, _otp1Focus, _otp2Focus),
            _buildOtpBox(_otp2Controller, _otp2Focus, _otp3Focus),
            _buildOtpBox(_otp3Controller, _otp3Focus, _otp4Focus),
            _buildOtpBox(_otp4Controller, _otp4Focus, null),
          ],
        ),

        if (_otpError != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              _otpError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],

        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed:
                  (_isLoading || (!_isOtpExpired && _remainingSeconds > 240))
                  ? null
                  : () {
                      _otpTimer?.cancel();
                      setState(() {
                        _currentStep = 0;
                        _otp1Controller.clear();
                        _otp2Controller.clear();
                        _otp3Controller.clear();
                        _otp4Controller.clear();
                        _receivedOtp = null;
                        _isOtpExpired = false;
                        _otpError = null;
                      });
                    },
              icon: const Icon(Icons.refresh),
              label: Text(
                _isOtpExpired ? 'Request New OTP' : 'Resend OTP',
                style: GoogleFonts.poppins(
                  color:
                      (_isLoading ||
                          (!_isOtpExpired && _remainingSeconds > 240))
                      ? Colors.grey
                      : themeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!_isOtpExpired && _remainingSeconds > 240)
          Center(
            child: Text(
              'Available after ${_formatTime(_remainingSeconds - 240)}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: (_isLoading || _isOtpExpired) ? null : _verifyOtp,
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
                    'Verify OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Set New Password",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Enter your new password",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 30),
        Text(
          "New Password",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: themeColor),
            suffixIcon: _isLoading
                ? null
                : IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
            hintText: "Enter new password",
            errorText: _passwordError,
            errorStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: !_isLoading
                ? Colors.green.shade50
                : Colors.grey.shade200,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _passwordError != null
                    ? Colors.red.shade300
                    : themeColor.withOpacity(.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _passwordError != null ? Colors.red : themeColor,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Confirm Password",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: themeColor),
            suffixIcon: _isLoading
                ? null
                : IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
            hintText: "Confirm password",
            errorText: _confirmPasswordError,
            errorStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: !_isLoading
                ? Colors.green.shade50
                : Colors.grey.shade200,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _confirmPasswordError != null
                    ? Colors.red.shade300
                    : themeColor.withOpacity(.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _confirmPasswordError != null ? Colors.red : themeColor,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
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
                    'Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        shadowColor: Colors.green.withOpacity(0.2),
        title: Text(
          'Forgot Password',
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
                if (_currentStep == 0) _buildEmailStep(),
                if (_currentStep == 1) _buildOtpStep(),
                if (_currentStep == 2) _buildPasswordStep(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
