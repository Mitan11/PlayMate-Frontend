import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:playmate/login_screen.dart';
import 'package:playmate/edit_profile_screen.dart';
import 'package:playmate/change_password_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color themeColor = const Color(0xFF2E7D32);

  String _firstName = '';
  String _lastName = '';
  String _userEmail = '';
  String _profileImage = '';
  String _userId = '';
  List<Map<String, dynamic>> _userSports = [];
  bool _isLoadingProfile = true;

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
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingProfile = true);
    
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      print('Loading profile for user_id: $userId');
      if (userId == null || token == null) {
        debugPrint('Missing user_id or token');
        setState(() => _isLoadingProfile = false);
        return;
      }
      
      final uri = Uri.parse('$base/user/profile/$userId');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Profile response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final userData = data['data']['user'];
        
        // Update SharedPreferences with latest data
        await prefs.setString('first_name', userData['first_name'] ?? '');
        await prefs.setString('last_name', userData['last_name'] ?? '');
        await prefs.setString('user_email', userData['user_email'] ?? '');
        await prefs.setString('profile_image', userData['profile_image'] ?? '');
        await prefs.setString('user_id', userData['user_id'].toString());
        
        setState(() {
          _firstName = userData['first_name'] ?? '';
          _lastName = userData['last_name'] ?? '';
          _userEmail = userData['user_email'] ?? '';
          _profileImage = userData['profile_image'] ?? '';
          _userId = userData['user_id'].toString();
          _userSports = List<Map<String, dynamic>>.from(userData['sports'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Profile Picture
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: _profileImage.isNotEmpty 
                ? NetworkImage(_profileImage) 
                : null,
              child: _profileImage.isEmpty 
                ? Icon(Icons.person, color: themeColor, size: 60)
                : null,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            '$_firstName $_lastName',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            _userEmail,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Edit Profile Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    _loadUserProfile();
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSportsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_tennis, color: themeColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'My Sports',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_userSports.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sports added yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userSports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sport = _userSports[index];
                final sportName = sport['sport_name'] ?? 'Unknown';
                final skillLevel = sport['skill_level'] ?? 'Beginner';
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getSkillLevelColor(skillLevel).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _sportIcons[sportName] ?? Icons.sports,
                          color: themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sportName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Skill Level',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSkillLevelColor(skillLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skillLevel,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getSkillLevelColor(skillLevel),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? themeColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? themeColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      body: _isLoadingProfile
          ? Center(
              child: CircularProgressIndicator(color: themeColor),
            )
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: themeColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    
                    // Sports Section
                    _buildSportsSection(),
                    
                    const SizedBox(height: 8),
                    
                    // Settings Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {
                        // Navigate to notifications settings
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      subtitle: 'Update your location',
                      onTap: () {
                        // Navigate to location settings
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Support Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Support',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help and support',
                      onTap: () {
                        // Navigate to help
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App version 1.0.0',
                      onTap: () {
                        // Show about dialog
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        // Navigate to privacy policy
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Logout Button
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      iconColor: Colors.red,
                      onTap: _logout,
                    ),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
