import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/booking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:playmate/manage_game_screen.dart';

class PlayScreen extends StatefulWidget {
  final String initialFilter;
  const PlayScreen({super.key, this.initialFilter = 'All Games'});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final Color themeColor = const Color(0xFF2E7D32);
  late String _selectedFilter; // Options: All Games, Joined, Created
  List<Map<String, dynamic>>? _sportsFilters;
  String _selectedSportFilter = 'All';
  // ignore: unused_field
  bool _isLoadingSports = false;
  bool _isLoadingGames = false;
  bool _isLoadingJoinedGames = false;
  bool _isLoadingCreatedGames = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _fetchAllSports();
    _fetchAllGames();
    _loadCreatedGames(); // Load saved games
  }

  Future<void> _loadCreatedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? createdGamesString = prefs.getString('created_games');
    if (createdGamesString != null) {
      try {
        final List<dynamic> loadedGames = jsonDecode(createdGamesString);
        setState(() {
          // Merge loaded games with existing API data
          _createdPlayItems ??= [];
          final existingIds = _createdPlayItems!
              .map((item) => item['booking_id'])
              .where((id) => id != null)
              .toSet();

          for (var game in loadedGames) {
            final gameMap = Map<String, dynamic>.from(game);
            // Only add if not already present
            if (!existingIds.contains(gameMap['booking_id'])) {
              _createdPlayItems!.add(gameMap);
            }
          }
        });
      } catch (e) {
        debugPrint('Error loading created games: $e');
      }
    }
  }

  Future<void> _fetchAllSports() async {
    setState(() => _isLoadingSports = true);
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/sports/getAllSports');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sportsData = data['data'];

        if (sportsData != null && sportsData['sports'] != null) {
          setState(() {
            _sportsFilters = List<Map<String, dynamic>>.from(
              sportsData['sports'].map(
                (sport) => {
                  'sport_name': sport['sport_name'],
                  'sport_id': sport['sport_id'],
                },
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sports: $e');
    } finally {
      setState(() => _isLoadingSports = false);
    }
  }

  Future<void> _fetchAllGames() async {
    setState(() => _isLoadingGames = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/user/allGames');
      final resp = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final rows =
            (data is Map<String, dynamic> ? data['data'] : data)
                as List<dynamic>?;
        if (rows != null) {
          setState(() {
            _allPlayItems = rows.map((row) {
              final Map<String, dynamic> item = Map<String, dynamic>.from(
                row as Map,
              );
              final sportName = item['sport_name']?.toString() ?? 'Unknown';
              final venueName = item['venue_name']?.toString();
              final address = item['address']?.toString();
              final joinedCount =
                  item['total_joined_player']?.toString() ?? '0';
              final firstName = item['first_name']?.toString() ?? '';
              final lastName = item['last_name']?.toString() ?? '';
              final profileImage = item['profile_image']?.toString();

              return {
                'sport': sportName,
                'image': '',
                'title': '$sportName Game',
                'location': venueName ?? address ?? 'Unknown',
                'distance': 'N/A',
                'players': joinedCount,
                'level': 'All Levels',
                'isJoined': false,
                'isCreated': false,
                'user_name': '$firstName $lastName'.trim(),
                'user_image': profileImage,
                'created_at': item['created_at']?.toString(),
                'game_id': item['game_id'],
                'status': item['status'],
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading games: $e');
    } finally {
      setState(() => _isLoadingGames = false);
    }
  }

  Future<void> _fetchJoinedGames() async {
    setState(() => _isLoadingJoinedGames = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/user/joinedGames');
      final resp = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final rows =
            (data is Map<String, dynamic> ? data['data'] : data)
                as List<dynamic>?;
        if (rows != null) {
          setState(() {
            _joinedPlayItems = rows.map((row) {
              final Map<String, dynamic> item = Map<String, dynamic>.from(
                row as Map,
              );
              final sportName = item['sport_name']?.toString() ?? 'Unknown';
              final venueName = item['venue_name']?.toString();
              final venueLocation = item['venue_location']?.toString();
              final joinedCount = item['total_players']?.toString() ?? '0';
              final firstName = item['first_name']?.toString() ?? '';
              final lastName = item['last_name']?.toString() ?? '';
              final profileImage = item['profile_image']?.toString();

              return {
                'sport': sportName,
                'image': '',
                'title': '$sportName Game',
                'location': venueName ?? venueLocation ?? 'Unknown',
                'distance': 'N/A',
                'players': joinedCount,
                'level': 'All Levels',
                'isJoined': true,
                'isCreated': false,
                'user_name': '$firstName $lastName'.trim(),
                'user_image': profileImage,
                'created_at': item['created_at']?.toString(),
              };
            }).toList();
          });
        } else {
          debugPrint('Joined games: data is null or not a list');
        }
      } else {
        debugPrint(
          'Joined games request failed: ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Error loading joined games: $e');
    } finally {
      setState(() => _isLoadingJoinedGames = false);
    }
  }

  Future<void> _fetchCreatedGames() async {
    setState(() => _isLoadingCreatedGames = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/user/usersCreatedGames');
      final resp = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final rows =
            (data is Map<String, dynamic> ? data['data'] : data)
                as List<dynamic>?;
        if (rows != null) {
          setState(() {
            _createdPlayItems = rows.map((row) {
              final Map<String, dynamic> item = Map<String, dynamic>.from(
                row as Map,
              );
              final sportName = item['sport_name']?.toString() ?? 'Unknown';
              final venueName = item['venue_name']?.toString();
              final address = item['address']?.toString();
              final joinedCount =
                  item['total_joined_player']?.toString() ?? '0';
              final apiFirstName = item['first_name']?.toString() ?? '';
              final apiLastName = item['last_name']?.toString() ?? '';
              final apiImage = item['profile_image']?.toString() ?? '';
              final apiCreatedAt = item['created_at']?.toString();

              final prefsFirstName = prefs.getString('first_name');
              final prefsLastName = prefs.getString('last_name');
              final prefsImage = prefs.getString('profile_image');

              final firstName = apiFirstName.isNotEmpty
                  ? apiFirstName
                  : (prefsFirstName != null && prefsFirstName.isNotEmpty
                        ? prefsFirstName
                        : 'You');

              final lastName = apiLastName.isNotEmpty
                  ? apiLastName
                  : (prefsLastName ?? '');

              final profileImage = apiImage.isNotEmpty
                  ? apiImage
                  : (prefsImage ?? '');

              // Fallback to now if created_at is missing, to ensure "Just now" shows
              // for newly created games if API doesn't return it immediately.
              final createdAt =
                  apiCreatedAt ?? DateTime.now().toIso8601String();

              return {
                'sport': sportName,
                'image': '',
                'title': '$sportName Game',
                'location': venueName ?? address ?? 'Unknown',
                'distance': 'N/A',
                'players': joinedCount,
                'level': 'All Levels',
                'isJoined': false,
                'isCreated': true,
                'user_name': '$firstName $lastName'.trim(),
                'user_image': profileImage,
                'created_at': createdAt,
                'booking_id': item['booking_id'],
                'payment_status': item['payment_status'],
                'total_price': item['total_price'],
              };
            }).toList();
          });
        } else {
          debugPrint('Created games: data is null or not a list');
        }
      } else {
        debugPrint(
          'Created games request failed: ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Error loading created games: $e');
    } finally {
      setState(() => _isLoadingCreatedGames = false);
    }
  }

  Future<void> _joinGame(Map<String, dynamic> item) async {
    final gameId = item['game_id'];
    if (gameId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error: Game ID not found')));
      return;
    }

    // Optimistic update
    final oldStatus = item['status'];
    setState(() {
      item['status'] = 'Pending';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      final base = dotenv.env['BASE_URL'] ?? '';

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to join games')),
        );
        return;
      }

      final uri = Uri.parse('$base/user/joinGame/$userId/$gameId');

      final resp = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined game successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh all data
        await _fetchJoinedGames();
        await _fetchAllGames();
      } else {
        setState(() {
          item['status'] = oldStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: ${resp.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error joining game: $e');
      setState(() {
        item['status'] = oldStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>>? _allPlayItems;
  List<Map<String, dynamic>>? _joinedPlayItems;
  List<Map<String, dynamic>>? _createdPlayItems;

  List<Map<String, dynamic>> get _filteredItems {
    List<Map<String, dynamic>> items;

    // First filter by Main Tab
    if (_selectedFilter == 'Joined') {
      items = _joinedPlayItems ?? [];
    } else if (_selectedFilter == 'Created') {
      items = _createdPlayItems ?? [];
    } else {
      // All Games: Show only games that are NOT joined AND NOT created
      items = (_allPlayItems ?? [])
          .where(
            (item) => item['isJoined'] != true && item['isCreated'] != true,
          )
          .toList();
    }

    // Then filter by Selected Sport
    if (_selectedSportFilter != 'All') {
      items = items
          .where(
            (item) =>
                item['sport'].toString().toLowerCase() ==
                _selectedSportFilter.toLowerCase(),
          )
          .toList();
    }

    return items;
  }

  List<Map<String, dynamic>> _getFilteredItemsSafe() {
    try {
      return _filteredItems;
    } catch (e) {
      debugPrint('Error building filtered items: $e');
      return [];
    }
  }

  String _timeAgo(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String? status) {
    if (status?.toLowerCase() == 'paid') return Colors.green;
    if (status?.toLowerCase() == 'unpaid') return Colors.red;

    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItemsSafe();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      body: Column(
        children: [
          // Filter Tabs (All, Joined, Created)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterTab('All Games'),
                _buildFilterTab('Joined'),
                _buildFilterTab('Created'),
              ],
            ),
          ),

          // Sport Filters List
          if ((_sportsFilters ?? []).isNotEmpty)
            Container(
              height: 50,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: (_sportsFilters ?? []).length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSportFilterChip('All');
                  }
                  final sport = (_sportsFilters ?? [])[index - 1];
                  return _buildSportFilterChip(
                    sport['sport_name'] ?? 'Unknown',
                  );
                },
              ),
            ),

          // Create Game Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Create a Game',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Matches List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchAllSports();
                if (_selectedFilter == 'Joined') {
                  await _fetchJoinedGames();
                } else if (_selectedFilter == 'Created') {
                  await _fetchCreatedGames();
                } else {
                  await _fetchAllGames();
                }
                await _loadCreatedGames(); // Reload games on refresh
                // Simulate data reload for matches
                await Future.delayed(const Duration(milliseconds: 500));
                setState(() {}); // Refresh UI
              },
              color: themeColor,
              child: filteredItems.isEmpty
                  ? Center(
                      child:
                          (_selectedFilter == 'Joined'
                              ? _isLoadingJoinedGames
                              : _selectedFilter == 'Created'
                              ? _isLoadingCreatedGames
                              : _isLoadingGames)
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_tennis_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No game found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // User Profile (New)
                                        if ((item['user_name'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                backgroundImage:
                                                    (item['user_image'] !=
                                                            null &&
                                                        item['user_image']
                                                            .toString()
                                                            .isNotEmpty)
                                                    ? NetworkImage(
                                                        item['user_image']
                                                            .toString(),
                                                      )
                                                    : null,
                                                child:
                                                    (item['user_image'] ==
                                                            null ||
                                                        item['user_image']
                                                            .toString()
                                                            .isEmpty)
                                                    ? Icon(
                                                        Icons.person,
                                                        size: 16,
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['user_name'],
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    _timeAgo(
                                                      item['created_at'],
                                                    ),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                        // Status Tag
                                        if (item['status'] != null)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                item['status'],
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(
                                                  item['status'],
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              item['status'].toString(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(
                                                  item['status'],
                                                ),
                                              ),
                                            ),
                                          ),

                                        // Payment Status Tag for Created Games
                                        if (item['isCreated'] == true &&
                                            item['payment_status'] != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  (item['payment_status']
                                                                  .toString()
                                                                  .toLowerCase() ==
                                                              'paid'
                                                          ? Colors.green
                                                          : Colors.red)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color:
                                                    item['payment_status']
                                                            .toString()
                                                            .toLowerCase() ==
                                                        'paid'
                                                    ? Colors.green
                                                    : Colors.red,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              item['payment_status']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    item['payment_status']
                                                            .toString()
                                                            .toLowerCase() ==
                                                        'paid'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],

                                        const SizedBox(width: 8),

                                        // Sport Tag
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: themeColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            item['sport'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: themeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['title'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['location'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Players joined',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              Text(
                                                item['players'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (item['status']
                                                ?.toString()
                                                .toLowerCase() !=
                                            'pending')
                                          if (item['isCreated'] == true)
                                            OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ManageGameScreen(
                                                          gameData: item,
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: themeColor,
                                                side: BorderSide(
                                                  color: themeColor,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 0,
                                                    ),
                                                minimumSize: const Size(0, 36),
                                              ),
                                              child: Text(
                                                'Manage',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          else if (item['isJoined'] == true)
                                            OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  item['isJoined'] = false;
                                                });
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(
                                                  color: Colors.red,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 0,
                                                    ),
                                                minimumSize: const Size(0, 36),
                                              ),
                                              child: Text(
                                                'Leave',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          else
                                            ElevatedButton(
                                              onPressed: () {
                                                _joinGame(item);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: themeColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 0,
                                                    ),
                                                minimumSize: const Size(0, 36),
                                              ),
                                              child: Text(
                                                'Join',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    final isSelected = _selectedFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = title;
            if (title == 'Joined') {
              _selectedSportFilter = 'All';
            }
          });
          if (title == 'Joined' && (_joinedPlayItems?.isEmpty ?? true)) {
            _fetchJoinedGames();
          } else if (title == 'Created' &&
              (_createdPlayItems?.isEmpty ?? true)) {
            _fetchCreatedGames();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12, // slightly smaller to fit
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilterChip(String label) {
    final isSelected = _selectedSportFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSportFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
