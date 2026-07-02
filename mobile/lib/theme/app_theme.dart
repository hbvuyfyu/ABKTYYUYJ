import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Black & White premium palette
  static const Color primary = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFFE8E8E8);
  static const Color accent = Color(0xFF000000);
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceVariant = Color(0xFF141414);
  static const Color cardBg = Color(0xFF111111);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9A);
  static const Color textHint = Color(0xFF555555);
  static const Color success = Color(0xFF00D97E);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4757);
  static const Color border = Color(0xFF222222);
  static const Color glassBorder = Color(0x33FFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.cairo(color: textPrimary),
        bodyMedium: GoogleFonts.cairo(color: textSecondary),
        bodySmall: GoogleFonts.cairo(color: textHint),
        labelLarge: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.cairo(color: textSecondary),
        hintStyle: GoogleFonts.cairo(color: textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
    );
  }
}

// 3D card decoration helper
class GlassCard {
  static BoxDecoration decoration({double radius = 20, Color? color, bool glow = false}) {
    return BoxDecoration(
      color: color ?? AppTheme.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      boxShadow: glow
        ? [BoxShadow(color: Colors.white.withOpacity(0.08), blurRadius: 30, spreadRadius: 2, offset: const Offset(0, 4))]
        : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
    );
  }

  static BoxDecoration gradientDecoration({double radius = 20}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 25, offset: const Offset(0, 10))],
    );
  }
}
