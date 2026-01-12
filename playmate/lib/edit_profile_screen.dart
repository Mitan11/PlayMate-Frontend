import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color themeColor = const Color(0xFF2E7D32);

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  Uint8List? _selectedImageBytes;
  Uint8List? _profileImageBytes;
  String _currentProfileImage = '';
  bool _isCropping = false;
  bool _isSavingProfile = false;

  String? _firstNameError;
  String? _lastNameError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('first_name') ?? '';
      _lastNameController.text = prefs.getString('last_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _currentProfileImage = prefs.getString('profile_image') ?? '';
    });
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _isCropping = true;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    bool hasError = false;

    if (firstName.isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      hasError = true;
    }
    if (lastName.isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      hasError = true;
    }

    if (hasError) return;

    final base = dotenv.env['BASE_URL'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');

    final uri = Uri.parse('$base/user/updateDetails');

    setState(() => _isSavingProfile = true);
    try {
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['user_email'] = _emailController.text;
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;

      if (_profileImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            _profileImageBytes!,
            filename: 'profile.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final userData = data['data']?['user'];

        if (userData != null) {
          await prefs.setString(
            'first_name',
            userData['first_name'] ?? firstName,
          );
          await prefs.setString('last_name', userData['last_name'] ?? lastName);
          await prefs.setString(
            'profile_image',
            userData['profile_image'] ?? _currentProfileImage,
          );

          // Update user_id if present in response
          if (userData['user_id'] != null) {
            await prefs.setString('user_id', userData['user_id'].toString());
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    setState(() => _isCropping = false);
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Crop(
                    controller: _cropController,
                    image: _selectedImageBytes!,
                    aspectRatio: 1,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: themeColor.withOpacity(0.1),
        title: Text(
          'Edit Profile',
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
        actions: [
          TextButton(
            onPressed: _isSavingProfile ? null : _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: _isSavingProfile ? Colors.grey : themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: GestureDetector(
                  onTap: _isSavingProfile ? null : pickImage,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: themeColor, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : (_currentProfileImage.isNotEmpty
                                        ? NetworkImage(_currentProfileImage)
                                        : null)
                                    as ImageProvider?,
                          child:
                              _profileImageBytes == null &&
                                  _currentProfileImage.isEmpty
                              ? Icon(Icons.person, color: themeColor, size: 60)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Personal Information
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'First Name',
                controller: _firstNameController,
                errorText: _firstNameError,
                enabled: !_isSavingProfile,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Last Name',
                controller: _lastNameController,
                errorText: _lastNameError,
                enabled: !_isSavingProfile,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Email',
                controller: _emailController,
                enabled: false,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
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
          decoration: InputDecoration(
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
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
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
