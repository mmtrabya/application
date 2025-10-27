// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  String name;
  String email;
  String phone;
  String address;
  String? nationalId;
  bool isVerified;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    this.nationalId,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'nationalId': nationalId,
    'isVerified': isVerified,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    nationalId: json['nationalId'],
    isVerified: json['isVerified'] ?? false,
  );
}

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool('isAuthenticated') ?? false;

    if (isAuth) {
      _isAuthenticated = true;
      _user = UserModel(
        name: prefs.getString('userName') ?? '',
        email: prefs.getString('userEmail') ?? '',
        phone: prefs.getString('userPhone') ?? '',
        address: prefs.getString('userAddress') ?? '',
        nationalId: prefs.getString('userNationalId'),
        isVerified: prefs.getBool('isVerified') ?? false,
      );
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _user = UserModel(
      name: name,
      email: email,
      phone: phone,
    );

    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPhone', phone);

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    _isAuthenticated = true;
    await loadUser();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (_user == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      _user!.name = name;
      await prefs.setString('userName', name);
    }
    if (email != null) {
      _user!.email = email;
      await prefs.setString('userEmail', email);
    }
    if (phone != null) {
      _user!.phone = phone;
      await prefs.setString('userPhone', phone);
    }
    if (address != null) {
      _user!.address = address;
      await prefs.setString('userAddress', address);
    }

    notifyListeners();
  }

  Future<void> completeVerification(String nationalId) async {
    if (_user == null) return;

    final prefs = await SharedPreferences.getInstance();
    _user!.nationalId = nationalId;
    _user!.isVerified = true;

    await prefs.setString('userNationalId', nationalId);
    await prefs.setBool('isVerified', true);

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}