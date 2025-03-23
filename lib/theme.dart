// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF26A69A); // Teal
  static const Color accentColor = Color(0xFFFF8A65); // Soft coral
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color textColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: backgroundColor, // Using surface instead of background.
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      // Updated keys to the latest naming conventions:
      displayLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textColor),
      titleMedium: TextStyle(fontSize: 16, color: secondaryTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Replaces primary.
        foregroundColor: Colors.white, // Replaces onPrimary.
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: primaryColor),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );
}
