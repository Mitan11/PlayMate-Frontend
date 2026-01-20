import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/venue_selection_screen.dart';
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
  List<Map<String, dynamic>> _sportsFilters = [];
  String _selectedSportFilter = 'All';
  bool _isLoadingSports = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _fetchAllSports();
    _loadCreatedGames(); // Load saved games
  }

  Future<void> _loadCreatedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? createdGamesString = prefs.getString('created_games');
    if (createdGamesString != null) {
      try {
        final List<dynamic> loadedGames = jsonDecode(createdGamesString);
        setState(() {
          // Filter out existing created games to avoid duplicates if re-loading
          _allPlayItems.removeWhere((item) => item['isCreated'] == true);

          // Add loaded games
          _allPlayItems.addAll(loadedGames.cast<Map<String, dynamic>>());
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

  List<Map<String, dynamic>> _allPlayItems = [
    {
      'sport': 'Tennis',
      'image': 'assets/images/tennis_court.jpg',
      'title': 'Evening Doubles Match',
      'location': 'Green Valley Club',
      'distance': '2.5 km',
      'players': '3/4',
      'level': 'Intermediate',
      'isJoined': true,
      'isCreated': false,
    },
    {
      'sport': 'Badminton',
      'image': '',
      'title': 'Weekend Badminton',
      'location': 'City Sports Complex',
      'distance': '4.0 km',
      'players': '2/4',
      'level': 'Beginner',
      'isJoined': false,
      'isCreated': true,
    },
    {
      'sport': 'Cricket',
      'image': '',
      'title': 'Friendly Box Cricket',
      'location': 'Metro Turf',
      'distance': '1.2 km',
      'players': '8/12',
      'level': 'All Levels',
      'isJoined': false,
      'isCreated': false,
    },
    {
      'sport': 'Tennis',
      'image': '',
      'title': 'Morning Singles',
      'location': 'City Court',
      'distance': '1.0 km',
      'players': '1/2',
      'level': 'Pro',
      'isJoined': false,
      'isCreated': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    List<Map<String, dynamic>> items = _allPlayItems;

    // First filter by Main Tab
    if (_selectedFilter == 'Joined') {
      items = items.where((item) => item['isJoined'] == true).toList();
    } else if (_selectedFilter == 'Created') {
      items = items.where((item) => item['isCreated'] == true).toList();
    } else {
      // All Games: Show only games that are NOT joined AND NOT created
      items = items
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

  @override
  Widget build(BuildContext context) {
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
          if (_sportsFilters.isNotEmpty)
            Container(
              height: 50,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _sportsFilters.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSportFilterChip('All');
                  }
                  final sport = _sportsFilters[index - 1];
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
                    builder: (context) => const VenueSelectionScreen(),
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
                await _loadCreatedGames(); // Reload games on refresh
                // Simulate data reload for matches
                await Future.delayed(const Duration(milliseconds: 500));
                setState(() {}); // Refresh UI
              },
              color: themeColor,
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
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
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
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
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        item['sport'] == 'Tennis'
                                            ? Icons.sports_tennis
                                            : item['sport'] == 'Badminton'
                                            ? Icons.sports_tennis_outlined
                                            : Icons.sports_cricket,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    if (item['isJoined'] == true)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Joined',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 10,
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
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
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
                                        Text(
                                          item['distance'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Level',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              Text(
                                                item['level'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                                              setState(() {
                                                item['isJoined'] = true;
                                              });
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
          });
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
