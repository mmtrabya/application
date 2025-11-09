import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class BookingModel {
  String bookingId;
  String userId;
  String vehicleId;
  String type;
  String status;
  String unlockCode;
  DateTime? codeExpiresAt;
  Map<String, dynamic> pickupLocation;
  Map<String, dynamic> dropoffLocation;
  double estimatedPrice;
  double estimatedDistance;
  int estimatedDuration;
  double? actualPrice;
  double? actualDistance;
  int? actualDuration;
  DateTime? createdAt;
  DateTime? actualStartTime;
  DateTime? actualEndTime;
  String paymentStatus;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.vehicleId,
    required this.type,
    required this.status,
    required this.unlockCode,
    this.codeExpiresAt,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.estimatedPrice,
    required this.estimatedDistance,
    required this.estimatedDuration,
    this.actualPrice,
    this.actualDistance,
    this.actualDuration,
    this.createdAt,
    this.actualStartTime,
    this.actualEndTime,
    this.paymentStatus = 'pending',
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      type: data['type'] ?? 'rental',
      status: data['status'] ?? 'pending',
      unlockCode: data['unlockCode'] ?? '',
      codeExpiresAt: (data['codeExpiresAt'] as Timestamp?)?.toDate(),
      pickupLocation: data['pickupLocation'] ?? {},
      dropoffLocation: data['dropoffLocation'] ?? {},
      estimatedPrice: (data['estimatedPrice'] ?? 0.0).toDouble(),
      estimatedDistance: (data['estimatedDistance'] ?? 0.0).toDouble(),
      estimatedDuration: data['estimatedDuration'] ?? 0,
      actualPrice: (data['actualPrice'] as num?)?.toDouble(),
      actualDistance: (data['actualDistance'] as num?)?.toDouble(),
      actualDuration: data['actualDuration'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      actualStartTime: (data['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (data['actualEndTime'] as Timestamp?)?.toDate(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
    );
  }
}

class VehicleModel {
  String vehicleId;
  String model;
  String category;
  String licensePlate;
  String color;
  int year;
  int seats;
  double batteryCapacity;
  double range;
  String status;
  bool isOnline;
  int batteryLevel;
  Map<String, dynamic>? location;
  double pricePerHour;
  double pricePerKm;
  Map<String, dynamic>? versions;
  double? distance; // Calculated distance from user

  VehicleModel({
    required this.vehicleId,
    required this.model,
    required this.category,
    required this.licensePlate,
    required this.color,
    required this.year,
    required this.seats,
    required this.batteryCapacity,
    required this.range,
    required this.status,
    required this.isOnline,
    required this.batteryLevel,
    this.location,
    required this.pricePerHour,
    required this.pricePerKm,
    this.versions,
    this.distance,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VehicleModel(
      vehicleId: doc.id,
      model: data['model'] ?? '',
      category: data['category'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      color: data['color'] ?? '',
      year: data['year'] ?? 2024,
      seats: data['seats'] ?? 4,
      batteryCapacity: (data['batteryCapacity'] ?? 0.0).toDouble(),
      range: (data['range'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'available',
      isOnline: data['isOnline'] ?? false,
      batteryLevel: data['batteryLevel'] ?? 0,
      location: data['location'],
      pricePerHour: (data['pricePerHour'] ?? 15.0).toDouble(),
      pricePerKm: (data['pricePerKm'] ?? 0.5).toDouble(),
      versions: data['versions'],
      distance: (data['distance'] as num?)?.toDouble(),
    );
  }

  factory VehicleModel.fromMap(Map<String, dynamic> data) {
    return VehicleModel(
      vehicleId: data['vehicleId'] ?? '',
      model: data['model'] ?? '',
      category: data['category'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      color: data['color'] ?? '',
      year: data['year'] ?? 2024,
      seats: data['seats'] ?? 4,
      batteryCapacity: (data['batteryCapacity'] ?? 0.0).toDouble(),
      range: (data['range'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'available',
      isOnline: data['isOnline'] ?? false,
      batteryLevel: data['batteryLevel'] ?? 0,
      location: data['location'],
      pricePerHour: (data['pricePerHour'] ?? 15.0).toDouble(),
      pricePerKm: (data['pricePerKm'] ?? 0.5).toDouble(),
      versions: data['versions'],
      distance: (data['distance'] as num?)?.toDouble(),
    );
  }
}

class BookingProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<VehicleModel> _nearbyVehicles = [];
  List<BookingModel> _userBookings = [];
  BookingModel? _currentBooking;
  bool _isLoading = false;

  List<VehicleModel> get nearbyVehicles => _nearbyVehicles;
  List<BookingModel> get userBookings => _userBookings;
  BookingModel? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;

  /// Get nearby vehicles
  Future<void> loadNearbyVehicles({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vehicles = await _firebaseService.getNearbyVehicles(
        latitude: latitude,
        longitude: longitude,
        radiusInKm: radius,
      );

      _nearbyVehicles = vehicles.map((data) => VehicleModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error loading nearby vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a booking
  Future<String?> createBooking({
    required String userId,
    required String vehicleId,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required double estimatedPrice,
    required double estimatedDistance,
    required int estimatedDuration,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bookingId = await _firebaseService.createBooking(
        userId: userId,
        vehicleId: vehicleId,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        estimatedPrice: estimatedPrice,
        estimatedDistance: estimatedDistance,
        estimatedDuration: estimatedDuration,
      );

      // Load the created booking
      await loadBooking(bookingId);

      return bookingId;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a specific booking
  Future<void> loadBooking(String bookingId) async {
    try {
      final bookingData = await _firebaseService.getBooking(bookingId);

      if (bookingData != null) {
        _currentBooking = BookingModel.fromFirestore(
          await _firebaseService.firestore
              .collection('bookings')
              .doc(bookingId)
              .get(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading booking: $e');
    }
  }

  /// Load user bookings
  void listenToUserBookings(String userId) {
    _firebaseService.getUserBookings(userId).listen((snapshot) {
      _userBookings = snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  /// Complete a booking
  Future<void> completeBooking({
    required String bookingId,
    required double actualPrice,
    required double actualDistance,
    required int actualDuration,
  }) async {
    try {
      await _firebaseService.completeBooking(
        bookingId: bookingId,
        actualPrice: actualPrice,
        actualDistance: actualDistance,
        actualDuration: actualDuration,
      );

      _currentBooking = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing booking: $e');
      rethrow;
    }
  }

  /// Clear current booking
  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }
}