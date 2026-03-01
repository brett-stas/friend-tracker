import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GarminColors {
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

ThemeData buildGarminTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: GarminColors.background,
    colorScheme: const ColorScheme.dark(
      primary: GarminColors.orange,
      onPrimary: GarminColors.background,
      secondary: GarminColors.orange,
      onSecondary: GarminColors.background,
      surface: GarminColors.surface,
      onSurface: GarminColors.textPrimary,
      error: GarminColors.error,
    ),
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.oswald(
        color: GarminColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
      displayMedium: GoogleFonts.oswald(
        color: GarminColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
      titleLarge: GoogleFonts.oswald(
        color: GarminColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.05,
      ),
      titleMedium: GoogleFonts.roboto(
        color: GarminColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.roboto(
        color: GarminColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: GarminColors.textSecondary,
        fontSize: 14,
      ),
      labelLarge: GoogleFonts.oswald(
        color: GarminColors.background,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: GarminColors.background,
      foregroundColor: GarminColors.textPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.oswald(
        color: GarminColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
    ),
    cardTheme: const CardTheme(
      color: GarminColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GarminColors.orange,
        foregroundColor: GarminColors.background,
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
        foregroundColor: GarminColors.textPrimary,
        side: const BorderSide(color: GarminColors.textSecondary),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GarminColors.orange,
      foregroundColor: GarminColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: GarminColors.divider,
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: GarminColors.surface,
      selectedItemColor: GarminColors.orange,
      unselectedItemColor: GarminColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GarminColors.surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        borderSide: BorderSide(color: GarminColors.divider),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        borderSide: BorderSide(color: GarminColors.divider),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        borderSide: BorderSide(color: GarminColors.orange, width: 2),
      ),
      labelStyle: GoogleFonts.roboto(color: GarminColors.textSecondary),
      hintStyle: GoogleFonts.roboto(color: GarminColors.textMuted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? GarminColors.orange
              : GarminColors.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? GarminColors.orangeDark
              : GarminColors.divider),
    ),
  );
}
