import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Palette ───
  static const primary = Color(0xFF6C5CE7);
  static const primaryContainer = Color(0xFF8B7CF6);
  static const primaryLight = Color(0xFFA29BFE);

  // ─── Accent Colors ───
  static const secondary = Color(0xFF00D2D3);
  static const coral = Color(0xFFFF6B6B);
  static const green = Color(0xFF43E97B);
  static const blue = Color(0xFF4FACFE);
  static const pink = Color(0xFFF093FB);
  static const yellow = Color(0xFFFECA57);
  static const teal = Color(0xFF00B894);
  static const orange = Color(0xFFFF9F43);

  // ─── Dark Theme ───
  static const darkBg = Color(0xFF0B1326);
  static const darkSurface = Color(0xFF111B33);
  static const darkSurfaceContainer = Color(0xFF162040);
  static const darkSurfaceContainerLow = Color(0xFF0E1830);
  static const darkSurface2 = Color(0xFF1A2540);
  static const darkOnSurface = Color(0xFFE8E6F0);
  static const darkOnSurfaceVariant = Color(0xFFC8C4D7);
  static const darkOutline = Color(0xFF3D3A50);

  // ─── Light Theme ───
  static const lightBg = Color(0xFFF0F2F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF5F5FA);
  static const lightSurfaceContainerLow = Color(0xFFF8F8FC);
  static const lightOnSurface = Color(0xFF1A1B2E);
  static const lightOnSurfaceVariant = Color(0xFF6B6B7B);
  static const lightOutline = Color(0xFFD0D0D8);

  // ─── Glass ───
  static Color glassWhite(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => Colors.black.withValues(alpha: opacity);

  // ─── Gradients ───
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSecondary = LinearGradient(
    colors: [Color(0xFF00D2D3), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCoral = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
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
