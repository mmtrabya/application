import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme/app_theme.dart';
import 'config/api_config.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/sign_in_page.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate API key configuration (optional - remove in production)
  if (!ApiConfig.isApiKeyConfigured) {
    debugPrint('⚠️  WARNING: Google Maps API key is not configured!');
    debugPrint('📝 Build with: flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Changed to light for dark splash
    ),
  );

  runApp(const SmartCityTransportApp());
}

class SmartCityTransportApp extends StatefulWidget {
  const SmartCityTransportApp({Key? key}) : super(key: key);

  @override
  State<SmartCityTransportApp> createState() => _SmartCityTransportAppState();
}

class _SmartCityTransportAppState extends State<SmartCityTransportApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _showSplash = true;
  bool _isAuthenticated = false; // Set to false to show sign-in first

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Widget _getInitialPage() {
    if (_showSplash) {
      return const SplashScreen();
    }
    if (!_isAuthenticated) {
      return const SignInPage();
    }
    return HomePage(onThemeToggle: _toggleTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City Transport',
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
      home: _getInitialPage(),
      routes: {
        '/home': (context) => HomePage(onThemeToggle: _toggleTheme),
        '/signin': (context) => const SignInPage(),
      },
    );
  }
}