import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final Color themeColor = const Color(0xFF2E7D32);
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  bool get _canPost {
    return _textController.text.trim().isNotEmpty || _selectedImage != null;
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (!_canPost || _isPosting) return;

    setState(() => _isPosting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('auth_token');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/user/createPost/$userId');

      final textContent = _textController.text.trim();

      // Create multipart request for file upload
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add form fields
      request.fields['user_id'] = int.tryParse(userId).toString() ?? userId;
      request.fields['text_content'] = textContent.isNotEmpty
          ? textContent
          : '';

      // Add image file if selected
      if (_selectedImage != null) {
        final imageFile = http.MultipartFile.fromBytes(
          'media_url',
          await _selectedImage!.readAsBytes(),
          filename: _selectedImage!.path.split('/').last,
        );
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);
      // Parse API response which uses the format:
      // { status, statusCode, message, data, token, timestamp }
      String respMessage = 'Post created successfully';
      bool success = false;
      try {
        final Map<String, dynamic> respData = jsonDecode(resp.body);
        respMessage = (respData['message'] ?? respMessage).toString();
        success =
            (respData['status'] == true) ||
            (respData['statusCode'] == 201) ||
            (resp.statusCode == 201);
      } catch (_) {
        success = resp.statusCode == 200 || resp.statusCode == 201;
      }

      if (success) {
        // Persist locally as before for fast local reads
        Map<String, dynamic> postData = {
          'timestamp': DateTime.now().toIso8601String(),
        };
        if (textContent.isNotEmpty) postData['caption'] = textContent;
        if (_selectedImage != null) postData['path'] = _selectedImage!.path;

        final currentPosts = prefs.getStringList('user_posts_$userId') ?? [];
        currentPosts.insert(0, jsonEncode(postData));
        await prefs.setStringList('user_posts_$userId', currentPosts);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(respMessage, style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        final err = respMessage.isNotEmpty
            ? respMessage
            : 'Failed to create post';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error creating post: $err',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating post: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
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
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: _canPost && !_isPosting ? _createPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canPost ? themeColor : Colors.grey.shade300,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Post',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main composition area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar and text input (Twitter-like)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 4),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: themeColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: themeColor,
                            size: 20,
                          ),
                        ),
                      ),

                      // Text input area
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _textController,
                              focusNode: _textFocusNode,
                              maxLines: null,
                              minLines: 3,
                              maxLength: 280, // Twitter-like character limit
                              decoration: InputDecoration(
                                hintText: "What's happening in sports today?",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              onChanged: (text) => setState(() {}),
                            ),

                            // Image preview if selected
                            if (_selectedImage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        _selectedImage!,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        height: 200,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _selectedImage = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom toolbar (Twitter-like)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Media picker buttons
                IconButton(
                  onPressed: _isLoading ? null : _pickImageFromGallery,
                  icon: Icon(
                    Icons.image_outlined,
                    color: _isLoading ? Colors.grey : themeColor,
                    size: 24,
                  ),
                  tooltip: 'Add photo',
                ),
                IconButton(
                  onPressed: _isLoading ? null : _pickImageFromCamera,
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: _isLoading ? Colors.grey : themeColor,
                    size: 24,
                  ),
                  tooltip: 'Take photo',
                ),

                const Spacer(),

                // Character counter
                if (_textController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_textController.text.length}/280',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _textController.text.length > 280
                            ? Colors.red
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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
}
