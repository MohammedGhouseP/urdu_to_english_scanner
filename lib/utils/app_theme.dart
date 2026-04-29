import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color navy = Color(0xFF0E2A47);
  static const Color gold = Color(0xFFC9A24A);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color ink = Color(0xFF1B1B1B);
  static const Color slate = Color(0xFF445063);
  static const Color paper = Color(0xFFF6EFE0);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: navy,
        secondary: gold,
        surface: cream,
        onPrimary: cream,
        onSecondary: ink,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: navy,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.sourceSerif4TextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: navy,
      ),
      cardTheme: CardTheme(
        color: paper,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: cream,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: gold, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    const dNavy = Color(0xFF0A1A2E);
    const dPaper = Color(0xFF12233A);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: gold,
        surface: dNavy,
        onPrimary: ink,
        onSecondary: ink,
        onSurface: cream,
      ),
      scaffoldBackgroundColor: dNavy,
      appBarTheme: AppBarTheme(
        backgroundColor: dNavy,
        foregroundColor: gold,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: gold,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.sourceSerif4TextTheme(base.textTheme).apply(
        bodyColor: cream,
        displayColor: gold,
      ),
      cardTheme: CardTheme(
        color: dPaper,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static TextStyle nastaliq({double size = 18, Color? color}) {
    return GoogleFonts.notoNastaliqUrdu(
      fontSize: size,
      color: color,
      height: 1.9,
    );
  }
}
