import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.white,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        error: AppColors.error,
        surface: AppColors.white,
      ),

      // Typography
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Anta', fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Anta', fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: 'Anta', fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Anta', fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Anta', fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Anta', fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Anta', fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Anta', fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: 'Anta', fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14),
        bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12),
      ),

      // Component Themes
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
