import 'package:flutter/material.dart';

class AppIcons {
  /// Returns the correct Home icon depending on current theme
  static String home(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return brightness == Brightness.light
        ? 'assets/icons/home.png'
        : 'assets/icons/home.png';
  }
}