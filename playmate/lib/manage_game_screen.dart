import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:playmate/manage_requests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ManageGameScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;

  const ManageGameScreen({super.key, required this.gameData});

  @override
  State<ManageGameScreen> createState() => _ManageGameScreenState();
}

class _ManageGameScreenState extends State<ManageGameScreen> {
  String _userName = 'Player';
  String _userInitial = 'P';
  Razorpay? _razorpay;
  bool _isProcessingPayment = false;
  final bool _isRazorpayAvailable = !kIsWeb;
  // ignore: unused_field
  double _courtPrice = 0.0;
  final double _convenienceFee = 50.0;
  double _lastPaymentAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRazorpay();
  }

  @override
  void dispose() {
    _razorpay?.clear();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful. Verifying...'),
        backgroundColor: Colors.green,
      ),
    );

    final paymentData = {
      'razorpay_order_id': response.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
      'amount': _lastPaymentAmount,
    };

    _verifyPayment(paymentData);
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

  Future<Map<String, dynamic>?> _createRazorpayOrder(double amount) async {
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
    final receipt = 'game_payment_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.round(),
          'currency': 'INR',
          'receipt': receipt,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderData = data['data'] ?? data;

        final orderId = orderData['order_id']?.toString();
        // Convert API amount (paise) to double if needed, wait, API usually takes rupees and converts or expects paise?
        // Razorpay API expects amount in smallest currency unit (paise).
        // The backend /payments/order likely handles this or expects standard amount.
        // Based on booking_screen: 'amount': _totalAmount.round() (which was double rupees), and API returned amount.
        // Let's assume the backend expects Rupees as amount in body based on booking screen implementation.
        // BUT wait, Razorpay standard is paise.
        // In booking_screen: 'amount': _totalAmount.round() -> passed to Backend. Backend likely creates order.

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
      debugPrint('Order creation failed: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } catch (e) {
      debugPrint('Error creating order: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      return null;
    }
  }

  Future<void> _verifyPayment(Map<String, dynamic> paymentData) async {
    final gameId = widget.gameData['game_id'] ?? widget.gameData['booking_id'];
    if (gameId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Game ID not found')));
      setState(() => _isProcessingPayment = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final base = dotenv.env['BASE_URL'] ?? '';

      // Changed to use /user/ prefix as per user request pattern matching
      final uri = Uri.parse('$base/user/payments/complete/$gameId');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Verified! Game is now Paid.'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          widget.gameData['payment_status'] = 'paid';
          _isProcessingPayment = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        debugPrint('Payment verification failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _startPayment() async {
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

    // Get amount from game data
    final totalPriceString = widget.gameData['total_price'];
    double courtPrice = 0.0;
    if (totalPriceString != null) {
      courtPrice = double.tryParse(totalPriceString.toString()) ?? 0.0;
    }

    _courtPrice = courtPrice;
    final totalAmount = courtPrice + _convenienceFee;
    _lastPaymentAmount = totalAmount;

    if (totalAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    final orderData = await _createRazorpayOrder(totalAmount);
    if (orderData == null) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      return;
    }

    final options = {
      'key': keyId,
      'order_id': orderData['order_id'],
      'amount': orderData['amount'],
      'currency': orderData['currency'],
      'name': 'PlayMate',
      'description': 'Game Payment',
      'theme': {'color': '#2E7D32'},
    };

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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        final String firstName = userData['first_name'] ?? '';
        final String lastName = userData['last_name'] ?? '';

        setState(() {
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            _userName = '$firstName $lastName'.trim();
          }
          if (firstName.isNotEmpty) {
            _userInitial = firstName[0].toUpperCase();
          }
        });
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract dynamic data or defaults
    final String sportName = widget.gameData['sport'] ?? 'Sport';
    final String playersCount = widget.gameData['players'] ?? '1/4';
    final String level = widget.gameData['level'] ?? 'Open';
    final themeColor = const Color(0xFF2E7D32);

    return Stack(
      children: [
        IgnorePointer(
          ignoring: _isProcessingPayment,
          child: Scaffold(
            backgroundColor: const Color(0xFFF3F8F3),
            appBar: AppBar(
              title: Text(
                'Game Details',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: Container(
                margin: const EdgeInsets.only(left: 16),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Location Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Details',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.gameData['title'] ?? 'Game Event',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.gameData['location'] ??
                                        'Unknown Location',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Venue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header: Players count & Globe
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Created By',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // User Profile Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _userInitial,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _userName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'Host',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Badges Row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildInfoBadge(
                                        level.toUpperCase(),
                                        themeColor,
                                      ),
                                      _buildInfoBadge(
                                        sportName.toUpperCase(),
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Divider(color: Colors.grey.shade100, height: 1),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey.shade100, height: 1),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Pay Button (only if unpaid)
                            if (widget.gameData['payment_status'] == 'unpaid')
                              _buildModernActionButton(
                                icon: Icons.currency_rupee_rounded,
                                label: 'Pay Now',
                                color: Colors.red,
                                isActive: !_isProcessingPayment, // Highlighted
                                onTap: () {
                                  _startPayment();
                                },
                              ),
                            _buildModernActionButton(
                              icon: Icons.settings_rounded,
                              label: 'Manage',
                              color: themeColor,
                              isActive: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageRequestsScreen(
                                      gameData: widget.gameData,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildModernActionButton(
                              icon: Icons.arrow_forward_rounded,
                              label: 'All Players',
                              color: Colors.orange.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageRequestsScreen(
                                      gameData: widget.gameData,
                                      showAllPlayers: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isProcessingPayment)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.7),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing Payment...',
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
          ),
      ],
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color.withOpacity(0.3) : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? color : Colors.grey.shade700,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? color : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
