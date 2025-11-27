// lib/features/booking/rental_booking_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import 'active_trip_page.dart';

class RentalBookingPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const RentalBookingPage({Key? key, required this.onThemeToggle}) : super(key: key);

  @override
  State<RentalBookingPage> createState() => _RentalBookingPageState();
}

class _RentalBookingPageState extends State<RentalBookingPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation; // ✅ Nullable - no default location
  Set<Marker> _markers = {};
  List<VehicleModel> _nearbyVehicles = [];
  bool _isLoadingLocation = true;
  bool _isLoadingVehicles = false;
  bool _isBooking = false;
  String? _unlockCode;
  VehicleModel? _selectedVehicle;
  bool _showList = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _isLoadingLocation = false;
        });
        _showLocationServicesDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        _showPermissionDeniedDialog();
        return;
      }

      // Get current position with timeout
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      debugPrint('✅ User location: ${position.latitude}, ${position.longitude}');

      // Move camera to user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );

      // Load nearby vehicles
      await _loadNearbyVehicles();
    } on TimeoutException {
      setState(() {
        _locationError = 'Location request timed out';
        _isLoadingLocation = false;
      });
      if (mounted) {
        _showErrorSnackbar('Unable to get location. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      setState(() {
        _locationError = e.toString();
        _isLoadingLocation = false;
      });
      if (mounted) {
        _showErrorSnackbar('Failed to get your location: ${e.toString()}');
      }
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to find nearby vehicles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to find nearby vehicles. Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _initializeLocation,
        ),
      ),
    );
  }

  Future<void> _loadNearbyVehicles() async {
    if (_currentLocation == null) {
      debugPrint('⚠️ Cannot load vehicles - location not available');
      return;
    }

    setState(() => _isLoadingVehicles = true);

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.loadNearbyVehicles(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: 10.0,
      );

      setState(() {
        _nearbyVehicles = bookingProvider.nearbyVehicles;
      });

      _updateMapMarkers();

      if (_nearbyVehicles.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No vehicles available nearby. Try expanding search radius.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading vehicles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingVehicles = false);
    }
  }

  void _updateMapMarkers() {
    if (_currentLocation == null) return;

    final Set<Marker> markers = {};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add vehicle markers
    for (var vehicle in _nearbyVehicles) {
      if (vehicle.location != null) {
        final lat = vehicle.location!['latitude'] as double;
        final lng = vehicle.location!['longitude'] as double;

        markers.add(
          Marker(
            markerId: MarkerId(vehicle.vehicleId),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: vehicle.model,
              snippet: '${vehicle.batteryLevel}% • \$${vehicle.pricePerHour}/hr',
            ),
            onTap: () {
              setState(() {
                _selectedVehicle = vehicle;
                _showList = false;
              });
              _showVehicleDetails(vehicle);
            },
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  void _showVehicleDetails(VehicleModel vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.electric_car,
                    size: 40,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.licensePlate} • ${vehicle.color}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.distance?.toStringAsFixed(1) ?? "0.0"} km away',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSpecItem(
                    Icons.battery_charging_full,
                    '${vehicle.batteryLevel}%',
                    'Battery',
                  ),
                ),
                Expanded(
                  child: _buildSpecItem(
                    Icons.airline_seat_recline_normal,
                    '${vehicle.seats}',
                    'Seats',
                  ),
                ),
                Expanded(
                  child: _buildSpecItem(
                    Icons.speed,
                    '${vehicle.range.toInt()} km',
                    'Range',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hourly Rate',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '\$${vehicle.pricePerHour.toStringAsFixed(2)}/hr',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Per Kilometer',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '\$${vehicle.pricePerKm.toStringAsFixed(2)}/km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _bookVehicle(vehicle);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Book This Vehicle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _bookVehicle(VehicleModel vehicle) async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable location services.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (!userProvider.isAuthenticated || userProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to book a vehicle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
      _selectedVehicle = vehicle;
    });

    try {
      final bookingId = await bookingProvider.createBooking(
        userId: userProvider.user!.userId,
        vehicleId: vehicle.vehicleId,
        pickupLocation: {
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
        },
        dropoffLocation: {},
        estimatedPrice: vehicle.pricePerHour,
        estimatedDistance: vehicle.distance ?? 0.0,
        estimatedDuration: 0,
      );

      final booking = bookingProvider.currentBooking;
      if (booking != null) {
        setState(() => _unlockCode = booking.unlockCode);
        if (mounted) {
          _showUnlockDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter this code on the vehicle\'s infotainment screen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ✅ Navigate to Active Trip Screen
              final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
              if (bookingProvider.currentBooking != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveTripPage(
                      booking: bookingProvider.currentBooking!,
                    ),
                  ),
                );
              }
            },
            child: const Text('View Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleListItem(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showVehicleDetails(vehicle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
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
                  Icons.electric_car,
                  size: 30,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.battery_charging_full,
                          size: 16,
                          color: vehicle.batteryLevel > 50 ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.batteryLevel}%',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.distance?.toStringAsFixed(1) ?? "0.0"} km',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    '\$${vehicle.pricePerHour.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Text(
                    'per hour',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Vehicle'),
        actions: [
          if (_currentLocation != null) ...[
            IconButton(
              icon: Icon(_showList ? Icons.map : Icons.list),
              onPressed: () => setState(() => _showList = !_showList),
              tooltip: _showList ? 'Map View' : 'List View',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoadingVehicles ? null : _loadNearbyVehicles,
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
      body: _isLoadingLocation
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      )
          : _currentLocation == null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Location Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _locationError ?? 'Unable to access your location',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _initializeLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          if (!_showList)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 14),
                );
              },
            )
          else
            _nearbyVehicles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.car_rental,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No vehicles available nearby',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try adjusting your location or check back later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadNearbyVehicles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.electric_car,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_nearbyVehicles.length} Vehicles Available',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Near your location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._nearbyVehicles.map(
                      (vehicle) => _buildVehicleListItem(vehicle),
                ),
              ],
            ),
          if (_isLoadingVehicles || _isBooking)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isBooking
                          ? 'Booking vehicle...'
                          : 'Loading vehicles...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}