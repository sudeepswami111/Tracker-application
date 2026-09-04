import 'package:flutter/material.dart';

class AppColors {
  // ─── Reference Design System Palette (Light Theme Truth) ───
  static const primaryGreen = Color(0xFF4CAF50);    // Steps, walking, completed activity, positive status
  static const primaryTeal = Color(0xFF00C4B4);     // Primary actions, running, active navigation, progress
  static const secondaryBlue = Color(0xFF6366F1);   // Study, workouts, focus timers, selected states
  static const accentOrange = Color(0xFFFFBA00);    // Streak flame, calories, warnings, motivation
  static const accentCoral = Color(0xFFFF6B6B);     // Heart rate, alerts, liked reactions
  static const neutralGray = Color(0xFF64748B);     // Secondary text, icons, inactive states
  static const lightBg = Color(0xFFF0F4F8);         // Global background
  static const cardWhite = Color(0xFFFFFFFF);       // Cards, modals, sheets
  static const cardBorder = Color(0xFFE2E8F0);      // Subtle border for light surfaces
  static const textPrimary = Color(0xFF0F172A);     // Deep slate text for high readability
  static const textSecondary = Color(0xFF64748B);   // Muted slate text

  // ─── Bio-Harmonic / Zen Aliases ───
  static const zenDarkBg = Color(0xFF0B1320);
  static const zenDarkCard = Color(0xFF131F2E);
  static const zenDarkElevated = Color(0xFF1B2B3E);
  static const zenMint = primaryGreen;
  static const zenMintLight = Color(0xFF81C784);
  static const zenAmber = accentOrange;
  static const zenAmberLight = Color(0xFFFFD54F);
  static const zenLavender = secondaryBlue;
  static const zenLavenderLight = Color(0xFF9FA8DA);
  static const zenSky = primaryTeal;
  static const zenSkyLight = Color(0xFF4DD0E1);
  static const zenCoral = accentCoral;
  static const zenCoralLight = Color(0xFFFF8A80);
  static const zenBorder = cardBorder;

  // ─── Semantic Aliases ───
  static const pulseRed = accentCoral;
  static const voltCyan = primaryTeal;
  static const irisViolet = secondaryBlue;
  static const solarAmber = accentOrange;
  static const borderSubtle = cardBorder;

  // ─── Legacy Mapping & Theme Compatibility ───
  static const primary = primaryTeal;
  static const primaryLight = Color(0xFF4DD0E1);
  static const primaryContainer = Color(0xFFE0F7FA);
  static const secondary = secondaryBlue;
  static const coral = accentCoral;
  static const green = primaryGreen;
  static const blue = secondaryBlue;
  static const pink = Color(0xFFF093FB);
  static const yellow = accentOrange;
  static const teal = primaryTeal;
  static const orange = accentOrange;

  static const backgroundDeep = lightBg;
  static const surfaceCard = cardWhite;
  static const surfaceElevated = cardWhite;

  static const darkBg = Color(0xFF0B1320);
  static const darkSurface = Color(0xFF131F2E);
  static const darkSurfaceContainer = Color(0xFF1B2B3E);
  static const darkSurfaceContainerLow = Color(0xFF0E1830);
  static const darkSurface2 = Color(0xFF1A2540);
  static const darkOnSurface = Color(0xFFF8FAFC);
  static const darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const darkOutline = Color(0xFF334155);

  static const lightSurface = cardWhite;
  static const lightSurfaceContainer = cardWhite;
  static const lightSurfaceContainerLow = Color(0xFFF8FAFC);
  static const lightOnSurface = textPrimary;
  static const lightOnSurfaceVariant = textSecondary;
  static const lightOutline = cardBorder;

  // ─── Glass & Opacity Helpers ───
  static Color glassWhite(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => Colors.black.withValues(alpha: opacity);

  // ─── Gradients from Reference Image ───
  static const gradientTealGreen = LinearGradient(
    colors: [primaryTeal, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBlueTeal = LinearGradient(
    colors: [secondaryBlue, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientStartRun = LinearGradient(
    colors: [secondaryBlue, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientPrimary = gradientBlueTeal;
  static const gradientCyan = gradientTealGreen;

  static const gradientCoral = LinearGradient(
    colors: [Color(0xFFFF8A80), accentCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientAmber = LinearGradient(
    colors: [accentOrange, Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSecondary = LinearGradient(
    colors: [primaryTeal, Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF81C784), primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBlue = LinearGradient(
    colors: [Color(0xFF818CF8), secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientPink = LinearGradient(
    colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientStreak = LinearGradient(
    colors: [accentCoral, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
