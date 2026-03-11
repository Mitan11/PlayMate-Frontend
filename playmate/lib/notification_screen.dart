import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Color themeColor = const Color(0xFF2E7D32);
  bool _isLoading = true;
  bool _isMarkingSeen = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    // Best-effort fallback in case user leaves screen via system back/gesture.
    _markVisibleNotificationsAsSeen();
    super.dispose();
  }

  Future<void> _markVisibleNotificationsAsSeen() async {
    if (_isMarkingSeen) {
      return;
    }

    _isMarkingSeen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';

      if (token == null || token.isEmpty || base.isEmpty) {
        return;
      }

      final postLikeIds = <Map<String, int>>[];
      final joinRequestIds = <int>[];
      final currentUserId = int.tryParse(prefs.getString('user_id') ?? '');

      for (final notification in _notifications) {
        final status =
            int.tryParse(notification['notification_status']?.toString() ?? '') ??
            0;
        if (status != 0) {
          continue;
        }

        final type = (notification['type'] ?? '').toString().toLowerCase();
        final notificationId = _readInt(notification, 'id');

        final postId =
            _readInt(notification, 'post_id') ??
            _readInt(notification, 'post_like_id') ??
            (type == 'post_like' ? notificationId : null);
        final sourceUserId =
            _readInt(notification, 'user_id') ??
            _readInt(notification, 'from_user_id') ??
            _readInt(notification, 'sender_user_id') ??
            currentUserId;

        if ((type == 'post_like' || postId != null) &&
            postId != null &&
            postId > 0 &&
            sourceUserId != null &&
            sourceUserId > 0) {
          postLikeIds.add({'post_id': postId, 'user_id': sourceUserId});
        }

        final gamePlayerId =
            _readInt(notification, 'game_player_id') ??
            ((type == 'game' || type == 'join_request' || type == 'joinrequest')
                ? notificationId
                : null);
        if ((type == 'game' ||
                type == 'join_request' ||
                type == 'joinrequest' ||
                gamePlayerId != null) &&
            gamePlayerId != null &&
            gamePlayerId > 0) {
          joinRequestIds.add(gamePlayerId);
        }
      }

      await _patchWithFallback(
        base: base,
        token: token,
        primaryPath: '/notifications/postLike/markAsSeen',
        fallbackPath: '/user/notifications/postLike/markAsSeen',
        body: {'post_like_ids': postLikeIds},
      );

      await _patchWithFallback(
        base: base,
        token: token,
        primaryPath: '/notifications/joinrequest/markAsSeen',
        fallbackPath: '/user/notifications/joinrequest/markAsSeen',
        body: {'game_player_ids': joinRequestIds.toList()},
      );

      debugPrint(
        'markAsSeen sent. post_like_ids=$postLikeIds game_player_ids=$joinRequestIds',
      );
    } catch (e) {
      debugPrint('Error marking notifications as seen: $e');
    } finally {
      _isMarkingSeen = false;
    }
  }

  int? _readInt(Map<String, dynamic> source, String key) {
    final direct = int.tryParse(source[key]?.toString() ?? '');
    if (direct != null) {
      return direct;
    }

    final nestedData = source['data'];
    if (nestedData is Map<String, dynamic>) {
      return int.tryParse(nestedData[key]?.toString() ?? '');
    }
    return null;
  }

  Future<void> _patchWithFallback({
    required String base,
    required String token,
    required String primaryPath,
    required String fallbackPath,
    required Map<String, dynamic> body,
  }) async {
    Future<http.Response> send(String path) {
      return http.patch(
        Uri.parse('$base$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    }

    var response = await send(primaryPath);
    if (response.statusCode == 404 || response.statusCode == 405) {
      response = await send(fallbackPath);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'markAsSeen failed (${response.statusCode}) for $body: ${response.body}',
      );
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      if (token == null || userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final uri = Uri.parse('$base/user/notifications/all');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List<Map<String, dynamic>> items = [];
        if (data['data'] != null && data['data']['notifications'] != null) {
          items = List<Map<String, dynamic>>.from(
            data['data']['notifications'],
          );
        }
        setState(() {
          _notifications = items;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _markVisibleNotificationsAsSeen();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: themeColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await _markVisibleNotificationsAsSeen();
            if (!mounted) {
              return;
            }
            navigator.pop();
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : _notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final String name =
                    '${n['first_name'] ?? ''} ${n['last_name'] ?? ''}'.trim();
                final String profileUrl = n['profile_image'] ?? '';
                final String type = n['type'] ?? '';
                final String timeAgo = _getTimeAgo(n['created_at']);
                final int status = n['notification_status'] ?? 0;
                final bool isUnread = status == 0;
                final String message = _getNotificationMessage(n);
                IconData typeIcon;
                Color iconColor;
                switch (type) {
                  case 'game':
                    typeIcon = Icons.sports_soccer;
                    iconColor = Colors.blue;
                    break;
                  case 'post_like':
                    typeIcon = Icons.favorite;
                    iconColor = Colors.red;
                    break;
                  default:
                    typeIcon = Icons.notifications;
                    iconColor = themeColor;
                }
                return InkWell(
                  onTap: () async {
                    // Handle navigation logic
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.green.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                            backgroundColor: themeColor.withValues(alpha: 0.1),
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
                                  Icon(typeIcon, color: iconColor, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeAgo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Icon(Icons.circle, color: Colors.green, size: 12),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  String _getNotificationMessage(Map<String, dynamic> n) {
    final type = n['type'] ?? '';
    final name = '${n['first_name'] ?? ''} ${n['last_name'] ?? ''}'.trim();
    switch (type) {
      case 'game':
        return '$name requested to join your game.';
      case 'post_like':
        return '$name liked your post.';
      default:
        return 'You have a new notification.';
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}
