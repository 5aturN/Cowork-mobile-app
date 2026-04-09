import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Типографика приложения на основе Manrope
class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.15,
      ),
      
      // Headline styles
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
      ),
      
      // Title styles
      titleLarge: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      
      // Body styles
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      
      // Label styles
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }
}
