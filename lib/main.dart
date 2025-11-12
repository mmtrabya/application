// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme/app_theme.dart';
import 'config/api_config.dart';
import 'config/firebase_config.dart';
import 'providers/user_provider.dart';
import 'providers/booking_provider.dart'; // ← ADD THIS
import 'services/firebase_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/sign_in_page.dart';
import 'features/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  // Check Google Maps API
  if (!ApiConfig.isApiKeyConfigured) {
    debugPrint('⚠️  WARNING: Google Maps API key is not configured!');
    debugPrint('📝 Add your key to lib/config/api_config.dart');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    // ✅ ADD MultiProvider to register multiple providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()), // ← ADD THIS
      ],
      child: const SmartCityTransportApp(),
    ),
  );
}

class SmartCityTransportApp extends StatefulWidget {
  const SmartCityTransportApp({Key? key}) : super(key: key);

  @override
  State<SmartCityTransportApp> createState() => _SmartCityTransportAppState();
}

class _SmartCityTransportAppState extends State<SmartCityTransportApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _showSplash = true;
  bool _isInitialized = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Load user data from Firebase
      await Provider.of<UserProvider>(context, listen: false).loadUser();

      // Setup FCM if user is authenticated
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isAuthenticated && userProvider.user != null) {
        await _setupFCM(userProvider.user!.userId);
      }

      // Show splash screen for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _showSplash = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _showSplash = false;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _setupFCM(String userId) async {
    try {
      // Request notification permission
      await _firebaseService.messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      final String? token = await _firebaseService.getFCMToken();

      if (token != null) {
        // Save token to user document
        await _firebaseService.saveFCMToken(userId, token);
        debugPrint('✅ FCM Token saved: ${token.substring(0, 20)}...');
      }

      // Listen for token refresh
      _firebaseService.messaging.onTokenRefresh.listen((newToken) {
        _firebaseService.saveFCMToken(userId, newToken);
      });
    } catch (e) {
      debugPrint('Error setting up FCM: $e');
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kynetic SDV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme().copyWith(
        textTheme: AppTheme.lightTheme().textTheme.apply(
          fontFamily: 'Inter',
        ),
      ),
      darkTheme: AppTheme.darkTheme().copyWith(
        textTheme: AppTheme.darkTheme().textTheme.apply(
          fontFamily: 'Inter',
        ),
      ),
      themeMode: _themeMode,
      home: _showSplash
          ? const SplashScreen()
          : Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (!_isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return userProvider.isAuthenticated
              ? HomePage(onThemeToggle: _toggleTheme)
              : const SignInPage();
        },
      ),
      routes: {
        '/home': (context) => HomePage(onThemeToggle: _toggleTheme),
        '/signin': (context) => const SignInPage(),
      },
    );
  }
}