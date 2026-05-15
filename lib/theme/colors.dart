import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color harvestGold = Color(0xFFF9C74F);
  static const Color sproutGreen = Color(0xFF90BE6D);
  static const Color lightMint = Color(0xFFD8F3DC);

  // Light Mode
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: forestGreen,
    primary: forestGreen,
    secondary: const Color(0xFF9A8300), // Slightly darkened gold for contrast
    surface: const Color(0xFFF8FAF7),
    onSurface: const Color(0xFF191C1A),
  );

  // Dark Mode
  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: forestGreen,
    brightness: Brightness.dark,
    primary: const Color(0xFF95D5B2),
    secondary: harvestGold,
    surface: const Color(0xFF1A1C1A),
  );
}
