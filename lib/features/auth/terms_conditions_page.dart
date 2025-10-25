import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing and using Smart City Transport application, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildSection(
              '2. Use of Service',
              'You agree to use our autonomous vehicle ride-hailing service only for lawful purposes and in accordance with these Terms.',
            ),
            _buildSection(
              '3. User Accounts',
              'When you create an account with us, you must provide accurate, complete, and current information. Failure to do so constitutes a breach of the Terms.',
            ),
            _buildSection(
              '4. Ride Booking',
              'All ride bookings are subject to availability. We reserve the right to refuse service for any reason.',
            ),
            _buildSection(
              '5. Payment Terms',
              'You agree to pay all fees and charges incurred in connection with your use of the Service.',
            ),
            _buildSection(
              '6. Safety and Conduct',
              'Users must comply with all safety instructions provided by our autonomous vehicles. Any misuse or damage to vehicles will result in account termination and potential legal action.',
            ),
            _buildSection(
              '7. Privacy Policy',
              'Your use of the Service is also governed by our Privacy Policy, which is incorporated into these Terms by reference.',
            ),
            _buildSection(
              '8. Limitation of Liability',
              'Smart City Transport shall not be liable for any indirect, incidental, special, consequential, or punitive damages.',
            ),
            _buildSection(
              '9. Changes to Terms',
              'We reserve the right to modify these Terms at any time. Continued use of the Service after changes constitutes acceptance of the modified Terms.',
            ),
            _buildSection(
              '10. Contact Us',
              'If you have any questions about these Terms, please contact us at support@smartcitytransport.com',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}