// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'config/api_config.dart';
import 'providers/user_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/sign_in_page.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
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

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Load user data from SharedPreferences
    await Provider.of<UserProvider>(context, listen: false).loadUser();

    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _showSplash = false;
        _isInitialized = true;
      });
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