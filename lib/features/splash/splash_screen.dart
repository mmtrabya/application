// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Splash logo path
  String get _splashLogo => 'assets/images/splash.svg';

  // Background color based on theme
  Color get _bgColor =>
      Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double size = constraints.maxWidth * 0.6; // 60% of screen width
              return SvgPicture.asset(
                _splashLogo,
                width: size,
                height: size,
                fit: BoxFit.contain, // keeps aspect ratio
              );
            },
          ),
        ),
      ),
    );
  }
}
