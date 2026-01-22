import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailScreen extends StatefulWidget {
  final File? imageFile;
  final int postIndex;
  final String? caption;
  final String? textContent;

  const PostDetailScreen({
    super.key,
    this.imageFile,
    required this.postIndex,
    this.caption,
    this.textContent,
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

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    final prefs = await SharedPreferences.getInstance();
    final String identifier =
        widget.imageFile?.path ?? widget.textContent ?? '';

    setState(() {
      _isLiked = prefs.getBool('liked_$identifier') ?? false;
      _likeCount =
          prefs.getInt('likes_count_$identifier') ??
          (15 + (identifier.hashCode % 100));
      _isLoading = false;
    });
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final String identifier =
        widget.imageFile?.path ?? widget.textContent ?? '';

    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    await prefs.setBool('liked_$identifier', _isLiked);
    await prefs.setInt('likes_count_$identifier', _likeCount);
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
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        if (userId != null) {
          final currentPosts = prefs.getStringList('user_posts_$userId') ?? [];
          if (widget.postIndex >= 0 && widget.postIndex < currentPosts.length) {
            currentPosts.removeAt(widget.postIndex);
            await prefs.setStringList('user_posts_$userId', currentPosts);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Post deleted successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true); // Return true to indicate deletion
            }
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
                        child: Icon(Icons.person, color: themeColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${DateTime.now().difference(DateTime.now().subtract(const Duration(hours: 2))).inHours}h',
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
