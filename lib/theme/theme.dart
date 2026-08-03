import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF003527);
  static const Color primaryGreenDarkMapped = Color(0xFF0A3A2A);
  static const Color goldAccent = Color(0xFFC5A059);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    useMaterial3: true,
    fontFamily: GoogleFonts.cairo().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: goldAccent,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Color(0xFF1E1E1E),
      surfaceContainerHighest: Color(0xFFECEEED),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      iconTheme: const IconThemeData(color: primaryGreen),
      titleTextStyle: GoogleFonts.amiri(
        color: primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
      bodyLarge: GoogleFonts.cairo(color: const Color(0xFF1E1E1E)),
      bodyMedium: GoogleFonts.cairo(color: const Color(0xFF475569)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGreenDarkMapped,
    scaffoldBackgroundColor: const Color(0xFF051C14),
    useMaterial3: true,
    fontFamily: GoogleFonts.cairo().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreenDarkMapped,
      secondary: goldAccent,
      surface: Color(0xFF0F2C20),
      onPrimary: Colors.white,
      onSurface: Color(0xFFF0F0F0),
      surfaceContainerHighest: Color(0xFF143A2B),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      iconTheme: const IconThemeData(color: goldAccent),
      titleTextStyle: GoogleFonts.amiri(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: GoogleFonts.cairo(color: const Color(0xFFF0F0F0)),
      bodyMedium: GoogleFonts.cairo(color: Colors.white70),
    ),
  );
}

// Glassmorphism Adaptation Extension
extension GlassmorphismTheme on BuildContext {
  Color get glassBackgroundColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.8);
  }

  Color get glassBorderColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFFC5A059).withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.3);
  }
}

// Central Typography Extension
extension AppTypography on BuildContext {
  TextStyle cairo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(this).colorScheme.onSurface,
      height: height,
      decoration: decoration,
    );
  }

  TextStyle amiri({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(this).colorScheme.onSurface,
      height: height,
    );
  }

  TextStyle arefRuqaa({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.arefRuqaa(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(this).colorScheme.onSurface,
    );
  }

  TextStyle outfit({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(this).colorScheme.onSurface,
      letterSpacing: letterSpacing,
    );
  }
}
