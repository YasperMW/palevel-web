import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF07746B);
  static const Color primaryLight = Color(0xFF0DDAC9);
  static const Color primaryDark = Color(0xFF055851); // Derived dark shade

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color transparent = Colors.transparent;

  // Semantic Colors
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color rating = Color(0xFFFFA000);
  static const Color info = Color(0xFF9C27B0); // Used for reviews/info cards

  // UI Specific Colors
  static Color glassBackground = Colors.white.withValues(alpha:0.2);
  static Color glassBorder = Colors.white.withValues(alpha:0.3);
  static Color shadow = Colors.black.withValues(alpha:0.05);

  // Gradient
  static const List<Color> mainGradient = [
    primary,
    primaryLight,
    white,
  ];

  static const List<Color> primaryGradient = [
    primary,
    primaryLight,
  ];

  static const List<Color> errorGradient = [
    Color(0xFFFF0000),
    Color(0xFF880808),
  ];
}
