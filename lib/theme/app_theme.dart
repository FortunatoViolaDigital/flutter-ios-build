import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF0E0E10);
  static const Color backgroundDark2 = Color(0xFF17171A);
  static const Color surfaceDark = Color(0xFF1A1B1F);
  static const Color surfaceDark2 = Color(0xFF22232A);

  static const Color primaryGreen = Color(0xFF1D8548);
  static const Color goldLuxury = Color(0xFFE7B215);
  static const Color goldSoft = Color(0xFFFFD76A);
  static const Color softWhite = Color(0xFFF5F5F5);
  static const Color mutedText = Color(0xFFB8B8C2);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: goldLuxury,
        surface: surfaceDark,
        onPrimary: softWhite,
        onSecondary: Colors.black,
        onSurface: softWhite,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme).apply(
        bodyColor: softWhite,
        displayColor: softWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: softWhite),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1D1E23),
        contentTextStyle: GoogleFonts.urbanist(
          color: softWhite,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(primaryGreen),
          foregroundColor: const WidgetStatePropertyAll(softWhite),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.urbanist(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldSoft,
          side: BorderSide(color: goldSoft.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16171A),
        labelStyle: const TextStyle(color: softWhite),
        hintStyle: TextStyle(color: mutedText.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: goldLuxury.withValues(alpha: 0.7), width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}
