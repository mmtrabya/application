import 'package:flutter/material.dart';
import '../../core/widgets/gradient_container.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GradientContainer(
              padding: const EdgeInsets.all(32),
              child: const Icon(Icons.directions_car, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Smart City Transport',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Our Mission',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To revolutionize urban transportation through autonomous Software-Defined Vehicles (SDVs), making cities smarter, safer, and more sustainable.',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Technology',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(Icons.smart_toy, 'AI-Powered ADAS', 'Advanced Driver Assistance System'),
                    _buildFeature(Icons.security, 'Cybersecurity', 'End-to-end encryption'),
                    _buildFeature(Icons.wifi, 'V2X Communication', 'Vehicle-to-Everything connectivity'),
                    _buildFeature(Icons.update, 'FOTA/SOTA', 'Over-the-air updates'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(Icons.email, 'support@smartcitytransport.com'),
                    _buildContactItem(Icons.phone, '+1 (555) 123-4567'),
                    _buildContactItem(Icons.language, 'www.smartcitytransport.com'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '© 2025 Smart City Transport. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD6FF3F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFD6FF3F)),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}