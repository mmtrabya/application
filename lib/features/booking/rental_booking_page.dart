// lib/features/booking/rental_booking_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';

class RentalBookingPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const RentalBookingPage({Key? key, required this.onThemeToggle}) : super(key: key);

  @override
  State<RentalBookingPage> createState() => _RentalBookingPageState();
}

class _RentalBookingPageState extends State<RentalBookingPage> {
  String? _selectedVehicleId;
  String? _unlockCode;
  bool _isBooking = false;
  bool _showUnlockCode = false;

  Future<void> _bookVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (!userProvider.isAuthenticated || userProvider.user == null) {
      _showError('Please sign in to book a vehicle');
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Create booking
      final bookingId = await bookingProvider.createBooking(
        userId: userProvider.user!.userId,
        vehicleId: vehicleId,
        pickupLocation: {
          'latitude': 30.0444,
          'longitude': 31.2357,
        },
        dropoffLocation: {},
        estimatedPrice: 15.0,
        estimatedDistance: 0.0,
        estimatedDuration: 0,
      );

      // Get unlock code from created booking
      final booking = bookingProvider.currentBooking;
      if (booking != null) {
        setState(() {
          _unlockCode = booking.unlockCode;
          _showUnlockCode = true;
        });

        _showUnlockDialog();
      }
    } catch (e) {
      _showError('Booking failed: $e');
    } finally {
      setState(() => _isBooking = false);
    }
  }

  void _showUnlockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Vehicle Booked!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your autonomous vehicle is reserved!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Unlock Code:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: SelectableText(
                _unlockCode ?? '----',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _unlockCode ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Copy code',
                ),
                const SizedBox(width: 8),
                const Text('Tap to copy', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code expires in 15 minutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter this code on the vehicle touchscreen to unlock and start your ride',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Autonomous Vehicle'),
        actions: [
          if (_showUnlockCode)
            IconButton(
              icon: const Icon(Icons.key),
              onPressed: _showUnlockDialog,
              tooltip: 'Show unlock code',
            ),
        ],
      ),
      body: Center(
        child: _isBooking
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () => _bookVehicle('SDV_001'),
          child: const Text('Book Vehicle'),
        ),
      ),
    );
  }
}