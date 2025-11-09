import 'package:flutter/material.dart';

class AppColors {
  // Primary Red (#ab0f0f)
  static const Color primaryRed = Color(0xFFAB0F0F);
  static const Color secondaryRed = Color(0xFFD32F2F);
  static const Color tertiaryRed = Color(0xFFE53935);
  static const Color darkRed = Color(0xFF8B0000);

  // Background Colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, secondaryRed, tertiaryRed],
  );

  static LinearGradient redGradientWithOpacity(double opacity) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryRed.withOpacity(opacity * 0.9),
        secondaryRed.withOpacity(opacity * 0.8),
        tertiaryRed.withOpacity(opacity * 0.7),
      ],
    );
  }

  // Dark mode gradient
  static const LinearGradient darkRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkRed, primaryRed, secondaryRed],
  );
}