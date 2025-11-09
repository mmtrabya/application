// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/firebase_service.dart';

class UserModel {
  String userId;
  String name;
  String email;
  String phone;
  String address;
  String? nationalId;
  String? nationalIdFrontUrl;
  String? nationalIdBackUrl;
  String? drivingLicenseUrl;
  bool isVerified;
  String verificationStatus;
  int totalRides;
  double totalSpent;
  double rating;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    this.nationalId,
    this.nationalIdFrontUrl,
    this.nationalIdBackUrl,
    this.drivingLicenseUrl,
    this.isVerified = false,
    this.verificationStatus = 'pending',
    this.totalRides = 0,
    this.totalSpent = 0.0,
    this.rating = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'nationalId': nationalId,
    'nationalIdFrontUrl': nationalIdFrontUrl,
    'nationalIdBackUrl': nationalIdBackUrl,
    'drivingLicenseUrl': drivingLicenseUrl,
    'isVerified': isVerified,
    'verificationStatus': verificationStatus,
    'totalRides': totalRides,
    'totalSpent': totalSpent,
    'rating': rating,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    nationalId: json['nationalId'],
    nationalIdFrontUrl: json['nationalIdFrontUrl'],
    nationalIdBackUrl: json['nationalIdBackUrl'],
    drivingLicenseUrl: json['drivingLicenseUrl'],
    isVerified: json['isVerified'] ?? false,
    verificationStatus: json['verificationStatus'] ?? 'pending',
    totalRides: json['totalRides'] ?? 0,
    totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
    rating: (json['rating'] ?? 0.0).toDouble(),
  );
}

class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  /// Initialize and load user data
  Future<void> loadUser() async {
    try {
      final User? currentUser = _firebaseService.getCurrentUser();

      if (currentUser != null) {
        // Fetch user data from Firestore
        final userData = await _firebaseService.getUserData(currentUser.uid);

        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isAuthenticated = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;

    try {
      final User? user = await _firebaseService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (user != null) {
        // Fetch created user data
        final userData = await _firebaseService.getUserData(user.uid);

        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      _isLoading = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _isLoading = true;

    try {
      final User? user = await _firebaseService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        // Fetch user data
        final userData = await _firebaseService.getUserData(user.uid);

        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      _isLoading = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (_user == null) return;

    try {
      await _firebaseService.updateUserProfile(
        userId: _user!.userId,
        name: name,
        phone: phone,
        address: address,
      );

      // Update local user model
      if (name != null) _user!.name = name;
      if (email != null) _user!.email = email;
      if (phone != null) _user!.phone = phone;
      if (address != null) _user!.address = address;

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload ID verification documents
  Future<void> uploadVerificationDocuments({
    required String nationalId,
    required File nationalIdFront,
    required File nationalIdBack,
    required File drivingLicense,
  }) async {
    if (_user == null) return;

    try {
      // Upload documents to Firebase Storage
      final String frontUrl = await _firebaseService.uploadIdDocument(
        userId: _user!.userId,
        file: nationalIdFront,
        documentType: 'national_id_front',
      );

      final String backUrl = await _firebaseService.uploadIdDocument(
        userId: _user!.userId,
        file: nationalIdBack,
        documentType: 'national_id_back',
      );

      final String licenseUrl = await _firebaseService.uploadIdDocument(
        userId: _user!.userId,
        file: drivingLicense,
        documentType: 'driving_license',
      );

      // Submit verification
      await _firebaseService.submitVerification(
        userId: _user!.userId,
        nationalId: nationalId,
        nationalIdFrontUrl: frontUrl,
        nationalIdBackUrl: backUrl,
        drivingLicenseUrl: licenseUrl,
      );

      // Update local user model
      _user!.nationalId = nationalId;
      _user!.nationalIdFrontUrl = frontUrl;
      _user!.nationalIdBackUrl = backUrl;
      _user!.drivingLicenseUrl = licenseUrl;
      _user!.verificationStatus = 'pending';

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Complete verification (for backward compatibility)
  Future<void> completeVerification(String nationalId) async {
    if (_user == null) return;

    try {
      _user!.nationalId = nationalId;
      _user!.verificationStatus = 'pending';
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _firebaseService.signOut();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh user data from Firebase
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      final userData = await _firebaseService.getUserData(_user!.userId);

      if (userData != null) {
        _user = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }
}