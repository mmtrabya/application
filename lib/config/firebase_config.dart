// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Web Configuration
  static const String webApiKey = "AIzaSyDPEAz-ao5mRfyLRwf4VtYjsiiiYat5Hfs";
  static const String authDomain = "sdv-ota-system.firebaseapp.com";
  static const String databaseURL = "https://sdv-ota-system-default-rtdb.europe-west1.firebasedatabase.app";
  static const String projectId = "sdv-ota-system";
  static const String storageBucket = "sdv-ota-system.firebasestorage.app";
  static const String messagingSenderId = "406514704389";
  static const String webAppId = "1:406514704389:web:e200a58f5738349ec3fc6c";
  static const String measurementId = "G-87QXNM347P";

  // Android Configuration (from your google-services.json)
  static const String androidApiKey = "AIzaSyDPEAz-ao5mRfyLRwf4VtYjsiiiYat5Hfs"; // Replace with actual Android API key
  static const String androidAppId = "1:406514704389:android:YOUR_ANDROID_APP_ID"; // Replace with actual Android app ID

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'FirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: webApiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: webAppId,
    measurementId: measurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: androidApiKey, // Use Android-specific API key
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: androidAppId, // Use Android app ID
    measurementId: measurementId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: webApiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: '1:406514704389:ios:YOUR_IOS_APP_ID',
    iosClientId: '406514704389-yourios.apps.googleusercontent.com',
    iosBundleId: 'com.kynetic.sdv',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: webApiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: '1:406514704389:ios:YOUR_IOS_APP_ID',
    iosClientId: '406514704389-yourios.apps.googleusercontent.com',
    iosBundleId: 'com.kynetic.sdv',
  );
}