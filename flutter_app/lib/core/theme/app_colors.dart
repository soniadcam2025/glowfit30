import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Pink
  static const Color primary = Color(0xFFFF6B8A);
  static const Color primaryDark = Color(0xFFFF4060);
  static const Color primaryLight = Color(0xFFFF9EAD);

  // Secondary - Coral
  static const Color secondary = Color(0xFFFF9B6B);
  static const Color secondaryDark = Color(0xFFFF7A42);

  // Accent - Gold
  static const Color accent = Color(0xFFFFD166);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8CC);
  static const Color textTertiary = Color(0xFF7B7B9E);
  static const Color textDisabled = Color(0xFF4A4A6A);

  // Backgrounds
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF252540);
  static const Color surfaceHigh = Color(0xFF303050);

  // State
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF29B6F6);

  // Border & Divider
  static const Color border = Color(0xFF2A2A45);
  static const Color divider = Color(0xFF1E1E35);

  // Overlay
  static const Color overlay = Color(0x1AFFFFFF);
  static const Color overlayDark = Color(0x80000000);

  // Gradients
  static const List<Color> gradientPrimary = [
    Color(0xFFFF6B8A),
    Color(0xFFFF4060),
  ];

  static const List<Color> gradientSecondary = [
    Color(0xFFFF9B6B),
    Color(0xFFFF7A42),
  ];

  static const List<Color> gradientSplash = [
    Color(0xFF1C0B25),
    Color(0xFF2E1040),
    Color(0xFF1C0B25),
  ];

  static const List<Color> gradientCard = [
    Color(0xFF1A1A2E),
    Color(0xFF252540),
  ];
}
