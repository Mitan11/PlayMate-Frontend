import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: January 17, 2026',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              '1. Introduction',
              'Welcome to PlayMate. We value your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our application.',
            ),

            _buildSection(
              '2. Information We Collect',
              'We collect information used to facilitate sports activities and social connections, including:\n\n• Personal identification (Name, Email, Phone Number)\n• Profile information (Sports interests, skill levels, profile photo)\n• Location data (to find nearby players and events)\n• Device information (for app functionality and security)',
            ),

            _buildSection(
              '3. How We Use Your Information',
              'Your data is primarily used to:\n\n• Connect you with other players and sports events.\n• Facilitate communication between users.\n• Improve our app functionality and user experience.\n• Ensure the security of our platform.',
            ),

            _buildSection(
              '4. Data Sharing',
              'We do not sell your personal data. Your information is only shared with other users to the extent necessary to arrange sports activities (e.g., showing your name and sports interests on your profile).',
            ),

            _buildSection(
              '5. Your Rights',
              'You have the right to access, update, or delete your personal information. You can manage your profile settings directly within the app or contact support for assistance.',
            ),

            _buildSection(
              '6. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at privacy@playmate.com.',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
