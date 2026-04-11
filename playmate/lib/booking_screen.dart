import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:playmate/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PaymentMethod { payAtVenue, online }

class BookingScreen extends StatefulWidget {
  final String? initialArea;
  final String? venueName;
  final String? price;
  final String? venueId;
  final List<dynamic>? availableSports;

  const BookingScreen({
    super.key,
    this.initialArea,
    this.venueName,
    this.price,
    this.venueId,
    this.availableSports,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
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

  // Map to store price for each slot
  Map<String, double> _slotPrices = {};

  // Map to store slot_id for each slot
  Map<String, int> _slotIds = {};
  Map<String, String> _slotStartTimes = {};
  Map<String, String> _slotEndTimes = {};

  // Recommendation metadata per slot
  Map<String, bool> _slotRecommended = {};
  Map<String, String> _slotRecommendationReason = {};

  // Price Data
  double _courtPrice = 0.0;
  // final double _convenienceFee = 50.0; // Removed convenience fee

  double _totalAmount = 0.0;
  bool _isLoadingPrice = false;

  // Payment
  PaymentMethod _paymentMethod = PaymentMethod.payAtVenue;
  Razorpay? _razorpay;
  bool _isProcessingPayment = false;
  final bool _isRazorpayAvailable = !kIsWeb;

  // State for venue selection mode (if widget.venueId is null)
  String? _currentVenueId;
  String? _currentVenueName;
  String? _currentPrice;
  List<dynamic>? _currentSports;

  // Venue List Data
  List<Map<String, dynamic>> _venues = [];
  bool _isLoadingVenues = false;
  String _venueSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(text: widget.initialArea);

    if (widget.venueId != null) {
      // Direct booking mode
      _currentVenueId = widget.venueId;
      _currentVenueName = widget.venueName;
      _currentPrice = widget.price;
      _currentSports = widget.availableSports;
      _initializeSports();
    } else {
      // Venue selection mode
      _fetchVenues();
    }

    _setupRazorpay();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _areaController.dispose();
    _playersController.dispose();
    super.dispose();
  }

  void _setupRazorpay() {
    if (!_isRazorpayAvailable) {
      return;
    }

    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    // Keep loading while we create the booking

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful. Finalizing booking...'),
        backgroundColor: Colors.green,
      ),
    );

    final paymentData = {
      'razorpay_order_id': response.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
      "amount": _totalAmount,
    };

    _createBooking(payment: paymentData);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessingPayment = false);
    final message = response.message ?? 'Payment failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName ?? 'Unknown'}'),
      ),
    );
  }

  Future<Map<String, dynamic>?> _createRazorpayOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    final base = dotenv.env['BASE_URL'] ?? '';
    final uri = Uri.parse('$base/user/payments/order');
    final receipt = 'booking_${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': _totalAmount.round(),
        'currency': 'INR',
        'receipt': receipt,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final orderData = data['data'] ?? data;

      final orderId = orderData['order_id']?.toString();
      final amountRaw = orderData['amount'];
      final currency = orderData['currency']?.toString() ?? 'INR';
      final amount = amountRaw is int
          ? amountRaw
          : int.tryParse(amountRaw?.toString() ?? '');

      if (orderId == null || amount == null) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid order response. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      return {'order_id': orderId, 'amount': amount, 'currency': currency};
    }

    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order failed: ${response.body}'),
        backgroundColor: Colors.red,
      ),
    );
    return null;
  }

  Future<void> _startOnlinePayment({bool upiOnly = false}) async {
    if (!_isRazorpayAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online payment is not available on web.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final keyId = dotenv.env['RAZORPAY_KEY_ID'];
    if (keyId == null || keyId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing Razorpay key. Please configure it.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_totalAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount. Please re-check your booking.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    final orderData = await _createRazorpayOrder();
    if (orderData == null) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final firstName = (prefs.getString('first_name') ?? '').trim();
    final lastName = (prefs.getString('last_name') ?? '').trim();
    final userEmail = (prefs.getString('user_email') ?? '').trim();
    final userPhone = (prefs.getString('phone_number') ?? '').trim();
    final userId = (prefs.getString('user_id') ?? '').trim();
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();

    final selectedSport = _sportsList.firstWhere(
      (sport) => sport['sport_id'].toString() == _selectedSportId,
      orElse: () => {'sport_name': 'Game'},
    );
    final sportName = selectedSport['sport_name']?.toString() ?? 'Game';
    final bookingDate =
        '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
    final venueName = _currentVenueName ?? 'PlayMate';
    final slotText = _selectedSlot ?? 'N/A';
    final userNameForDisplay = fullName.isEmpty ? 'PlayMate User' : fullName;
    final compactSlot = slotText.replaceAll(' to ', '-');
    final bookingDescription =
      '$userNameForDisplay | $sportName | $bookingDate | $compactSlot' ;

    final shouldContinue = await _showPaymentDetailsSheet(
      userName: userNameForDisplay,
      userEmail: userEmail,
      userPhone: userPhone,
      venueName: venueName,
      sportName: sportName,
      bookingDate: bookingDate,
      slotText: slotText,
      amountText: 'INR ${_totalAmount.toStringAsFixed(0)}',
      area: _areaController.text.trim(),
    );

    if (!shouldContinue) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      return;
    }

    final Map<String, dynamic> options = {
      'key': keyId,
      'order_id': orderData['order_id'],
      'amount': orderData['amount'],
      'currency': orderData['currency'],
      'name': venueName,
      'description': bookingDescription,
      'theme': {'color': '#2E7D32'},
      'retry': {'enabled': true, 'max_count': 1},
      'notes': {
        'user_name': fullName.isEmpty ? 'PlayMate User' : fullName,
        'user_id': userId,
        'venue': venueName,
        'sport': sportName,
        'date': bookingDate,
        'slot': _selectedSlot ?? '',
        'area': _areaController.text.trim(),
        'court_price': _courtPrice.toStringAsFixed(0),
        'total_amount': _totalAmount.toStringAsFixed(0),
      },
    };

    final Map<String, dynamic> prefill = {
      'name': fullName.isEmpty ? 'PlayMate User' : fullName,
    };
    if (userEmail.isNotEmpty) {
      prefill['email'] = userEmail;
    }
    if (userPhone.isNotEmpty) {
      prefill['contact'] = userPhone;
    }
    options['prefill'] = prefill;

    if (upiOnly) {
      options['method'] = {'upi': true};
      options['config'] = {
        'display': {
          'blocks': {
            'upi': {
              'name': 'UPI',
              'instruments': [
                {'method': 'upi'},
              ],
            },
          },
          'sequence': ['block.upi'],
          'preferences': {'show_default_blocks': false},
        },
      };
    }

    try {
      _razorpay?.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
    }
  }

  Future<bool> _showPaymentDetailsSheet({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String venueName,
    required String sportName,
    required String bookingDate,
    required String slotText,
    required String amountText,
    required String area,
  }) async {
    if (!mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirm Payment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPriceRow('User', userName),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Email', userEmail),
                  ],
                  if (userPhone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Phone', userPhone),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow('Venue', venueName),
                  const SizedBox(height: 8),
                  _buildPriceRow('Sport', sportName),
                  const SizedBox(height: 8),
                  _buildPriceRow('Date', bookingDate),
                  const SizedBox(height: 8),
                  _buildPriceRow('Slot', slotText),
                  if (area.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Area', area),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow('Amount', amountText),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Back',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _createBooking({required dynamic payment}) async {
    if (_selectedSportId == null || _selectedSlot == null) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select sport and slot')),
      );
      return;
    }

    final selectedSport = _sportsList.firstWhere(
      (s) => s['sport_id'].toString() == _selectedSportId,
      orElse: () => {'sport_name': 'Unknown'},
    );

    try {
      // Get auth token and user ID
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Try to get user_id as int first, then as string
      String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get slot_id for the selected slot
      final slotId = _slotIds[_selectedSlot] ?? 0;

      // Format datetime for API (YYYY-MM-DD HH:MM:SS)
      final dateStr =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      // Always send API datetimes in 24h format, even when UI displays 12h.
      final startTime = _slotStartTimes[_selectedSlot!] ?? '00:00';
      final endTime = _slotEndTimes[_selectedSlot!] ?? '00:00';

      final startDatetime = '$dateStr $startTime:00';
      final endDatetime = '$dateStr $endTime:00';

      // Prepare booking data
      final bookingData = {
        'sport_id': int.parse(_selectedSportId!),
        'venue_id': int.parse(_currentVenueId!),
        'start_datetime': startDatetime,
        'end_datetime': endDatetime,
        'host_id': userId,
        'price': _courtPrice,
        'slot_id': slotId,
        'payment': payment,
      };

      debugPrint('Sending booking data: $bookingData');

      // Send POST request to create booking
      final base = dotenv.env['BASE_URL'] ?? '';
      final uri = Uri.parse('$base/user/venueBooking');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bookingData),
      );

      debugPrint('Booking response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Save Game to SharedPreferences
        final sportName = selectedSport['sport_name'] ?? 'Unknown';
        final displayDateStr =
            "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}";
        final totalPlayers = _playersController.text.isNotEmpty
            ? _playersController.text
            : '4';

        final newGame = {
          'sport': sportName,
          'image': '',
          'title': '$sportName Match',
          'location': _currentVenueName ?? 'Unknown Venue',
          'distance': '0.0 km',
          'players': '1/$totalPlayers',
          'level': 'Open',
          'date': displayDateStr,
          'time': _selectedSlot!,
          'isJoined': false,
          'isCreated': true,
          'booking_id': responseData['data']?['booking_id'],
          'created_at': DateTime.now().toIso8601String(),
        };

        final String? existingGamesString = prefs.getString('created_games');
        List<dynamic> existingGames = [];
        if (existingGamesString != null) {
          existingGames = jsonDecode(existingGamesString);
        }
        existingGames.insert(0, newGame);
        await prefs.setString('created_games', jsonEncode(existingGames));

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking Successful! Game Created.'),
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
      } else {
        // Booking failed
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorData['message'] ?? 'Booking failed. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _initializeSports() {
    if (_currentSports != null && _currentSports!.isNotEmpty) {
      setState(() {
        _sportsList = List<Map<String, dynamic>>.from(_currentSports!);
      });
    } else {
      _fetchSports();
    }
  }

  Future<void> _fetchVenues() async {
    setState(() => _isLoadingVenues = true);
    try {
      final base = dotenv.env['BASE_URL'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      final uri = Uri.parse('$base/venue/allVenues');

      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            _venues = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching venues: $e');
    } finally {
      setState(() => _isLoadingVenues = false);
    }
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
      'Values -> VenueId: $_currentVenueId, SportId: $_selectedSportId, Date: $_selectedDate',
    );

    if (_selectedSportId == null || _currentVenueId == null) {
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
      final userId = prefs.getString('user_id');

      final dateStr =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      final uri = Uri.parse(
        '$base/venue/slots/available/$_currentVenueId?date=$dateStr&sportId=$_selectedSportId',
      );

      debugPrint('Fetching Slots URL: $uri');

      final request = http.Request('GET', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Content-Type'] = 'application/json';
      if (userId != null && userId.isNotEmpty) {
        request.body = jsonEncode({'userId': userId});
      }

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      debugPrint('Slots Response Code: ${resp.statusCode}');
      debugPrint('Slots Response Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List<dynamic> slotsData = [];

        // Supports new structure (merged_slots/available_slots), while
        // keeping backward compatibility with the old data array response.
        if (data is Map<String, dynamic>) {
          if (data['merged_slots'] is List) {
            slotsData = List<dynamic>.from(data['merged_slots']);
          } else if (data['available_slots'] is List) {
            slotsData = List<dynamic>.from(data['available_slots']);
          } else if (data['data'] is List) {
            slotsData = List<dynamic>.from(data['data']);
          } else if (data['data'] is Map<String, dynamic>) {
            final nested = data['data'] as Map<String, dynamic>;
            if (nested['merged_slots'] is List) {
              slotsData = List<dynamic>.from(nested['merged_slots']);
            } else if (nested['available_slots'] is List) {
              slotsData = List<dynamic>.from(nested['available_slots']);
            }
          }
        }

        if (slotsData.isNotEmpty) {
          // Prepare a list of slot info objects for sorting
          final List<Map<String, dynamic>> slotInfoList = [];
          // Clear previous data
          _slotPrices = {};
          _slotIds = {};
          _slotStartTimes = {};
          _slotEndTimes = {};
          _slotRecommended = {};
          _slotRecommendationReason = {};

          for (var e in slotsData) {
            if (e is Map) {
              final start = e['start_time']?.toString();
              final end = e['end_time']?.toString();
              final priceData = e['price_per_slot'];
              final slotId = e['slot_id'];
              final isRecommended = e['is_recommended'] == true;
              String recommendationReason = '';
              if (e['recommendation'] is Map) {
                final recommendation = e['recommendation'] as Map;
                recommendationReason = recommendation['reason']?.toString() ?? '';
              }

              if (start != null && end != null) {
                final s = start.length >= 5 ? start.substring(0, 5) : start;
                final endTime = end.length >= 5 ? end.substring(0, 5) : end;
                final slotTime = '${_to12Hour(s)} to ${_to12Hour(endTime)}';

                slotInfoList.add({
                  'slotTime': slotTime,
                  'start': s,
                  'end': endTime,
                  'priceData': priceData,
                  'slotId': slotId,
                  'isRecommended': isRecommended,
                  'recommendationReason': recommendationReason,
                });
              }
            } else if (e is String) {
              final raw = e.trim();
              if (raw.isEmpty) continue;

              final parts = raw.split(' to ');
              if (parts.length == 2) {
                final rawStart = parts[0].trim();
                final rawEnd = parts[1].trim();
                final start24 = _to24Hour(rawStart);
                final end24 = _to24Hour(rawEnd);
                final slotDisplay = '${_to12Hour(start24)} to ${_to12Hour(end24)}';
                slotInfoList.add({
                  'slotTime': slotDisplay,
                  'start': start24,
                  'end': end24,
                  'priceData': null,
                  'slotId': null,
                  'isRecommended': false,
                  'recommendationReason': '',
                });
              } else {
                slotInfoList.add({
                  'slotTime': raw,
                  'start': null,
                  'end': null,
                  'priceData': null,
                  'slotId': null,
                  'isRecommended': false,
                  'recommendationReason': '',
                });
              }
            }
          }

          // Sort: recommended slots first, then by start time if available
          slotInfoList.sort((a, b) {
            if (a['isRecommended'] == b['isRecommended']) {
              // If both have start, sort by start time
              if (a['start'] != null && b['start'] != null) {
                return a['start'].compareTo(b['start']);
              }
              return 0;
            }
            return b['isRecommended'] ? 1 : -1;
          });

          setState(() {
            _slots = [];
            for (final slot in slotInfoList) {
              final slotTime = slot['slotTime'];
              _slots.add(slotTime);
              if (slot['start'] != null) _slotStartTimes[slotTime] = slot['start'];
              if (slot['end'] != null) _slotEndTimes[slotTime] = slot['end'];
              if (slot['priceData'] != null) {
                final priceData = slot['priceData'];
                final price = (priceData is int)
                    ? priceData.toDouble()
                    : (priceData is double)
                        ? priceData
                        : double.tryParse(priceData.toString()) ?? 0.0;
                _slotPrices[slotTime] = price;
              }
              if (slot['slotId'] != null) {
                final slotId = slot['slotId'];
                final id = (slotId is int)
                    ? slotId
                    : int.tryParse(slotId.toString()) ?? 0;
                _slotIds[slotTime] = id;
              }
              _slotRecommended[slotTime] = slot['isRecommended'] ?? false;
              if ((slot['recommendationReason'] ?? '').isNotEmpty) {
                _slotRecommendationReason[slotTime] = slot['recommendationReason'];
              }
            }
            debugPrint('Loaded ${_slots.length} slots with prices: $_slotPrices');
          });
        } else {
          debugPrint('No slots found in response structure.');
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

  Future<void> _fetchPriceData() async {
    debugPrint('--- _fetchPriceData Called ---');
    debugPrint(
      'Values -> VenueId: $_currentVenueId, SportId: $_selectedSportId, Date: $_selectedDate, Slot: $_selectedSlot',
    );

    if (_selectedSportId == null ||
        _currentVenueId == null ||
        _selectedSlot == null) {
      debugPrint('WARNING: Missing required data for price fetch. Aborting.');
      return;
    }

    setState(() {
      _isLoadingPrice = true;
    });

    try {
      // Get the price for the selected slot from the map
      double courtPrice = _slotPrices[_selectedSlot] ?? 0.0;

      // If court price is not available from slot map, use fallback
      if (courtPrice == 0.0) {
        // Parse price from _currentPrice if available
        final priceString = _currentPrice;
        if (priceString != null) {
          // Remove commas first, then remove non-digits/dots
          final cleanString = priceString
              .replaceAll(',', '')
              .replaceAll(RegExp(r'[^0-9.]'), '');
          if (cleanString.isNotEmpty) {
            courtPrice = double.tryParse(cleanString) ?? 500.0;
          }
        } else {
          courtPrice = 500.0; // Default fallback
        }
      }

      // Calculate total (no convenience fee)
      double totalAmount = courtPrice;

      debugPrint(
        'Selected Slot: $_selectedSlot, Court Price: $courtPrice, Total: $totalAmount',
      );

      setState(() {
        _courtPrice = courtPrice;
        _totalAmount = totalAmount;
      });
    } catch (e) {
      debugPrint('Error calculating price: $e');
    } finally {
      setState(() => _isLoadingPrice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no venue selected, show venue list
    if (_currentVenueId == null) {
      return _buildVenueSelection();
    }

    // Otherwise show booking form
    return _buildBookingForm();
  }

  Widget _buildVenueSelection() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F8F3),
        elevation: 0,
        leading: widget.venueId == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'Select Venue',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingVenues
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _venueSearchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _venues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final venue = _venues[index];
                      // Very basic search filter
                      if (_venueSearchQuery.isNotEmpty) {
                        final name = (venue['venue_name'] ?? '').toLowerCase();
                        if (!name.contains(_venueSearchQuery.toLowerCase())) {
                          return const SizedBox.shrink();
                        }
                      }

                      final venueName = venue['venue_name'] ?? 'Unnamed Venue';
                      // Check for null or empty name better handled
                      if (venueName.toString().trim().isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final venueId = venue['venue_id'].toString();
                      final priceText = venue['min_price'] != null
                          ? 'INR ${venue['min_price']} Onwards'
                          : 'Price not available';
                      final address = venue['address'] ?? 'No address';
                      final sports = venue['sports'] as List<dynamic>? ?? [];
                      final images = venue['images'] as List<dynamic>? ?? [];

                      return VenueCard(
                        venueId: venueId,
                        venueName: venueName,
                        address: address,
                        priceText: priceText,
                        sports: sports,
                        images: images,
                        themeColor: themeColor,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBookingForm() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F8F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isProcessingPayment
              ? null
              : () {
                  // If we came from external selection, pop.
                  // If we selected venue internally, go back to venue list.
                  if (widget.venueId == null) {
                    setState(() {
                      _currentVenueId = null;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        title: Text(
          _currentVenueName ?? 'Book Slot',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
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
                                    color: isSelected
                                        ? themeColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? themeColor
                                          : Colors.grey.shade300,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: themeColor.withOpacity(
                                                0.3,
                                              ),
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
                                  final slotPrice = _slotPrices[slot] ?? 0.0;
                                  final isRecommended =
                                      _slotRecommended[slot] == true;
                                  final recommendationReason =
                                      _slotRecommendationReason[slot] ?? '';

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSlot = slot;
                                      });
                                      _fetchPriceData();
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slot,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (isRecommended) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withOpacity(
                                                        0.22,
                                                      )
                                                    : const Color(0xFFE8F5E9),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Recommended',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : themeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (slotPrice > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'INR ${slotPrice.toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white.withOpacity(
                                                        0.9,
                                                      )
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                        ),

                        // Price Breakdown Section - Only show if price data is loaded
                        if (_selectedSlot != null &&
                            !_isLoadingPrice &&
                            _totalAmount > 0) ...[
                          const SizedBox(height: 30),

                          // Price Details Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              children: [
                                _buildPriceRow(
                                  'Court Price',
                                  'INR ${_courtPrice.toStringAsFixed(0)}',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Total Amount Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade900,
                                  Colors.grey.shade800,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _paymentMethod == PaymentMethod.online
                                            ? 'Pay Online'
                                            : 'Pay at Venue',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'INR ${_totalAmount.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Payment Method
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Payment Method',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RadioListTile<PaymentMethod>(
                                        value: PaymentMethod.payAtVenue,
                                        groupValue: _paymentMethod,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _paymentMethod = value,
                                          );
                                        },
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Pay at Venue',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Pay at the venue. Booking marked unpaid.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      RadioListTile<PaymentMethod>(
                                        value: PaymentMethod.online,
                                        groupValue: _paymentMethod,
                                        onChanged: _isRazorpayAvailable
                                            ? (value) {
                                                if (value == null) return;
                                                setState(
                                                  () => _paymentMethod = value,
                                                );
                                              }
                                            : null,
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Pay Online',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _isRazorpayAvailable
                                              ? 'Pay now via Razorpay and confirm booking.'
                                              : 'Online payment not available on web.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
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

                        // Loading indicator for price
                        if (_selectedSlot != null && _isLoadingPrice) ...[
                          const SizedBox(height: 30),
                          const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
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
                      onPressed: _isProcessingPayment
                          ? null
                          : () async {
                              if (_selectedSportId == null ||
                                  _selectedSlot == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select sport and slot',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (_paymentMethod == PaymentMethod.online) {
                                await _startOnlinePayment();
                              } else {
                                setState(() => _isProcessingPayment = true);
                                await _createBooking(payment: 'unpaid');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor, // Use App Theme Color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isProcessingPayment
                            ? 'PROCESSING...'
                            : _paymentMethod == PaymentMethod.online
                            ? 'PAY & CONFIRM'
                            : 'CONFIRM BOOKING',
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
          if (_isProcessingPayment)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing Booking...',
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
        ],
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

  String _to12Hour(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;
    if (raw.toUpperCase().contains('AM') || raw.toUpperCase().contains('PM')) {
      return raw;
    }

    final parts = raw.split(':');
    if (parts.length < 2) return raw;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return raw;

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _to24Hour(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    final upper = raw.toUpperCase();
    if (!upper.contains('AM') && !upper.contains('PM')) {
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final hh = int.tryParse(parts[0]);
        final mm = int.tryParse(parts[1]);
        if (hh != null && mm != null) {
          return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
        }
      }
      return raw;
    }

    final cleaned = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = cleaned.split(':');
    if (parts.length < 2) return raw;
    final hour12 = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour12 == null || minute == null) return raw;

    final isPm = upper.contains('PM');
    int hour24 = hour12 % 12;
    if (isPm) hour24 += 12;

    return '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class VenueCard extends StatefulWidget {
  final String venueId;
  final String venueName;
  final String address;
  final String priceText;
  final List<dynamic> sports;
  final List<dynamic> images;
  final Color themeColor;

  const VenueCard({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.address,
    required this.priceText,
    required this.sports,
    required this.images,
    required this.themeColor,
  });

  @override
  State<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<VenueCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingScreen(
              venueId: widget.venueId,
              initialArea: widget.address,
              venueName: widget.venueName,
              price: widget.priceText,
              availableSports: widget.sports,
            ),
          ),
        );
      },
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            SizedBox(
              height: 140,
              child: widget.images.isNotEmpty
                  ? Stack(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 140,
                            viewportFraction: 1.0,
                            autoPlay: widget.images.length > 1,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(
                              milliseconds: 800,
                            ),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: widget.images.length > 1,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                          items: widget.images.map((imageUrl) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: double.infinity,
                                  color: Colors.grey.shade200,
                                  child: Image.network(
                                    imageUrl.toString(),
                                    width: double.infinity,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.stadium_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        // Page indicator dots
                        if (widget.images.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: widget.images.asMap().entries.map((
                                entry,
                              ) {
                                return Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.stadium_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.venueName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Display sports if available
                  if (widget.sports.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.sports.take(3).map((sport) {
                        final sportName = sport['sport_name'] ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sportName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: widget.themeColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.priceText,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
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
