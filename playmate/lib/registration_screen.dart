import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final Color themeColor = const Color(0xFF2E7D32);

  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  Uint8List? _selectedImageBytes; // original picked image
  Uint8List? _profileImageBytes; // final cropped image
  bool _isCropping = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _croppedImageFile;

  // Default avatar URL
  final String _defaultAvatarUrl =
      'https://res.cloudinary.com/dsw5tkkyr/image/upload/v1764845539/avatar_wcaknk.png';

  // Validation error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneNumberError;
  String? _passwordError;
  String? _confirmPasswordError;

  // PICK IMAGE AND OPEN CROP UI
  Future<void> pickImage() async {
    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Choose Image Source',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: themeColor),
              ),
              title: Text(
                'Camera',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: themeColor),
              ),
              title: Text(
                'Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
        _isCropping = true;
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
      _phoneNumberError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phoneNumber = phoneNumberController.text.trim();
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
    if (phoneNumber.isEmpty) {
      setState(() => _phoneNumberError = 'Phone number is required');
      hasError = true;
    } else if (phoneNumber.length != 10) {
      setState(
        () => _phoneNumberError = 'Phone number must be exactly 10 digits',
      );
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
      request.fields['phone_number'] = phoneNumber;

      if (_croppedImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _croppedImageFile!.path,
            contentType: MediaType('image', 'jpeg'),
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

          // Try to find token at root or inside data
          token = data['token']?.toString();
          if (token == null && data['data'] != null && data['data'] is Map) {
            token = data['data']['token']?.toString();
          }

          msg = (data['message'] ?? msg).toString();

          // Save user data
          var userData = data['data'];
          Map<String, dynamic>? userMap;

          if (userData is List && userData.isNotEmpty) {
            userMap = userData[0] as Map<String, dynamic>;
          } else if (userData is Map) {
            if (userData.containsKey('user')) {
              userMap = userData['user'];
            } else {
              userMap = userData as Map<String, dynamic>;
            }
          }

          if (userMap != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'user_id',
              userMap['user_id']?.toString() ?? '',
            );
            await prefs.setString('user_email', userMap['user_email'] ?? '');
            await prefs.setString('first_name', userMap['first_name'] ?? '');
            await prefs.setString('last_name', userMap['last_name'] ?? '');
            await prefs.setString(
              'phone_number',
              userMap['phone_number'] ?? '',
            );
            await prefs.setString(
              'profile_image',
              userMap['profile_image'] ?? '',
            );
          }
        } catch (_) {}

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          debugPrint('Auth token saved: $token');
        } else {
          debugPrint('Warning: Auth token not found in registration response');
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

          // Handle validation errors
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map<String, dynamic>;
            setState(() {
              _firstNameError = errors['first_name_error']?.toString();
              _lastNameError = errors['last_name_error']?.toString();
              _emailError = errors['email_error']?.toString();
              _phoneNumberError = errors['phone_number_error']?.toString();
              _passwordError = errors['password_error']?.toString();
              _confirmPasswordError = errors['confirm_password_error']
                  ?.toString();
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
                    onCropped: (croppedBytes) async {
                      final decoded = img.decodeImage(croppedBytes);
                      if (decoded == null) return;

                      final jpgBytes = img.encodeJpg(decoded, quality: 85);

                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/profile.jpg');
                      await file.writeAsBytes(jpgBytes);

                      if (!mounted) return; // 🔥 IMPORTANT

                      setState(() {
                        _croppedImageFile = file;
                        _profileImageBytes = Uint8List.fromList(jpgBytes);
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
                                  border: Border.all(
                                    color: themeColor,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.green.shade100,
                                  backgroundImage: _profileImageBytes != null
                                      ? MemoryImage(_profileImageBytes!)
                                      : NetworkImage(_defaultAvatarUrl)
                                            as ImageProvider,
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
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
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
                        "Create Your Account",
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

                      _label("Phone Number"),
                      _inputField(
                        controller: phoneNumberController,
                        hint: "Enter your phone number",
                        icon: Icons.phone_outlined,
                        prefixText: "+91 ",
                        keyboardType: TextInputType.phone,
                        errorText: _phoneNumberError,
                        enabled: !_isLoading,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
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
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
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
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  );
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
    String? prefixText,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterText: "", // Hide character counter
        prefixIcon: Icon(icon, color: themeColor),
        prefixText: prefixText,
        prefixStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: TextStyle(fontSize: 12, height: 1.3),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade200,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: errorText != null
                ? Colors.red.shade300
                : Colors.green.shade200,
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 18,
        ),
      ),
    );
  }
}
