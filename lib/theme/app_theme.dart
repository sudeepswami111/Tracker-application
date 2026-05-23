import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark({Color accentColor = AppColors.voltCyan}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDeep,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderSubtle,
        error: AppColors.pulseRed,
        surfaceContainerHighest: AppColors.surfaceElevated,
        surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, height: 52/48, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, height: 40/34, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, height: 28/22, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, height: 22/17, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 22/15, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 18/13, color: AppColors.textSecondary),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, height: 14/11, color: AppColors.textSecondary),
        displaySmall: GoogleFonts.dmMono(fontSize: 28, fontWeight: FontWeight.w600, height: 32/28, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, height: 28/22, color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderSubtle),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
      ),
    );
  }

  static ThemeData light({Color accentColor = AppColors.voltCyan}) {
    const lightOnSurface = AppColors.lightOnSurface;
    const lightOnSurfaceVariant = AppColors.lightOnSurfaceVariant;
    const lightSurface = AppColors.lightSurface;
    const lightSurfaceContainer = AppColors.lightSurfaceContainer;
    const lightBg = AppColors.lightBg;
    const lightOutline = AppColors.lightOutline;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: lightSurface,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
        outline: lightOutline,
        error: AppColors.pulseRed,
        surfaceContainerHighest: lightSurfaceContainer,
        surfaceContainerLow: AppColors.lightSurfaceContainerLow,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, height: 52/48, color: lightOnSurface),
        displayMedium: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, height: 40/34, color: lightOnSurface),
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, height: 28/22, color: lightOnSurface),
        headlineMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, height: 22/17, color: lightOnSurface),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 22/15, color: lightOnSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 18/13, color: lightOnSurfaceVariant),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, height: 14/11, color: lightOnSurfaceVariant),
        displaySmall: GoogleFonts.dmMono(fontSize: 28, fontWeight: FontWeight.w600, height: 32/28, color: lightOnSurface),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: lightOutline, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightOnSurface),
        titleTextStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, height: 28/22, color: lightOnSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: lightOnSurfaceVariant),
        hintStyle: TextStyle(color: lightOnSurfaceVariant.withValues(alpha: 0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightOnSurface,
          side: const BorderSide(color: lightOutline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightOutline),
      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightOutline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accentColor : lightOutline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? accentColor.withValues(alpha: 0.3)
                : lightOutline.withValues(alpha: 0.3)),
      ),
    );
  }
}
