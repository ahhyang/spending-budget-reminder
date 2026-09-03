import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark finance palette — deep forest base, mint signal, amber warning.
abstract final class StashColors {
  static const bg = Color(0xFF0A0F0D);
  static const surface = Color(0xFF121916);
  static const surfaceHigh = Color(0xFF1A2420);
  static const border = Color(0xFF2A3832);
  static const mint = Color(0xFF3DDC97);
  static const mintDim = Color(0xFF1F8F62);
  static const amber = Color(0xFFE8B84A);
  static const coral = Color(0xFFFF6B5A);
  static const text = Color(0xFFE7EEEA);
  static const textMuted = Color(0xFF8FA39A);
  static const income = Color(0xFF3DDC97);
  static const expense = Color(0xFFFF6B5A);
}

ThemeData buildStashTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: StashColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: StashColors.surface,
      primary: StashColors.mint,
      secondary: StashColors.amber,
      error: StashColors.coral,
      onPrimary: Color(0xFF062217),
      onSurface: StashColors.text,
      outline: StashColors.border,
    ),
  );

  final textTheme = GoogleFonts.soraTextTheme(base.textTheme).apply(
    bodyColor: StashColors.text,
    displayColor: StashColors.text,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: StashColors.bg,
      foregroundColor: StashColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: StashColors.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: StashColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: StashColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: StashColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: StashColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: StashColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: StashColors.mint, width: 1.5),
      ),
      labelStyle: const TextStyle(color: StashColors.textMuted),
      hintStyle: const TextStyle(color: StashColors.textMuted),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: StashColors.mint,
      foregroundColor: Color(0xFF062217),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: StashColors.surface,
      selectedItemColor: StashColors.mint,
      unselectedItemColor: StashColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: StashColors.border,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: StashColors.surfaceHigh,
      contentTextStyle: GoogleFonts.sora(color: StashColors.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
