import 'package:flutter/material.dart';

class AppColors {
  // Primary Lime Green
  static const Color primaryLime = Color(0xFFD6FF3F);
  static const Color secondaryLime = Color(0xFFBFE830);
  static const Color tertiaryLime = Color(0xFFA8D121);

  // Background Colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Status Colors
  static const Color success = Colors.green;
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Colors.amber;

  // Gradients
  static const LinearGradient limeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLime, secondaryLime, tertiaryLime],
  );

  static LinearGradient limeGradientWithOpacity(double opacity) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryLime.withOpacity(opacity * 0.9),
        secondaryLime.withOpacity(opacity * 0.8),
        tertiaryLime.withOpacity(opacity * 0.7),
      ],
    );
  }
}