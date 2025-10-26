import 'package:flutter/material.dart';
import '../about/about_page.dart';
import 'edit_profile_page.dart';
import 'payment_cards_page.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onThemeToggle;
  const ProfilePage({Key? key, required this.onThemeToggle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'john.doe@email.com',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '+1 (555) 123-4567',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Account'),
          _buildMenuItem(
            context,
            Icons.credit_card,
            'Payment Methods',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentCardsPage()),
              );
            },
          ),
          _buildMenuItem(context, Icons.history, 'Rental History', () {}),
          _buildMenuItem(context, Icons.favorite, 'Favorite Vehicles', () {}),
          const SizedBox(height: 24),
          _buildSectionTitle('Preferences'),
          _buildMenuItemWithSwitch(
            context,
            Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
            'Dark Mode',
            Theme.of(context).brightness == Brightness.dark,
                (value) => onThemeToggle(),
          ),
          _buildMenuItem(context, Icons.notifications, 'Notifications', () {}),
          _buildMenuItem(context, Icons.language, 'Language', () {}),
          const SizedBox(height: 24),
          _buildSectionTitle('Support'),
          _buildMenuItem(context, Icons.help, 'Help Center', () {}),
          _buildMenuItem(
            context,
            Icons.info,
            'About',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
          _buildMenuItem(context, Icons.privacy_tip, 'Privacy Policy', () {}),
          const SizedBox(height: 24),
          Card(
            color: Colors.red.withValues(alpha: 0.1),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Smart City Transport v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontFamily: 'Inter')),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuItemWithSwitch(BuildContext context, IconData icon, String title, bool value, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontFamily: 'Inter')),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}