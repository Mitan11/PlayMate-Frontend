import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageRequestsScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final bool showAllPlayers;

  const ManageRequestsScreen({
    super.key,
    required this.gameData,
    this.showAllPlayers = false,
  });

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _requests =
      []; // Placeholder for requests if needed later

  @override
  void initState() {
    super.initState();
    if (widget.showAllPlayers) {
      _fetchPlayers();
    } else {
      _fetchRequests();
    }
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';

      final gameId =
          widget.gameData['game_id'] ?? widget.gameData['booking_id'];
      if (gameId == null) {
        throw Exception('Game ID not found');
      }

      final uri = Uri.parse(
        '$base/user/getPlayersByGameId/$gameId?t=${DateTime.now().millisecondsSinceEpoch}',
      );

      // Assuming GET request as per user instruction
      final resp = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == true &&
            data['data'] != null &&
            data['data']['players'] != null) {
          final List<dynamic> playersData = data['data']['players'];
          setState(() {
            _players = playersData
                .map((p) => Map<String, dynamic>.from(p))
                .toList();
          });
        }
      } else {
        debugPrint('Failed to fetch players: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error fetching players: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading players: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';

      final gameId =
          widget.gameData['game_id'] ?? widget.gameData['booking_id'];
      if (gameId == null) throw Exception('Game ID not found');

      final uri = Uri.parse(
        '$base/user/requestedUserList/$gameId?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final resp = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == true &&
            data['data'] != null &&
            data['data']['players'] != null) {
          final List<dynamic> requestsData = data['data']['players'];
          setState(() {
            _requests = requestsData
                .map((p) => Map<String, dynamic>.from(p))
                .toList();
          });
        }
      } else {
        debugPrint('Failed to fetch requests: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading requests: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.showAllPlayers ? 'All Players' : 'Manage Requests',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: widget.showAllPlayers ? _buildPlayersTab() : _buildRequestsTab(),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Text(
          'No Pending Requests',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        // Pass true for isRequest to show Accept/Reject buttons if implemented in card
        return _buildPlayerCard(request, isRequest: true);
      },
    );
  }

  Widget _buildPlayersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_players.isEmpty) {
      return Center(
        child: Text(
          'No Players Joined Yet',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return _buildPlayerCard(player);
      },
    );
  }

  Future<void> _updatePlayerStatus(
    int userId,
    int? gamePlayerId,
    String status,
  ) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';

      final uri = Uri.parse('$base/user/updateGamePlayerStatus');
      final body = jsonEncode({
        'game_player_id':
            gamePlayerId ?? 0, // Assuming 0 if null, or handle error
        'user_id': userId,
        'status': status,
      });

      final resp = await http.patch(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (!mounted) return; // Check if widget is still mounted

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // Robust success check:
        // 1. Check explicit status (bool or string)
        // 2. Check if message implies success
        // 3. Fallback: Assume success on 200 OK unless status is explicitly false
        bool isSuccess =
            data['status'] == true ||
            data['status'] == 'true' ||
            (data['message']?.toString().toLowerCase().contains(
                  'successfully',
                ) ??
                false);

        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    'Request ${status.toLowerCase()} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh list
          await _fetchRequests();
        } else {
          // Only throw if we strictly determine it failed
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Failed to update status: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(int userId, int? gamePlayerId) async {
    await _updatePlayerStatus(userId, gamePlayerId, 'Approved');
  }

  Future<void> _rejectRequest(int userId, int? gamePlayerId) async {
    await _updatePlayerStatus(userId, gamePlayerId, 'Rejected');
  }

  Widget _buildPlayerCard(Map<String, dynamic> data, {bool isRequest = false}) {
    final firstName = data['first_name'] ?? 'Unknown';
    final lastName = data['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final profileImage = data['profile_image'];
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    // Status removed from UI
    // final status = data['request_status'] ?? 'Unknown';
    final allSkills = data['all_skills']?.toString() ?? 'Player';

    // Safely parse IDs
    final userId = int.tryParse(data['user_id']?.toString() ?? '');
    final gamePlayerId = int.tryParse(data['game_player_id']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade100,
                  image:
                      (profileImage != null &&
                          profileImage.toString().isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(profileImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child:
                    (profileImage != null && profileImage.toString().isNotEmpty)
                    ? null
                    : Text(
                        initial,
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (allSkills.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        allSkills,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isRequest) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Reject',
                    Colors.red.shade50,
                    Colors.red,
                    () {
                      if (userId != null) {
                        _rejectRequest(userId, gamePlayerId);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Accept',
                    Colors.green,
                    Colors.white,
                    () {
                      if (userId != null) {
                        _acceptRequest(userId, gamePlayerId);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
