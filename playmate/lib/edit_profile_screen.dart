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
  final bool _isLoading = false;
  bool _isSavingProfile = false;

  List<Map<String, dynamic>> _userSports = [];
  List<Map<String, dynamic>> _availableSports = [];
  bool _isLoadingSports = true;

  String? _firstNameError;
  String? _lastNameError;

  final Map<String, IconData> _sportIcons = {
    'Football': Icons.sports_soccer,
    'Basketball': Icons.sports_basketball,
    'Tennis': Icons.sports_tennis,
    'Cricket': Icons.sports_cricket,
    'Badminton': Icons.sports_baseball,
    'Volleyball': Icons.sports_volleyball,
    'Swimming': Icons.pool,
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'Gym': Icons.fitness_center,
    'Pickleball': Icons.sports_tennis,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserSports();
    _loadAvailableSports();
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

  Future<void> _loadUserSports() async {
    setState(() => _isLoadingSports = true);
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        debugPrint('User ID not found');
        setState(() {
          _userSports = [];
          _isLoadingSports = false;
        });
        return;
      }
      
      final uri = Uri.parse('$base/user/profile/$userId');
      debugPrint('Loading user sports from: $uri');
      
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('User sports response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final userData = data['data']['user'];
        final sportsList = userData['sports'] as List;
        
        setState(() {
          _userSports = sportsList.map((sport) {
            return {
              'user_sport_id': sport['sport_id'], // Use sport_id for deletion
              'sport_id': sport['sport_id'],
              'sport_name': sport['sport_name'],
              'skill_level': sport['skill_level'],
            };
          }).toList();
        });
        
        debugPrint('Loaded ${_userSports.length} sports');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user sports: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoadingSports = false);
    }
  }

  Future<void> _loadAvailableSports() async {
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/sports/getAllSports');
      
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sportsData = data['data'];
        
        if (sportsData != null && sportsData['sports'] != null) {
          final sportsList = sportsData['sports'] as List;
          
          setState(() {
            _availableSports = sportsList.map((sport) {
              return {
                'sport_id': sport['sport_id'],
                'sport_name': sport['sport_name'],
              };
            }).toList();
          });
        } else {
          setState(() => _availableSports = []);
        }
      } else {
        setState(() => _availableSports = []);
      }
    } catch (e) {
      debugPrint('Error loading sports: $e');
      setState(() => _availableSports = []);
    }
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
          await prefs.setString('first_name', userData['first_name'] ?? firstName);
          await prefs.setString('last_name', userData['last_name'] ?? lastName);
          await prefs.setString('profile_image', userData['profile_image'] ?? _currentProfileImage);
          
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _showAddSportDialog() {
    int? selectedSportId;
    String selectedSkillLevel = 'Beginner';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Sport',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Sport',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Show loading or empty state
                if (_availableSports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No sports available. Check console for details.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedSportId,
                        isExpanded: true,
                        hint: Text(
                          'Choose a sport',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: themeColor),
                        items: _availableSports.map((sport) {
                          final sportId = sport['sport_id'] as int;
                          final sportName = sport['sport_name'] as String;
                          return DropdownMenuItem<int>(
                            value: sportId,
                            child: Text(
                              sportName,
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedSportId = value);
                        },
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                Text(
                  'Skill Level',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Beginner', 'Intermediate', 'Pro']
                      .map((level) => ChoiceChip(
                            label: Text(level),
                            selected: selectedSkillLevel == level,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => selectedSkillLevel = level);
                              }
                            },
                            selectedColor: themeColor,
                            labelStyle: GoogleFonts.poppins(
                              color: selectedSkillLevel == level
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: (selectedSportId == null || _availableSports.isEmpty)
                  ? null
                  : () {
                      Navigator.pop(context);
                      _addSport(selectedSportId!, selectedSkillLevel);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSport(int sportId, String skillLevel) async {
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userIdString = prefs.getString('user_id');
      
      // Convert user_id from String to int
      final userId = userIdString != null ? int.tryParse(userIdString) : null;
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final uri = Uri.parse('$base/user/userSport');
      
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'sport_id': sportId,
          'skill_level': skillLevel,
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _loadUserSports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sport added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Try to parse error response
        String errorMessage = 'Failed to add sport';
        try {
          final errorData = jsonDecode(resp.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If not JSON, show status code
          errorMessage = 'Server error (${resp.statusCode})';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding sport: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSport(int userSportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Remove Sport',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove this sport?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final uri = Uri.parse('$base/user/deleteUserSport/$userId/$userSportId');
      debugPrint('Deleting sport from: $uri');
      
      final resp = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Delete response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        await _loadUserSports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sport removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove sport (${resp.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting sport: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getSkillLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.blue;
      case 'intermediate':
        return Colors.orange;
      case 'pro':
        return Colors.purple;
      default:
        return Colors.grey;
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
                                  : null) as ImageProvider?,
                          child: _profileImageBytes == null && _currentProfileImage.isEmpty
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

              // Sports & Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sports & Skills',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddSportDialog,
                    icon: Icon(Icons.add_circle, color: themeColor, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoadingSports)
                const Center(child: CircularProgressIndicator())
              else if (_userSports.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_tennis,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No sports added',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userSports.length,
                  itemBuilder: (context, index) {
                    final userSport = _userSports[index];
                    final sportName = userSport['sport_name'] ?? 'Unknown';
                    final skillLevel = userSport['skill_level'] ?? 'Beginner';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _sportIcons[sportName] ?? Icons.sports,
                            color: themeColor,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          sportName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSkillLevelColor(skillLevel).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skillLevel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getSkillLevelColor(skillLevel),
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            _deleteSport(userSport['user_sport_id']);
                          },
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 80),
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
                color: errorText != null ? Colors.red.shade300 : Colors.green.shade200,
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
