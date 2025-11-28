import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0A84FF); // modern blue
  static const Color primaryDark = Color(0xFF0060D1); // darker blue
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFFF2F4F7); // smoother modern grey
  static const Color textGrey = Color(0xFF7A7A7A);
  static const Color borderGrey = Color(0xFFE1E1E1);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      /// ------- COLOR SCHEME -------
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSurface: AppColors.black,
        // primary = main brand color
        // onPrimary = text/icon color that appears on top of primary
        // surface = background of cards/surfaces
      ),

      scaffoldBackgroundColor: AppColors.white,

      /// ------- APP BAR -------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white, // White AppBar
        foregroundColor: AppColors.black, // Black icons & title text
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.black,
          fontSize: 22,
          fontFamily: 'amaranth',
          fontWeight: FontWeight.w700,
        ),
      ),

      /// ------- BUTTONS -------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Blue button bg
          foregroundColor: AppColors.white, // White icons & title text
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      /// ------- CARDS -------
      cardTheme: CardThemeData(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: AppColors.white,
      ),

      /// ------- TEXT FIELDS -------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),

      /// ------- ICONS -------
      iconTheme: const IconThemeData(color: AppColors.primary, size: 26),

      /// ------- BOTTOM NAV BAR -------
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
