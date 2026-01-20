import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simple data store to persist state during the session
class GameDataStore {
  static final List<Map<String, dynamic>> requests = [
    {
      'name': 'Patel Pranay',
      'initial': 'A',
      'level': 'INTERMEDIATE',
      'color': Colors.blueAccent,
    },
    {
      'name': 'Patel nidhi',
      'initial': 'N',
      'level': 'INTERMEDIATE',
      'color': Colors.blueAccent,
    },
    {
      'name': 'Rahul Sharma',
      'initial': 'R',
      'level': 'BEGINNER',
      'color': Colors.redAccent,
    },
  ];

  static final List<Map<String, dynamic>> players = [
    {
      'name': 'Patel Pranay',
      'initial': 'P',
      'level': 'PRO',
      'color': Colors.green,
    },
    {
      'name': 'John Doe',
      'initial': 'J',
      'level': 'BEGINNER',
      'color': Colors.orange,
    },
  ];
}

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
  void _acceptRequest(int index) {
    setState(() {
      final player = GameDataStore.requests[index];
      GameDataStore.requests.removeAt(index);
      GameDataStore.players.add(player);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Player Accepted')));
  }

  void _rejectRequest(int index) {
    setState(() {
      GameDataStore.requests.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request Rejected')));
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
    if (GameDataStore.requests.isEmpty) {
      return Center(
        child: Text(
          'No Pending Requests',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: GameDataStore.requests.length,
      itemBuilder: (context, index) {
        final request = GameDataStore.requests[index];
        return _buildPlayerCard(request, index, isRequest: true);
      },
    );
  }

  Widget _buildPlayersTab() {
    if (GameDataStore.players.isEmpty) {
      return Center(
        child: Text(
          'No Players Joined',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: GameDataStore.players.length,
      itemBuilder: (context, index) {
        final player = GameDataStore.players[index];
        return _buildPlayerCard(player, index, isRequest: false);
      },
    );
  }

  Widget _buildPlayerCard(
    Map<String, dynamic> data,
    int index, {
    required bool isRequest,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade300,
                child: Text(
                  data['initial'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
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
                      data['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['level'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isRequest) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                _buildActionButton(
                  'Reject',
                  Colors.white,
                  Colors.black87,
                  () => _rejectRequest(index),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  'Accept',
                  Colors.white,
                  Colors.black87,
                  () => _acceptRequest(index),
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
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}
