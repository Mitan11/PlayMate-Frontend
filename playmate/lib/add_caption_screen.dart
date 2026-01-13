import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class AddCaptionScreen extends StatefulWidget {
  final File imageFile;

  const AddCaptionScreen({super.key, required this.imageFile});

  @override
  State<AddCaptionScreen> createState() => _AddCaptionScreenState();
}

class _AddCaptionScreenState extends State<AddCaptionScreen> {
  final Color themeColor = const Color(0xFF2E7D32);
  final TextEditingController _captionController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _sharePost() async {
    setState(() => _isPosting = true);

    // Simulate posting delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isPosting = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post shared successfully! 🎉',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: themeColor,
        ),
      );

      // Navigate back to home (pop twice to go back to home screen)
      Navigator.pop(context);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isPosting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'New Post',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isPosting ? null : _sharePost,
              style: TextButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Share',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Preview
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.45,
              color: Colors.grey[100],
              child: Image.file(widget.imageFile, fit: BoxFit.contain),
            ),

            // Caption Input Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write a caption (optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 6,
                      maxLength: 500,
                      enabled: !_isPosting,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts... (optional)',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tips Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: themeColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add hashtags to reach more players!',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
