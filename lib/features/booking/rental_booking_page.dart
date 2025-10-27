// lib/features/booking/rental_booking_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Remove lottie import to avoid Marker conflict
import '../../config/constants.dart';
import '../../core/utils/haptic_feedback.dart';

class RentalBookingPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const RentalBookingPage({Key? key, required this.onThemeToggle}) : super(key: key);

  @override
  State<RentalBookingPage> createState() => _RentalBookingPageState();
}

class _RentalBookingPageState extends State<RentalBookingPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final LatLng _currentLocation = const LatLng(30.0444, 31.2357);
  final Set<Marker> _markers = {};
  String? _selectedCarId;
  bool _isRenting = false;

  DateTime? _rentalStartTime;
  double _distanceTraveled = 0.0;
  Timer? _rentalTimer;

  static const double pricePerHour = 15.0;
  static const double pricePerKm = 0.5;

  final List<AutonomousVehicle> _nearbyVehicles = [
    AutonomousVehicle(
      id: 'AV001',
      model: 'City Cruiser',
      category: 'Compact',
      distance: 0.3,
      location: const LatLng(30.0454, 31.2367),
      pricePerHour: 15.0,
      batteryLevel: 85,
      seats: 4,
      color: 'Pearl White',
    ),
    AutonomousVehicle(
      id: 'AV002',
      model: 'Urban Elite',
      category: 'Premium',
      distance: 0.5,
      location: const LatLng(30.0434, 31.2347),
      pricePerHour: 25.0,
      batteryLevel: 92,
      seats: 5,
      color: 'Midnight Blue',
    ),
    AutonomousVehicle(
      id: 'AV003',
      model: 'Eco Glide',
      category: 'Economy',
      distance: 0.8,
      location: const LatLng(30.0464, 31.2377),
      pricePerHour: 12.0,
      batteryLevel: 78,
      seats: 4,
      color: 'Lime Green',
    ),
    AutonomousVehicle(
      id: 'AV004',
      model: 'Executive Pro',
      category: 'Luxury',
      distance: 1.2,
      location: const LatLng(30.0424, 31.2387),
      pricePerHour: 35.0,
      batteryLevel: 95,
      seats: 6,
      color: 'Carbon Black',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    for (var vehicle in _nearbyVehicles) {
      _markers.add(
        Marker(
          markerId: MarkerId(vehicle.id),
          position: vehicle.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: vehicle.model,
            snippet: '${vehicle.distance} km • \$${vehicle.pricePerHour}/hr',
          ),
          onTap: () => _selectVehicle(vehicle.id),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rentalTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _selectVehicle(String carId) {
    setState(() {
      _selectedCarId = carId;
    });
  }

  void _startRental() {
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    AppHaptics.heavy();
    setState(() {
      _isRenting = true;
      _rentalStartTime = DateTime.now();
      _distanceTraveled = 0.0;
    });

    _rentalTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isRenting) {
        setState(() {
          _distanceTraveled += 0.2;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚗 Rental started! Enjoy your autonomous ride'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _endRental() {
    if (!_isRenting) return;

    AppHaptics.heavy();
    _rentalTimer?.cancel();

    final duration = DateTime.now().difference(_rentalStartTime!);
    final hours = duration.inMinutes / 60;
    final totalCost = (hours * pricePerHour) + (_distanceTraveled * pricePerKm);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Rental Summary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Duration', '${duration.inMinutes} minutes'),
            _buildSummaryRow('Distance', '${_distanceTraveled.toStringAsFixed(2)} km'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isRenting = false;
                _selectedCarId = null;
                _rentalStartTime = null;
                _distanceTraveled = 0.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Complete Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rent Autonomous Vehicle',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onTap: (_) => setState(() => _selectedCarId = null),
          ),
          if (_isRenting) _buildRentalStatus(),
          if (!_isRenting) _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildRentalStatus() {
    final duration = _rentalStartTime != null
        ? DateTime.now().difference(_rentalStartTime!)
        : Duration.zero;
    final hours = duration.inMinutes / 60;
    final currentCost = (hours * pricePerHour) + (_distanceTraveled * pricePerKm);

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'RENTAL IN PROGRESS',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem('${duration.inMinutes}', 'Minutes', Icons.access_time),
                _buildStatusItem(_distanceTraveled.toStringAsFixed(1), 'KM', Icons.route),
                _buildStatusItem('\$${currentCost.toStringAsFixed(2)}', 'Cost', Icons.attach_money),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _endRental,
              icon: const Icon(Icons.stop_circle),
              label: const Text('End Rental'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Available Vehicles Nearby',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              ..._nearbyVehicles.map((vehicle) => _buildVehicleCard(vehicle)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(AutonomousVehicle vehicle) {
    final isSelected = _selectedCarId == vehicle.id;

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        _selectVehicle(vehicle.id);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(vehicle.location),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          )
              : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.electric_car_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.model,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              vehicle.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${vehicle.distance} km',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${vehicle.pricePerHour}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Text(
                      'per hour',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVehicleInfo(Icons.battery_charging_full, '${vehicle.batteryLevel}%', Colors.green),
                const SizedBox(width: 16),
                _buildVehicleInfo(Icons.airline_seat_recline_normal, '${vehicle.seats} seats', Colors.blue),
                const SizedBox(width: 16),
                _buildVehicleInfo(Icons.palette, vehicle.color, Colors.purple),
                const Spacer(),
                if (isSelected)
                  ElevatedButton.icon(
                    onPressed: _startRental,
                    icon: const Icon(Icons.key, size: 18),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
      ],
    );
  }
}

class AutonomousVehicle {
  final String id;
  final String model;
  final String category;
  final double distance;
  final LatLng location;
  final double pricePerHour;
  final int batteryLevel;
  final int seats;
  final String color;

  AutonomousVehicle({
    required this.id,
    required this.model,
    required this.category,
    required this.distance,
    required this.location,
    required this.pricePerHour,
    required this.batteryLevel,
    required this.seats,
    required this.color,
  });
}