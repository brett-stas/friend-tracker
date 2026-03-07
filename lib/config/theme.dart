import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GTrackerColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const card = Color(0xFF242424);
  static const divider = Color(0xFF2E2E2E);
  static const orange = Color(0xFFFF9B00);
  static const orangeDark = Color(0xFFCC7C00);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF727272);
  static const textMuted = Color(0xFF4A4A4A);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
}

ThemeData buildGTrackerTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: GTrackerColors.background,
    colorScheme: const ColorScheme.dark(
      primary: GTrackerColors.orange,
      onPrimary: GTrackerColors.background,
      secondary: GTrackerColors.orange,
      onSecondary: GTrackerColors.background,
      surface: GTrackerColors.surface,
      onSurface: GTrackerColors.textPrimary,
      error: GTrackerColors.error,
    ),
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.oswald(
        color: GTrackerColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
      displayMedium: GoogleFonts.oswald(
        color: GTrackerColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
      titleLarge: GoogleFonts.oswald(
        color: GTrackerColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.05,
      ),
      titleMedium: GoogleFonts.roboto(
        color: GTrackerColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.roboto(
        color: GTrackerColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: GTrackerColors.textSecondary,
        fontSize: 14,
      ),
      labelLarge: GoogleFonts.oswald(
        color: GTrackerColors.background,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: GTrackerColors.background,
      foregroundColor: GTrackerColors.textPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.oswald(
        color: GTrackerColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
    ),
    cardTheme: const CardThemeData(
      color: GTrackerColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GTrackerColors.orange,
        foregroundColor: GTrackerColors.background,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        textStyle: GoogleFonts.oswald(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GTrackerColors.textPrimary,
        side: const BorderSide(color: GTrackerColors.textSecondary),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GTrackerColors.orange,
      foregroundColor: GTrackerColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: GTrackerColors.divider,
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: GTrackerColors.surface,
      selectedItemColor: GTrackerColors.orange,
      unselectedItemColor: GTrackerColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GTrackerColors.surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        borderSide: BorderSide(color: GTrackerColors.divider),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        borderSide: BorderSide(color: GTrackerColors.divider),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        borderSide: BorderSide(color: GTrackerColors.orange, width: 2),
      ),
      labelStyle: GoogleFonts.roboto(color: GTrackerColors.textSecondary),
      hintStyle: GoogleFonts.roboto(color: GTrackerColors.textMuted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? GTrackerColors.orange
              : GTrackerColors.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? GTrackerColors.orangeDark
              : GTrackerColors.divider),
    ),
  );
}
