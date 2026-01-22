import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:playmate/edit_profile_screen.dart';
import 'package:playmate/settings_screen.dart';
import 'package:playmate/post_detail_screen.dart';
import 'package:playmate/create_post_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final Color themeColor = const Color(0xFF2E7D32);
  late TabController _tabController;

  String _firstName = '';
  String _lastName = '';
  String _userEmail = '';
  String _profileImage = '';
  List<Map<String, dynamic>> _userSports = [];
  List<Map<String, dynamic>> _availableSports = [];
  bool _isLoadingProfile = true;
  List<String> _userPosts = [];
  Map<int, bool> _likedPosts = {};
  Map<int, int> _postLikes = {};

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
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadUserSports();
    _loadAvailableSports();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadUserSports() async {
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');

      if (userId == null || token == null) {
        debugPrint('Missing user_id or token for loading user sports');
        return;
      }

      final uri = Uri.parse('$base/sports/getUserSports/$userId');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('User Sports API response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sportsData = data['data'];

        if (sportsData != null && sportsData['sports'] != null) {
          setState(() {
            _userSports = List<Map<String, dynamic>>.from(sportsData['sports']);
          });
          debugPrint('Loaded ${_userSports.length} user sports from API');
        } else {
          debugPrint('No user sports data found in response');
          setState(() {
            _userSports = [];
          });
        }
      } else {
        debugPrint('Failed to load user sports: ${resp.statusCode}');
        setState(() {
          _userSports = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading user sports: $e');
      setState(() {
        _userSports = [];
      });
    }
  }

  Future<void> _loadAvailableSports() async {
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/sports/getAllSports');
      final resp = await http.get(uri);

      debugPrint('Sports API response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sportsData = data['data'];

        if (sportsData != null && sportsData['sports'] != null) {
          setState(() {
            _availableSports = List<Map<String, dynamic>>.from(
              sportsData['sports'].map(
                (sport) => {
                  'sport_id': sport['sport_id'],
                  'sport_name': sport['sport_name'],
                },
              ),
            );
          });
          debugPrint('Loaded ${_availableSports.length} sports from API');
        } else {
          debugPrint('No sports data found in response');
        }
      } else {
        debugPrint('Failed to load sports: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading available sports: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      setState(() {
        _userPosts = prefs.getStringList('user_posts_$userId') ?? [];
      });
    }
  }

  void _addSport(int sportId, String skillLevel) async {
    final alreadyExists = _userSports.any((s) => s['sport_id'] == sportId);
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This sport is already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final uri = Uri.parse('$base/sports/addUserSport/');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': int.parse(userId),
          'sport_id': sportId,
          'skill_level': skillLevel,
        }),
      );

      debugPrint('Add sport API response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sport added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserSports();
      } else {
        final errorData = jsonDecode(resp.body);
        final errorMessage = errorData['message'] ?? 'Failed to add sport';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error adding sport: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteSport(int userSportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final uri = Uri.parse('$base/sports/deleteUserSport/$userSportId');
      final resp = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'Delete sport API response: ${resp.statusCode} - ${resp.body}',
      );

      if (resp.statusCode == 200) {
        setState(() {
          _userSports.removeWhere(
            (sport) => sport['user_sport_id'] == userSportId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sport removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserSports();
      } else {
        final errorData = jsonDecode(resp.body);
        final errorMessage = errorData['message'] ?? 'Failed to remove sport';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error deleting sport: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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
                if (_availableSports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No sports available',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                      .map(
                        (level) => ChoiceChip(
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
                        ),
                      )
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

  Widget _buildModernProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Stats
          Row(
            children: [
              // Avatar
              Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [themeColor, const Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImage.isNotEmpty
                      ? NetworkImage(_profileImage)
                      : null,
                  child: _profileImage.isEmpty
                      ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                      : null,
                ),
              ),

              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('${_userPosts.length}', 'Posts'),
                    _buildStatItem('${_userSports.length}', 'Sports'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Name
          Text(
            '$_firstName $_lastName',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          // Bio / Email (Acting as bio for now)
          if (_userEmail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _userEmail,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEFEF),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEFEF),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Adjusted Stat Item for black text on white background
  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: themeColor,
        unselectedLabelColor: Colors.grey[400],
        indicatorColor: themeColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_rounded), text: 'Posts'),
          Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Sports'),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userPosts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 48,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Posts Yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your sports moments with the community',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        _loadUserPosts();
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      'Create First Post',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Post Count and Add Button (Unchanged logic, just keeping context)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_userPosts.length} Post${_userPosts.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    child: TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePostScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadUserPosts();
                        }
                      },
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: themeColor,
                      ),
                      label: Text(
                        'Add New',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Twitter-style Timeline
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userPosts.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                return _buildTwitterPostItem(index);
              },
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildTwitterPostItem(int index) {
    String postItem = _userPosts[index];
    String? imagePath;
    String? caption;
    String? textContent;
    String timestamp = 'now';

    try {
      if (postItem.trim().startsWith('{')) {
        final Map<String, dynamic> data = jsonDecode(postItem);
        imagePath = data['path'];
        caption = data['caption'];
        textContent = data['caption'];

        // Calculate time ago
        if (data['timestamp'] != null) {
          final postTime = DateTime.parse(data['timestamp']);
          final difference = DateTime.now().difference(postTime);
          if (difference.inDays > 0) {
            timestamp = '${difference.inDays}d';
          } else if (difference.inHours > 0) {
            timestamp = '${difference.inHours}h';
          } else if (difference.inMinutes > 0) {
            timestamp = '${difference.inMinutes}m';
          } else {
            timestamp = 'now';
          }
        }
      } else {
        imagePath = postItem;
      }
    } catch (e) {
      imagePath = postItem;
    }

    final bool hasImage = imagePath != null && imagePath.isNotEmpty;
    final bool hasText = textContent != null && textContent.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              imageFile: hasImage ? File(imagePath!) : null,
              postIndex: index,
              caption: caption,
              textContent: textContent,
            ),
          ),
        );
        if (result == true && mounted) {
          _loadUserPosts();
        }
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: themeColor.withOpacity(0.1),
              backgroundImage: _profileImage.isNotEmpty
                  ? NetworkImage(_profileImage)
                  : null,
              child: _profileImage.isEmpty
                  ? Icon(Icons.person, size: 20, color: themeColor)
                  : null,
            ),
            const SizedBox(width: 12),

            // Post content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        '$_firstName $_lastName',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '·',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_horiz,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: () => _deletePostAtIndex(index),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Text content
                  if (hasText) ...[
                    const SizedBox(height: 4),
                    Text(
                      textContent,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Image content
                  if (hasImage) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Engagement section
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLike(index),
                        child: Row(
                          children: [
                            Icon(
                              _likedPosts[index] == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: _likedPosts[index] == true
                                  ? Colors.red
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_postLikes[index] ?? (index * 3 + 5)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _likedPosts[index] == true
                                    ? Colors.red
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike(int index) {
    setState(() {
      if (_likedPosts[index] == true) {
        _likedPosts[index] = false;
        _postLikes[index] = (_postLikes[index] ?? (index * 3 + 5)) - 1;
      } else {
        _likedPosts[index] = true;
        _postLikes[index] = (_postLikes[index] ?? (index * 3 + 5)) + 1;
      }
    });
  }

  Future<void> _deletePostAtIndex(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this post?',
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
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        if (userId != null) {
          final currentPosts = prefs.getStringList('user_posts_$userId') ?? [];
          if (index >= 0 && index < currentPosts.length) {
            currentPosts.removeAt(index);
            await prefs.setStringList('user_posts_$userId', currentPosts);
            _loadUserPosts();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Post deleted successfully',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Sports',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddSportDialog,
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: themeColor,
                ),
                label: Text(
                  'Add New',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        if (_userSports.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.sports_basketball_outlined,
                  size: 50,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Sports Added Yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add sports to find partners nearby',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _userSports.length,
            itemBuilder: (context, index) {
              final userSport = _userSports[index];
              final sportName = userSport['sport_name'] ?? 'Unknown';
              final skillLevel = userSport['skill_level'] ?? 'Beginner';
              final skillColor = _getSkillLevelColor(skillLevel);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Sport Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _sportIcons[sportName] ?? Icons.sports,
                        color: themeColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sportName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: skillColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skillLevel,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: skillColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete Button
                    InkWell(
                      onTap: () => _deleteSport(userSport['user_sport_id']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _isLoadingProfile
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeColor, themeColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        Icon(
                          Icons.person_outline,
                          color: Colors.white.withOpacity(0.3),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading your profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _loadUserProfile(),
                  _loadUserSports(),
                  _loadAvailableSports(),
                  _loadUserPosts(),
                ]);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              notificationPredicate: (notification) {
                return notification.depth <= 2;
              },
              color: themeColor,
              backgroundColor: Colors.white,
              strokeWidth: 3,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(child: _buildModernProfileHeader()),
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: innerBoxIsScrolled ? 0.5 : 0,
                    floating: true,
                    pinned: true,
                    toolbarHeight: 0,
                    flexibleSpace: Container(color: Colors.white),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(80),
                      child: _buildTabBar(),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildPostsSection(),
                    ),
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildSportsSection(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
