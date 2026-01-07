import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SportsPreferencesScreen extends StatefulWidget {
  const SportsPreferencesScreen({super.key});

  @override
  State<SportsPreferencesScreen> createState() => _SportsPreferencesScreenState();
}

class _SportsPreferencesScreenState extends State<SportsPreferencesScreen> {
  final Color themeColor = const Color(0xFF2E7D32);
  
  List<Map<String, dynamic>> _userSports = [];
  List<Map<String, dynamic>> _availableSports = [];
  bool _isLoading = true;
  String? _userId;

  final Map<String, IconData> _sportIcons = {
    'Football': Icons.sports_soccer,
    'Basketball': Icons.sports_basketball,
    'Tennis': Icons.sports_tennis,
    'Cricket': Icons.sports_cricket,
    'Badminton': Icons.sports_baseball,
    'Volleyball': Icons.sports_volleyball,
    'Swimming': Icons.pool,
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'Gym': Icons.fitness_center,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId != null) {
      await Future.wait([
        _loadUserSports(),
        _loadAvailableSports(),
      ]);
    }
  }

  Future<void> _loadUserSports() async {
    setState(() => _isLoading = true);
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final uri = Uri.parse('$base/user-sports');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _userSports = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading user sports: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableSports() async {
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      
      final uri = Uri.parse('$base/sports');
      final resp = await http.get(uri);

      debugPrint('Sports API response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final sportsData = data['data'];
        
        if (sportsData != null && sportsData['sports'] != null) {
          setState(() {
            _availableSports = List<Map<String, dynamic>>.from(
              sportsData['sports'].map((sport) => {
                'sport_id': sport['sport_id'],
                'sport_name': sport['sport_name'],
              })
            );
          });
          debugPrint('Loaded ${_availableSports.length} sports from API');
        }
      } else {
        debugPrint('Failed to load sports: ${resp.statusCode}');
        // Fallback to empty list
        setState(() {
          _availableSports = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading sports: $e');
      // Fallback to empty list on error
      setState(() {
        _availableSports = [];
      });
    }
  }

  Future<void> _addSport(int sportId, String skillLevel) async {
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final uri = Uri.parse('$base/user-sports');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sport_id': sportId,
          'skill_level': skillLevel,
        }),
      );

      debugPrint('Add sport response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _loadUserSports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sport added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        String err = 'Failed to add sport';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? err).toString();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding sport: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteSport(int userSportId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Remove Sport',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove this sport?',
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
              'Remove',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final uri = Uri.parse('$base/user-sports/$userSportId');
      final resp = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete sport response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode == 200) {
        await _loadUserSports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sport removed successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        String err = 'Failed to remove sport';
        try {
          final data = jsonDecode(resp.body);
          err = (data['message'] ?? err).toString();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting sport: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddSportDialog() {
    int? selectedSportId;
    String selectedSkillLevel = 'Beginner';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Sport',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Sport',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _availableSports.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No sports available',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedSportId,
                        isExpanded: true,
                        hint: Text('Choose a sport', style: GoogleFonts.poppins()),
                        items: _availableSports.map((sport) {
                          return DropdownMenuItem<int>(
                            value: sport['sport_id'],
                            child: Text(
                              sport['sport_name'],
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedSportId = value);
                        },
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              Text(
                'Skill Level',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                    .map((level) => ChoiceChip(
                          label: Text(level),
                          selected: selectedSkillLevel == level,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() => selectedSkillLevel = level);
                            }
                          },
                          selectedColor: themeColor,
                          labelStyle: GoogleFonts.poppins(
                            color: selectedSkillLevel == level
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: (selectedSportId == null || _availableSports.isEmpty)
                  ? null
                  : () {
                      Navigator.pop(context);
                      _addSport(selectedSportId!, selectedSkillLevel);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSkillLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.blue;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.purple;
      case 'expert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return true to indicate sports may have changed
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F8F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: themeColor.withOpacity(0.1),
          title: Text(
            'Sports Preferences',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Sports',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_userSports.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.sports_tennis,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No sports added yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add sports',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _userSports.length,
                          itemBuilder: (context, index) {
                            final userSport = _userSports[index];
                            final sportName = userSport['sport_name'] ?? 'Unknown';
                            final skillLevel = userSport['skill_level'] ?? 'Beginner';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _sportIcons[sportName] ?? Icons.sports,
                                    color: themeColor,
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  sportName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getSkillLevelColor(skillLevel).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    skillLevel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getSkillLevelColor(skillLevel),
                                    ),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    _deleteSport(userSport['user_sport_id']);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddSportDialog,
          backgroundColor: themeColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
