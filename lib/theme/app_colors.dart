import 'package:flutter/material.dart';

class AppColors {
  // ─── Core Backgrounds ───
  static const backgroundDeep = Color(0xFF0A0A0F);
  static const surfaceCard = Color(0xFF141420);
  static const surfaceElevated = Color(0xFF1E1E2E);

  // ─── Accents ───
  static const pulseRed = Color(0xFFFF3B5C);
  static const voltCyan = Color(0xFF00E5CC);
  static const irisViolet = Color(0xFF8B5CF6);
  static const solarAmber = Color(0xFFF59E0B);

  // ─── Text & Borders ───
  static const textPrimary = Color(0xFFF2F2F7);
  static const textSecondary = Color(0xFF8E8E9E);
  static const borderSubtle = Color(0xFF2C2C3E);

  // ─── Legacy Mapping (to prevent immediate build errors during transition) ───
  static const primary = irisViolet;
  static const primaryLight = Color(0xFFA29BFE);
  static const primaryContainer = Color(0xFF8B7CF6);
  static const secondary = voltCyan;
  static const coral = pulseRed;
  static const green = Color(0xFF43E97B);
  static const blue = Color(0xFF4FACFE);
  static const pink = Color(0xFFF093FB);
  static const yellow = Color(0xFFFECA57);
  static const teal = Color(0xFF00B894);
  static const orange = Color(0xFFFF9F43);
  
  static const darkBg = backgroundDeep;
  static const darkSurface = surfaceCard;
  static const darkSurfaceContainer = surfaceElevated;
  static const darkSurfaceContainerLow = Color(0xFF0E1830);
  static const darkSurface2 = Color(0xFF1A2540);
  static const darkOnSurface = textPrimary;
  static const darkOnSurfaceVariant = textSecondary;
  static const darkOutline = borderSubtle;

  static const lightBg = Color(0xFFF0F2F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF5F5FA);
  static const lightSurfaceContainerLow = Color(0xFFF8F8FC);
  static const lightOnSurface = Color(0xFF1A1B2E);
  static const lightOnSurfaceVariant = Color(0xFF6B6B7B);
  static const lightOutline = Color(0xFFD0D0D8);

  // ─── Glass & Opacity Helpers ───
  static Color glassWhite(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => Colors.black.withValues(alpha: opacity);

  // ─── Gradients ───
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCoral = LinearGradient(
    colors: [Color(0xFFFF3B5C), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCyan = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientAmber = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFECA57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSecondary = LinearGradient(
    colors: [Color(0xFF00D2D3), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBlue = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientPink = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientStreak = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFECA57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
