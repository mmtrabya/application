// lib/services/vehicle_service.dart
import 'package:geolocator/geolocator.dart';

class VehicleService {
  final FirebaseService _firebase = FirebaseService();

  /// Get nearby available vehicles
  Future<List<VehicleModel>> getNearbyVehicles() async {
    // Get current location from device GPS
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Query Firebase for nearby vehicles
    final vehicles = await _firebase.getNearbyVehicles(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInKm: 5.0,
    );

    return vehicles.map((v) => VehicleModel.fromMap(v)).toList();
  }

  /// Book a vehicle
  Future<String> bookVehicle({
    required String vehicleId,
    required String userId,
  }) async {
    final position = await Geolocator.getCurrentPosition();

    final bookingId = await _firebase.createBooking(
      userId: userId,
      vehicleId: vehicleId,
      pickupLocation: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      dropoffLocation: {}, // Can be set later
      estimatedPrice: 15.0,
      estimatedDistance: 0.0,
      estimatedDuration: 0,
    );

    return bookingId;
  }
}