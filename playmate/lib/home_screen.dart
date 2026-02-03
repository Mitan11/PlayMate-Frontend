import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:playmate/login_screen.dart';
import 'package:playmate/profile_screen.dart';
import 'package:playmate/create_post_screen.dart';
import 'package:playmate/play_screen.dart';
import 'package:playmate/booking_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:developer';

import 'package:playmate/post_state.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color themeColor = const Color(0xFF2E7D32);
  late int _selectedIndex;

  String _userName = 'User';
  String _profileImage = '';

  String _welcomePrefix = '';
  bool _showWelcome = false;
  Timer? _welcomeTimer;

  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingActivities = true;

  StreamSubscription? _postUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData();
    _loadRecentActivities();

    _postUpdateSubscription = PostState().onPostUpdate.listen((update) {
      if (!mounted) return;

      final index = _recentActivities.indexWhere(
        (a) => a['post_id'] == update.postId,
      );
      if (index != -1) {
        setState(() {
          _recentActivities[index]['likes_count'] = update.likeCount;
          _recentActivities[index]['is_liked_by_user'] = update.isLiked;
        });
      }
    });
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _postUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData({bool isRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    if (!isRefresh) {
      setState(() {
        _welcomePrefix = 'Welcome';
        _showWelcome = true;
      });

      _welcomeTimer?.cancel();
      _welcomeTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWelcome = false;
          });
        }
      });
    }

    setState(() {
      _userName =
          '${prefs.getString('first_name') ?? 'User'} ${prefs.getString('last_name') ?? ''}';
      _profileImage = prefs.getString('profile_image') ?? '';
    });
  }

  Future<void> _loadRecentActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');

      if (userId == null || token == null) {
        setState(() => _isLoadingActivities = false);
        return;
      }

      final uri = Uri.parse(
        '$base/user/recentActivities/$userId?page=1&limit=10',
      );
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('Recent activities response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // data structure: { data: { posts: [...] } }
        if (data['data'] != null && data['data']['posts'] != null) {
          setState(() {
            _recentActivities = List<Map<String, dynamic>>.from(
              data['data']['posts'],
            );
          });
        } else if (data['data'] is List) {
          // Fallback if it returns a direct list
          setState(() {
            _recentActivities = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          setState(() => _recentActivities = []);
        }
      } else {
        debugPrint('Failed to load activities: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading recent activities: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingActivities = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: themeColor.withOpacity(0.1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlayMate',
              style: GoogleFonts.poppins(
                color: themeColor,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            AnimatedCrossFade(
              firstChild: Text(
                '$_welcomePrefix, $_userName',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              secondChild: const SizedBox(height: 0, width: 0),
              crossFadeState: _showWelcome
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: themeColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
              if (result == true) {
                _loadRecentActivities();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: themeColor),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = 3);
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green.shade100,
                backgroundImage: _profileImage.isNotEmpty
                    ? NetworkImage(_profileImage)
                    : null,
                child: _profileImage.isEmpty
                    ? Icon(Icons.person, color: themeColor, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          switch (_selectedIndex) {
            case 0:
              return _buildHomeTab();
            case 1:
              return PlayScreen(
                initialFilter: widget.initialIndex == 1
                    ? 'Created'
                    : 'All Games',
              );
            case 2:
              return const VenueSelectionScreen();
            case 3:
              return const ProfileScreen();
            default:
              return _buildPlaceholder();
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: themeColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_tennis_outlined),
              activeIcon: Icon(Icons.sports_tennis),
              label: 'Play',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadUserData(isRefresh: true),
          _loadRecentActivities(),
        ]);
      },
      color: themeColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Posts Section
            const SizedBox(height: 5),

            if (_isLoadingActivities)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: themeColor),
                ),
              )
            else if (_recentActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.feed_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activities',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  return _buildActivityItem(index);
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activity = _recentActivities[index];

    // Parse data safely
    String firstName = '';
    String lastName = '';

    if (activity['user'] != null) {
      firstName = activity['user']['first_name'] ?? '';
      lastName = activity['user']['last_name'] ?? '';
    } else {
      // Try top level
      firstName = activity['first_name'] ?? '';
      lastName = activity['last_name'] ?? '';
    }

    String name = '$firstName $lastName'.trim();
    if (name.isEmpty) {
      name = 'PlayMate User';
    }

    final String profileUrl =
        activity['user']?['profile_image'] ?? activity['profile_image'] ?? '';
    final String text = activity['text_content'] ?? activity['caption'] ?? '';
    final String? mediaUrl = activity['media_url'];

    final int likes = activity['likes_count'] ?? activity['like_count'] ?? 0;
    final bool isLiked = activity['is_liked_by_user'] == true;

    String timeAgo = 'Just now';
    if (activity['created_at'] != null) {
      try {
        final date = DateTime.parse(activity['created_at']);
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0)
          timeAgo = '${diff.inDays}d ago';
        else if (diff.inHours > 0)
          timeAgo = '${diff.inHours}h ago';
        else if (diff.inMinutes > 0)
          timeAgo = '${diff.inMinutes}m ago';
      } catch (e) {
        // ignore
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: themeColor.withOpacity(0.1),
            backgroundImage: profileUrl.isNotEmpty
                ? NetworkImage(profileUrl)
                : null,
            child: profileUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      color: themeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
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
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      mediaUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _togglePostLike(index),
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? Colors.red : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isLiked ? Colors.red : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePostLike(int index) async {
    final activity = _recentActivities[index];
    final postId = activity['post_id'];

    if (postId == null) return;

    // Optimistic UI update
    setState(() {
      final bool isLiked = activity['is_liked_by_user'] == true;
      activity['is_liked_by_user'] = !isLiked;
      // Handle both keys
      int current = activity['likes_count'] ?? activity['like_count'] ?? 0;
      activity['likes_count'] = current + (isLiked ? -1 : 1);
    });

    final int newCount = activity['likes_count'];
    final bool newLiked = activity['is_liked_by_user'];

    // Notify others
    PostState().updatePost(postId, newCount, newLiked);

    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) return;

      final uri = Uri.parse('$base/user/toggle/$postId/$userId');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'] ?? body;

        int finalCount = newCount;
        bool finalLiked = newLiked;
        bool updated = false;

        if (data['like_count'] != null) {
          finalCount = data['like_count'];
          updated = true;
        }

        // Check for explicit status first
        if (data['is_liked_by_user'] != null || data['liked'] != null) {
          finalLiked = (data['is_liked_by_user'] ?? data['liked']) == true;
          updated = true;

          // If likers list is also there, update count from it
          if (data['likers'] != null && data['likers'] is List) {
            finalCount = (data['likers'] as List).length;
          }
        } else if (data['likers'] != null && data['likers'] is List) {
          final likers = List<dynamic>.from(data['likers']);
          // Override count with likers length
          finalCount = likers.length;
          updated = true;

          final String uidStr = userId.toString();
          finalLiked = likers.any((l) {
            if (l is Map) {
              return l['user_id']?.toString() == uidStr ||
                  l['id']?.toString() == uidStr;
            }
            return l.toString() == uidStr;
          });
        }

        if (updated) {
          setState(() {
            activity['likes_count'] = finalCount;
            activity['is_liked_by_user'] = finalLiked;
          });
          PostState().updatePost(postId, finalCount, finalLiked);
        }
      } else {
        // Revert if failed
        setState(() {
          final bool isLiked = activity['is_liked_by_user'] == true;
          activity['is_liked_by_user'] = !isLiked;
          activity['likes_count'] =
              (activity['likes_count'] ?? 0) + (!isLiked ? 1 : -1);
        });

        final int revertedCount = activity['likes_count'];
        final bool revertedLiked = activity['is_liked_by_user'];
        PostState().updatePost(postId, revertedCount, revertedLiked);

        debugPrint('Failed to toggle like: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert if error
      if (mounted) {
        setState(() {
          final bool isLiked = activity['is_liked_by_user'] == true;
          activity['is_liked_by_user'] = !isLiked; // Revert back
          activity['likes_count'] =
              (activity['likes_count'] ?? 0) + (isLiked ? -1 : 1);
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
