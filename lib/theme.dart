// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Color Palette
  static const Color primaryColor = Color(0xFF4C8DAE); // Calming blue
  static const Color primaryLightColor = Color(0xFF6CABC9); // Lighter blue
  static const Color primaryDarkColor = Color(0xFF337799); // Darker blue

  // Accent Colors
  static const Color accentColor = Color(0xFFE2966C); // Warm terracotta
  static const Color accentLightColor = Color(0xFFF4B896); // Lighter terracotta
  static const Color accentDarkColor = Color(0xFFD17A4B); // Darker terracotta

  // Background Colors
  static const Color backgroundColor = Color(0xFFF9F7F3); // Warm off-white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Card background

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF35424A); // Dark blue-gray
  static const Color textSecondaryColor = Color(0xFF6B7C85); // Medium blue-gray
  static const Color textTertiaryColor = Color(0xFF9EACB4); // Light blue-gray

  // Functional Colors
  static const Color successColor = Color(0xFF76B99E); // Soothing green
  static const Color warningColor = Color(0xFFF7D06F); // Soft yellow
  static const Color errorColor = Color(0xFFE57373); // Gentle red
  static const Color infoColor = Color(0xFF64B5F6); // Light blue

  // Status Colors for medical urgency
  static const Color lowUrgencyColor = Color(0xFF88C399); // Soft green
  static const Color mediumUrgencyColor = Color(0xFFFFCC80); // Soft orange
  static const Color highUrgencyColor = Color(0xFFE57373); // Soft red
  static const Color emergencyColor = Color(0xFFD32F2F); // Deeper red

  // Gradient for header elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryLightColor,
      secondary: accentColor,
      secondaryContainer: accentLightColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,

    // AppBar styling
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      centerTitle: false,
    ),

    // Text styling
    textTheme: TextTheme(
      // Large titles
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),

      // Headings
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),

      // Titles and subtitles
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondaryColor,
      ),

      // Body text
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
        height: 1.5,
      ),

      // Labels
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textTertiaryColor,
      ),
    ),

    // Card styling
    cardTheme: CardTheme(
      color: cardBackgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: textTertiaryColor.withOpacity(0.1), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shadowColor: Colors.black.withOpacity(0.1),
    ),

    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),

    // Text button styling
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Outlined button styling
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Icon styling
    iconTheme: IconThemeData(color: primaryColor, size: 24),

    // Input field styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: textTertiaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: textTertiaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: GoogleFonts.poppins(fontSize: 16, color: textSecondaryColor),
      hintStyle: GoogleFonts.poppins(fontSize: 16, color: textTertiaryColor),
    ),

    // Divider styling
    dividerTheme: DividerThemeData(
      color: textTertiaryColor.withOpacity(0.2),
      thickness: 1,
      space: 24,
    ),

    // Chip styling
    chipTheme: ChipThemeData(
      backgroundColor: primaryLightColor.withOpacity(0.15),
      disabledColor: textTertiaryColor.withOpacity(0.1),
      selectedColor: primaryColor.withOpacity(0.3),
      secondarySelectedColor: accentColor.withOpacity(0.3),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: primaryColor),
      secondaryLabelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: textSecondaryColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Checkbox styling
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Bottom navigation bar styling
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiaryColor,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      elevation: 8,
    ),

    // Progress indicator styling
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: primaryLightColor.withOpacity(0.2),
      linearTrackColor: primaryLightColor.withOpacity(0.2),
    ),
  );

  // Helper methods for consistent UI elements

  // Create a gradient container for headers
  static Widget gradientHeader({required Widget child, double height = 200}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: child,
    );
  }

  // Create a styled card with consistent shadow and border radius
  static Widget styledCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softShadow,
      ),
      padding: padding ?? EdgeInsets.all(16),
      child: child,
    );
  }
}
