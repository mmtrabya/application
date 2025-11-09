import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const String apiKey = "AIzaSyDPEAz-ao5mRfyLRwf4VtYjsiiiYat5Hfs";
  static const String authDomain = "sdv-ota-system.firebaseapp.com";
  static const String databaseURL = "https://sdv-ota-system-default-rtdb.europe-west1.firebasedatabase.app";
  static const String projectId = "sdv-ota-system";
  static const String storageBucket = "sdv-ota-system.firebasestorage.app";
  static const String messagingSenderId = "406514704389";
  static const String appId = "1:406514704389:web:e200a58f5738349ec3fc6c";
  static const String measurementId = "G-87QXNM347P";

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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'FirebaseOptions have not been configured for Windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions have not been configured for Linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'FirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
    iosClientId: '406514704389-yourios.apps.googleusercontent.com',
    iosBundleId: 'com.example.sdvApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    databaseURL: databaseURL,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
    measurementId: measurementId,
    iosClientId: '406514704389-yourios.apps.googleusercontent.com',
    iosBundleId: 'com.example.sdvApplication',
  );
}