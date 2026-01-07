import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final Color themeColor = const Color(0xFF2E7D32);

  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  Uint8List? _selectedImageBytes;  // original picked image
  Uint8List? _profileImageBytes; // final cropped image
  bool _isCropping = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Default avatar URL
  final String _defaultAvatarUrl = 'https://res.cloudinary.com/dsw5tkkyr/image/upload/v1764845539/avatar_wcaknk.png';

  // Validation error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // PICK IMAGE AND OPEN CROP UI
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _isCropping = true; // show cropping screen
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _register() async {
    // Clear previous errors
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final cpass = confirmPasswordController.text;

    bool hasError = false;

    // Validate each field
    if (firstName.isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      hasError = true;
    }
    if (lastName.isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      hasError = true;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Enter a valid email address');
      hasError = true;
    }
    if (pass.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (pass.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      hasError = true;
    }
    if (cpass.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      hasError = true;
    } else if (pass != cpass) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    final base = dotenv.env['BASE_URL'] ?? '';
    final uri = Uri.parse('$base/auth/register');

    setState(() => _isLoading = true);
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['user_email'] = email;
      request.fields['user_password'] = pass;
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;

      // Add profile image if selected (this is the correct way for multer)
      if (_profileImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            _profileImageBytes!,
            filename: 'profile.jpg',
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final resp = await http.Response.fromStream(streamedResponse);

      debugPrint('Registration response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        String msg = 'Registration successful';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        String err = 'Registration failed';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? data['error'] ?? err).toString();
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
  Widget build(BuildContext context) {
    // If cropping mode is on, show the cropper screen instead of the form
    if (_isCropping && _selectedImageBytes != null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.white,
                elevation: 2,
                centerTitle: true,
                title: Text(
                  'Adjust Image',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _isCropping = false;
                    });
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Crop(
                    controller: _cropController,
                    image: _selectedImageBytes!,
                    aspectRatio: 1, // square crop
                    onCropped: (croppedBytes) {
                      setState(() {
                        _profileImageBytes = croppedBytes;
                        _isCropping = false;
                      });
                    },
                    baseColor: Colors.black,
                    maskColor: Colors.black26,
                    cornerDotBuilder: (size, edgeAlignment) => Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _cropController.crop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal registration screen UI
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 3,
              centerTitle: true,
              shadowColor: Colors.green.withOpacity(0.2),
              title: Text(
                'Registration',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROFILE IMAGE UPLOAD
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : pickImage,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: themeColor, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.green.shade100,
                                  backgroundImage: _profileImageBytes != null
                                      ? MemoryImage(_profileImageBytes!)
                                      : NetworkImage(_defaultAvatarUrl) as ImageProvider,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        "Create Your Account 🍀",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Let’s get you started",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 35),

                      _label("First Name"),
                      _inputField(
                        controller: firstNameController,
                        hint: "Enter your first name",
                        icon: Icons.person_outline,
                        errorText: _firstNameError,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 20),

                      _label("Last Name"),
                      _inputField(
                        controller: lastNameController,
                        hint: "Enter your last name",
                        icon: Icons.person_outline,
                        errorText: _lastNameError,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 20),

                      _label("Email"),
                      _inputField(
                        controller: emailController,
                        hint: "example@email.com",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 20),

                      _label("Password"),
                      _inputField(
                        controller: passwordController,
                        hint: "Enter password",
                        obscure: _obscurePassword,
                        icon: Icons.lock_outline,
                        errorText: _passwordError,
                        enabled: !_isLoading,
                        suffixIcon: _isLoading ? null : IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      _label("Confirm Password"),
                      _inputField(
                        controller: confirmPasswordController,
                        hint: "Re-enter password",
                        obscure: _obscureConfirmPassword,
                        icon: Icons.lock_outline,
                        errorText: _confirmPasswordError,
                        enabled: !_isLoading,
                        suffixIcon: _isLoading ? null : IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                      ),

                      const SizedBox(height: 35),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register, // changed
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  "Next",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                            children: const [
                              TextSpan(
                                text: "By signing up, you agree to our ",
                              ),
                              TextSpan(
                                text: "Terms of Service",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
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
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscure = false,
    String? errorText,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: themeColor),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade200,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red.shade300 : Colors.green.shade200,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red : themeColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      ),
    );
  }
}
