// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up new user
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'userId': credential.user!.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'isVerified': false,
      'verificationStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential.user;
  }
}