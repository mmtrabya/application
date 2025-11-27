import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseDatabase get database => _database;
  FirebaseMessaging get messaging => _messaging;

  // ==================== AUTHENTICATION ====================

  /// Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'isVerified': false,
          'verificationStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'totalRides': 0,
          'totalSpent': 0.0,
          'rating': 0.0,
        });

        return user;
      }
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
    return null;
  }

  /// Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // ==================== USER PROFILE ====================

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
    return null;
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;

      updates['lastActive'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ==================== ID VERIFICATION ====================

  /// Upload ID document
  Future<String> uploadIdDocument({
    required String userId,
    required File file,
    required String documentType,
  }) async {
    try {
      final String fileName = '${userId}_$documentType.jpg';
      final Reference ref = _storage.ref().child('ids/$fileName');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Submit verification documents
  Future<void> submitVerification({
    required String userId,
    required String nationalId,
    required String nationalIdFrontUrl,
    required String nationalIdBackUrl,
    required String drivingLicenseUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'nationalId': nationalId,
        'nationalIdFrontUrl': nationalIdFrontUrl,
        'nationalIdBackUrl': nationalIdBackUrl,
        'drivingLicenseUrl': drivingLicenseUrl,
        'verificationStatus': 'pending',
        'isVerified': false,
      });
    } catch (e) {
      throw Exception('Failed to submit verification: $e');
    }
  }

  // ==================== VEHICLES ====================

  /// Get all available vehicles
  Stream<QuerySnapshot> getAvailableVehicles() {
    return _firestore
        .collection('vehicles')
        .where('status', isEqualTo: 'available')
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  /// Get vehicle by ID
  Future<Map<String, dynamic>?> getVehicle(String vehicleId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('vehicles').doc(vehicleId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      throw Exception('Failed to get vehicle: $e');
    }
    return null;
  }

  /// Get vehicles near location
  Future<List<Map<String, dynamic>>> getNearbyVehicles({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('vehicles')
          .where('status', isEqualTo: 'available')
          .where('isOnline', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> nearbyVehicles = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final vehicleLocation = data['location'];

        if (vehicleLocation != null) {
          final double distance = _calculateDistance(
            latitude,
            longitude,
            vehicleLocation['latitude'],
            vehicleLocation['longitude'],
          );

          if (distance <= radiusInKm) {
            data['distance'] = distance;
            data['vehicleId'] = doc.id;
            nearbyVehicles.add(data);
          }
        }
      }

      nearbyVehicles.sort((a, b) => a['distance'].compareTo(b['distance']));

      return nearbyVehicles;
    } catch (e) {
      throw Exception('Failed to get nearby vehicles: $e');
    }
  }

  // ==================== BOOKINGS ====================

  /// Create a booking
  Future<String> createBooking({
    required String userId,
    required String vehicleId,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required double estimatedPrice,
    required double estimatedDistance,
    required int estimatedDuration,
  }) async {
    try {
      final String unlockCode = _generateUnlockCode();

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 15));

      final DocumentReference bookingRef = await _firestore.collection('bookings').add({
        'userId': userId,
        'vehicleId': vehicleId,
        'type': 'rental',
        'status': 'confirmed',
        'unlockCode': unlockCode,
        'codeExpiresAt': Timestamp.fromDate(expiresAt),
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'estimatedPrice': estimatedPrice,
        'estimatedDistance': estimatedDistance,
        'estimatedDuration': estimatedDuration,
        'createdAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending',
      });

      await _firestore.collection('vehicles').doc(vehicleId).update({
        'status': 'reserved',
        'currentBooking': {
          'bookingId': bookingRef.id,
          'userId': userId,
          'unlockCode': unlockCode,
          'status': 'confirmed',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(expiresAt),
        },
      });

      return bookingRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get user bookings
  Stream<QuerySnapshot> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get booking details
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
    return null;
  }

  /// Complete booking
  Future<void> completeBooking({
    required String bookingId,
    required double actualPrice,
    required double actualDistance,
    required int actualDuration,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'actualEndTime': FieldValue.serverTimestamp(),
        'actualPrice': actualPrice,
        'actualDistance': actualDistance,
        'actualDuration': actualDuration,
        'paymentStatus': 'completed',
      });
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      throw Exception('Failed to get FCM token: $e');
    }
  }

  /// Save FCM token to user document
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }

  // ==================== V2X DATA ====================

  /// Get V2X messages for vehicle
  Stream<DatabaseEvent> getV2XMessages(String vehicleId) {
    return _database.ref('v2x/messages/$vehicleId').onValue;
  }

  /// Get nearby hazards from V2X
  Future<List<Map<String, dynamic>>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusInKm = 1.0,
  }) async {
    try {
      final DatabaseEvent event = await _database.ref('v2x/hazards').once();
      final Map<dynamic, dynamic>? hazards = event.snapshot.value as Map<dynamic, dynamic>?;

      if (hazards == null) return [];

      final List<Map<String, dynamic>> nearbyHazards = [];

      hazards.forEach((key, value) {
        final hazard = Map<String, dynamic>.from(value as Map);
        final double distance = _calculateDistance(
          latitude,
          longitude,
          hazard['latitude'],
          hazard['longitude'],
        );

        if (distance <= radiusInKm) {
          hazard['distance'] = distance;
          hazard['hazardId'] = key;
          nearbyHazards.add(hazard);
        }
      });

      return nearbyHazards;
    } catch (e) {
      throw Exception('Failed to get nearby hazards: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Generate random 4-digit unlock code
  String _generateUnlockCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    return random.toString();
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.141592653589793 / 180;
  }
}