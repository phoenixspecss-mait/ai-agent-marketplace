import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color emeraldGreen = Color(0xFF00B894);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color darkBackground = Color(0xFF0C1311);
  static const Color cardDark = Color(0xFF15201D);
  static const Color inputBackground = Color(0xFF16221F);

  static const Color primaryPurple = emeraldGreen;
  static const Color errorRed = Color(0xFFFF5252);
  static const Color successGreen = Color(0xFF00B894);
  static const Color warningOrange = Color(0xFFFFB74D);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: emeraldGreen,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: emeraldGreen,
      surface: cardDark,
      onSurface: Colors.white,
      error: errorRed,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.normal, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFFD1D5DB)),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF9CA3AF)),
    ),
    dividerColor: const Color(0xFF263330),
    iconTheme: const IconThemeData(color: Colors.white),
    cardTheme: CardThemeData(
      color: cardDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF263330), width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackground,
      selectedItemColor: emeraldGreen,
      unselectedItemColor: Color(0xFF6B7280),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF263833), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF263833), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: emeraldGreen, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF9CA3AF), fontSize: 15),
    ),
  );

  static final ThemeData lightTheme = darkTheme;
}
