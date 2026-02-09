import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGameScreen extends StatefulWidget {
  final String? initialArea;
  final String? venueName;
  final String? price;
  final String? venueId;

  const CreateGameScreen({
    super.key,
    this.initialArea,
    this.venueName,
    this.price,
    this.venueId,
  });

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final Color themeColor = const Color(
    0xFF2E7D32,
  ); // Consistently using the app's theme color
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  // Data
  List<Map<String, dynamic>> _sportsList = [];
  String? _selectedSportId;
  // ignore: unused_field
  bool _isLoadingSports = false;

  // Controllers
  late TextEditingController _areaController;
  final TextEditingController _playersController = TextEditingController();

  // Slots
  List<String> _slots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(text: widget.initialArea);
    _fetchSports();
  }

  Future<void> _fetchSports() async {
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
            _sportsList = List<Map<String, dynamic>>.from(sportsData['sports']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sports: $e');
    } finally {
      setState(() => _isLoadingSports = false);
    }
  }

  Future<void> _fetchAvailableSlots() async {
    debugPrint('--- _fetchAvailableSlots Called ---');
    debugPrint(
      'Values -> VenueId: ${widget.venueId}, SportId: $_selectedSportId, Date: $_selectedDate',
    );

    if (_selectedSportId == null || widget.venueId == null) {
      debugPrint('WARNING: Missing venueId or sportId. Aborting slot fetch.');
      return;
    }

    setState(() {
      _isLoadingSlots = true;
      _slots = [];
      _selectedSlot = null;
    });

    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dateStr =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      final uri = Uri.parse(
        '$base/venue/slots/available/${widget.venueId}?date=$dateStr&sportId=$_selectedSportId',
      );

      debugPrint('Fetching Slots URL: $uri');

      final resp = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      debugPrint('Slots Response Code: ${resp.statusCode}');
      debugPrint('Slots Response Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == true && data['data'] != null) {
          final slotsData = List<dynamic>.from(data['data']);

          setState(() {
            _slots = slotsData
                .map((e) {
                  if (e is String) return e;
                  if (e is Map) {
                    final start = e['start_time']?.toString();
                    final end = e['end_time']?.toString();
                    if (start != null && end != null) {
                      // Format "09:00:00" -> "09:00"
                      final s = start.length >= 5
                          ? start.substring(0, 5)
                          : start;
                      final e = end.length >= 5 ? end.substring(0, 5) : end;
                      return '$s to $e';
                    }
                    return e['slot_time']?.toString() ??
                        e['time']?.toString() ??
                        e.toString();
                  }
                  return e.toString();
                })
                .toList()
                .cast<String>();
          });
        } else {
          debugPrint('API status false or data null: ${data['message']}');
        }
      } else {
        debugPrint('Failed to load slots: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F8F3), // Match scaffold bg
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Game',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sport Selection Dropdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSportId,
                          hint: Text(
                            'Select Sport',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _sportsList.map((sport) {
                            return DropdownMenuItem<String>(
                              value: sport['sport_id'].toString(),
                              child: Text(
                                sport['sport_name'] ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSportId = val;
                            });
                            _fetchAvailableSlots();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Area Input
                    _buildInputLabelField('Area', _areaController),
                    const SizedBox(height: 16),

                    // Total Player Input

                    // Date Selection
                    Text(
                      'Select Date',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14, // 2 weeks
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final date = DateTime.now().add(
                            Duration(days: index),
                          );
                          final isSelected =
                              date.day == _selectedDate.day &&
                              date.month == _selectedDate.month &&
                              date.year == _selectedDate.year;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                                _fetchAvailableSlots();
                              });
                            },
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? themeColor : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: themeColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getWeekday(date.weekday),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Select Slot Label
                    Text(
                      'Select Slot',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Time Slots
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _isLoadingSlots
                          ? [
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ]
                          : _slots.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'No slots available',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ]
                          : _slots.map((slot) {
                              final isSelected = _selectedSlot == slot;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSlot = slot;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? themeColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? themeColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    slot,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedSportId == null || _selectedSlot == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select sport and slot'),
                        ),
                      );
                      return;
                    }

                    final selectedSport = _sportsList.firstWhere(
                      (s) => s['sport_id'].toString() == _selectedSportId,
                      orElse: () => {'sport_name': 'Unknown'},
                    );

                    // Save Game to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    final sportName = selectedSport['sport_name'] ?? 'Unknown';
                    final dateStr =
                        "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}";
                    final totalPlayers = _playersController.text.isNotEmpty
                        ? _playersController.text
                        : '4';

                    final newGame = {
                      'sport': sportName,
                      'image': '',
                      'title': '$sportName Match',
                      'location': widget.venueName ?? 'Unknown Venue',
                      'distance': '0.0 km',
                      'players': '1/$totalPlayers',
                      'level': 'Open',
                      'date': dateStr,
                      'time': _selectedSlot!,
                      'isJoined': false,
                      'isCreated': true,
                    };

                    final String? existingGamesString = prefs.getString(
                      'created_games',
                    );
                    List<dynamic> existingGames = [];
                    if (existingGamesString != null) {
                      existingGames = jsonDecode(existingGamesString);
                    }
                    existingGames.insert(0, newGame);
                    await prefs.setString(
                      'created_games',
                      jsonEncode(existingGames),
                    );

                    if (!context.mounted) return;

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Game Created Successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Navigate to PlayScreen (Index 1 of HomeScreen)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor, // Use App Theme Color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'CREATE GAME',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabelField(String hint, TextEditingController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // In image: Today 30, Sat 31.
    // Logic: If selected date is today, show 'Today'?
    // Image shows "Today 30" (probably placeholder).
    // I'll stick to Mon/Tue etc for now unless I want to implement 'Today' logic properly.
    // Let's implement active day logic if you want exact replica, but simplest is day name.

    // Additional logic for "Today" if needed, but strict day name is fine.
    return days[weekday - 1];
  }
}
