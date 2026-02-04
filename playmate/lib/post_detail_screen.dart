import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:playmate/post_state.dart';

class PostDetailScreen extends StatefulWidget {
  final File? imageFile;
  final int postIndex;
  final String? caption;
  final String? textContent;
  final int? postId;
  final int? initialLikeCount;
  final bool? initialIsLiked;
  final String? userName;
  final String? profileImage;
  final String? createdAt;

  const PostDetailScreen({
    super.key,
    this.imageFile,
    required this.postIndex,
    this.caption,
    this.textContent,
    this.postId,
    this.initialLikeCount,
    this.initialIsLiked,
    this.userName,
    this.profileImage,
    this.createdAt,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  int _likeCount = 0;
  // ignore: unused_field
  bool _isLoading = true;
  final Color themeColor = const Color(0xFF2E7D32);
  StreamSubscription? _postUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadPostData();
    _setupPostStateSubscription();
  }

  @override
  void dispose() {
    _postUpdateSubscription?.cancel();
    super.dispose();
  }

  void _setupPostStateSubscription() {
    if (widget.postId == null) return;

    _postUpdateSubscription = PostState().onPostUpdate.listen((update) {
      if (!mounted) return;
      if (update.postId == widget.postId) {
        setState(() {
          _likeCount = update.likeCount;
          _isLiked = update.isLiked;
        });
      }
    });
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return 'now';
    try {
      final postTime = DateTime.parse(createdAt);
      final difference = DateTime.now().difference(postTime);
      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return 'now';
    }
  }

  Future<void> _loadPostData() async {
    if (widget.postId == null) {
      // Fallback to local storage if no postId (legacy behavior or local posts)
      final prefs = await SharedPreferences.getInstance();
      final String identifier =
          widget.imageFile?.path ?? widget.textContent ?? '';

      if (mounted) {
        setState(() {
          _isLiked = prefs.getBool('liked_$identifier') ?? false;
          _likeCount =
              prefs.getInt('likes_count_$identifier') ??
              (15 + (identifier.hashCode % 100));
          _isLoading = false;
        });
      }
      return;
    }

    // Initialize with passed data from caller
    if (mounted) {
      setState(() {
        _isLiked = widget.initialIsLiked ?? false;
        _likeCount = widget.initialLikeCount ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (widget.postId == null) {
      // Legacy local toggle
      final prefs = await SharedPreferences.getInstance();
      final String identifier =
          widget.imageFile?.path ?? widget.textContent ?? '';

      setState(() {
        _isLiked = !_isLiked;
        _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      });

      await prefs.setBool('liked_$identifier', _isLiked);
      await prefs.setInt('likes_count_$identifier', _likeCount);
      return;
    }

    final int postId = widget.postId!;
    final bool currentLiked = _isLiked;
    final int currentCount = _likeCount;

    final bool newLiked = !currentLiked;
    final int newCount = currentCount + (newLiked ? 1 : -1);

    // Optimistic update
    setState(() {
      _isLiked = newLiked;
      _likeCount = newCount;
    });

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

      bool updated = false;
      int finalCount = newCount;
      bool finalLiked = newLiked;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'] ?? body;

        // Check for explicit status first
        if (data['is_liked_by_user'] != null ||
            data['liked'] != null ||
            data['is_liked'] != null) {
          finalLiked =
              (data['is_liked_by_user'] ?? data['liked'] ?? data['is_liked']) ==
              true;
          updated = true;

          if (data['likers'] != null && data['likers'] is List) {
            finalCount = (data['likers'] as List).length;
          } else if (data['like_count'] != null) {
            finalCount = data['like_count'];
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
        } else if (data['like_count'] != null) {
          finalCount = data['like_count'];
          updated = true;
        }

        if (updated) {
          setState(() {
            _likeCount = finalCount;
            _isLiked = finalLiked;
          });
          PostState().updatePost(postId, finalCount, finalLiked);
        }
      } else {
        // Revert
        if (mounted) {
          setState(() {
            _isLiked = currentLiked;
            _likeCount = currentCount;
          });
          PostState().updatePost(postId, currentCount, currentLiked);
        }
        debugPrint('Failed to toggle like: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert
      if (mounted) {
        setState(() {
          _isLiked = currentLiked;
          _likeCount = currentCount;
        });
        PostState().updatePost(postId, currentCount, currentLiked);
      }
    }
  }

  Future<void> _deletePost(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      if (widget.postId == null) {
        // Fallback to old shared prefs logic if no postId
        try {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_id');
          if (userId != null) {
            final currentPosts =
                prefs.getStringList('user_posts_$userId') ?? [];
            if (widget.postIndex >= 0 &&
                widget.postIndex < currentPosts.length) {
              currentPosts.removeAt(widget.postIndex);
              await prefs.setStringList('user_posts_$userId', currentPosts);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              }
            }
          }
        } catch (e) {}
        return;
      }

      try {
        final base = dotenv.env['BASE_URL'] ?? '';
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final userId = prefs.getString('user_id');

        if (token == null || userId == null) return;

        final uri = Uri.parse('$base/user/deletePost/${widget.postId}/$userId');
        final resp = await http.delete(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (resp.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete post'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _deletePost(context),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main post content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info (placeholder - in real app would come from user data)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: themeColor.withOpacity(0.1),
                        backgroundImage:
                            widget.profileImage != null &&
                                widget.profileImage!.isNotEmpty
                            ? NetworkImage(widget.profileImage!)
                            : null,
                        child:
                            widget.profileImage == null ||
                                widget.profileImage!.isEmpty
                            ? Icon(Icons.person, color: themeColor, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName ?? 'You',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _getTimeAgo(widget.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Text content
                  if ((widget.caption != null && widget.caption!.isNotEmpty) ||
                      (widget.textContent != null &&
                          widget.textContent!.isNotEmpty)) ...[
                    Text(
                      widget.caption ?? widget.textContent ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Image content
                  if (widget.imageFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.imageFile!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Post stats
                  if (_likeCount > 0)
                    Text(
                      '${_likeCount} likes',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

            // Like action button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isLiked ? 'Liked' : 'Like',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _isLiked ? Colors.red : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_likeCount',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _isLiked ? Colors.red : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
